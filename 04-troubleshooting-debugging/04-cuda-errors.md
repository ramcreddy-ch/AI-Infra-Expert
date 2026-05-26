# CUDA Runtime & Kernel Crashes

Debugging runtime failures in CUDA execution.

---

## 1. CUDA Error: Device-Side Assert Triggered

### Symptom:
Your Python code fails with:
```
RuntimeError: CUDA error: device-side assert triggered
```

### Why this is difficult:
Because CUDA executes asynchronously, the line of Python code where this error is raised is rarely the actual line that caused the error. The crash occurred on a GPU kernel running in the background, and the error was only reported when PyTorch synced memory back to the host.

### Troubleshooting:
Force PyTorch to run operations synchronously to identify the exact line causing the crash:

```bash
# Run your training script with this environment variable:
export CUDA_LAUNCH_BLOCKING=1
```
Now, PyTorch will block host execution until each CUDA kernel completes. The traceback will point to the exact operation (e.g., an index out of bounds in an embedding layer) that triggered the assert.

---

## 2. Using Compute Sanitizer

If you are writing custom CUDA extensions or using low-level libraries and encounter memory leaks or segmentation faults, use NVIDIA's **Compute Sanitizer** tool:

```bash
compute-sanitizer --tool memcheck python training_job.py
```
This utility monitors kernel execution, reporting out-of-bounds memory accesses, misaligned memory reads, or thread race conditions.
