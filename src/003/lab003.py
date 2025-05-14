"""
Low clockrate

Problem: GPU frequency is low, leading to poor performance.

Prevalence:                     0/5
Estimated Visibility w/ iaprof: low
    Reason: iaprof does not not know GPU clock rate or other global metrics.

Benchmark Example: A script that repeats an operation on the GPU. Slower when
frequency is set to 200 MHz.
"""

import torch

device = torch.device("xpu")

x = torch.randn(8000, 8000)

def compute_on_device(tensor):
    return tensor ** 2 + tensor

for i in range(1000):
    compute_on_device(x.to(device))

torch.xpu.synchronize()
