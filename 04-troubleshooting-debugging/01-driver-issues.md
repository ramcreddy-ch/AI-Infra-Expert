# Troubleshooting Driver Failures

This guide covers identifying and fixing driver issues in production.

---

## 1. "NVIDIA-SMI has failed because..."

### Symptom:
Running `nvidia-smi` returns:
```
NVIDIA-SMI has failed because it couldn't communicate with the NVIDIA driver. Make sure that the latest NVIDIA driver is installed and running.
```

### Diagnosing Causes:
1.  **Driver is not loaded:**
    Run `lsmod | grep nvidia`. If no modules are listed, the driver is not loaded.
    *Resolution:* Try loading it manually: `sudo modprobe nvidia`.
2.  **Kernel Upgrade Broke the Module:**
    If the host OS automatically updated its kernel in the background (e.g., via `unattended-upgrades`), the compiled NVIDIA driver kernel module no longer matches the running kernel.
    *Resolution:* Recompile modules using DKMS:
    ```bash
    sudo apt-get install --reinstall dkms
    sudo dpkg-reconfigure nvidia-kernel-common-535
    ```
3.  **GPU Driver Crash:**
    Check `dmesg | grep -E 'NVRM|nvidia'`. If the logs show `NVRM: GPU at 0000:00:04.0 has fallen off the bus`, the driver crashed due to a hardware failure.
    *Resolution:* Hard-reboot the server. If this occurs repeatedly, request a hardware replacement (RMA).
