#!/usr/bin/env bash

TOOL_PREFIX="/home/ubuntu/intc/iaprof_scripts/tools/prefix"

export PATH="${TOOL_PREFIX}/gcc-14/bin:$PATH"
export PATH="${TOOL_PREFIX}/python_fp/bin:$PATH"
export PATH="${TOOL_PREFIX}/intel_graphics_stack_fp/bin:$PATH"
export PATH="${TOOL_PREFIX}/sycl_abi_8/bin:$PATH"
export PATH="${TOOL_PREFIX}/sycl_bin/bin:$PATH"

# Set up the runtime environment
source ${TOOL_PREFIX}/sycl_bin/setvars.sh --force
export LD_LIBRARY_PATH="${TOOL_PREFIX}/gcc-14/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/sycl_abi_8/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/sycl_bin/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/onednn/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/usr/lib/libc6-prof/x86_64-linux-gnu:${LD_LIBRARY_PATH}"

# Intel NEO/L0
export LD_LIBRARY_PATH="${TOOL_PREFIX}/intel_graphics_stack_fp/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/intel_graphics_stack_fp/lib/intel-opencl:${LD_LIBRARY_PATH}"
export OCL_ICD_FILENAMES="${TOOL_PREFIX}/intel_graphics_stack_fp/lib/intel-opencl/libigdrcl.so:${OCL_ICD_FILENAMES}"
export OCL_ICD_VENDORS="${TOOL_PREFIX}/intel_graphics_stack_fp/etc/OpenCL/vendors/"

source /opt/intel/oneapi/pti/latest/env/vars.sh

# Set up the Python env
rm -rf env
python3 -m venv env
source env/bin/activate
pip3 install --upgrade pip

rm -rf intel-xpu-backend-for-triton
git clone https://github.com/intel/intel-xpu-backend-for-triton.git
pushd intel-xpu-backend-for-triton
git checkout 488874d1410886da115f22a864555190475e2442 || exit $?
git apply ../xpu_triton.patch || exit $?
export CFLAGS="-Wno-error=maybe-uninitialized -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer"
scripts/install-pytorch.sh --source || exit $?
scripts/compile-triton.sh || exit $?
popd

pip3 install --force-reinstall intel-xpu-backend-for-triton/.scripts_cache/pytorch/dist/torch*.whl
pip3 install transformers
pip3 install sentencepiece
pip3 install protobuf

deactivate
