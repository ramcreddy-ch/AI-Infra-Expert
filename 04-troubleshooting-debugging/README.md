# Module 04: Troubleshooting & Debugging

This module covers identifying, diagnosing, and resolving common GPU and TPU failures in production environments.

## 📚 Table of Contents

1. [**Driver Failures**](01-driver-issues.md)
   - "NVIDIA-SMI has failed" causes
   - Persistence daemon errors and upgrades
2. [**XID Error Codes**](02-xid-errors.md)
   - Detailed lookup reference for XID error codes (31, 45, 62, 79, etc.)
   - Hardware vs software fault assessment and RMA flows
3. [**Out-Of-Memory (OOM) Debugging**](03-oom-debugging.md)
   - GPU VRAM vs Host OOM diagnostics
   - PyTorch memory profiling and memory leak detection
4. [**CUDA Runtime & Kernel Crashes**](04-cuda-errors.md)
   - "Illegal Memory Access" troubleshooting
   - Using CUDA-MEMCHECK / Compute Sanitizer
5. [**NCCL Communication Hangs**](05-nccl-debugging.md)
   - Troubleshooting network timeouts in distributed training
   - Analyzing topology and interface configurations
6. [**Performance & Bottlenecks**](06-performance-debugging.md)
   - Profiling CPU data loaders, PCIe bottlenecks, and NVLink speeds
   - Optimization workflows using PyTorch Profiler
7. [**Thermal & Power Issues**](07-thermal-power-issues.md)
   - Thermal throttling diagnostics
   - Power cap limits and clock monitoring
