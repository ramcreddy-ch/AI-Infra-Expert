# vLLM Deployment

**vLLM** is an open-source library designed for LLM serving. It uses **PagedAttention**, an algorithm that manages memory for the attention Key-Value (KV) cache to reduce fragmentation and increase serving throughput.

---

## 1. How PagedAttention Works

In standard LLM generation, KV cache size depends on the input sequence length, which varies per request. Because of this, traditional frameworks pre-allocate contiguous blocks of VRAM based on the maximum sequence length. This leads to **internal fragmentation** (VRAM allocated but unused).
*   **PagedAttention** partitions the KV cache into small blocks (similar to virtual memory paging in OS kernels). These blocks do not need to be contiguous in physical VRAM. vLLM links them dynamically, reducing memory overhead and unlocking higher batch capacities.

```
  Traditional:   [ Allocated Contiguous Block (Wasted Memory) ]
  PagedAttention: [ Page 1 (Active) ] -> [ Page 4 (Active) ] -> [ Page 2 (Active) ]
```

---

## 2. Kubernetes Deployment with Tensor Parallelism

To serve large models (e.g., LLaMA-70B), you must split the model weights across multiple GPUs using Tensor Parallelism:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-llama-70b
  namespace: model-serving
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: vllm-server
        image: vllm/vllm-openai:latest
        args: [
          "--model", "meta-llama/Llama-2-70b-chat-hf",
          "--tensor-parallel-size", "4", # Split model across 4 GPUs
          "--port", "8000"
        ]
        ports:
        - containerPort: 8000
        resources:
          limits:
            nvidia.com/gpu: "4" # Request 4 physical GPUs
```
