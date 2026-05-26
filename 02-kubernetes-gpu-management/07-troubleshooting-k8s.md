# Kubernetes GPU Troubleshooting Runbook

This guide covers common issues encountered when managing GPUs in Kubernetes and steps to resolve them.

---

## 1. Pod Stuck in `Pending` with `FailedScheduling`

### Symptom:
`kubectl describe pod <pod-name>` shows:
```
0/3 nodes are available: 3 Insufficient nvidia.com/gpu.
```

### Troubleshooting Steps:
1.  **Check GPU Node Allocatable Resources:**
    ```bash
    kubectl get nodes -o custom-columns=NAME:.metadata.name,GPU_ALLOCATABLE:.status.allocatable.nvidia\.com/gpu
    ```
    If output is `0` or `none`, the device plugin is not running or failed to discover GPUs.
2.  **Verify Taints & Tolerations:**
    Ensure your pod spec includes the correct tolerations for your GPU node pool.
3.  **Verify Node Selector / Affinity:**
    Check if the pod requests labels that do not match the target node's labels (e.g., requesting `nvidia.com/gpu.product: NVIDIA-A100-SXM4-80GB` on a cluster containing only H100s).

---

## 2. Pod Stuck in `ContainerCreating` / CrashLoopBackOff

### Symptom:
`kubectl describe pod <pod-name>` shows:
```
Warning  FailedCreatePodSandBox  12s  kubelet  Failed to create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container: failed to configure nvidia container runtime: ...
```

### Root Cause:
*   **Mismatched Runtime Hooks:** The NVIDIA container runtime hook failed to inject the required driver mounts, or the host containerd config is corrupt.
*   **Driver crash:** The host GPU driver encountered a critical kernel error (e.g., fallen off the bus).

### Resolution:
1.  Verify the GPU is healthy on the host node:
    ```bash
    ssh <node-ip> nvidia-smi
    ```
2.  Restart the containerd service on the host node:
    ```bash
    sudo systemctl restart containerd
    ```
3.  Check host logs:
    ```bash
    sudo journalctl -u containerd -n 100 --no-pager
    ```

---

## 3. GPU is Not Detected Inside Container

### Symptom:
The pod starts up, but running `python -c "import torch; print(torch.cuda.is_available())"` outputs `False`.

### Resolution:
1.  Ensure you requested `nvidia.com/gpu` in the pod's `resources` section.
2.  Verify the environment variable `NVIDIA_VISIBLE_DEVICES` is set to `all` inside the running container:
    ```bash
    kubectl exec -it <pod-name> -- printenv NVIDIA_VISIBLE_DEVICES
    ```
    If this variable is missing, the container runtime did not mount the GPU devices.
