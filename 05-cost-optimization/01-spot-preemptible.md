# Spot & Preemptible Instances

Spot and Preemptible instances offer significant cost discounts (up to 70-90% compared to on-demand pricing), but they can be reclaimed by the cloud provider with little notice (typically a 30-second to 2-minute warning). This guide covers how to design system architectures to utilize these instances.

---

## 1. Spot Instance Disruption Handlers

To use spot instances for long-running training jobs, your systems must handle interruptions gracefully.

### Checkpointing Workflows
Your training scripts must save checkpoints to persistent remote storage (e.g., AWS S3 or GCP Cloud Storage) at regular intervals.

```python
import torch

# Save state helper
def save_training_checkpoint(state, path="s3://my-bucket/checkpoints/checkpoint.pt"):
    # 1. Save locally
    torch.save(state, "local_temp.pt")
    # 2. Upload to remote object storage using boto3 or gsutil
    upload_to_s3("local_temp.pt", path)
```

### Kubernetes Node Termination Handler
The **AWS Node Termination Handler** monitors IMDS (Instance Metadata Service) or EventBridge for Spot Interruption notices. When it detects a termination warning, it cordons and drains the node automatically:

```
  [AWS EventBridge / IMDS] ──> [Termination Notice (2 min warning)]
                                            │
                                            ▼
                             [Node Termination Handler]
                                            │
                                            ▼
                              [kubectl cordon & drain]
                                            │
                                            ▼
                             [Pod saves checkpoint & exits]
```
This gives the pod time to complete its current step, save a checkpoint, and exit gracefully before the node is terminated.
