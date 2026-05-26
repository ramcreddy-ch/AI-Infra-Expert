# GPU Architecture Deep Dive

To effectively manage GPU resources in production, you must understand their underlying hardware architecture. This guide details the differences between CPUs and GPUs, traces NVIDIA's architectural generations, and explains memory and interconnect topologies.

---

## 1. CPU vs. GPU Architecture

The fundamental difference between a Central Processing Unit (CPU) and a Graphics Processing Unit (GPU) lies in their design goals:
*   **CPUs** are designed for **low-latency** execution of sequential operations. They have large caches, complex control logic (out-of-order execution, branch prediction), and a few powerful execution cores.
*   **GPUs** are designed for **high-throughput** parallel execution. They prioritize executing thousands of simple threads concurrently over executing a single thread quickly.

### Architecture Comparison Diagram

```
           CPU ARCHITECTURE                              GPU ARCHITECTURE
  ┌─────────────────────────────────────────┐     ┌─────────────────────────────────────────┐
  │ ┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐ │     │ ┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐ │
  │ │ Core  │ │ Core  │ │ Core  │ │ Core  │ │     │ └─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘ │
  │ └───────┘ └───────┘ └───────┘ └───────┘ │     │ ┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐┌─┐ │
  │ ┌─────────────────────────────────────┐ │     │ └─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘└─┘ │
  │ │            L1/L2 Caches             │ │     │                   ...                   │
  │ └─────────────────────────────────────┘ │     │          Streaming Multiprocessors      │
  │ ┌─────────────────────────────────────┐ │     │         (Thousands of Arithmetic Units) │
  │ │             Control Unit            │ │     │ ┌─────────────────────────────────────┐ │
  │ └─────────────────────────────────────┘ │     │ │            L2 Cache (SRAM)          │ │
  │ ┌─────────────────────────────────────┐ │     │ └─────────────────────────────────────┘ │
  │ │             DRAM (DDR5)             │ │     │ ┌─────────────────────────────────────┐ │
  │ └─────────────────────────────────────┘ │     │ │             Memory (HBM/GDDR)       │ │
  └─────────────────────────────────────────┘     └─────────────────────────────────────────┘
```

---

## 2. Streaming Multiprocessors (SMs) & Cores

NVIDIA GPUs are organized into **Streaming Multiprocessors (SMs)**. Each SM is a self-contained processing engine that contains execution cores, cache memory, registers, and scheduling logic.

### Streaming Multiprocessor Components
1.  **CUDA Cores:** Arithmetic Logic Units (ALUs) designed to perform integer and single-precision (FP32) floating-point calculations.
2.  **Tensor Cores:** Specialized execution units designed specifically to perform mixed-precision matrix multiply-accumulate (MMA) operations in a single clock cycle. This is the hardware foundation of deep learning.
3.  **Warp Scheduler:** Warps are groups of 32 threads. The scheduler manages the execution of these warps. GPUs hide memory access latency by context-switching warps instantly when one warp is blocked waiting for data.
4.  **Register File:** Massive register files (up to 256KB per SM) to allow thousands of threads to keep their state on-chip without slow DRAM accesses.
5.  **Shared Memory / L1 Cache:** On-chip SRAM shared among threads in the same block.

### NVIDIA GPU Generation Comparison

| Spec | Volta (V100) | Ampere (A100) | Hopper (H100) | Blackwell (B200) |
|---|---|---|---|---|
| **Release Year** | 2017 | 2020 | 2022 | 2024 / 2025 |
| **Process Node** | TSMC 12nm FFN | TSMC 7nm | TSMC 4N (5nm optimized) | TSMC 4NP |
| **Transistor Count** | 21.1 Billion | 54.2 Billion | 80 Billion | 208 Billion (Dual-die) |
| **SM Count** | 80 | 108 (SXM4) / 84 (PCIe) | 132 (SXM5) / 114 (PCIe) | 160 per die (320 total) |
| **Tensor Cores** | 640 (1st Gen) | 432 (3rd Gen) | 528 (4th Gen) | 1280 (5th Gen) |
| **FP32 Compute** | 15.7 TFLOPS | 19.5 FLOPS | 67 TFLOPS | 180 TFLOPS (Non-tensor) |
| **Tensor Compute (FP16/BF16)** | 125 TFLOPS | 312 TFLOPS | 989 TFLOPS | 2,250 TFLOPS |
| **Tensor Compute (FP8)** | N/A | N/A | 1,978 TFLOPS | 4,500 TFLOPS |
| **Memory Type** | HBM2 | HBM2 / HBM2e | HBM3 | HBM3e |
| **Memory Capacity** | 16GB / 32GB | 40GB / 80GB | 80GB / 96GB | 192GB |
| **Memory Bandwidth** | 900 GB/s | 1.6 TB/s / 2.0 TB/s | 3.35 TB/s | 8.0 TB/s |
| **TDP (Power Limit)**| 250W - 300W | 250W (PCIe) / 400W (SXM) | 350W (PCIe) / 700W (SXM) | Up to 1000W - 1200W |

