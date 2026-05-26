# Performance & Bottlenecks

Low GPU utilization indicates that you are not getting the full value out of your hardware. This guide covers how to profile pipelines and identify bottlenecks.

---

## 1. Common Performance Bottlenecks

### A. The Data Loader Bottleneck (CPU Bound)
- **Symptom:** `nvidia-smi` shows GPU utilization fluctuating between 0% and 90% in cycles.
- **Cause:** The GPU computes faster than the host CPU can read, preprocess, and load batches into memory. The GPU sits idle waiting for the next batch.
- **Remediation:**
  - Increase the number of workers in PyTorch Dataloaders: `num_workers=4` or higher.
  - Enable memory pinning: `pin_memory=True` in the DataLoader. This speeds up data transfers from Host RAM to GPU VRAM.

### B. PCIe Bus Bottleneck
- **Symptom:** Profiles show high latency during `tensor.to('cuda')` operations.
- **Cause:** Large tensors are transferred frequently between the CPU and GPU over a slow PCIe bus link.
- **Remediation:** Keep tensors on the GPU as much as possible, or preprocess entire batches directly on the GPU.

---

## 2. Using PyTorch Profiler

Use the PyTorch Profiler to trace execution times for operations and dataloader tasks:

```python
import torch

with torch.profiler.profile(
    activities=[
        torch.profiler.ProfilerActivity.CPU,
        torch.profiler.ProfilerActivity.CUDA,
    ],
    on_trace_ready=torch.profiler.tensorboard_trace_handler('./logs'),
    record_shapes=True,
    profile_memory=True,
    with_stack=True
) as prof:
    # Run a single training step
    output = model(inputs)
    loss = loss_fn(output, targets)
    loss.backward()
    optimizer.step()
    prof.step()
```
Open the generated log files in TensorBoard to view execution timelines and identify bottlenecked operations.
