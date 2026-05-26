# Node Feature Discovery (NFD) & GFD

To schedule workloads based on specific hardware properties (e.g., matching a job only to H100 GPUs with at least 80GB of VRAM), Kubernetes needs labels that describe the physical nodes.

---

## 1. NFD and GFD Integration

*   **Node Feature Discovery (NFD):** Scans host hardware and labels worker nodes with general capabilities (e.g., CPU features, kernel version, PCIe devices).
*   **GPU Feature Discovery (GFD):** Runs as a helper container alongside the NVIDIA Device Plugin. It queries the local GPU specifications and applies detailed GPU labels to the Kubernetes node.

### System Flow
```
  [Physical GPU] ──> [NVML API] ──> [GFD Daemonset] ──> [Kubernetes API Server] ──> [Node Labels Applied]
```

---

## 2. Typical GPU Node Labels

Once NFD and GFD are running, `kubectl get node <node> --show-labels` will output properties similar to:

```properties
nvidia.com/gpu.count=8
nvidia.com/gpu.family=hopper
nvidia.com/gpu.memory=81920
nvidia.com/gpu.product=NVIDIA-H100-SXM5
nvidia.com/gpu.driver_version=535.104.05
nvidia.com/cuda.driver.major=12
nvidia.com/cuda.driver.minor=2
```

---

## 3. Targeting Jobs to Specific GPU Types

You can use these labels in pod specifications to match workloads to the appropriate hardware:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: llama-inference-deploy
spec:
  template:
    spec:
      containers:
      - name: vllm
        image: vllm/vllm-openai:latest
        resources:
          limits:
            nvidia.com/gpu: "4"
      nodeSelector:
        nvidia.com/gpu.product: NVIDIA-H100-SXM5
        nvidia.com/gpu.memory: "81920"
```
