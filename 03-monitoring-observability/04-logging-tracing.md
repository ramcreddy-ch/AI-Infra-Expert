# Logging & Distributed Tracing

This guide covers tracing GPU issues through host kernel logs, application outputs, and communication tracing.

---

## 1. System Logs & Dmesg

When a GPU driver or hardware crashes, the details are written to the host OS system log. Use these commands to search for failures:

```bash
# Search system logs for NVIDIA messages
dmesg | grep -i nvrm
journalctl -u systemd-journald -k --grep=NVRM

# Check if the kernel registers GPU errors
cat /proc/driver/nvidia/gpus/*/information
```

---

## 2. Tracing NCCL Logs for Distributed Training

When training across multiple nodes hangs or fails, the issue is typically a network routing or packet loss failure. Enable **NCCL debugging logs** inside the training pods to trace these issues:

Add these environment variables to your deployment or torchrun config:

```bash
export NCCL_DEBUG=INFO
export NCCL_DEBUG_SUBSYS=INIT,COLL,ENV,ALLOC
export NCCL_DEBUG_FILE=/workspace/logs/nccl_debug_%h_%p.log
```

### Typical Log Output Analysis:
```
node-0:1204:1204 [0] NCCL INFO Bootstrap : Found interface eth0:10.244.1.20<0>
node-0:1204:1204 [0] NCCL INFO Ring 00 : 0 -> 1 -> 2 -> 3 -> 0
node-0:1204:1204 [0] NCCL INFO trees match rings
node-0:1204:1204 [0] NCCL INFO CUDA Dev 0, NCCL PCIe ID 0000:00:04.0, NVLink Peer Access Enabled
```
*If a node fails to initialize or routes through slow interfaces, this log will show `Bootstrap: connection refused` or indicate that it is fallback-routing through `TCP` instead of `InfiniBand`.*
