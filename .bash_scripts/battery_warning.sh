#!/bin/bash

while :
do
	STATE=$(cat /sys/class/power_supply/BAT0/status)
	POWER=$(cat /sys/class/power_supply/BAT0/capacity)
	if [[ $POWER -le 15 ]] && [[ $STATE = "Discharging" ]]; then
		notify-send "Battery power is lower than 15%!"
	fi
sleep 30
done
