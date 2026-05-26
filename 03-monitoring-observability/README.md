# Module 03: Monitoring & Observability

To manage GPU clusters at scale, you must monitor GPU telemetry in real time. This module covers setting up DCGM Exporter, integrating with Prometheus and Grafana, establishing alerting rules, and tracing distributed logging.

## 📚 Table of Contents

1. [**DCGM Exporter**](01-dcgm-exporter.md)
   - Data Center GPU Manager (DCGM) architecture
   - Deploying DCGM Exporter in Kubernetes
   - Critical GPU metrics catalog (Compute, Memory, PCIe, NVLink)
2. [**Prometheus & Grafana Integration**](02-prometheus-grafana.md)
   - Setting up the ServiceMonitor for Prometheus Operator
   - Production Grafana Dashboard JSON template
   - PromQL queries for capacity planning and incident response
3. [**Production Alerting Rules**](03-alerting-rules.md)
   - Configuring AlertManager for hardware failures and resource leaks
   - Critical vs Warning alert threshold configurations
4. [**Logging & Distributed Tracing**](04-logging-tracing.md)
   - Reading GPU kernel logs (`dmesg`, `syslog`)
   - Interpreting XID error codes in logs
   - NCCL communication trace configuration (`NCCL_DEBUG`)