---

## 3. High Bandwidth Memory (HBM) vs. GDDR

GPUs use specialized memory architectures to meet their massive bandwidth requirements:
*   **GDDR (Graphics Double Data Rate):** Found in consumer and inference-focused GPUs (e.g., RTX 4090, L4, L40S, T4). GDDR chips are mounted on the PCB around the GPU die and connected via a wide memory bus (typically 128-bit to 384-bit).
*   **HBM (High Bandwidth Memory):** Found in enterprise training/inference GPUs (e.g., V100, A100, H100, B200). HBM stacks memory dies vertically on a silicon interposer right next to the GPU logic die. This enables ultra-wide memory buses (4096-bit or more) and significantly higher bandwidth at lower power consumption.

---

## 4. Interconnect Topologies: PCIe, NVLink, and NVSwitch

In distributed training, the speed of data transfer between GPUs is often the primary bottleneck.

### PCIe (Peripheral Component Interconnect Express)
- GPUs communicate with the host CPU and memory via PCIe slots.
- **PCIe Gen 4:** Up to 32 GB/s bidirectional bandwidth per x16 slot.
- **PCIe Gen 5:** Up to 64 GB/s bidirectional bandwidth per x16 slot.
- Direct GPU-to-GPU communication via PCIe is slow and routes through the host CPU/PCIe switch.

### NVLink (GPU-to-GPU Interconnect)
- A high-speed, direct GPU-to-GPU bridge bypasses PCIe.
- **NVLink 3 (A100):** Up to 600 GB/s total bidirectional bandwidth per GPU.
- **NVLink 4 (H100):** Up to 900 GB/s total bidirectional bandwidth per GPU.
- **NVLink 5 (B200):** Up to 1.8 TB/s total bidirectional bandwidth per GPU.

### NVSwitch
- On multi-GPU servers (e.g., NVIDIA DGX systems), NVLink channels are connected to physical **NVSwitch** chips on the motherboard.
- This creates an all-to-all crossbar network where every GPU can communicate with any other GPU at full NVLink speeds simultaneously.
- **DGX H100 Architecture:** Contains 8 H100 GPUs and 4 custom NVSwitch chips, enabling 3.2 TB/s of external network bandwidth.

---

## 5. Decoding `nvidia-smi` in Production

The `nvidia-smi` command is the first line of defense for GPU operations. Here is how to read a typical production output.

### Real `nvidia-smi` Output Example:
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.104.05             Driver Version: 535.104.05    CUDA Version: 12.2     |
|-----------------------------------------+----------------------+------------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC   |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M.   |
|                                         |                      |               MIG M.   |
|=========================================+======================+========================|
|   0  NVIDIA H100 SXM5               On  | 00000000:00:04.0 Off |                    0   |
| N/A   42C    P0             320W / 700W |  45120MiB / 81920MiB |    92%      Default   |
|                                         |                      |                  Disabled|
+-----------------------------------------+----------------------+------------------------+
```

### Key Field Breakdown:
1.  **NVIDIA-SMI / Driver / CUDA Version:**
    - Driver `535.104.05` dictates compatibility with CUDA runtimes.
    - CUDA `12.2` represents the max supported CUDA toolkit version of this driver.
2.  **Persistence-M (Persistence Mode):**
    - Set to `On`. This keeps the driver kernel module loaded even when no active application is running, eliminating a ~2-second latency delay to initialize the driver when starting new PyTorch scripts or K8s pods.
3.  **Volatile Uncorr. ECC:**
    - Error Correcting Code. `0` indicates no uncorrectable memory errors have occurred since the last boot.
4.  **Temp & Perf State:**
    - `42C` (Celsius). Normal operating temp. Thermal throttling typically kicks in above 80°C.
    - `P0` performance state (P0 = highest performance, P12 = idle/lowest power).
5.  **Power Usage / Cap:**
    - `320W / 700W`. Currently consuming 320 Watts out of a maximum allowed 700 Watts.
6.  **Memory-Usage:**
    - `45120MiB / 81920MiB`. Shows memory allocated vs. total capacity. Important: This represents allocated VRAM, not necessarily active compute utilisation.
7.  **GPU-Util:**
    - `92%`. The percentage of time over the last sample period that one or more kernels were executing on the GPU.

---

## 6. Pro-Tips for GPU Selection
- **For LLM Training:** High VRAM and high interconnect speed (HBM3/NVLink) are critical. Hopper (H100) or Ampere (A100 SXM) are preferred.
- **For LLM Inference serving:** High memory bandwidth is crucial because LLM decoding is memory-bandwidth bound. vLLM serving benefit heavily from H100 or A100. Lower-cost setups can utilize L40S or L4 with quantization.
- **For computer vision/classic ML training:** PCIe-based GPUs (L4, T4, A10g) are often cost-effective because model parameters are smaller and inter-GPU communication is less intensive.
