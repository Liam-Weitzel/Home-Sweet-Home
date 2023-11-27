#!/bin/bash

clear;

echo " ########  ########  ##     ##                  
 ##     ## ##     ## ###   ###                  
 ##     ## ##     ## #### ####                  
 ##     ## ########  ## ### ##                  
 ##     ## ##     ## ##     ##                  
 ##     ## ##     ## ##     ##                  
 ########  ########  ##     ##                  
                                                 
                                               
 ##     ## ######## ######## ######## ########  
 ###   ### ##          ##    ##       ##     ## 
 #### #### ##          ##    ##       ##     ## 
 ## ### ## ######      ##    ######   ########  
 ##     ## ##          ##    ##       ##   ##   
 ##     ## ##          ##    ##       ##    ##  
 ##     ## ########    ##    ######## ##     ## ";

echo;
echo List of available network interfaces to use:;
echo;

minsumarr=( )
itermin="0"
prevlow="999"
prevhigh="0"
iterarr="0"
prevlowmin="999"
prevlowminindex="0"
prevhighmin="0"
prevhighminindex="0"

raw=$(ip link show | grep -oP '(: .*: <)');
trunc1=${raw//: /};
trunc2=${trunc1//</};

networkarr=($trunc2);

loopcounter="0";
for i in ${networkarr[@]}; 
	do
		loopcounter=$((loopcounter+1));
	 	echo "     $loopcounter: $i";
	done

echo;

read -p "Select network interface to use by number: " networkinterfaceint;
networkinterface=${networkarr[$networkinterfaceint-1]};

clear;

while true; 
	do
	itertotal=$((itertotal + 1));

	if [ "$itermin" -le "59" ];
		then
		itermin=$((itermin+1));
	fi

	currdBm=$(iwconfig $networkinterface | grep -oP '(?<=Signal level=-)[0-9]+'); 

	if [ "$currdBm" -lt "$prevlow" ];
		then
		prevlow=$((currdBm));
	fi

	if [ "$currdBm" -gt "$prevhigh" ];
		then
		prevhigh=$((currdBm));
	fi


	if [ "$iterarr" -le "59" ];
		then
		iterarr=$((iterarr+1));
	else
		iterarr=0
	fi

	minsumarr[$iterarr]=$currdBm;

	minsum=0
	for i in ${!minsumarr[@]}; 
		do
		if [ "${minsumarr[$prevhighminindex]}" = "$prevhighmin" ]
			then
			prevhighmin=$((prevhighmin));
		else
			prevhighmin=0
		fi

		if [ "${minsumarr[$prevlowminindex]}" = "$prevlowmin" ]
			then
			prevlowmin=$((prevlowmin));
		else
			prevlowmin=999
		fi

		if [ "${minsumarr[$i]}" -gt "$prevhighmin" ];
			then
			prevhighmin=${minsumarr[$i]};
			prevhighminindex=$i;
		fi
		if [ "${minsumarr[$i]}" -lt "$prevlowmin" ];
			then
			prevlowmin=${minsumarr[$i]};
			prevlowminindex=$i;
		fi
	 	minsum=$((${minsumarr[$i]} + minsum));
	done

	minavg=$((minsum/itermin));

	totalsum=$((totalsum+currdBm)); 
	totalavg=$((totalsum/itertotal)); 

	echo;
	echo Network interface: $networkinterface;
	echo;
	echo Curr dBm: -$currdBm;
	echo;
	echo -------Since start-------;
	echo Avg dBm: -$totalavg;
	echo Lowest dBm: -$prevlow;
	echo Highest dBm: -$prevhigh;
	echo;
	echo -------Last minute-------;
	echo Avg dBm: -$minavg;
	echo Lowest dBm: -$prevlowmin;
	echo Highest dBm: -$prevhighmin;

	sleep 1;
	clear;
	done;
