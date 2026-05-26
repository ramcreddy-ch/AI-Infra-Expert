# Kubernetes Device Plugins

To allocate hardware resources like GPUs, FPGAs, or custom NICs in Kubernetes, the cluster relies on the **Device Plugin Framework**. This guide explains how this framework operates and how the NVIDIA Device Plugin integrates with Kubernetes.

---

## 1. How Device Plugins Work

In standard Kubernetes, the `kubelet` allocates CPU, RAM, and storage. It does not know how to manage specialized hardware like GPUs. The Device Plugin framework lets external agents advertise these hardware assets to the `kubelet`.

### Device Plugin Architecture

```
  ┌────────────────────────────────────────────────────────┐
  │ Kubelet (on Worker Node)                               │
  └──────────▲───────────────────────────────▲──────────────┘
             │ (gRPC / Register Call)        │ (gRPC / Allocate Call)
             │                               │
  ┌──────────┴───────────────┐   ┌───────────┴──────────────┐
  │ NVIDIA Device Plugin     │   │ Container Runtime (CRI)  │
  │ (DaemonSet Pod)          │   │ (containerd / Docker)    │
  └──────────────────────────┘   └──────────────────────────┘
```

### Lifecycle of GPU Advertising
1.  **Registration:** The Device Plugin (running as a DaemonSet) starts up and registers itself with the host `kubelet` via a Unix domain socket at `/var/lib/kubelet/device-plugins/kubelet.sock`.
2.  **ListAndWatch:** The plugin sends a list of healthy GPUs (identified by UUIDs) to the `kubelet` via a gRPC stream.
3.  **Advertising:** Kubelet updates the node capacity. The node now lists `nvidia.com/gpu: <count>` in its status capacity.
4.  **Allocation:** When a pod requests a GPU, the scheduler assigns it to the node. The `kubelet` on that node calls the plugin's `Allocate()` gRPC method, passing the device UUIDs.
5.  **Runtime Config:** The Device Plugin returns the list of environment variables, mount points, and devices that the runtime (containerd) needs to inject into the container.

---

## 2. Deploying the NVIDIA Device Plugin

While the GPU Operator (covered in the next chapter) is the standard method to manage GPUs, you can deploy the NVIDIA Device Plugin independently.

### Step 1: Set Container Runtime to Nvidia
Ensure `nvidia-container-runtime` is set as default in `/etc/docker/daemon.json` or `/etc/containerd/config.toml`.

### Step 2: Apply the Manifest
```bash
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/deployments/static/nvidia-device-plugin.yml
```

### Verification
```bash
# Verify the plugin daemonset is running
kubectl get pods -n kube-system -l app=nvidia-device-plugin-daemonset

# Check if node lists GPU capacity
kubectl get node <your-gpu-node> -o jsonpath='{.status.capacity}' | grep nvidia.com/gpu
```
