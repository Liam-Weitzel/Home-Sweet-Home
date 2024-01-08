output=$(xrandr | grep " connected" | awk '{ print$1 }' | dmenu -p "Move workspace to output: ")

echo $output

i3-msg move workspace to output $output
