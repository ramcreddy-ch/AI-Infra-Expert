# 🚀 AI-Infra-Expert

> **The definitive, one-stop repository for mastering AI Infrastructure in Production** — from GPU basics to planet-scale distributed training, used and battle-tested by the world's top 100 companies.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 🎯 Who Is This For?

| Role | What You'll Learn |
|------|-------------------|
| **ML Engineers** | Debug GPU OOMs, optimize CUDA kernels, tune NCCL for multi-node training |
| **Platform/Infra Engineers** | Design K8s GPU clusters, implement monitoring, manage GPU lifecycle |
| **DevOps/SRE** | Production alerting, incident response runbooks, cost optimization |
| **Engineering Managers** | Capacity planning, vendor comparison, architecture decisions |

---

## 📚 Table of Contents

### Part I: Foundations
| # | Module | Description | Difficulty |
|---|--------|-------------|------------|
| 01 | [**GPU & TPU Fundamentals**](01-fundamentals/) | Architecture, CUDA, memory hierarchy, drivers | 🟢 Beginner |
| 02 | [**Kubernetes for AI Workloads**](02-kubernetes-gpu-management/) | Device plugins, GPU Operator, scheduling, node affinity | 🟢 Beginner |

### Part II: Operations
| # | Module | Description | Difficulty |
|---|--------|-------------|------------|
| 03 | [**Monitoring & Observability**](03-monitoring-observability/) | DCGM, Prometheus, Grafana dashboards, alerting | 🟡 Intermediate |
| 04 | [**Troubleshooting & Debugging**](04-troubleshooting-debugging/) | OOM, CUDA errors, XID errors, NCCL failures, thermal issues | 🟡 Intermediate |
| 05 | [**Cost Optimization**](05-cost-optimization/) | Spot instances, GPU sharing, MIG, autoscaling, right-sizing | 🟡 Intermediate |

### Part III: Scaling
| # | Module | Description | Difficulty |
|---|--------|-------------|------------|
| 06 | [**Distributed Training**](06-distributed-training/) | Multi-GPU, NCCL, InfiniBand, DeepSpeed, FSDP, Horovod | 🔴 Advanced |
| 07 | [**Model Serving & Inference**](07-model-serving-inference/) | Triton, vLLM, TGI, TensorRT, autoscaling inference | 🔴 Advanced |

### Part IV: Advanced & Enterprise
| # | Module | Description | Difficulty |
|---|--------|-------------|------------|
| 08 | [**Security & Multi-Tenancy**](08-security-isolation/) | MIG isolation, vGPU, RBAC, namespace isolation, compliance | 🔴 Advanced |
| 09 | [**Cloud Provider Deep Dives**](09-cloud-providers/) | AWS (p5/p4d), GCP (A3/TPU v5), Azure (ND H100), On-Prem | 🟡 Intermediate |
| 10 | [**Advanced Scheduling & Orchestration**](10-advanced-topics/) | Custom schedulers, Volcano, topology-aware, fractional GPUs | 🔴 Advanced |
| 11 | [**Real-World Architectures**](11-real-world-architectures/) | How OpenAI, Meta, Google, Netflix, Tesla run AI infra | 🔴 Advanced |

### Quick References
| Resource | Description |
|----------|-------------|
| [**Cheatsheets**](cheatsheets/) | nvidia-smi, kubectl GPU commands, debugging flowcharts |
| [**Scripts**](scripts/) | Health checks, diagnostics, benchmarks, setup automation |
| [**K8s Manifests**](manifests/) | Production-ready YAML for GPU clusters |
| [**Runbooks**](runbooks/) | Incident response playbooks for common GPU failures |

---

## 🗺️ Learning Roadmap

