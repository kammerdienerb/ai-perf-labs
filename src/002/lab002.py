"""
Inefficient Model Architecture (Kernel Launch Overhead)

Problem: Using many small, inefficient operations instead of fused, larger
kernels results in overhead due to frequent kernel launches.

Prevalence:                     2/5
Estimated Visibility w/ iaprof: high

Benchmark Example: Demonstrate this with kernel fusion via compilation so that more complex
kernel graphs will be compiled into one with something like triton. This
example will be something that is visible in the profiler as you can directly
see the launched kernels and notice if some have been fused. The performance
impact of this, however, may not be easily ascertained from a flame graph.

Eventually we want:
Benchmark Example: A neural network with many small element-wise operations
(e.g., repeated relu or sigmoid activations) on large tensors, instead of a
single fused operation.
"""

import torch

N = 8000
x = torch.randn(N, N).to("xpu")

# @torch.compile
def f(x):
    a = torch.sin(x)
    b = torch.cos(x)
    return a + b

for i in range(1000):
    y = f(x)

torch.xpu.synchronize()
