#! /usr/bin/env bash

# https://www.intel.com/content/www/us/en/docs/oneapi/optimization-guide-gpu/2023-1/configuring-gpu-device.html

if [[ "$#" == 0 ]]; then
    f=$(cat /sys/class/drm/card1/gt/gt0/rps_RP0_freq_mhz)
else
    f=$1
fi

echo $f > /sys/class/drm/card1/gt/gt0/rps_max_freq_mhz
