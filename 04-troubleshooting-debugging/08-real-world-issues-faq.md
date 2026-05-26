# Real-World GPU & AI Infrastructure Production Issues

This document compiles **34 production issues** encountered when managing GPU/TPU clusters and distributed AI infrastructure at scale. Each issue contains real-world error messages, root-cause analyses, and step-by-step remediation procedures.

---

## 📚 Categories
1. [Driver & System Initialization (Issues 1-6)](#1-driver--system-initialization)
2. [Hardware & PCIe Bus Faults (Issues 7-12)](#2-hardware--pcie-bus-faults)
3. [VRAM & Memory Errors (Issues 13-18)](#3-vram--memory-errors)
4. [Network & NCCL Distributed Training (Issues 19-24)](#4-network--nccl-distributed-training)
5. [Kubernetes Scheduling & Orchestration (Issues 25-30)](#5-kubernetes-scheduling--orchestration)
6. [Inference & Serving Bottlenecks (Issues 31-34)](#6-inference--serving-bottlenecks)

---

## 1. Driver & System Initialization

### Issue 1: `Failed to initialize NVML: Driver/library version mismatch`
*   **Symptom:** Running `nvidia-smi` returns `Failed to initialize NVML: Driver/library version mismatch`. Containers fail to start up, and K8s node status lists 0 GPUs.
*   **Root Cause:** The host OS updated the NVIDIA driver package via automated updates (e.g., `apt-get upgrade`), installing new user-space libraries. However, the older kernel module (`nvidia.ko`) is still loaded in memory.
*   **Remediation:**
    1. Check which kernel module is loaded: `cat /proc/driver/nvidia/version`
    2. Identify running processes using the driver: `sudo lsof /dev/nvidia*`
    3. Unload the kernel modules:
       ```bash
       sudo systemctl stop nvidia-persistenced
       sudo rmmod nvidia_drm nvidia_modeset nvidia_uvm nvidia
       ```
       *Note: If `rmmod` fails with "in use", you must stop any containers/processes using the GPU.*
    4. Reload the updated modules: `sudo modprobe nvidia`
    5. Restart persistence mode: `sudo systemctl start nvidia-persistenced`
    6. *Alternative:* Schedule a host reboot to force a clean reload.
*   **Prevention:** Disable automatic updates for NVIDIA packages: `sudo apt-mark hold nvidia-* cuda-*`

---

### Issue 2: `NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver`
*   **Symptom:** `nvidia-smi` fails. Host logs show driver initialization errors.
*   **Root Cause:** A Linux kernel update occurred, but the NVIDIA kernel modules did not rebuild because DKMS (Dynamic Kernel Module Support) is missing or compilation failed.
*   **Remediation:**
    1. Verify current running kernel: `uname -r`
    2. Install headers for the kernel: `sudo apt-get install -y linux-headers-$(uname -r)`
    3. Trigger a manual DKMS build:
       ```bash
       sudo dkms autoinstall
       ```
    4. Reload modules: `sudo modprobe nvidia`

---

### Issue 3: Fabric Manager fails to start on H100 SXM nodes (`NVLink link failure detected`)
*   **Symptom:** PyTorch multi-GPU training fails. Host logs report: `NVRM: GPU at 0000:00:04.0: NVLink Link 0 is down`.
*   **Root Cause:** On SXM systems, GPUs communicate via high-speed NVSwitches. The `nvidia-fabricmanager` service, which configures the switch routing tables at boot, is stopped or version-mismatched.
*   **Remediation:**
    1. Check fabricmanager status: `sudo systemctl status nvidia-fabricmanager`
    2. Check system log for errors: `journalctl -u nvidia-fabricmanager`
    3. Ensure fabricmanager version matches the driver version:
       ```bash
       dpkg -l | grep -E 'nvidia-driver|fabricmanager'
       ```
    4. Install matching version and restart:
       ```bash
       sudo apt-get install -y cuda-drivers-fabricmanager-535
       sudo systemctl restart nvidia-fabricmanager
       ```

---

### Issue 4: GFD (GPU Feature Discovery) fails to label nodes
*   **Symptom:** K8s pods targeting GPUs are stuck in `Pending` because nodes lack labels like `nvidia.com/gpu.product`.
*   **Root Cause:** GFD runs before the GPU driver container has fully compiled and loaded modules on the host. GFD enters a `CrashLoopBackOff` state.
*   **Remediation:**
    1. Check GFD logs: `kubectl logs -n gpu-operator -l app=gpu-feature-discovery`
    2. Verify the driver container is running: `kubectl get pods -n gpu-operator -l app=nvidia-driver-daemonset`
    3. Restart GFD once driver is ready:
       ```bash
       kubectl rollout restart daemonset nvidia-device-plugin-validator -n gpu-operator
       ```

---

### Issue 5: Container Runtime Hook `nvidia-container-cli: initialization error`
*   **Symptom:** Container creation fails with: `failed to create containerd task: nvidia-container-cli: initialization error: driver library not found`.
*   **Root Cause:** The `nvidia-container-runtime` cannot locate the host's driver libraries because the dynamic linker configuration `/etc/ld.so.conf.d/` is missing the driver installation paths.
*   **Remediation:**
    1. Locate your driver library: `find / -name "libcuda.so.1" 2>/dev/null`
    2. Add path (typically `/usr/lib/x86_64-linux-gnu`) to `/etc/ld.so.conf.d/nvidia.conf`.
    3. Refresh cache: `sudo ldconfig`
    4. Restart containerd: `sudo systemctl restart containerd`

---

### Issue 6: Intermittent latency spikes of 2 seconds at pod startup
*   **Symptom:** Starting a new training job or inference container takes an extra 2-3 seconds, and the GPU appears unresponsive during this time.
*   **Root Cause:** Persistence mode is disabled. When the last GPU process exits, the driver unloads. The next process triggers driver reload, causing a latency delay.
*   **Remediation:**
    1. Enable persistence mode:
       ```bash
       sudo nvidia-smi -pm 1
       ```
    2. Persist across reboots: `sudo systemctl enable nvidia-persistenced`

---

## 2. Hardware & PCIe Bus Faults

### Issue 7: GPU disappears from the OS (`NVRM: Xid: 79, fallen off the bus`)
*   **Symptom:** Training fails. `nvidia-smi` lists missing cards. `dmesg` contains `NVRM: Xid (PCI:0000:01:00.0): 79, GPU has fallen off the bus`.
*   **Root Cause:** A critical hardware or power interface crash occurred, forcing the GPU's PCIe connection to drop.
*   **Remediation:**
    1. Attempt to reset the PCIe slot (often fails if card is unresponsive):
       ```bash
       echo 1 > /sys/bus/pci/devices/0000:01:00.0/remove
       sleep 1
       echo 1 > /sys/bus/pci/rescan
       ```
    2. If rescan fails, a hardware cold boot is required.
    3. If the error recurs, the GPU card or PCIe motherboard slot is defective.

---

### Issue 8: Uncorrectable Double-Bit ECC errors in VRAM
*   **Symptom:** Training scripts crash with memory faults. `dmesg` contains `NVRM: Xid (PCI:0000:01:00.0): 48, Double-bit ECC error`.
*   **Root Cause:** Volatile VRAM memory encountered an uncorrectable double-bit error. The driver terminates active CUDA contexts to prevent data corruption.
*   **Remediation:**
    1. Query ECC status: `nvidia-smi -q -d ECC`
    2. Reset the GPU memory status (clears error state, requires stopping active jobs):
       ```bash
       sudo nvidia-smi -gpu-reset -i 0
       ```
    3. If double-bit errors occur regularly on the same card, drain the node and replace the GPU.

---

### Issue 9: GPU performance degradation due to PCIe link speed downgrade
*   **Symptom:** Training runs are 2x slower than expected. No errors are reported.
*   **Root Cause:** The GPU's PCIe connection has downgraded to a lower generation or lane width (e.g., Gen4 x1 instead of Gen4 x16) due to dirt in the slot, mechanical seating issues, or motherboard lane routing limits.
*   **Remediation:**
    1. Query link metrics: `nvidia-smi -q -d LINK`
    2. Look for mismatch: `Max Link Width: 16x` vs `Current Link Width: 1x`.
    3. Shut down server, clean the PCIe slot using compressed air, reseat the card, and reboot.

---

### Issue 10: Severe training slowdowns caused by Thermal Throttling
*   **Symptom:** Training throughput drops. `nvidia-smi` shows GPU core temperatures at 85°C+.
*   **Root Cause:** Cooling fans have failed, airflow is blocked, or ambient server room temperatures exceed environmental safety thresholds.
*   **Remediation:**
    1. Query thermal status: `nvidia-smi -q -d TEMPERATURE`
    2. Identify fan speeds: `nvidia-smi -q -d COOLING`
    3. Clean dust from fan intakes. Replace fan modules if speed is 0% while temperature is high.

---

### Issue 11: Power supply unit (PSU) issues trigger power capping
*   **Symptom:** GPU performance drops. Logs show `Power Brake Alert` or `Power capping limit active`.
*   **Root Cause:** The host server's PSU failed or was unplugged from its secondary power supply, forcing the motherboard to cap GPU draw to prevent overloading the remaining power supply.
*   **Remediation:**
    1. Check power draw caps: `nvidia-smi -q -d POWER`
    2. Check server chassis management logs (iDRAC/ILO) for power supply faults.
    3. Replace defective power supplies and ensure both power inlets are connected to active power distribution units (PDUs).

---

### Issue 12: XID 62 "Internal microcode engine error"
*   **Symptom:** Training hangs. GPU utilization is locked at 100% but no forward progress is made. `dmesg` logs `NVRM: Xid (PCI:0000:01:00.0): 62, Internal microcode engine error`.
*   **Root Cause:** A firmware or microcode exception occurred inside the GPU's command processor.
*   **Remediation:**
    1. Stop the application container.
    2. Reset the target GPU: `sudo nvidia-smi --gpu-reset -i <gpu-index>`
    3. If reset fails, reboot the host node.

---

## 3. VRAM & Memory Errors

### Issue 13: `RuntimeError: CUDA out of memory` during PyTorch transformer forward pass
*   **Symptom:** PyTorch training script terminates with: `RuntimeError: CUDA out of memory. Tried to allocate...`.
*   **Root Cause:** Model parameters, optimizer states, and batch activations exceed the physical memory capacity of the GPU.
*   **Remediation:**
    1. Decrease the batch size (e.g., from 64 to 32).
    2. Enable mixed-precision training:
       ```python
       from torch.cuda.amp import autocast
       with autocast(dtype=torch.bfloat16):
           outputs = model(inputs)
       ```
    3. Apply gradient checkpointing:
       ```python
       model.gradient_checkpointing_enable()
       ```

---

### Issue 14: PyTorch memory fragmentation OOM
*   **Symptom:** PyTorch raises CUDA OOM. The diagnostic dump shows: `Reserved memory 78.50 GiB` but `Allocated memory 55.20 GiB`. There is 23 GiB of free memory, but the allocation request still fails.
*   **Root Cause:** PyTorch's memory allocator caches memory blocks. If memory allocations fluctuate significantly in shape, the cache becomes fragmented, and PyTorch cannot find a single contiguous block of memory to satisfy the request.
*   **Remediation:**
    1. Instruct PyTorch to partition cached memory block sizes:
       ```bash
       export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
       ```
    2. Clear PyTorch's cache inside your script periodically:
       ```python
       torch.cuda.empty_cache()
       ```

---

### Issue 15: Container terminates with exit code `137`
*   **Symptom:** Pod crashes without error logs. `kubectl get pod` shows `OOMKilled` or exit code `137`.
*   **Root Cause:** The container exceeded its Host RAM (CPU) memory limit, triggering the Linux kernel's Out-Of-Memory killer. *Note: This is not a GPU VRAM limit.*
*   **Remediation:**
    1. Inspect system logs: `dmesg | grep -i oom`
    2. Increase the CPU memory limits in your pod specification:
       ```yaml
       resources:
         limits:
           memory: "32Gi" # Increase allocation limit
       ```

---

### Issue 16: Slow memory growth (leak) over 24 hours of training
*   **Symptom:** A training job runs successfully for hours, but eventually fails with a CUDA OOM error.
*   **Root Cause:** The training script is caching references to tensors (e.g., storing historical loss values without converting them to Python floats, which keeps their computational graphs in memory).
*   **Remediation:**
    1. Convert tensors to floats when logging metrics:
       ```python
       # Bad:
       epoch_loss += loss
       # Good:
       epoch_loss += loss.item()
       ```
    2. Avoid retaining evaluation outputs: Ensure tensors are detached using `.detach()` before storage.

---

### Issue 17: PyTorch DataLoader fails with `Bus error`
*   **Symptom:** PyTorch DataLoader workers crash with: `DataLoader worker (pid X) is killed by signal: Bus error`.
*   **Root Cause:** The container ran out of shared memory (`/dev/shm`). Docker and Kubernetes restrict `/dev/shm` to 64MB by default.
*   **Remediation:**
    Mount a temporary volume to override the default `/dev/shm` limit in your K8s deployment:
    ```yaml
    spec:
      containers:
      - name: training-container
        volumeMounts:
        - mountPath: /dev/shm
          name: dshm
      volumes:
      - name: dshm
        emptyDir:
          medium: Memory
          sizeLimit: "8Gi"
    ```

---

### Issue 18: Unified Memory (UVM) thrashing causes 90% performance loss
*   **Symptom:** Training progress drops significantly. GPU utilization shows 100%, but throughput is extremely slow.
*   **Root Cause:** Unified Memory is enabled, and the model footprint exceeds physical VRAM. The system page-faults constantly, moving pages back and forth between Host RAM and GPU VRAM over the slow PCIe bus.
*   **Remediation:**
    1. Monitor UVM migration activity: `nvidia-smi nvlink -g 0` (or check DCGM page fault metrics).
    2. Disable dynamic offloading to CPU.
    3. Reduce sequence lengths or batch sizes to fit within the physical GPU memory bounds.

---

## 4. Network & NCCL Distributed Training

### Issue 19: Multi-node training hangs during NCCL init phase
*   **Symptom:** Pod logs pause after initialization. `NCCL INFO` logs end with: `Bootstrap : connection reset` or `Bootstrap : connection timed out`.
*   **Root Cause:** NCCL binding issues. NCCL discovered multiple network interfaces (e.g., `docker0`, `eth0`, `ib0`) and tried to bind to an internal, non-routable Docker interface instead of the primary interface.
*   **Remediation:**
    Force NCCL to bind to your primary network interface name using environment variables:
    ```bash
    export NCCL_SOCKET_IFNAME=eth0
    ```

---

### Issue 20: NCCL training performance drops to 10%
*   **Symptom:** Distributed training runs without errors but throughput is extremely slow.
*   **Root Cause:** NCCL cannot find or use the high-speed network fabric (InfiniBand or RoCE) and has fallback-routed communication through the slow TCP network.
*   **Remediation:**
    1. Inspect NCCL initialization logs: `export NCCL_DEBUG=INFO`
    2. Check for fallback warning: `NCCL INFO Using transport TCP`.
    3. Verify your InfiniBand interfaces are active on the host: `ibv_devinfo`
    4. Force IB usage:
       ```bash
       export NCCL_IB_DISABLE=0
       ```

---

### Issue 21: NCCL collective communications fail with socket timeout
*   **Symptom:** Multi-node training starts but crashes after a few seconds with: `NCCL WARN Call to connect to... failed : Connection refused`.
*   **Root Cause:** A firewall or security group blocks the random high-range ports that NCCL dynamically opens for data transfers.
*   **Remediation:**
    1. Ensure port ranges are open between nodes in your security groups.
    2. Restrict NCCL's port range to a specific window and open those ports in your firewall:
       ```bash
       export NCCL_COMM_ID=10.244.1.20:12345
       ```

---

### Issue 22: Network packet drops on high-throughput runs
*   **Symptom:** Distributed training fails intermittently with NCCL timeouts under heavy workloads.
*   **Root Cause:** Network MTU mismatch. The network switches are configured for Jumbo Frames (9000 bytes) but the worker nodes or pod interfaces are configured for a standard MTU of 1500 bytes.
*   **Remediation:**
    1. Check MTU values: `ip addr show`
    2. Configure matching MTUs on the hosts and in your container runtime configurations (e.g., CNI networks).

---

### Issue 23: GPUDirect RDMA fails with `peermem` driver not loaded
*   **Symptom:** Multi-node training runs slowly. Logs show: `NCCL INFO GPUDirect RDMA: Disabled`.
*   **Root Cause:** The `nvidia-peermem` kernel module is not loaded on the host. This module is required to coordinate GPUDirect memory allocations between the GPU and the network interface card.
*   **Remediation:**
    1. Check module status: `lsmod | grep nvidia_peermem`
    2. Load module:
       ```bash
       sudo modprobe nvidia_peermem
       ```
    3. Enable auto-load: Add `nvidia_peermem` to `/etc/modules`.

---

### Issue 24: Distributed training runs desynchronize and hang
*   **Symptom:** Training hangs. Profiler shows multiple GPUs idling in `AllReduce` wait blocks.
*   **Root Cause:** The "straggler" problem. One of the worker nodes in the cluster is running slower than the others (due to disk I/O bottlenecks, CPU thermal issues, or network congestion), blocking the other nodes during synchronization blocks.
*   **Remediation:**
    1. Query processing throughput per node.
    2. Enable PyTorch distributed debugging to pinpoint the stuck device:
       ```bash
       export TORCH_DISTRIBUTED_DEBUG=INFO
       ```
    3. Replace or restart the degraded node.

---

## 5. Kubernetes Scheduling & Orchestration

### Issue 25: Pods stuck in `Pending` state with `Insufficient nvidia.com/gpu`
*   **Symptom:** Pod remains in `Pending`. Events list: `0/5 nodes are available: 5 Insufficient nvidia.com/gpu`.
*   **Root Cause:** All physical GPU slots in the cluster are allocated, or the pod requests a GPU quantity that doesn't match the nodes' capacities.
*   **Remediation:**
    1. List GPU allocations:
       ```bash
       kubectl get nodes -o custom-columns=NAME:.metadata.name,ALLOCATABLE:.status.allocatable.nvidia\\.com/gpu,CAPACITY:.status.capacity.nvidia\\.com/gpu
       ```
    2. Set up autoscaling to provision new GPU nodes when queue sizes grow.

---

### Issue 26: CPU-GPU NUMA affinity bottleneck causes slow training
*   **Symptom:** Training is 30% slower when scheduled in Kubernetes compared to running directly on the host bare metal.
*   **Root Cause:** The K8s scheduler assigned the pod's CPU requests and memory allocations to Socket 0 (NUMA Node 0) but assigned a GPU connected to Socket 1 (NUMA Node 1), forcing data transfers to traverse the slow cross-socket interconnect.
*   **Remediation:**
    1. Enable the Kubelet Topology Manager on worker nodes in `/var/lib/kubelet/config.yaml`:
       ```yaml
       topologyManagerPolicy: single-numa-node
       ```
    2. Configure your pod spec to request aligned resources: Set requests and limits for CPUs and memory alongside your GPU resources.

---

### Issue 27: MIG profile fragmentation prevents pods from scheduling
*   **Symptom:** Pods requesting a `nvidia.com/mig-2g.20gb` slice remain in `Pending`, even though the node has free GPU memory.
*   **Root Cause:** The GPU has been partitioned into other sizes (e.g., three `1g.10gb` slices are active, preventing the allocation of a `2g.20gb` slice).
*   **Remediation:**
    1. Check active MIG slices: `nvidia-smi mig -lgip`
    2. Reconfigure the GPU MIG partitions to free up space for the requested slice size:
       ```bash
       # Delete existing slices and recreate
       nvidia-smi mig -dgi
       nvidia-smi mig -cgi 19 # Profile code for 2g.20gb
       ```

---

### Issue 28: Multiple pods sharing a GPU via time-slicing crash when one pod leaks memory
*   **Symptom:** Pods sharing a GPU crash with OOM errors.
*   **Root Cause:** Time-slicing divides compute time but does not enforce VRAM memory limits. If one container leaks memory or allocates a large batch, it consumes the shared memory space, causing all other sharing pods to crash.
*   **Remediation:**
    - Transition to **MIG** for hard memory isolation.
    - If MIG is not supported, configure **MPS** with memory limits:
      ```yaml
      env:
      - name: CUDA_MPS_ACTIVE_THREAD_PERCENTAGE
        value: "40"
      ```

---

### Issue 29: Volcano Scheduler PodGroups get stuck in "Pending"
*   **Symptom:** Training jobs remain `Pending` even though enough GPUs are available.
*   **Root Cause:** The Volcano scheduler's gang-scheduling plugin requires a minimum number of member pods (`minMember`) to start a training group. If one worker pod fails to schedule due to resource issues, Volcano holds the entire group back, keeping the remaining pods in `Pending`.
*   **Remediation:**
    1. Inspect the PodGroup resource status: `kubectl get podgroups -n <namespace>`
    2. Verify resource availability for all members of the group.
    3. Adjust `minMember` to allow the job to run in a degraded state if appropriate.

---

### Issue 30: GPU Operator driver compilation fails on RedHat/Ubuntu
*   **Symptom:** The driver container enters `CrashLoopBackOff`. Logs show `kernel-headers not found` or compilation failures.
*   **Root Cause:** The host OS updated its kernel, but the driver container image does not contain the corresponding kernel headers required to compile the driver module.
*   **Remediation:**
    1. Mount the host's `/usr/src` and `/lib/modules` directories into the driver container so it can find the host's installed kernel headers.
    2. If headers are missing on the host, install them:
       ```bash
       sudo apt-get install -y linux-headers-$(uname -r)
       ```

---

## 6. Inference & Serving Bottlenecks

### Issue 31: vLLM serving engine crashes under heavy load
*   **Symptom:** Model serving pods crash with OOM errors during peak traffic periods.
*   **Root Cause:** The KV Cache allocation is set too high. vLLM pre-allocates a percentage of GPU memory for its cache. If your model parameters or input batch sizes grow, the remaining space is insufficient, causing a crash.
*   **Remediation:**
    Adjust vLLM's cache allocation limit in your container arguments:
    ```bash
    # Limit cache allocation to 85% of GPU memory (down from the default 90%)
    python3 -m vllm.entrypoints.openai.api_server --model ... --gpu-memory-utilization 0.85
    ```

---

### Issue 32: High Triton cold-start latency when scaling up from zero pods
*   **Symptom:** The serverless scaling configuration works, but the first request to scaled-up pods takes 30-60 seconds to respond.
*   **Root Cause:** Cold start latency. When a pod is scheduled, it must download the large model weights from remote storage (e.g., S3) and load them into GPU memory before it can process requests.
*   **Remediation:**
    1. Pre-warm containers: Use local SSD cache volumes to persist model weights on worker nodes.
    2. Configure Triton to preload models: Set `startup` probe parameters to delay routing traffic until the model is ready.
    3. Set a minimum replica count of 1 for critical production endpoints to avoid scaling down to zero.

---

### Issue 33: Low GPU compute utilization on model serving endpoints
*   **Symptom:** `nvidia-smi` shows GPU utilization under 15% during active request periods.
*   **Root Cause:** CPU bottlenecks during tokenization or image preprocessing. The GPU processes batches quickly and then sits idle waiting for the CPU to preprocess the next request.
*   **Remediation:**
    1. Implement dynamic batching in Triton to aggregate requests.
    2. Relocate preprocessing steps (e.g., image resizing or normalization) to the GPU using libraries like DALI.

---

### Issue 34: Quantized models return nonsensical text outputs
*   **Symptom:** Served LLMs respond with garbled characters or repetitive words.
*   **Root Cause:** Quantization calibration error. The model weights were converted to low-precision formats (INT8/FP8) without appropriate calibration data, leading to severe precision loss in key layers.
*   **Remediation:**
    1. Re-run calibration using representative datasets.
    2. Switch to newer quantization methods like AWQ (Activation-aware Weight Quantization) or GPTQ, which prioritize preserving precision in outlier dimensions.
