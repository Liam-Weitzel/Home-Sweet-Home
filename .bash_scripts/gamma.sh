#!/bin/bash

echo "press P to toggle gamma"

trap '' INT
while : ; do
read -n 1 k <&1
if [[ $k = p ]] ; then
redshift -g 2.5
fi
done
