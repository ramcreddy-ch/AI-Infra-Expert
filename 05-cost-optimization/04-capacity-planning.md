# Capacity Planning & FinOps

This guide covers forecasting GPU demand, managing reservations, and tracking costs.

---

## 1. GPU Pricing Comparison Table

*Prices are estimated averages. Check your cloud provider console for current rates.*

| Cloud Provider | Instance Name | GPU Type | VRAM | Hourly Cost (On-Demand)| Hourly Cost (Spot) |
|---|---|---|---|---|---|
| **AWS** | `g5.xlarge` | 1x A10G | 24 GB | ~$1.00 | ~$0.30 |
| **AWS** | `p4de.24xlarge` | 8x A100 | 80 GB | ~$40.00 | ~$12.00 |
| **AWS** | `p5.48xlarge` | 8x H100 | 80 GB | ~$98.00 | N/A |
| **GCP** | `a3-highgpu-8g` | 8x H100 | 80 GB | ~$88.00 | N/A |
| **Azure** | `ND96asd_v4` | 8x A100 | 80 GB | ~$32.00 | ~$10.00 |

---

## 2. Idle GPU Detection with Kubecost

**Kubecost** integrates with your Kubernetes cluster to calculate cost allocations per namespace, service, or label.

### PromQL Query to Identify Under-Utilized GPUs:
```promql
# List nodes where GPU compute utilization is below 5%
avg(DCGM_FI_DEV_GPU_UTIL) by (node) < 5
```
*Platform teams can use these metrics to identify idle environments or Jupyter instances and automate their teardown using custom controllers.*
