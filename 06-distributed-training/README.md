# Module 06: Distributed Training at Scale

When models exceed the capacity of a single GPU, you must scale training workloads across multiple GPUs and nodes. This module covers parallelism strategies, network fabric configurations, and frameworks like DeepSpeed and FSDP.

## 📚 Table of Contents

1. [**Parallelism Strategies**](01-parallelism-strategies.md)
   - Data Parallelism (DDP) vs Model Parallelism
   - Tensor, Pipeline, Sequence, and Hybrid (3D) Parallelism
   - Choosing a strategy based on model size and hardware
2. [**NCCL Configuration & Tuning**](02-nccl-configuration.md)
   - NCCL collective communications and topology discovery
   - Crucial environment variables for performance tuning
   - Running NCCL benchmarks (`nccl-tests`)
3. [**InfiniBand & RoCE Network Fabrics**](03-infiniband-rdma.md)
   - InfiniBand vs Ethernet vs RoCE comparisons
   - GPUDirect RDMA and GPUDirect Storage
   - Diagnostic tools and performance monitoring
4. [**DeepSpeed Configurations**](04-deepspeed-config.md)
   - ZeRO (Zero Redundancy Optimizer) stages 1, 2, and 3
   - Production JSON configuration templates
5. [**Fully Sharded Data Parallel (FSDP)**](05-fsdp-config.md)
   - PyTorch FSDP architecture
   - Auto-wrapping policies and state-dict checkpointing
6. [**Kubernetes Training Jobs**](06-kubernetes-training-jobs.md)
   - Kubeflow Training Operator (`PyTorchJob`)
   - Gang scheduling with Volcano
   - Fault tolerance and dynamic checkpoint loading
