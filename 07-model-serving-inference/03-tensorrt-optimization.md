# TensorRT & TensorRT-LLM Optimization

NVIDIA **TensorRT** is a high-performance deep learning inference optimizer. It takes model weights and structures from PyTorch or ONNX and compiles them into optimized runtimes for specific GPU models.

---

## 1. The Compilation Process

1.  **Operator Fusion:** Merges adjacent layers (e.g., Conv + ReLU) into a single execution kernel, reducing memory transfers.
2.  **Kernel Auto-Tuning:** Benchmarks multiple execution algorithms on the target GPU hardware and selects the fastest configuration for the specified input shapes.
3.  **Precision Calibration:** Quantizes weights to lower-precision formats like FP16, INT8, or FP8.

### Converting an ONNX Model to TensorRT Engine
Use the `trtexec` CLI utility to compile an ONNX model:

```bash
trtexec --onnx=model.onnx \
        --saveEngine=model.engine \
        --fp16 \
        --minShapes=input:1x3x224x224 \
        --optShapes=input:8x3x224x224 \
        --maxShapes=input:16x3x224x224
```
*This compiles the model, enabling FP16 precision and optimizing execution parameters for batch sizes between 1 and 16.*
