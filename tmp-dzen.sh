#!/bin/bash

while true; do
    tail -f /sys/class/power_supply/BAT0/capacity
    sleep 1
done | dzen2 -fn 'PixelCarnageMonoTT-9'
