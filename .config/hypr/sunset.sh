#!/bin/sh

killall -q hyprsunset
current_hour=$(date +%H)

if [ $current_hour -ge 19 ] || [ $current_hour -le 7 ]; then
  hyprsunset -t 3000
else
  hyprsunset -t 6000
fi