```
Week 1-2: Foundations
├── GPU Architecture & CUDA Basics
├── nvidia-smi Mastery
├── Driver & Container Runtime Setup
└── K8s Device Plugin Basics

Week 3-4: Kubernetes GPU Management
├── NVIDIA GPU Operator
├── Resource Requests & Limits
├── Node Feature Discovery
├── Scheduling & Affinity
└── MIG Configuration

Week 5-6: Monitoring & Debugging
├── DCGM Exporter Setup
├── Prometheus + Grafana Dashboards
├── XID Error Interpretation
├── OOM Debugging
└── NCCL Troubleshooting

Week 7-8: Distributed Training
├── Data Parallelism (DDP)
├── NCCL Tuning
├── InfiniBand / RoCE
├── DeepSpeed ZeRO
├── FSDP Configuration
└── Multi-Node Training Jobs

Week 9-10: Model Serving
├── Triton Inference Server
├── vLLM for LLM Serving
├── TensorRT Optimization
├── Autoscaling Strategies
└── A/B Testing & Canary Deploys

Week 11-12: Enterprise & Advanced
├── Cost Optimization Strategies
├── Security & Multi-Tenancy
├── Custom Schedulers (Volcano)
├── Capacity Planning
└── Disaster Recovery
```

---

## 🏢 Companies & Tools Referenced

| Company | AI Infra Contribution |
|---------|----------------------|
| **NVIDIA** | GPU Operator, DCGM, Triton, TensorRT, NCCL, MIG |
| **Google/DeepMind** | TPU, JAX, Borg/K8s, Vertex AI, GKE |
| **Meta** | PyTorch, FSDP, RSC supercomputer, Grand Teton |
| **OpenAI** | Kubernetes at scale, custom schedulers, Azure integration |
| **Microsoft** | DeepSpeed, Azure ND series, ONNX Runtime |
| **Tesla** | Dojo, custom training infra, FSD training pipeline |
| **Netflix** | Titus (container platform), GPU cost optimization |
| **Uber** | Michelangelo, Horovod (distributed training) |
| **Airbnb** | Bighead ML platform, GPU resource management |
| **ByteDance** | MegaScale (large-scale training), custom schedulers |
| **Databricks** | MLflow, Spark + GPU, Mosaic ML |
| **Hugging Face** | TGI, Optimum, accelerate library |
| **Anyscale/Ray** | Ray Serve, Ray Train, Ray Cluster autoscaling |
| **Run:ai** | GPU virtualization, fractional GPUs, scheduling |
| **CoreWeave** | GPU cloud, K8s-native GPU infrastructure |

---

## 🛠️ Prerequisites

```bash
# Minimum knowledge required:
- Linux system administration (intermediate)
- Kubernetes basics (pods, deployments, services)
- Docker / container fundamentals
- Basic understanding of ML training workflows

# Recommended tools installed:
- kubectl (v1.28+)
- helm (v3.12+)
- nvidia-smi (driver 535+)
- docker / containerd with nvidia-container-toolkit
- Python 3.10+
```

---

## 🚦 Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/AI-Infra-Expert.git
cd AI-Infra-Expert

# Verify your GPU setup
./scripts/gpu-health-check.sh

# Deploy GPU monitoring stack
kubectl apply -f manifests/monitoring/

# Run GPU diagnostics
python scripts/gpu-diagnostics.py

# Start with fundamentals
open 01-fundamentals/README.md
```

---

## 📊 Real-Time Debugging Decision Tree

```
GPU Issue Detected
├── nvidia-smi shows error?
│   ├── "No devices found" → See: 04-troubleshooting/01-driver-issues.md
│   ├── XID Error → See: 04-troubleshooting/02-xid-errors.md
│   └── ECC Error → See: 04-troubleshooting/05-hardware-errors.md
├── Training job OOM?
│   ├── GPU Memory OOM → See: 04-troubleshooting/03-oom-debugging.md
│   └── Host Memory OOM → See: 04-troubleshooting/03-oom-debugging.md#host-oom
├── Training hangs?
│   ├── Single GPU → See: 04-troubleshooting/04-cuda-errors.md
│   └── Multi-GPU → See: 04-troubleshooting/06-nccl-debugging.md
├── Slow performance?
│   ├── Low GPU utilization → See: 04-troubleshooting/07-performance-debugging.md
│   ├── PCIe bottleneck → See: 04-troubleshooting/07-performance-debugging.md#pcie
│   └── Thermal throttling → See: 04-troubleshooting/08-thermal-issues.md
└── K8s scheduling issues?
    ├── Pod pending → See: 02-kubernetes/05-troubleshooting.md
    └── Wrong GPU assigned → See: 02-kubernetes/03-scheduling.md
```

---

## 📝 Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

> **⭐ Star this repo** if you find it useful! Help the community by sharing your production experiences.
