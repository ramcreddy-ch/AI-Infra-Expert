# Module 02: Kubernetes GPU Management

Managing GPUs in Kubernetes requires orchestrating hardware drivers, runtime tools, and resource schedulers. This module covers setting up device plugins, deploying the GPU Operator, scheduling strategies, and configuring GPU sharing.

## 📚 Table of Contents

1. [**Device Plugins**](01-device-plugins.md)
   - Kubernetes Device Plugin framework overview
   - Exposing GPUs as extended resources (`nvidia.com/gpu`)
   - Troubleshooting device registration issues
2. [**NVIDIA GPU Operator**](02-gpu-operator.md)
   - GPU Operator Architecture (all daemons explained)
   - Production-ready Helm installation values
   - Upgrading and maintaining the operator
3. [**Scheduling & Placements**](03-scheduling.md)
   - Allocating GPU resource requests and limits
   - Node affinity, taints, and tolerations
   - Topology-aware scheduling and NUMA alignment
   - Preemption models for training vs inference
4. [**Node Feature Discovery (NFD) & GFD**](04-node-feature-discovery.md)
   - Labeling nodes with GPU model, driver version, memory capacity
   - Node Feature Discovery setup
   - Target-scheduling using GPU properties
5. [**Multi-Instance GPU (MIG)**](05-multi-instance-gpu.md)
   - MIG slicing and profile specifications (1g.5gb, 2g.10gb, etc.)
   - Dynamic vs static MIG configuration
   - Multi-tenant physical isolation guarantees
6. [**GPU Sharing: Time-Slicing, MPS, and Virtualization**](06-gpu-sharing.md)
   - Sharing GPUs: MIG vs Time-slicing vs MPS
   - Configuring time-slicing with GPU Operator
   - Running Multi-Process Service (MPS) in containers
7. [**Kubernetes GPU Troubleshooting Runbook**](07-troubleshooting-k8s.md)
   - Pods stuck in `Pending` due to GPU resources
   - Driver mounting and container runtime failures
   - Troubleshooting steps and validation scripts
