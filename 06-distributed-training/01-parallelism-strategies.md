# Parallelism Strategies

When training modern deep learning models, memory requirements often exceed the VRAM capacity of a single GPU. This guide outlines how to split workloads across multiple devices.

---

## 1. Data Parallelism (DDP)

In **Distributed Data Parallelism (DDP)**, the entire model is replicated on every GPU.
*   **Execution Flow:** Each GPU is fed a different shard of the training dataset. During the forward pass, each GPU computes its own activations and loss.
*   **Gradient Sync:** During the backward pass, gradients are calculated locally on each GPU. Before weights are updated, the GPUs run an **AllReduce** collective communication step to average the gradients across all devices.

```
  Data Shard A ──> GPU 0 (Replicated Model) ──┐
                                              ├──> [AllReduce Gradient Sync] ──> Weight Update
  Data Shard B ──> GPU 1 (Replicated Model) ──┘
```

*Limits of DDP:* Because the full model is replicated on each card, DDP fails if the model weights, optimizer states, and activations exceed the VRAM of a single GPU.

---

## 2. Model Parallelism (Sharding)

When a model is too large for one GPU, you must partition the model itself:

### A. Tensor Parallelism (TP)
- Partitions individual layer weight matrices (e.g., Attention or MLP projection layers) across multiple GPUs.
- Requires communications (AllReduce/AllGather) within every forward and backward pass, which is highly sensitive to interconnect bandwidth (requires NVLink).

### B. Pipeline Parallelism (PP)
- Partitions the model layers sequentially across a chain of GPUs (e.g., layers 1-8 on GPU 0, layers 9-16 on GPU 1).
- Introduces idle time ("bubbles") where upstream or downstream GPUs wait for calculations. Frameworks mitigate this using micro-batches.

### C. Hybrid (3D) Parallelism
- Combines DDP, TP, and PP to scale training to thousands of GPUs. Typically, TP is used within a node (connected via NVLink), PP across nodes on a fast network, and DDP across the remaining nodes.

---

## 3. Parallelism Selection Guide

| Model Size | Interconnect (NVLink available?) | Recommended Strategy |
|---|---|---|
| **< 10B Parameters** | N/A | DDP or FSDP (No sharding) |
| **10B - 30B Parameters** | Yes | PyTorch FSDP or DeepSpeed ZeRO-2/3 |
| **30B - 100B Parameters**| Yes (High bandwidth) | DeepSpeed ZeRO-3 or FSDP + TP |
| **> 100B Parameters** | Yes (Ultra bandwidth) | Hybrid 3D Parallelism (TP + PP + DP) |
