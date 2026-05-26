# NCCL Communication Hangs

NCCL (NVIDIA Collective Communications Library) is the primary framework used for multi-GPU communication in distributed PyTorch workloads. This guide explains how to troubleshoot hangs and timeout errors.

---

## 1. Common Symptoms

Your training run stops progressing. Output logs stop updating, and eventually, the job exits with a timeout:

```
RuntimeError: [Errno 110] Connection timed out
[INFO] NCCL Watchdog: Connection timeout or host unresponsive.
```

---

## 2. Troubleshooting Steps

1.  **Configure NCCL Debugging:**
    Enable verbose logging:
    ```bash
    export NCCL_DEBUG=INFO
    export NCCL_DEBUG_SUBSYS=INIT,COLL,ENV
    export TORCH_DISTRIBUTED_DEBUG=INFO
    ```
2.  **Verify Network Interfaces:**
    In multi-node environments, NCCL must bind to the correct network interface. If it binds to a slow interface or one blocked by firewall rules, initialization will hang.
    - Explicitly set the target interface using environment variables:
      ```bash
      # Match eth0 or ib0 depending on setup
      export NCCL_SOCKET_IFNAME=eth0
      ```
3.  **Disable GPUDirect RDMA if suspected:**
    If using InfiniBand or RoCE, verify if GPUDirect RDMA is causing issues by disabling it temporarily to test fallback behavior:
    ```bash
    export NCCL_IB_DISABLE=1
    ```
    If the job runs successfully with this flag enabled (at a slower speed), your InfiniBand configuration or host drivers are misconfigured.
