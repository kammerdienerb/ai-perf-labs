#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sudo ${LABS_ROOT}/set_freq.sh 200

python3 ${DIR}/lab003.py

sudo ${LABS_ROOT}/set_freq.sh
