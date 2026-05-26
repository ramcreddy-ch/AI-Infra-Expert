# Multi-Instance GPU (MIG)

Multi-Instance GPU (MIG) allows physical GPUs (A100, H100) to be partitioned into separate isolated instances. Each instance has its own dedicated SMs, memory, and internal paths, providing hardware-level quality-of-service (QoS) guarantees.

---

## 1. MIG vs. Time-Slicing

| Dimension | MIG (Multi-Instance GPU) | Time-Slicing |
|---|---|---|
| **Isolation Level** | Hardware (SM, VRAM, and Cache routing level) | Software (Only schedules workloads sequentially) |
| **Fault Isolation** | Yes. If a pod crashes the GPU, other partitions are unaffected. | No. Memory leaks or CUDA crashes affect all sharing pods. |
| **VRAM Limits** | Fixed per slice. Exceeding causes OOM on that slice only. | Shared. One pod can consume all VRAM, starving others. |
| **Performance Overhead**| Near zero. | Context-switching overhead of the CUDA driver. |

---

## 2. Supported MIG Profiles (H100 SXM 80GB)

| Profile Name | SMs | VRAM | Max Instances per GPU |
|---|---|---|---|
| **1g.10gb** | 14 | 10 GB | 7 |
| **2g.20gb** | 28 | 20 GB | 3 |
| **3g.40gb** | 42 | 40 GB | 2 |
| **4g.40gb** | 56 | 40 GB | 1 |
| **7g.80gb** | 112 (Full)| 80 GB | 1 |

---

## 3. Configuring MIG in Kubernetes

### Step 1: Enable MIG on the physical GPU
```bash
# Enable MIG mode on GPU 0
nvidia-smi -i 0 -mig 1

# Create instances (e.g., split one H100 into two 3g.40gb slices)
nvidia-smi mig -cgi 9,9 -C
```

### Step 2: Configure the GPU Operator
In your GPU Operator `values.yaml`, set the MIG strategy:
```yaml
mig:
  strategy: mixed # Options: 'single' (all GPUs partitioned identically) or 'mixed'
```

Once configured, the NVIDIA Device Plugin advertises these slices as individual extended resources:
*   `nvidia.com/mig-3g.40gb: 2` (if split into two 40GB slices)

### Allocating MIG Slices to Pods:
```yaml
spec:
  containers:
  - name: t5-inference
    image: huggingface/transformers-pytorch-gpu
    resources:
      limits:
        nvidia.com/mig-3g.40gb: "1" # Requesting 1 MIG slice
```
