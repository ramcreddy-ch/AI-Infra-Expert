# GPU Sharing Strategies

Maximizing GPU utilization is a key cost optimization strategy. This guide discusses how to select and apply sharing strategies based on your workloads.

---

## 1. Selecting a Sharing Strategy

Use this decision matrix to determine how to partition your GPUs:

| Workload Type | Isolation Required | Performance Impact Allowed | Recommended Strategy |
|---|---|---|---|
| **Large-scale LLM Training** | Absolute | None | Dedicated GPU (no sharing) |
| **LLM Inference Serving** | High | Low | Dedicated GPU or MIG (large slices) |
| **Small Task Inference (T5/BERT)**| Medium | Low | MIG (small slices) or MPS |
| **Jupyter Notebooks (Dev)** | Low | High | Time-Slicing |
| **CI/CD Testing Pipelines** | Low | High | Time-Slicing |

---

## 2. Setting Up MPS in Production

CUDA Multi-Process Service (MPS) allows multiple processes (such as separate model serving containers) to share the same GPU concurrently. Unlike time-slicing, it allows overlapping kernel execution on SMs, which increases utilization.

Ensure your worker pods contain the following environment variables to join the host node's MPS server:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mps-client-pod
spec:
  containers:
  - name: inference-app
    image: my-inference-image:latest
    env:
    - name: CUDA_MPS_ACTIVE_THREAD_PERCENTAGE
      value: "50" # Limit this pod to using 50% of SM execution resources
    resources:
      limits:
        nvidia.com/gpu: "1"
```
