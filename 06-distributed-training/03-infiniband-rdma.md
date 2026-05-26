# InfiniBand & RoCE Network Fabrics

At scale, inter-node network bandwidth is the primary bottleneck for distributed training. This guide compares network options and explains GPUDirect configurations.

---

## 1. Network Fabrics Comparison

| Feature | InfiniBand | RoCE (RDMA over Converged Ethernet) | Standard TCP/IP Ethernet |
|---|---|---|---|
| **Protocol** | Native InfiniBand | UDP/IP encapsulation | standard TCP/IP |
| **RDMA Support** | Yes (Native) | Yes | No |
| **Latency** | Ultra-low (< 1µs) | Low (~1.5-2µs) | High (~10-20µs) |
| **Throughput** | Up to 400 Gbps (NDR) | Up to 200/400 Gbps | Up to 100 Gbps |
| **Packet Loss** | Lossless (Credit-based) | Lossless (Requires PFC configured on switches) | Tolerates loss (TCP retransmissions) |
| **Cost** | Extremely High | High | Low |

---

## 2. GPUDirect RDMA (Remote Direct Memory Access)

Without GPUDirect RDMA, sending data from GPU 0 on Node A to GPU 0 on Node B requires multiple hops:

```
  Traditional: [GPU VRAM] ─> [Host RAM] ─> [CPU Socket] ─> [NIC] ─> [Network]
  GPUDirect:   [GPU VRAM] ──────────────────────────────> [NIC] ─> [Network]
```

GPUDirect RDMA allows the network interface card (NIC) to read and write GPU memory directly over the PCIe bus, bypassing host memory and CPU processing. This reduces latency and CPU utilization.
