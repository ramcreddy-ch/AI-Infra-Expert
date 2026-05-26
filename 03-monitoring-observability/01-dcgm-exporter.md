# DCGM Exporter

NVIDIA **Data Center GPU Manager (DCGM)** is a suite of tools for managing and monitoring NVIDIA GPUs in clustered environments. This guide explains its architecture and how to deploy it in Kubernetes to gather metrics.

---

## 1. DCGM Architecture

DCGM consists of a low-level host service (`nv-hostengine`) that communicates directly with the NVIDIA kernel driver via NVML.
*   **DCGM Exporter:** A Prometheus metrics collector that queries the DCGM engine and exposes standard HTTP endpoints (`/metrics`) on port `9400`.

### Key Metrics to Monitor in Production

| Prometheus Metric Name | Description | Alerting Importance |
|---|---|---|
| `DCGM_FI_DEV_GPU_UTIL` | GPU compute utilization (%). | High (identifies under-utilized or overloaded nodes) |
| `DCGM_FI_DEV_FB_USED` | Framebuffer (VRAM) used (MB). | High (pre-empts Out-Of-Memory errors) |
| `DCGM_FI_DEV_GPU_TEMP` | GPU Core Temperature (°C). | Critical (high temperatures trigger throttling) |
| `DCGM_FI_DEV_POWER_USAGE` | Current power draw (W). | Medium (monitors power capping limits) |
| `DCGM_FI_DEV_XID_ERRORS` | Tracks recent XID error code. | Critical (non-zero value indicates hardware/driver crash) |
| `DCGM_FI_DEV_ECC_DBE` | Double-bit ECC errors (uncorrectable). | Critical (indicates hardware memory failure) |
| `DCGM_FI_DEV_NVLINK_BANDWIDTH_TOTAL` | Total NVLink transfer speed (bytes/sec). | High (diagnoses training communication bottlenecks) |

---

## 2. Deploying DCGM Exporter in Kubernetes

The DCGM Exporter is typically deployed as a DaemonSet to run on every GPU-enabled worker node.

### YAML Manifest: `dcgm-exporter.yaml`
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: dcgm-exporter
  namespace: gpu-operator
  labels:
    app: dcgm-exporter
spec:
  selector:
    matchLabels:
      app: dcgm-exporter
  template:
    metadata:
      labels:
        app: dcgm-exporter
    spec:
      containers:
      - name: exporter
        image: nvcr.io/nvidia/k8s-device-plugin:v0.14.0
        command: ["dcgm-exporter", "-f", "/etc/dcgm-exporter/default-counters.csv"]
        ports:
        - name: metrics
          containerPort: 9400
        securityContext:
          runAsNonRoot: false
          capabilities:
            add: ["SYS_ADMIN"] # Required to access low-level NVML counters
```
