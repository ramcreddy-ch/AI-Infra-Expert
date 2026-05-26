# GPU Memory Hierarchy & Optimization

Deep learning models are notoriously resource-intensive, pushing GPU memory architectures to their limits. This guide details how GPU memory works and provides formulas and strategies to optimize VRAM utilization.

---

## 1. GPU Memory Hierarchy

GPU memory is structured hierarchically, trading capacity for bandwidth:

```
  ┌────────────────────────────────────────────────────────┐  Latency  Bandwidth
  │ Registers (per thread)                                 │   ~1 ns   ~100 TB/s
  ├────────────────────────────────────────────────────────┤
  │ Shared Memory / L1 Cache (per SM)                      │   ~5 ns   ~50 TB/s
  ├────────────────────────────────────────────────────────┤
  │ L2 Cache (SRAM, Chip-wide)                             │  ~15 ns   ~10 TB/s
  ├────────────────────────────────────────────────────────┤
  │ Global Memory (HBM3e / GDDR6, off-chip VRAM)           │ ~100 ns   ~3-8 TB/s
  └────────────────────────────────────────────────────────┘
```

### High Bandwidth Memory (HBM) Stack
HBM uses TSVs (Through-Silicon Vias) to stack DRAM dies vertically. A 3D stack connects to the GPU via an ultra-wide silicon interposer.
*   **HBM3e (Hopper/Blackwell):** Achieves up to 8.0 TB/s memory bandwidth compared to standard GDDR6 (typically ~1.0 TB/s). This speed is critical for LLMs, which perform massive memory reads during text generation.

---

## 2. Calculating Model VRAM Footprint

To prevent Out-Of-Memory (OOM) errors, you should be able to estimate the memory required for training or inference.

### Equation: Memory Requirements for Training (Mixed Precision)

For an $M$-parameter model trained with Adam optimizer using FP16/BF16 mixed precision, the memory allocation breakdown is:

1.  **Model Weights (FP16/BF16):** 2 bytes per parameter ($2M$).
2.  **Gradients (FP16/BF16):** 2 bytes per parameter ($2M$).
3.  **Adam Optimizer States (FP32):**
    - FP32 copy of model weights (4 bytes).
    - Momentum (4 bytes).
    - Variance (4 bytes).
    - Total Optimizer state = 12 bytes per parameter ($12M$).
4.  **Static Overhead:** $16M$ bytes.

$$\text{Minimum VRAM for Weights/Optimizer} = 16 \times M \text{ bytes}$$

*For a 7 Billion parameter model (LLaMA-7B):*
$$16 \times 7,000,000,000 = 112\text{ GB of VRAM}$$
This exceeds the capacity of a single A100 (80GB) GPU before even accounting for **Activation Memory** (activations stored during the forward pass to compute gradients during backward pass). Thus, multi-GPU parallelism is required.

---

## 3. Profiling VRAM in PyTorch

Use PyTorch's native memory diagnostic tool to identify leaks and layout profiles:

```python
import torch

# Run your dummy model forward/backward pass
device = torch.device("cuda:0")
x = torch.randn(1024, 1024, 16, device=device)
model = torch.nn.Linear(16, 16).to(device)
y = model(x)
y.sum().backward()

# Generate memory summary
print(torch.cuda.memory_summary(device=device))
```

---

## 4. Key Memory Optimization Techniques

When scaling workloads, use these standard mechanisms to reduce VRAM pressure:

### A. Mixed Precision (FP16 / BF16)
- Instead of using standard Single Precision (FP32, 4 bytes), load weight matrices in half precision (FP16 or BF16, 2 bytes). This instantly cuts weight memory in half and unlocks Tensor Core compute speeds.
- **BF16 (Brain Floating Point):** Highly recommended over FP16 because it preserves the exponent bits of FP32, preventing underflow/overflow issues without requiring complex loss scaling.

### B. Gradient Checkpointing
- Saves VRAM at the cost of compute.
- Instead of saving all activation states from the forward pass in memory, gradient checkpointing only saves the activations at block boundaries.
- During the backward pass, intermediate activations are recomputed on-the-fly.
- **Savings:** Reduces activation memory from $O(\text{layers})$ to $O(\sqrt{\text{layers}})$, at the expense of a ~30% increase in execution time.

### C. Unified Memory (UVM)
- Allows CPU and GPU to share a virtual address space.
- Page faults migrate pages dynamically between Host RAM and GPU VRAM.
- **Usage in PyTorch/DeepSpeed:** Offload optimizer states to Host RAM, allowing training of huge models on fewer GPUs at a slower speed.
