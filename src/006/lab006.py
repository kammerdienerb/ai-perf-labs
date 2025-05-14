"""
Low Execution Unit Occupancy

Problem: Work being performed doesn't optimally use GPU resources, likely due to
limited parallelization and batch sizing.

Prevalence:                     3/5
Estimated Visibility w/ iaprof: low

Benchmark Example: An operation split into many small batches. When the batch size
is too small, the GPU is not well utilized.
"""

import torch

device = torch.device("xpu")

TOTAL_WORK = 1000000
BATCH_SIZE = TOTAL_WORK // 100000

x = torch.randn(BATCH_SIZE, BATCH_SIZE).to("xpu")

for i in range(TOTAL_WORK // BATCH_SIZE):
    y = x @ x

torch.xpu.synchronize()
