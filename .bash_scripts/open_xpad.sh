pid=$(pidof xpad)
if [ -z "$pid" ]
then xpad
else pkill xpad
fi
