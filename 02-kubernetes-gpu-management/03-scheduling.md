# Scheduling & Placements

Running AI workloads alongside traditional microservices requires careful scheduling rules to prevent latency issues and maximize hardware utilization.

---

## 1. Resource Requests and Limits

In Kubernetes pod specifications, GPU requests are configured differently than CPU or memory:
*   **Integer Allocation:** You can only request integer quantities of `nvidia.com/gpu` (unless using sharing strategies like time-slicing or fractional GPU managers).
*   **Request equals Limit:** When requesting a GPU, you must set requests and limits to the exact same value. Fractional requests (e.g., `0.5`) will be rejected by the API server by default.

### Pod Manifest Example:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-training-pod
spec:
  containers:
  - name: pytorch-container
    image: pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime
    command: ["python", "-c", "import torch; print(torch.cuda.is_available())"]
    resources:
      limits:
        nvidia.com/gpu: "1" # Requesting 1 GPU
        memory: "16Gi"
        cpu: "4"
      requests:
        nvidia.com/gpu: "1"
        memory: "16Gi"
        cpu: "4"
```

---

## 2. Pod Taints, Tolerations, and Affinities

GPU nodes are expensive. To prevent standard microservices (which do not require GPUs) from scheduling on GPU nodes, apply taints to your GPU node pools.

### Step 1: Taint the Node
```bash
kubectl taint nodes <node-name> sku=gpu:NoSchedule
```

### Step 2: Pod Toleration & Affinity
Your GPU pods must include tolerations to bypass the taint, and node affinity to ensure they schedule onto the GPU node pool:

```yaml
spec:
  tolerations:
  - key: "sku"
    operator: "Equal"
    value: "gpu"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: nvidia.com/gpu.product
            operator: In
            values:
            - NVIDIA-H100-SXM5
```

---

## 3. Topology-Aware Scheduling

On multi-GPU servers, the physical layout affects communication performance. For example, two GPUs connected to the same PCIe switch communicate faster than two GPUs on separate CPU sockets.
*   **Topology Manager:** A `kubelet` component that aligns resources (CPUs, SRIOV devices, GPUs) for low latency.
*   Configure the Topology Manager on your worker nodes in `/var/lib/kubelet/config.yaml`:
    ```yaml
    topologyManagerPolicy: single-numa-node
    ```
    This forces the `kubelet` to assign CPUs and GPUs that are aligned to the same NUMA node, minimizing cross-socket latency bottlenecks.
