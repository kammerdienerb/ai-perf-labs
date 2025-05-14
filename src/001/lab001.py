"""
Excessive Memory Copy Operations

Problem: Frequent transfers between host (CPU) and device (GPU) memory reduce
performance, especially in hybrid setups where parts of the model run on CPU.

Prevalence:                     3/5
Estimated Visibility w/ iaprof: low
    Reason: Memory copies host <-> accelerator do not cause EU stalls.

Benchmark Example: A script that repeats an operation on the GPU, copying input
data each time.
"""

import torch

device = torch.device("xpu")

data_cpu = torch.randn(8000, 8000)

def compute_on_device(tensor):
    return tensor ** 2 + tensor

for i in range(1000):
    data_xpu   = data_cpu.to(device, copy=True)
    result_xpu = compute_on_device(data_xpu)
    result_cpu = result_xpu.to("cpu")

torch.xpu.synchronize()
