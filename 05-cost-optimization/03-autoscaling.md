# Autoscaling GPU Clusters

Provisioning GPU nodes on-demand and scaling down when idle is essential to managing costs. This guide covers node-level and pod-level autoscaling.

---

## 1. Karpenter for On-Demand GPU Provisioning

Karpenter is an open-source Kubernetes autoscaler that bypasses the limitations of the traditional Cluster Autoscaler, provisioning nodes directly from cloud APIs based on pending pod requirements.

### Production NodePool Manifest: `gpu-nodepool.yaml`
```yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: gpu-nodes
spec:
  template:
    spec:
      requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot", "on-demand"]
      - key: karpenter.k8s.aws/instance-category
        operator: In
        values: ["p4", "g5"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      nodeClassRef:
        name: default-ec2-node-class
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 720h # Terminate and recreate nodes after 30 days to apply patches
```

---

## 2. Pod Autoscaling with KEDA (Kubernetes Event-driven Autoscaling)

For model inference, scaling based on CPU or memory usage is often too slow. Instead, configure **KEDA** to scale deployments based on the number of pending requests in your model queue:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vllm-hpa-scaler
  namespace: model-serving
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: vllm-llama-deployment
  minReplicaCount: 1
  maxReplicaCount: 10
  cooldownPeriod: 300
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-k8s.monitoring.svc.cluster.local:9090
      metricName: vllm_num_requests_waiting
      query: sum(vllm_num_requests_waiting)
      threshold: '5' # Scale up if there are more than 5 requests waiting in the queue
```
