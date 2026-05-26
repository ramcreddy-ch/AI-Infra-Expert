# Thermal & Power Issues

GPUs require significant power and cooling. If temperatures or power limits are exceeded, hardware safety mechanisms will reduce performance or shut down the device.

---

## 1. Thermal Throttling

When core temperatures exceed the manufacturer's threshold (typically 80-85°C on enterprise cards), the GPU driver automatically lowers the engine clock frequency to prevent damage.
*   **Checking Thermal Status:**
    ```bash
    # Print current thermal status
    nvidia-smi -q -d TEMPERATURE
    ```

### Diagnostic Output Example:
```
GPU 00000000:00:04.0
    Temperature
        GPU Current Temp            : 82 C
        GPU Tlimit Temp             : 85 C
        GPU Shutdown Temp           : 90 C
```
If `Current Temp` approaches `Tlimit Temp`, thermal throttling is active, reducing training performance.

---

## 2. Power Limits and Capping

On high-density nodes, power delivery can limit performance. Check power consumption and caps:

```bash
nvidia-smi -q -d POWER
```

### Changing Power Draw Caps
If your server cooling or power delivery cannot support peak draws, you can enforce a lower power limit on the card:

```bash
# Cap GPU 0 power draw to 350W (e.g., on a 400W peak card)
sudo nvidia-smi -i 0 -pl 350
```
*Note: This reduces peak compute speeds but helps maintain stable operations on nodes with power delivery constraints.*
