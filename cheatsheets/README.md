# GPU Platform Cheatsheet

Quick reference guide for common GPU commands.

---

## 1. Local GPU Diagnostics (`nvidia-smi`)

```bash
# Query active GPU utilization, temperature, memory, and power draw
nvidia-smi --query-gpu=index,name,utilization.gpu,temperature.gpu,memory.used,power.draw --format=csv -l 1

# List all running graphics or compute processes using VRAM
nvidia-smi pmon

# Enable persistence mode on all local GPUs
sudo nvidia-smi -pm 1

# Cap power draw to 350 Watts on device 0
sudo nvidia-smi -i 0 -pl 350

# Check NVLink connection status
nvidia-smi nvlink --status
```

---

## 2. Kubernetes GPU Operations (`kubectl`)

```bash
# Get details on all nodes that have allocatable GPUs
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.allocatable.nvidia\.com/gpu}{"\n"}{end}'

# Inspect GPU driver logs from the GPU Operator namespace
kubectl logs -n gpu-operator -l app=nvidia-driver-daemonset --tail=100

# View the status of the device plugin pods
kubectl get pods -n gpu-operator -l app=nvidia-device-plugin-daemonset

# Check if GFD (GPU Feature Discovery) applied labels to your nodes
kubectl get nodes --show-labels | grep nvidia.com/gpu
```
