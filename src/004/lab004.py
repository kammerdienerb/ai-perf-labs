"""
Excessive Casting

Problem: Model layers may require different data types and conversion between
         types introduces slowdown.

Prevalence:                     2/5
Estimated Visibility w/ iaprof: high

Benchmark Example: A model with data type conversions between each layer.
"""

import torch

x = torch.randn(1000, 1000, dtype=torch.float32).to("xpu")

# Simulate layers with constant dtype conversions
def model_with_casting(x):
    x = x.to(torch.float16)   # Layer 1 wants float16
    x = torch.relu(x)         # Operation in float16
    x = x.to(torch.float32)   # Layer 2 wants float32
    x = x @ x.T               # Operation in float32
    x = x.to(torch.bfloat16)  # Layer 3 wants bfloat16
    return x

for i in range(0, 100000):
    x = model_with_casting(x)
torch.xpu.synchronize()
