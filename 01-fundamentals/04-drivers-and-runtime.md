# Driver Installation & Runtime Setup

Installing and configuring the driver and container runtime pipeline is a critical first step. This guide covers how to install drivers, configure `containerd`, manage persistence mode, and use Fabric Manager on systems with multi-GPU architectures.

---

## 1. Host Driver Architecture

The NVIDIA driver consists of two main parts:
1.  **Kernel-space modules:**
    - `nvidia.ko`: The core GPU interface.
    - `nvidia-modeset.ko`: Handles display modes (disabled on headless servers).
    - `nvidia-uvm.ko`: Unified Video Memory, handles virtual address mapping between CPU and GPU.
    - `nvidia-peermem.ko`: Direct GPU-to-GPU memory operations over third-party network fabrics (GPUDirect RDMA).
2.  **User-space libraries:** `libcuda.so`, `libnvidia-ml.so` (NVML - used for monitoring), etc.

---

## 2. Step-by-Step Installation: Ubuntu 22.04 LTS

For production servers, avoid using the interactive `.run` files from NVIDIA's website, as they are difficult to manage and upgrade. Instead, use package repositories.

```bash
# 1. Add NVIDIA package repositories
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update

# 2. Install recommended driver and fabric manager for multi-GPU nodes
sudo apt-get install -y nvidia-driver-535-server
sudo apt-get install -y cuda-drivers-fabricmanager-535

# 3. Enable and start Fabric Manager (Crucial for DGX / SXM4 / SXM5 NVSwitch boards)
sudo systemctl enable nvidia-fabricmanager
sudo systemctl start nvidia-fabricmanager
```

### What is Fabric Manager?
On systems with NVLink and NVSwitch (e.g., A100/H100 SXM clusters), NVSwitches routes GPU memory packets globally. Fabric Manager is a daemon that configures NVSwitch routing tables at boot.
*   **Pitfall:** If Fabric Manager is not running, calling `nvidia-smi` will fail or report NVLink link failures.

---

## 3. Configuring Containerd for GPU Passthrough

After installing the driver, you must configure the container runtime to use the NVIDIA Container Toolkit.

```bash
# 1. Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 2. Configure containerd to register nvidia runtime
sudo nvidia-container-toolkit runtime configure --runtime=containerd

# 3. Restart containerd
sudo systemctl restart containerd
```

### Verification of `/etc/containerd/config.toml`
The step above updates containerd config. Ensure it includes the following block:
```toml
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
  privileged_without_host_devices = false
  runtime_engine = ""
  runtime_root = ""
  runtime_type = "io.containerd.runtimes.tracker.v1"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia.options]
    BinaryName = "/usr/bin/nvidia-container-runtime"
```

---

## 4. Operational Best Practices: Persistence Mode

By default, the NVIDIA driver kernel module will unload and shut down when no applications are using it. When a new job begins, the driver must reinitialize the GPU, causing a ~2-second latency penalty. In Kubernetes, this can cause liveness/readiness probes to time out or container startups to feel sluggish.

Enable **Persistence Mode** at boot to keep the driver active:

```bash
# Enable persistence mode on all GPUs
sudo nvidia-smi -pm 1

# Make it permanent by creating a systemd service or udev rule
# Typically, the nvidia-persistenced systemd service is installed automatically:
sudo systemctl enable nvidia-persistenced
sudo systemctl start nvidia-persistenced
```

---

## 5. Troubleshooting Driver Failures

| Error Message | Root Cause | Solution |
|---|---|---|
| `NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver.` | Kernel module is not loaded, or driver crash occurred. | Check `dmesg \| grep NVRM`. Restart host or reload modules: `sudo modprobe nvidia` |
| `NVLink link failure detected` | NVSwitch routing failure / Fabric Manager not running. | Start service: `sudo systemctl restart nvidia-fabricmanager`. |
| `Failed to initialize NVML: Driver/library version mismatch` | Driver was updated via apt-get in background; kernel module is running old version but user-space is on new. | **Do not reboot yet!** Restart all containers, unload modules and reload, or schedule a clean reboot. |
