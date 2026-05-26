# GPU Memory Out-Of-Memory (OOM) Debugging

CUDA Out-Of-Memory (OOM) errors are the most common issue encountered when running training and inference jobs. This guide outlines how to diagnose and resolve them.

---

## 1. GPU VRAM OOM vs. Host RAM OOM

| Characteristic | GPU OOM | Host RAM OOM |
|---|---|---|
| **Symptom** | PyTorch raises `RuntimeError: CUDA out of memory`. | The container is terminated abruptly by the OS kernel. |
| **Exit Code** | Process continues running or exits with code `1`. | Process is killed with exit code `137` (SIGKILL). |
| **Log Entry** | PyTorch prints detailed memory allocation summary. | `dmesg` contains `Out of memory: Kill process (python)`. |

---

## 2. Reading the PyTorch OOM Diagnostic Dump

When PyTorch runs out of VRAM, it prints a detailed breakdown of the memory state:

```
RuntimeError: CUDA out of memory. Tried to allocate 2.00 GiB (GPU 0; 79.35 GiB total capacity; 75.12 GiB already allocated; 1.52 GiB free; 76.50 GiB reserved in total by PyTorch)
```

### Explaining the Terms:
-   **Total Capacity (79.35 GiB):** The total physical VRAM available on the GPU.
-   **Already Allocated (75.12 GiB):** The VRAM actively holding PyTorch tensors.
-   **Reserved in total (76.50 GiB):** The VRAM PyTorch has allocated from the OS kernel driver. To avoid allocation overhead, PyTorch's internal allocator caches blocks of memory.
-   **Actual Free VRAM (1.52 GiB):** VRAM that the OS driver reports as free. Since $2.00$ GiB was requested but only $1.52$ GiB is free, PyTorch raises an OOM error.

---

## 3. Resolving OOM Failures

If your job runs out of memory, try these adjustments:

1.  **Reduce Batch Size:** The simplest fix. Decreasing batch size reduces activation memory requirements.
2.  **Enable Mixed Precision:** Transitioning from FP32 to BF16 or FP8 cuts the memory footprint of weights and activations.
3.  **Gradient Checkpointing:** Recomputes intermediate activations during the backward pass instead of caching them, significantly reducing memory usage.
4.  **Use PyTorch Memory Allocator Flags:**
    Instruct PyTorch to release cached VRAM more aggressively if fragmentation occurs:
    ```bash
    export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
    ```
