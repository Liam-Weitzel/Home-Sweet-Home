#!/run/current-system/sw/bin/bash
echo "Enter hostname or IP address to trace:"
read -r target
if [ -z "$target" ]; then
    echo "No target specified!"
    read -p "Press Enter to exit..."
    exit 1
fi
echo "Tracing route to: $target"
sudo trip "$target" --geoip-mmdb-file ~/GeoLite2-City.mmdb
