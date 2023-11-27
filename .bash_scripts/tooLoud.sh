#!/bin/bash

while true; do
	arecord -d 1 -f U8 tooLoud.wav

	raw=$(sox tooLoud.wav -n stat 2>&1 | sed -n 's#^Maximum amplitude:[^0-9]*\([0-9.]*\)$#\1#p');
	trunc=${raw//0./};
	echo $trunc;
	if [[ "$trunc" -ge "900000" ]] ; then
		play tooLoud.wav;
	fi
done