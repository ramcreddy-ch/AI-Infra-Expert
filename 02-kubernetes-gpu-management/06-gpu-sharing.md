# GPU Sharing: Time-Slicing, MPS, and Virtualization

For small workloads (e.g., running Jupyter notebooks or small model inference), allocating an entire 80GB GPU is inefficient. When MIG is not supported or too rigid, other sharing strategies can be used.

---

## 1. Sharing Strategies Comparison

| Method | Isolation | Memory Protection | Cost | Setup Complexity |
|---|---|---|---|---|
| **MIG** | Hardware-level | Excellent (hard limits) | Moderate | Medium |
| **Time-Slicing** | Temporal (time sharing) | None | Low | Simple |
| **MPS (Multi-Process Service)** | Logical (shared SMs) | Weak (address spaces) | Low | Medium |
| **vGPU** | Virtualization / Hypervisor | Good | High (Licensing) | High |

---

## 2. Configuring Time-Slicing

Time-slicing configuration is managed by the NVIDIA Device Plugin via a ConfigMap.

### Step 1: Create the ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: device-plugin-config
  namespace: gpu-operator
data:
  any-name: |
    sharing:
      timeSlicing:
        resources:
        - name: nvidia.com/gpu
          replicas: 10 # Virtualize each physical GPU into 10 allocatable units
```

### Step 2: Apply config to the DaemonSet
Once applied, pods requesting `nvidia.com/gpu: 1` will be scheduled concurrently on the same physical card.

---

## 3. CUDA MPS (Multi-Process Service)

CUDA MPS is a client-server architecture that lets multiple CUDA processes share hardware execution resources. Unlike time-slicing (where jobs run sequentially), MPS allows kernels from different processes to run concurrently on the same SMs.

### Deploying MPS in Kubernetes
The GPU Operator simplifies MPS deployment. Enable it in your custom resource configuration:
```yaml
devicePlugin:
  config:
    name: mps-config
    data:
      default:
        sharing:
          mps:
            resources:
            - name: nvidia.com/gpu
              replicas: 10
```
This deploys the MPS control daemon on the nodes, managing thread scheduling and memory limits for sharing pods.
