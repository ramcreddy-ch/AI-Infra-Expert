# Runbook: Resolving GPU OOM (Out Of Memory) Failures

Use this checklist if a containerized training or serving workload fails with memory limits.

---

## 🚨 Troubleshooting Steps

1.  **Verify the Error Type:**
    Check the container log files. If you find `RuntimeError: CUDA out of memory`, proceed with this runbook. If the process is terminated abruptly with exit code `137`, verify host memory limits.
2.  **Inspect Active Allocations:**
    Add PyTorch's native memory tracker to capture allocations at the point of failure:
    ```python
    import torch
    print(torch.cuda.memory_summary())
    ```
3.  **Adjust Training parameters:**
    - Reduce the batch size in your data loaders (e.g., from 32 to 16).
    - Enable mixed precision (such as using BF16/FP16 models).
    - Implement gradient checkpointing in your transformer layers:
      ```python
      model.gradient_checkpointing_enable()
      ```
4.  **Manage PyTorch Allocation Fragmentation:**
    Instruct the allocator to release free memory blocks:
    ```bash
    export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
    ```
