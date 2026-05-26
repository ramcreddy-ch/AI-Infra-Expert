# TPU Architecture & Operations

Tensor Processing Units (TPUs) are custom Application-Specific Integrated Circuits (ASICs) designed by Google specifically for machine learning workloads. This guide covers TPU architecture, generations, Pod networking, and how to operate them.

---

## 1. How TPUs Work: Systolic Arrays and MXUs

While a GPU relies on general-purpose SIMD execution (Streaming Multiprocessors executing instructions across threads), a TPU uses a specialized hardware structure called a **Matrix Multiply Unit (MXU)** which is implemented as a **Systolic Array**.

### The Systolic Array Concept
*   In a typical processor (CPU/GPU), the arithmetic units execute an instruction, read inputs from registers, write results to registers, and repeat. Register file access consumes a major portion of power and time.
*   In a Systolic Array, data streams through a grid of processing elements (multiply-accumulate cells) continuously. The output of one cell is connected directly to the input of the adjacent cell.
*   Data flows through the grid like blood through the cardiovascular system (hence "systolic"), computing matrix multiplications without accessing register files at every step. This makes TPUs incredibly energy-efficient and fast for matrix math.

```
       Input Weights (Loaded once)
             ↓        ↓
  Data In ──> [MAC] ──> [MAC] ──> Data Out
             ↓        ↓
  Data In ──> [MAC] ──> [MAC] ──> Data Out
             ↓        ↓
```

---

## 2. TPU Generations Spec Comparison

| Specification | TPU v2 (2017) | TPU v3 (2018) | TPU v4 (2021) | TPU v5e (2023) | TPU v5p (2023) | TPU v6e (2024/2025) |
|---|---|---|---|---|---|---|
| **Form Factor** | TPU Pod | TPU Pod | TPU Pod | TPU Pod | TPU Pod | TPU Pod |
| **Chips per Board** | 4 | 4 | 4 | 4 | 4 | 4 |
| **HBM Memory per Chip**| 8 GB | 16 GB | 32 GB | 16 GB | 96 GB | 32 GB / 64 GB |
| **Memory Bandwidth** | 700 GB/s | 900 GB/s | 1.2 TB/s | 819 GB/s | 4.8 TB/s | 3.2 TB/s |
| **Peak FP16 TFLOPS** | 45 | 90 | 275 | 197 | 459 | 800+ |
| **Int8/Int4 Support** | No | No | Yes | Yes | Yes | Yes |
| **Max Pod Config** | 256 chips | 2048 chips | 4096 chips | 256 chips | 8960 chips | 16384 chips |
| **Interconnect (ICI)** | Torus (2D) | Torus (2D) | Torus (3D) | Torus (2D) | Torus (3D) | Torus (3D) |

---

## 3. TPU Pod Architecture & ICI (Inter-Chip Interconnect)

A unique advantage of Google Cloud's TPU offering is their hardware network topology.
*   **ICI (Inter-Chip Interconnect):** Every TPU chip contains dedicated network interfaces that allow direct chip-to-chip communication without routing through host CPUs or standard network switches (bypassing TCP/IP overhead).
*   **Torus Topology:** TPU Pods are connected in 2D or 3D torus topologies. This means each node has direct paths to its neighbors in X, Y, and Z directions, providing massive bisection bandwidth.
*   **TPU Slices:** Users can rent virtual subsets of a TPU Pod, ranging from a single host (e.g., `v4-8` = 4 chips, 8 TPU VM cores) to complete pods (e.g., `v4-4096`).

---

## 4. TPU vs. GPU Comparison

| Dimension | Google TPU | NVIDIA GPU |
|---|---|---|
| **Ecosystem** | Cloud-only (Google Cloud Platform) | Cloud (AWS, Azure, GCP) & On-Premises |
| **Primary Frameworks**| JAX, TensorFlow, PyTorch (via PyTorch-XLA) | PyTorch, JAX, TensorFlow (Native CUDA support)|
| **Precision Options** | bfloat16 (Native), int8, float32 | float16, bfloat16, FP8, float32, int4/8 |
| **Compiler Pipeline** | Mandatory XLA compilation | CUDA compiler / Triton / PyTorch Eager / Inductor |
| **Interconnect Network**| Integrated ICI (Direct Torus) | NVLink (Intra-node) + InfiniBand (Inter-node) |
| **Ideal Use Case** | Large-scale LLM training, JAX workloads | General deep learning, serving, active CUDA development |

---

## 5. The JAX/XLA Compilation Pipeline

TPUs cannot run arbitrary code. They require models to be compiled into optimized graphs via the **XLA (Accelerated Linear Algebra)** compiler.

```
  PyTorch / JAX Code
         │
         ▼
    Jaxpr / FX Graph (Intermediate Representation)
         │
         ▼
  StableHLO (Hardware-independent compiler input)
         │
         ▼
  XLA Compiler (Performs layout optimization, memory fusion)
         │
         ▼
  TPU Machine Code (Binary executable)
```

### Pro-Tip: Avoid Compilation Overhead
XLA compiles code based on the shapes of input tensors. If tensor shapes change frequently (e.g., dynamic sequence lengths in batches), XLA will trigger a recompilation for every new shape, causing severe latency spikes ("compilation storms").
*   **Solution:** Pad your inputs to fixed static bucket sizes (e.g., sequence lengths of 128, 256, 512, 1024) to reuse compiled graphs.

---

## 6. How to Configure and Run TPU Workloads

To provision and run a simple training workload on a GCP TPU VM:

```bash
# Provision a TPU v4-8 VM in us-central2-b
gcloud compute tpus tpu-vm create my-tpu-vm \
    --zone=us-central2-b \
    --accelerator-type=v4-8 \
    --version=tpu-vm-v4-base

# SSH into the TPU VM
gcloud compute tpus tpu-vm ssh my-tpu-vm --zone=us-central2-b

# Install PyTorch-XLA and run diagnostics
pip install torch torchvision torch_xla[tpu] -f https://storage.googleapis.com/tpu-pytorch/releases/tpuv4/snapshots/index.html

# Run simple check script
python -c "import torch; import torch_xla; import torch_xla.core.xla_model as xm; dev = xm.xla_device(); print('TPU Device initialized:', dev)"
```
