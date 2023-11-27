#!/bin/bash

clear;

echo "
  ##     ##  ######  ########     ##     ## ########  
  ##     ## ##    ## ##     ##    ##     ## ##     ## 
  ##     ## ##       ##     ##    ##     ## ##     ## 
  ##     ##  ######  ########     ##     ## ########  
  ##     ##       ## ##     ##    ##     ## ##        
  ##     ## ##    ## ##     ##    ##     ## ##        
   #######   ######  ########      #######  ##        "

echo;
lsusb | grep -oP '(ID .*)';
echo;

read -p "Enter ID of device: " deviceID;
echo;
read -p "Enter check delay in seconds: " updateDelay;

clear;

connectedcounter="0"
disconnectedcounter="0"

while true;
	do
	raw=$(lsusb | grep -o "$deviceID");

	if [ "$raw" = "$deviceID" ];
		then
		connectedcounter=$((connectedcounter+1));
	else
		disconnectedcounter=$((disconnectedcounter + 1));
	fi

	echo;
	echo Connected: $connectedcounter;
	echo Disconnected: $disconnectedcounter;
	total=$((connectedcounter+disconnectedcounter));
	echo Total: $total;
	echo ;
	echo Connected: $(((connectedcounter*100)/(total)))%;
	echo Disconnected: $(((disconnectedcounter*100)/(total)))%;

	sleep $updateDelay;
	clear
	done;