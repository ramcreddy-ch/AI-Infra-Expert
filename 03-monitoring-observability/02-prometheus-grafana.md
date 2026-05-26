# Prometheus & Grafana Integration

Once DCGM Exporter exposes metrics on port `9400`, you must configure Prometheus to scrape them and load a Grafana dashboard for visualization.

---

## 1. Configuring Prometheus ServiceMonitor

If you use the Prometheus Operator, configure a `ServiceMonitor` to discover the DCGM Exporter endpoints automatically:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dcgm-exporter-monitor
  namespace: gpu-operator
  labels:
    release: prometheus-stack
spec:
  selector:
    matchLabels:
      app: dcgm-exporter
  endpoints:
  - port: metrics
    interval: 15s # Scrape interval
    path: /metrics
```

---

## 2. Essential PromQL Queries for GPU Clusters

### A. GPU Utilization per Pod
Shows which Kubernetes pods are consuming GPU compute capacity:
```promql
sum(DCGM_FI_DEV_GPU_UTIL) by (pod)
```

### B. VRAM Memory Usage Trend
Identifies potential memory leaks by charting allocations over time:
```promql
sum(DCGM_FI_DEV_FB_USED) by (node) / sum(DCGM_FI_DEV_FB_FREE + DCGM_FI_DEV_FB_USED) by (node) * 100
```

### C. NVLink Transfer Bottlenecks
Helps diagnose slow distributed training runs:
```promql
sum(rate(DCGM_FI_DEV_NVLINK_BANDWIDTH_TOTAL[1m])) by (pod)
```
