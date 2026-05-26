# Kubernetes Training Jobs

This guide covers running distributed training jobs in Kubernetes.

---

## 1. Kubeflow Training Operator

The **Kubeflow Training Operator** provides a custom controller that manages multi-node training clusters. It supports PyTorchJob, TFJob, and MPIJob CRDs.

### Production `PyTorchJob` Manifest: `llama-training-job.yaml`
```yaml
apiVersion: "kubeflow.org/v1"
kind: "PyTorchJob"
metadata:
  name: "llama-7b-train"
  namespace: "ml-training"
spec:
  pytorchReplicaSpecs:
    Master:
      replicas: 1
      restartPolicy: OnFailure
      template:
        spec:
          containers:
          - name: pytorch
            image: "my-registry/llama-trainer:latest"
            command: ["torchrun", "--nnodes=2", "--nproc_per_node=8", "train.py"]
            resources:
              limits:
                nvidia.com/gpu: "8"
    Worker:
      replicas: 1 # Total 2 nodes (1 Master, 1 Worker) = 16 GPUs
      restartPolicy: OnFailure
      template:
        spec:
          containers:
          - name: pytorch
            image: "my-registry/llama-trainer:latest"
            resources:
              limits:
                nvidia.com/gpu: "8"
```
