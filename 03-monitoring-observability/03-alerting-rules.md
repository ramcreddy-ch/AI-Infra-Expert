# Production Alerting Rules

This guide outlines production Prometheus Alerting Rules for GPU clusters.

---

## 1. AlertManager GPU Rules

Configure these rules in your Prometheus setup (`prometheus-rules.yaml`):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: gpu-alert-rules
  namespace: gpu-operator
spec:
  groups:
  - name: GPUHardwareAlerts
    rules:
    - alert: GPUDeviceFallenOffBus
      expr: DCGM_FI_DEV_XID_ERRORS == 79 or DCGM_FI_DEV_XID_ERRORS == 43
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "GPU has fallen off PCIe bus on node {{ $labels.node }}"
        description: "A hardware crash caused the GPU to disappear from the PCIe bus. Action required: Hard reboot host or schedule RMA."

    - alert: GPUCriticalTemperature
      expr: DCGM_FI_DEV_GPU_TEMP > 85
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Critical temperature on GPU {{ $labels.gpu }} on node {{ $labels.node }}"
        description: "GPU core temperature is {{ $value }}°C, exceeding the safe limit. Thermal throttling is active. Action: Check cooling fan and ambient airflow."

    - alert: GPUUncorrectableECCError
      expr: DCGM_FI_DEV_ECC_DBE > 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Double-bit ECC error on GPU {{ $labels.gpu }} on node {{ $labels.node }}"
        description: "An uncorrectable double-bit memory error was detected. The GPU must be reset. Active jobs will fail. Action: Drain node and reboot host."

    - alert: IdleGPUPayload
      expr: DCGM_FI_DEV_GPU_UTIL < 5 and DCGM_FI_DEV_FB_USED > 5000
      for: 2h # Alert if GPU allocated but idle for over 2 hours
      labels:
        severity: warning
      annotations:
        summary: "GPU is allocated but idle on node {{ $labels.node }}"
        description: "Pod {{ $labels.pod }} has allocated GPU memory but compute utilization is under 5% for more than 2 hours. Wasting cluster budget."
```
