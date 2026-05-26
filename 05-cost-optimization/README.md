# Module 05: Cost Optimization

GPU instances are expensive. This module covers strategies to optimize cluster costs, including spot instances, GPU sharing, autoscaling, capacity planning, and FinOps practices.

## 📚 Table of Contents

1. [**Spot & Preemptible Instances**](01-spot-preemptible.md)
   - AWS Spot, GCP Preemptible, and Azure Spot VM models
   - Handling node interruptions gracefully with checkpointing
   - Using Karpenter and Node Termination Handlers
2. [**GPU Sharing Strategies**](02-gpu-sharing-strategies.md)
   - Split-GPU allocation options: MIG, Time-Slicing, and MPS
   - Quantifying utilization efficiency and selecting the right strategy
3. [**Autoscaling GPU Clusters**](03-autoscaling.md)
   - Cluster Autoscaler configuration for GPU node pools
   - Autoscaling pods based on GPU metrics via KEDA or HPA
   - Karpenter setups for on-demand GPU scaling
4. [**Capacity Planning & Cloud Providers**](04-capacity-planning.md)
   - Forecasting GPU demand and managing reservations
   - Cloud provider pricing comparison
5. [**FinOps & GPU Cost Allocation**](05-finops-gpu.md)
   - Tracking costs by team and project using Kubecost
   - Detecting idle GPU allocations and automating cleanup
