#!/usr/bin/env bash

TOOL_PREFIX="/home/ubuntu/intc/iaprof_scripts/tools/prefix"

export PATH="${TOOL_PREFIX}/gcc-14/bin:$PATH"
export PATH="${TOOL_PREFIX}/python_fp/bin:$PATH"
export PATH="${TOOL_PREFIX}/intel_graphics_stack_fp/bin:$PATH"
export PATH="${TOOL_PREFIX}/sycl_abi_8/bin:$PATH"
export PATH="${TOOL_PREFIX}/sycl_bin/bin:$PATH"

source ${TOOL_PREFIX}/sycl_bin/setvars.sh --force
export LD_LIBRARY_PATH="${TOOL_PREFIX}/gcc-14/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/sycl_abi_8/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/sycl_bin/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/onednn/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/usr/lib/libc6-prof/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

for lab in src/*; do
    if ! [ -f $lab/build.sh ]; then
        continue
    fi
    which clang++
    $lab/build.sh || exit $?
done
