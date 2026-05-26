# Triton Inference Server

NVIDIA's **Triton Inference Server** is a model serving software solution that supports multiple framework backends (PyTorch, TensorRT, ONNX, TensorFlow, vLLM).

---

## 1. Triton Model Repository Layout

Triton requires models to be organized in a specific directory structure on disk or in object storage:

```
  model_repository/
  └── llama-7b-onnx/
      ├── config.pbtxt
      └── 1/
          └── model.onnx
```

### Writing `config.pbtxt` with Dynamic Batching
Dynamic batching is a Triton feature that combines individual inference requests into a single batch to maximize GPU utilization:

```protobuf
name: "llama-7b-onnx"
platform: "onnxruntime_onnx"
max_batch_size: 16

input [
  {
    name: "input_ids"
    data_type: TYPE_INT32
    dims: [ -1 ]
  }
]
output [
  {
    name: "logits"
    data_type: TYPE_FP32
    dims: [ -1, 32000 ]
  }
]

dynamic_batching {
  max_queue_delay_microseconds: 5000 # Wait up to 5ms to collect requests into a batch
}

instance_group [
  {
    count: 2 # Deploy 2 concurrent instances of this model on the GPU
    kind: KIND_GPU
  }
]
```

---

## 2. Deploying Triton on Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: triton-server
  namespace: model-serving
spec:
  replicas: 1
  selector:
    matchLabels:
      app: triton-server
  template:
    metadata:
      labels:
        app: triton-server
    spec:
      containers:
      - name: triton
        image: nvcr.io/nvidia/tritonserver:23.09-py3
        args: ["tritonserver", "--model-repository=s3://my-bucket/model_repository"]
        ports:
        - containerPort: 8000
          name: http
        - containerPort: 8001
          name: grpc
        resources:
          limits:
            nvidia.com/gpu: "1"
```
