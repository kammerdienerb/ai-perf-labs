#!/usr/bin/env bash

export LABS_ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $LABS_ROOT

if [[ $# != 1 ]]; then
    echo "usage: $0 WHICH_LAB"
    exit 1
fi

WHICH_LAB="$1"

if ! [ -f "src/${WHICH_LAB}/run.sh" ]; then
    echo "no lab found (src/${WHICH_LAB}/run.sh)"
    exit 1
fi

RUN_IAPROF="yes"

TOOL_PREFIX="/home/ubuntu/intc/iaprof_scripts/tools/prefix"

export PATH="${TOOL_PREFIX}/python_fp/bin:$PATH"

# Set up the runtime environment
source ${TOOL_PREFIX}/sycl_bin/setvars.sh --force
export LD_LIBRARY_PATH="${TOOL_PREFIX}/sycl_bin/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/gcc-14/lib64:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/sycl_abi_8/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/onednn/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="/usr/lib/libc6-prof/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/libffi/lib:${LD_LIBRARY_PATH}"

# Intel NEO/L0
export LD_LIBRARY_PATH="${TOOL_PREFIX}/intel_graphics_stack_fp/lib:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH="${TOOL_PREFIX}/intel_graphics_stack_fp/lib/intel-opencl:${LD_LIBRARY_PATH}"
export OCL_ICD_FILENAMES="${TOOL_PREFIX}/intel_graphics_stack_fp/lib/intel-opencl/libigdrcl.so:${OCL_ICD_FILENAMES}"
export OCL_ICD_VENDORS="${TOOL_PREFIX}/intel_graphics_stack_fp/etc/OpenCL/vendors/"
export ZE_ENABLE_LOADER_DEBUG_TRACE=1

export PYTHONPERFSUPPORT=1

source /opt/intel/oneapi/pti/latest/env/vars.sh

source env/bin/activate || exit $?

# Reset GPU frequency
sudo ./set_freq.sh

# Start the profiler
if [[ "${RUN_IAPROF}" == "yes" ]]; then
    for f in /sys/class/drm/card*/prelim_enable_eu_debug
        do echo 1 | sudo tee "$f"
    done
    export ZET_ENABLE_PROGRAM_DEBUGGING=1
    export NEOReadDebugKeys=1
    export ONEDNN_JIT_PROFILE=6
    sudo sysctl kernel.perf_event_max_stack=512

    OUT_PROF="$(basename ${WHICH_LAB}).profile"
    OUT_STACK="$(basename ${WHICH_LAB}).stackcollapse"

    sudo cat /sys/kernel/debug/tracing/trace_pipe &> /dev/null &
    TRACE_PIPE_PID=$!
    sudo kill $TRACE_PIPE_PID
    wait $TRACE_PIPE_PID

    sudo cat /sys/kernel/tracing/trace_pipe > trace_pipe.txt &
    TRACE_PIPE_PID=$!

    sudo ${TOOL_PREFIX}/bin/iaprof record -b -d 2>profile.err 1> ${OUT_PROF} &
    PROF_PID=$!
    sleep 60

    stty sane
fi

# Run the lab
src/${WHICH_LAB}/run.sh

# Profiler teardown
if [[ "${RUN_IAPROF}" == "yes" ]]; then
    sudo kill -TERM ${TRACE_PIPE_PID}
    wait ${TRACE_PIPE_PID}
    sudo kill -INT ${PROF_PID}
    wait ${PROF_PID}

    ${TOOL_PREFIX}/bin/iaprof flame < ${OUT_PROF} > ${OUT_STACK}

    SEDSTR='s/_Py[^;]*;//g'
    SEDSTR+=';s/Py(Object|Eval|Number)_[^;]*;//g'
    SEDSTR+=';s/run_mod;//g'
    SEDSTR+=';s/run_eval_code_obj;//g'
    SEDSTR+=';s/cfunction_call;//g'
    SEDSTR+=';s/slot_nb_[^;]*;//g'
    SEDSTR+=';s/slot_tp_[^;]*;//g'
    SEDSTR+=';s/binary_op1;//g'
    SEDSTR+=';s/ternary_op;//g'
    SEDSTR+=';s/(method_)?vectorcall[^;]*;//g'

    sed -i -E "${SEDSTR}" ${OUT_STACK}
fi

stty sane
