# Fully Sharded Data Parallel (FSDP)

PyTorch **Fully Sharded Data Parallel (FSDP)** is a native implementation of ZeRO-like sharding.

---

## 1. FSDP Workflows

FSDP shards the model parameters, gradients, and optimizer states across data-parallel workers.
*   **Forward Pass:** For each layer, FSDP runs an **AllGather** step to collect weights from other GPUs, executes the forward pass, and then discards the collected weights.
*   **Backward Pass:** Runs an **AllGather** step to collect weights, calculates gradients, releases weight memory, and runs a **ReduceScatter** step to sync and partition the gradients.

---

## 2. Auto-Wrapping Policies

To prevent all model layers from gathering at once (which would exhaust memory), you must configure an auto-wrapping policy. This groups layers (typically individual Transformer blocks) so that memory is allocated and released incrementally:

```python
from torch.distributed.fsdp import FullyShardedDataParallel as FSDP
from torch.distributed.fsdp.wrap import transformer_auto_wrap_policy
from transformers.models.llama.modeling_llama import LlamaDecoderLayer

# Configure the wrap policy specifically for LLaMA decoder layers
my_auto_wrap_policy = functools.partial(
    transformer_auto_wrap_policy,
    transformer_layer_cls={LlamaDecoderLayer}
)

# Wrap the model in FSDP
model = FSDP(
    raw_model,
    auto_wrap_policy=my_auto_wrap_policy,
    device_id=torch.cuda.current_device()
)
```
