# EKS & Kubernetes GPU Real-Time Production Issues

This guide focuses specifically on platform engineering and operational challenges when running GPU workloads in **Amazon EKS (Elastic Kubernetes Service)** and self-managed Kubernetes clusters in production.

---

## 📚 Table of Contents
1. [Amazon EKS Specific GPU Issues (Issues 1-5)](#1-amazon-eks-specific-gpu-issues)
2. [Kubernetes Cluster & Scheduling GPU Issues (Issues 6-10)](#2-kubernetes-cluster--scheduling-gpu-issues)

---

## 1. Amazon EKS Specific GPU Issues

### Issue 1: EKS Worker Nodes missing `nvidia.com/gpu` resource after cluster upgrade
*   **Symptom:** You upgrade your EKS cluster from version 1.27 to 1.28. The nodes register as `Ready`, but running `kubectl describe node` lists `nvidia.com/gpu: 0` or the metric is completely missing.
*   **Root Cause:** Custom launch templates or node group configurations point to an older EKS GPU-optimized AMI that is incompatible with the updated Kubernetes control plane container runtime path. In Kubernetes 1.24+, the dockershim was removed, and updates to the containerd config layout can cause the NVIDIA container runtime hook to fail to register.
*   **Remediation:**
    1. Verify if containerd is using the NVIDIA runtime configuration:
       ```bash
       ssh -i key.pem ec2-user@<node-ip> "cat /etc/containerd/config.toml"
       ```
    2. Ensure the following runtime block is configured under `plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia`:
       ```toml
       [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia]
         privileged_without_host_devices = false
         runtime_type = "io.containerd.runtimes.handler.v1"
       ```
    3. Update the node group's Launch Template to target the latest official AWS EKS GPU-optimized AMI (available in SSM Parameter Store):
       ```bash
       aws ssm get-parameter --name /aws/service/eks/optimized-ami/1.28/amazon-linux-2-gpu/recommended/image_id
       ```
    4. Terminate the old nodes sequentially to trigger a rolling update.

---

### Issue 2: VPC CNI IP address exhaustion on multi-GPU instances
*   **Symptom:** You deploy multiple pods (e.g., sharing a GPU via time-slicing or MPS) on a single large node like `g5.12xlarge`. Pods remain stuck in `Pending` with `NetworkPlugin cni failed to set up pod: no IP addresses available`.
*   **Root Cause:** By default, the AWS VPC CNI allocates IP addresses directly from your AWS VPC subnet. Each EC2 instance type has a maximum limit on Elastic Network Interfaces (ENIs) and IP addresses per ENI. If you run many small sharing pods on one node, you run out of IP allocations before utilizing the CPU or GPU resources.
*   **Remediation:**
    1. Enable **Prefix Delegation** on the VPC CNI daemonset. This allows each ENI to allocate a `/28` prefix (16 IPs) instead of a single IP address:
       ```bash
       kubectl set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
       kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
       ```
    2. Restart the CNI pods:
       ```bash
       kubectl rollout restart daemonset aws-node -n kube-system
       ```

---

### Issue 3: Karpenter fails to scale up GPU nodes due to missing node template overrides
*   **Symptom:** You submit a training job requesting a GPU. Karpenter logs error messages like: `failed to provision node, no instance types matched requirements` or the EC2 instances launch but fail to join the cluster.
*   **Root Cause:** Karpenter's EC2NodeClass is missing the subnet or security group tags that are required to register new GPU nodes with the EKS cluster, or the InstanceProfile lacks the AWS SSM policy required to initialize EKS bootstrapping.
*   **Remediation:**
    1. Inspect Karpenter logs: `kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter`
    2. Verify the `EC2NodeClass` definition:
       ```yaml
       apiVersion: karpenter.k8s.aws/v1beta1
       kind: EC2NodeClass
       metadata:
         name: gpu-node-class
       spec:
         amiFamily: AL2 # Ensure AL2 or Bottlerocket is selected for EKS GPU compatibility
         role: KarpenterNodeRole-YourClusterName # Must have AmazonEKSWorkerNodePolicy and AmazonSSMManagedInstanceCore
         subnetSelectorTerms:
         - tags:
             karpenter.sh/discovery: YourClusterName
         securityGroupSelectorTerms:
         - tags:
             karpenter.sh/discovery: YourClusterName
       ```
    3. Ensure the security groups allow traffic between Karpenter-provisioned nodes and the control plane.

---

### Issue 4: AWS EFA (Elastic Fabric Adapter) not working in EKS PyTorch training jobs
*   **Symptom:** Multi-node training runs slowly on EKS `p4d.24xlarge` or `p5.48xlarge` nodes. PyTorch logs show communication reverting to standard TCP interface speeds rather than EFA speed.
*   **Root Cause:** The EFA interfaces are not mounted into the pod specs, or the AWS EFA device plugin is missing from the cluster.
*   **Remediation:**
    1. Apply the AWS VPC resource controller and EFA device plugin:
       ```bash
       kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.12/aws-k8s-device-plugin.yaml
       ```
    2. Update the pod specification to request EFA resources explicitly:
       ```yaml
       resources:
         limits:
           vpc.amazonaws.com/efa: "4" # Request 4 EFA interfaces (typical on p4d instances)
           nvidia.com/gpu: "8"
       ```
    3. Mount the EFA driver directories from the host in your training containers:
       - Ensure your container image has `libfabric` and the AWS EFA libraries installed.

---

### Issue 5: IAM Role for Service Accounts (IRSA) failing on GPU training pods accessing S3 bucket
*   **Symptom:** The PyTorchJob starts training but fails on the first checkpoint step with: `botocore.exceptions.ClientError: An error occurred (403) when calling the PutObject operation: Access Denied`.
*   **Root Cause:** The training pods are using the default EC2 instance profile role instead of a service account IAM role, or the container runtime runs as non-root and lacks access to the projected AWS token file.
*   **Remediation:**
    1. Create an IAM policy with read/write access to your S3 bucket.
    2. Associate this policy with a K8s Service Account using `eksctl` or Terraform:
       ```bash
       eksctl create iamserviceaccount \
         --name gpu-s3-writer \
         --namespace ml-training \
         --cluster my-cluster \
         --role-name EKS-GPU-S3-Access-Role \
         --attach-policy-arn arn:aws:iam::123456789012:policy/S3TrainingCheckpointsPolicy \
         --approve
       ```
    3. Verify that your Pod specification contains the `serviceAccountName: gpu-s3-writer`.

---

## 2. Kubernetes Cluster & Scheduling GPU Issues

### Issue 6: Pod Security Standards (PSS) block GPU Operator daemonsets
*   **Symptom:** You deploy the GPU Operator via Helm. The driver and container toolkit pods are created but remain stuck in `FailedCreate` or `CreateContainerConfigError` states.
*   **Root Cause:** The namespace has a Pod Security Standard (PSS) label set to `privileged: false` or `enforce: restricted`. The GPU Operator requires privileged access to load kernel modules on the host.
*   **Remediation:**
    1. Inspect namespace labels: `kubectl get ns gpu-operator --show-labels`
    2. Apply the privileged policy label to the `gpu-operator` namespace:
       ```bash
       kubectl label --overwrite namespace gpu-operator pod-security.kubernetes.io/enforce=privileged
       ```
    3. Re-run or restart the deployment.

---

### Issue 7: Cluster Autoscaler "Scale from Zero" fails for GPU nodes
*   **Symptom:** You request a GPU pod. The cluster has 0 active GPU nodes. The pod remains `Pending`, but the Cluster Autoscaler does not scale up the GPU node group.
*   **Root Cause:** The Cluster Autoscaler does not know that the pending node group contains GPU resources. By default, it requires at least one active node to query hardware properties.
*   **Remediation:**
    Apply specific auto-scaling group (ASG) tags in AWS (or metadata labels in GCP/Azure) to advertise the GPU hardware specs to the autoscaler:
    - **Tag Key:** `k8s.io/cluster-autoscaler/node-template/resources/nvidia.com/gpu`
      - **Value:** `1` (or count of GPUs per instance)
    - **Tag Key:** `k8s.io/cluster-autoscaler/node-template/label/nvidia.com/gpu.product`
      - **Value:** `NVIDIA-H100-SXM5`
    - Restart the cluster-autoscaler deployment:
      ```bash
      kubectl rollout restart deployment cluster-autoscaler -n kube-system
      ```

---

### Issue 8: Eviction and node drains hang on GPU training jobs
*   **Symptom:** You execute `kubectl drain <node>` to perform driver maintenance. The command hangs, and the node remains in `SchedulingDisabled` state.
*   **Root Cause:** GPU training pods are running without a termination grace period or ignore the SIGTERM signal, blocking the eviction controller. Alternatively, no Pod Disruption Budget (PDB) is configured to handle the eviction.
*   **Remediation:**
    1. Force eviction by specifying a timeout:
       ```bash
       kubectl drain <node-name> --delete-emptydir-data --ignore-daemonsets --force --grace-period=60
       ```
    2. Update training scripts to register a signal handler for `SIGTERM` to save progress and exit:
       ```python
       import signal
       import sys

       def sigterm_handler(signum, frame):
           print("Received SIGTERM. Saving checkpoint...")
           save_checkpoint()
           sys.exit(0)

       signal.signal(signal.SIGTERM, sigterm_handler)
       ```

---

### Issue 9: GPU Node Feature Discovery labels out of sync after GPU replacement
*   **Symptom:** A node's physical GPU is upgraded from an A100 to an H100, but Kubernetes labels still display `nvidia.com/gpu.product=NVIDIA-A100-SXM4-80GB`.
*   **Root Cause:** GFD caches discovery labels in the local filesystem or memory, failing to update until the daemonset is restarted.
*   **Remediation:**
    Force a re-discovery by restarting the GFD and Node Feature Discovery daemonset pods:
    ```bash
    kubectl rollout restart daemonset -n gpu-operator nvidia-device-plugin-validator
    kubectl rollout restart daemonset -n gpu-operator node-feature-discovery-worker
    ```

---

### Issue 10: Prometheus DCGM Exporter fails to scrape metrics due to NetworkPolicies
*   **Symptom:** The Prometheus targets dashboard shows the `dcgm-exporter` endpoint as `DOWN` or returns connection timeout status.
*   **Root Cause:** A `NetworkPolicy` configured in the namespace restricts ingress traffic, blocking the Prometheus service from scraping port `9400`.
*   **Remediation:**
    Configure a NetworkPolicy to allow scraping traffic:
    ```yaml
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-prometheus-scraping
      namespace: gpu-operator
    spec:
      podSelector:
        matchLabels:
          app: nvidia-dcgm-exporter
      ingress:
      - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring # Namespace of Prometheus server
        ports:
        - protocol: TCP
          port: 9400
    ```
