pid=$(pidof feh)
if [ -z "$pid" ]
then feh ~/layout/layer$1.png &
fi
