# NVIDIA GPU Operator

The NVIDIA GPU Operator uses Kubernetes custom resource definitions (CRDs) to manage the lifecycle of all software components required to expose GPUs to Kubernetes.

---

## 1. GPU Operator Components

When you deploy the GPU Operator, it monitors your cluster nodes. When it detects a node with a GPU, it deploys the following stack in order:

```
  ┌────────────────────────────────────────────────────────┐
  │ 7. GFD (GPU Feature Discovery)                         │ (Labels node with GPU attributes)
  ├────────────────────────────────────────────────────────┤
  │ 6. DCGM Exporter (Telemetry)                           │ (Exposes GPU metrics for Prometheus)
  ├────────────────────────────────────────────────────────┤
  │ 5. NVIDIA Device Plugin                                │ (Advertises "nvidia.com/gpu" to Kubelet)
  ├────────────────────────────────────────────────────────┤
  │ 4. MIG Manager (If enabled)                            │ (Dynamically provisions MIG profiles)
  ├────────────────────────────────────────────────────────┤
  │ 3. Container Toolkit Container                         │ (Injects NVIDIA OCI runtime hooks)
  ├────────────────────────────────────────────────────────┤
  │ 2. Fabric Manager Container (SXM systems only)         │ (Configures NVLink / NVSwitch routing)
  ├────────────────────────────────────────────────────────┤
  │ 1. NVIDIA Driver Container                             │ (Compiles & inserts kernel modules)
  └────────────────────────────────────────────────────────┘
```

---

## 2. Production Installation: Helm Config

Create a custom `values.yaml` for helm installation to ensure stable operation in production.

```yaml
# values.yaml for Production GPU Operator
driver:
  enabled: true
  useDataDir: true
  repository: nvcr.io/nvidia
  version: "535.104.05"
  rdma:
    enabled: false # Set true if using RoCE/InfiniBand GPUDirect

toolkit:
  enabled: true
  repository: nvcr.io/nvidia
  version: "v1.13.5-centos7"

devicePlugin:
  enabled: true
  config:
    name: "dp-config"
    create: true
    data:
      default:
        sharing:
          timeSlicing:
            resources:
            - name: nvidia.com/gpu
              replicas: 4 # Allows up to 4 pods to share one physical GPU

dcgmExporter:
  enabled: true
  serviceMonitor:
    enabled: true # Integrates with Prometheus Operator
```

Install the operator:
```bash
helm repo add nvidia https://helm.github.io/gpu-operator
helm repo update
helm install gpu-operator nvidia/gpu-operator -f values.yaml --namespace gpu-operator --create-namespace
```

---

## 3. Operations & Zero-Downtime Upgrades

Upgrading drivers or GPU operator components can disrupt active workloads. Use these guidelines to maintain uptime:

1.  **Node Cordon & Drain:** Before updating the GPU Operator or node drivers, cordon and drain the node to ensure active jobs are scheduled elsewhere.
    ```bash
    kubectl cordon <node-name>
    kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
    ```
2.  **Rolling Driver Updates:** The GPU Operator supports rolling upgrades. It updates one node at a time based on Pod Disruption Budgets (PDB).
