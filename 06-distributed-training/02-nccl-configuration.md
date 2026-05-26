# NCCL Configuration & Tuning

NVIDIA Collective Communications Library (NCCL) implements multi-GPU communication primitives (AllReduce, AllGather, ReduceScatter, Broadcast) optimized for NVIDIA platforms.

---

## 1. Crucial NCCL Environment Variables

Configure these variables inside your training containers to tune performance:

| Env Var | Recommended Value | Description |
|---|---|---|
| `NCCL_DEBUG` | `INFO` | Enables verbose logging to verify interfaces and driver loading. |
| `NCCL_SOCKET_IFNAME` | e.g., `eth0` or `ib0` | Forces NCCL to bind to the specified network interface. |
| `NCCL_IB_DISABLE` | `0` (or `1` to debug) | Enables (`0`) or disables (`1`) InfiniBand/RoCE usage. |
| `NCCL_NET_GDR_LEVEL` | `5` (on GPUDirect nodes) | Configures GPUDirect RDMA path level (5 = path includes NVSwitch/PCIe links). |
| `NCCL_BUFFSIZE` | `4194304` (4MB) | Increases communication buffer size (default is 4MB, higher values can improve throughput). |

---

## 2. Running NCCL Benchmarks

Before launching large training jobs, run the `nccl-tests` suite to verify network bandwidth:

```bash
# Run AllReduce benchmark across 8 local GPUs
mpirun -np 8 \
   --allow-run-as-root \
   -H localhost:8 \
   -bind-to none -map-by slot \
   -x NCCL_DEBUG=INFO \
   /usr/local/bin/all_reduce_perf -b 8M -e 256M -f 2 -g 1
```

### Reading Benchmark Output:
```
#                                           out-of-place                       in-place          
#       size         count      type   op    time  algbw  busbw #ers     time  algbw  busbw #ers
#        (B)    (elements)                  (us) (GB/s) (GB/s)        (us) (GB/s) (GB/s)
   268435456      67108864     float  sum  2681.4  100.1  175.2    0   2679.2  100.2  175.4    0
```
*Look for `busbw` (bus bandwidth). On an H100 SXM node, internal GPU-to-GPU transfer speeds should approach 400+ GB/s over NVLink.*
