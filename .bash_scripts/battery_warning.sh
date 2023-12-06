#!/bin/bash

while :
do
	STATE=$(acpi -b | grep "Battery 1" | grep -o "Discharging")
	POWER=$(acpi -b | grep "Battery 1" | grep -o '[0-9]\+%' | tr -d '%')
	if [[ $POWER -le 20 ]] && [[ $STATE = "Discharging" ]]; then
		notify-send "Battery power is lower than 15%!"
	fi
sleep 30
done
