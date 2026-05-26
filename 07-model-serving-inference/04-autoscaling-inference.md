# Autoscaling Inference Workloads

This guide covers autoscaling configurations for inference workloads.

---

## 1. Scale-to-Zero with Knative Serving

To save costs on low-volume models, you can configure **Knative Serving** to scale pod allocations down to zero when no active requests are detected.

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: low-volume-model
  namespace: model-serving
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/min-scale: "0" # Scale down to zero pods
        autoscaling.knative.dev/max-scale: "3"
        autoscaling.knative.dev/target: "10" # Scale up if a pod averages >10 concurrent requests
    spec:
      containers:
      - image: my-model-container:latest
        resources:
          limits:
            nvidia.com/gpu: "1"
```
*Note: Scaling up from zero pods introduces startup latency ("cold start"), as the container must initialize and load weights into GPU memory before responding to the first request. Use this strategy only when immediate response times are not required.*
