# DeepSpeed Configurations

Microsoft's **DeepSpeed** provides memory optimizations via the **Zero Redundancy Optimizer (ZeRO)**.

---

## 1. ZeRO Stages Explained

ZeRO partitions model memory states across available GPUs, instead of replicating them as in DDP.

-   **ZeRO-Stage 1:** Partitions Adam optimizer states (cuts VRAM usage by ~4x).
-   **ZeRO-Stage 2:** Partitions optimizer states and gradients (cuts VRAM usage by ~8x).
-   **ZeRO-Stage 3:** Partitions optimizer states, gradients, and model parameters (VRAM scale scales linearly with device count).
-   **ZeRO-Offload:** Offloads partitioned states (gradients/optimizer) to Host RAM or NVMe storage.

---

## 2. Production `ds_config.json` Template

This configuration implements ZeRO-Stage 3 with BF16 precision and activation checkpointing:

```json
{
  "train_batch_size": "auto",
  "train_micro_batch_size_per_gpu": "auto",
  "zero_optimization": {
    "stage": 3,
    "offload_optimizer": {
      "device": "cpu",
      "pin_memory": true
    },
    "offload_param": {
      "device": "none"
    },
    "overlap_comm": true,
    "contiguous_gradients": true,
    "sub_group_size": 1e9,
    "reduce_bucket_size": "auto",
    "stage3_prefetch_bucket_size": "auto",
    "stage3_param_persistence_threshold": "auto",
    "stage3_max_live_parameters": 1e9,
    "stage3_max_reuse_distance": 1e9,
    "stage3_gather_16bit_weights_on_model_save": true
  },
  "bf16": {
    "enabled": true
  },
  "gradient_clipping": "auto",
  "steps_per_print": 100
}
```
