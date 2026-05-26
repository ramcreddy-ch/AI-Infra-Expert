# Module 07: Model Serving & Inference

Exposing models in production requires serving engines designed for low latency and high throughput. This module covers Triton Inference Server, vLLM, TensorRT compilation, and dynamic scaling.

## 📚 Table of Contents

1. [**Triton Inference Server**](01-triton-inference-server.md)
   - Triton architecture and multi-backend support
   - Designing model repositories and configuring dynamic batching
   - Deploying Triton in Kubernetes
2. [**vLLM Deployment**](02-vllm-deployment.md)
   - Continuous Batching and PagedAttention concepts
   - Serving LLMs with Tensor Parallelism
   - Kubernetes deployments and OpenAPI integrations
3. [**TensorRT & TensorRT-LLM Optimization**](03-tensorrt-optimization.md)
   - Converting PyTorch/ONNX models to TensorRT engines
   - Precision scaling (FP16, INT8, FP8)
4. [**Autoscaling Inference Workloads**](04-autoscaling-inference.md)
   - Queue-based autoscaling (Knative, KEDA)
   - Scale-to-zero configurations for low-demand models
5. [**Model Optimization Techniques**](05-model-optimization.md)
   - Quantization (AWQ, GPTQ, SmoothQuant)
   - Speculative decoding and KV cache management
