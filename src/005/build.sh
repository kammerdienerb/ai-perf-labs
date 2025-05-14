#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

clang++ -o lab005 -fsycl -g -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer lab005.cpp
