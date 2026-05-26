# CUDA Toolkit & Runtime

Compute Unified Device Architecture (CUDA) is NVIDIA's parallel computing platform and programming model. This guide outlines CUDA components, versions, containerization, and compatibility matrices which are critical to preventing version conflicts in production.

---

## 1. CUDA Toolkit Components

When you install CUDA, you install several components:
1.  **CUDA Driver:** Kernel-level driver (`nvidia.ko`) that interfaces with the physical PCIe device.
2.  **CUDA Runtime API:** High-level library (`libcudart.so`) utilized by deep learning frameworks to allocate memory, manage devices, and launch kernels.
3.  **CUDA Driver API:** Low-level, direct control API (`libcuda.so`) used by systems program level tools.
4.  **Math Libraries:** Highly optimized kernels for mathematical operations:
    - **cuBLAS:** Basic Linear Algebra Subprograms (matrix multiplications).
    - **cuDNN:** CUDA Deep Neural Network library (convolutions, pooling, activation layers).
    - **NCCL:** NVIDIA Collective Communications Library (multi-GPU communication primitives like AllReduce).
5.  **Compiler:** `nvcc` translates CUDA C/C++ code into PTX (Parallel Thread Execution) assembly code.

---

## 2. CUDA Compatibility Matrix

A common production issue is mismatched CUDA versions. You must understand the two main APIs:
*   **Driver API:** Determined by the host kernel driver installed on the OS (e.g., `535.104.05`).
*   **Runtime API:** Packaged inside your application or Docker image (e.g., PyTorch 2.1 includes its own CUDA 12.1 runtime).

### Compatibility Rules
1.  **Host Driver determines maximum CUDA version:** The host driver version must be equal to or greater than the minimum driver version required by the CUDA Runtime version used in the container.
2.  **CUDA Forward Compatibility:** On enterprise systems, if the host driver is slightly older, you can deploy a special user-space forward compatibility package (`cuda-compat`) inside your container to run newer CUDA versions.

| Host Driver Version | Max Supported CUDA Version | Supported PyTorch Version (Typical) |
|---|---|---|
| >= 550.54 | CUDA 12.4 | PyTorch 2.3+ |
| >= 535.54.03 | CUDA 12.2 | PyTorch 2.1 - 2.2 |
| >= 525.60.13 | CUDA 12.0 | PyTorch 2.0 |
| >= 450.80.02 | CUDA 11.0 | PyTorch 1.7 - 1.13 |

---

## 3. How GPU Container Passthrough Works

Docker containers cannot directly access host hardware. NVIDIA uses the **NVIDIA Container Toolkit** to hook into container runtimes (like containerd or Docker) and expose GPU devices to containers.

### Container GPU Passthrough Diagram
```
  ┌────────────────────────────────────────────────────────┐
  │ Docker / Kubernetes Pod                                │
  │   - PyTorch Code                                       │
  │   - CUDA Runtime (libcudart.so)                        │
  └──────────┬─────────────────────────────────────────────┘
             │ (Routes through Container Runtime Hook)
             ▼
  ┌────────────────────────────────────────────────────────┐
  │ NVIDIA Container Runtime Hook (libnvidia-container)    │
  │   - Mounts /dev/nvidia* device files                  │
  │   - Mounts /usr/lib/x86_64-linux-gnu/libcuda.so        │
  └──────────┬─────────────────────────────────────────────┘
             │
             ▼
  ┌────────────────────────────────────────────────────────┐
  │ Host OS Kernel                                         │
  │   - NVIDIA Kernel Driver (nvidia.ko)                   │
  └──────────┬─────────────────────────────────────────────┘
             │ (PCIe / NVLink)
             ▼
  ┌────────────────────────────────────────────────────────┐
  │ Physical NVIDIA GPU Hardware                           │
  └────────────────────────────────────────────────────────┘
```

### Verification Commands

To check container CUDA and GPU status from the host and inside containers:

```bash
# Verify nvidia-container-toolkit is installed and working with Docker:
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# Check what PyTorch detects:
python -c "import torch; print('CUDA Available:', torch.cuda.is_available()); print('Device Count:', torch.cuda.device_count()); print('Device Name:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None')"
```
