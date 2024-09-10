focus=$(i3-msg -t get_tree | grep -oP '(?<='\"focused\":true,').*?(?=})');

output=$(echo "$focus" | cut -d'"' -f4);
windowWidth=$(echo "$focus" | grep -oP '(?<='\"width\":').*?(?=,)');
windowHeight=$(echo "$focus" | grep -oP '(?<='\"height\":').*');

maxWidth=$(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect["width"]');
maxHeight=$(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect["height"]');

xrandrOutput=$(xrandr | grep $(echo "$output"));
if [[ $xrandrOutput =~ "primary" ]]; then
	xrandrRes=$(echo "$xrandrOutput" | cut -d" " -f4);
else
	xrandrRes=$(echo "$xrandrOutput" | cut -d" " -f3); 
fi

leftOffSet=$(echo "$xrandrRes" | cut -d"+" -f2);
topOffSet=$(echo "$xrandrRes" | cut -d"+" -f3);

if [ $windowWidth -gt $(( $maxWidth*90/100 )) ] && [ $windowHeight -gt $(( $maxHeight*90/100 )) ]; 
then i3-msg floating disable;
else i3-msg border pixel 7;
	i3-msg floating enable;
	i3-msg resize set $(echo "$maxWidth") $(echo "$maxHeight");
	i3-msg move position $(echo "$leftOffSet") $(echo "$topOffSet");
	i3-msg border pixel 2;
fi
