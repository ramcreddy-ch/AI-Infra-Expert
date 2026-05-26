# Decoding XID Error Codes

XID errors are reporting messages printed by the NVIDIA driver to the kernel log (`dmesg`). They indicate that a GPU error occurred, often causing any active CUDA context to crash.

---

## 1. Production XID Error Code Reference

| XID | Severity | Type | Description | Remediation |
|---|---|---|---|---|
| **31** | Critical | Driver/HW | GPU Memory Page Fault. The GPU tried to access an invalid memory address. | Software issue (check for out-of-bounds array access in CUDA code) or GPU VRAM failure. |
| **43** | Critical | HW | GPU dirty power or temperature threshold exceeded. | Check host power supplies and cooling fans. |
| **45** | Critical | HW | GPU physical link connection lost (Fallen off bus). | Check PCIe slot seating or mainboard connections. Hard reboot host. |
| **62** | Critical | HW | Internal microcode engine error. | Typically indicates a hardware defect. Drain node and run DCGM diagnostics. |
| **79** | Critical | HW | GPU has fallen off the bus. | Hardware crash. The PCIe bus interface reset. Hard reboot needed. |
| **92** | High | Driver | NVLink communication failure. | Check if Fabric Manager is active. Restart Fabric Manager. |

---

## 2. Searching and Capturing XID Errors

To find and monitor XID errors on host systems:

```bash
# Query kernel logs for XID codes
dmesg | grep -i "NVRM: Xid"

# Output format example:
# [20145.105432] NVRM: Xid (PCI:0000:01:00.0): 31, Ch 00000010, e0004500 00000000
```
*In the example above, XID 31 occurred on the GPU located at PCIe address `0000:01:00.0`.*
