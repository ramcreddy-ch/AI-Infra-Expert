# Module 01: GPU & TPU Fundamentals

Welcome to the fundamentals module. Understanding the physical and software layers of GPUs and TPUs is essential to debugging issues like out-of-memory errors, communication bottlenecks, and driver mismatches in production.

## 📚 Table of Contents

1. [**GPU Architecture Deep Dive**](01-gpu-architecture.md)
   - CPU vs GPU architecture design philosophies
   - NVIDIA GPU Generations (Volta, Ampere, Hopper, Blackwell)
   - SMs, CUDA Cores, Tensor Cores, HBM vs GDDR memory
   - PCIe, NVLink, NVSwitch topologies
   - Reading `nvidia-smi` outputs
2. [**TPU Architecture**](02-tpu-architecture.md)
   - Matrix Multiply Units (MXUs) and HBM
   - TPU Generations (v2 through v6e)
   - TPU Pod topologies and ICI
   - TPU vs GPU comparison
   - JAX/XLA compiler pipeline
3. [**CUDA Toolkit & Runtime**](03-cuda-basics.md)
   - nvcc, cuDNN, cuBLAS, NCCL
   - Compute Capabilities
   - Compatibility matrices (Driver vs CUDA vs PyTorch)
   - CUDA Memory Model
   - Container GPU passthrough (NVIDIA Container Toolkit)
4. [**Driver Installation & Runtime Setup**](04-drivers-and-runtime.md)
   - Driver kernel modules and user-space libraries
   - Persistence mode and Fabric Manager
   - Step-by-step container runtime configuration (containerd/CRI-O)
   - Rolling driver upgrades in production
   - Common driver failure scenarios
5. [**GPU Memory Hierarchy & Optimization**](05-memory-hierarchy.md)
   - Registers, L1/L2 caches, Shared Memory, HBM
   - High Bandwidth Memory (HBM2 vs HBM3e)
   - Memory fragmentation and Unified Memory
   - Estimating memory requirements for training & inference (formula guides)
   - Memory optimization techniques (Mixed Precision, Gradient Checkpointing)

---

## 🚦 Recommended Learning Flow

```
[GPU Architecture] ──> [CUDA Toolkit & Container Runtime] ──> [Driver Operations]
                                                                     │
[TPU Architecture] ──> [XLA & JAX Compilation] ──────────────────────┴─> [Memory Hierarchy]
```
