focus=$(i3-msg -t get_tree | grep -oP '(?<='\"focused\":true,').*?(?=})');
windowWidth=$(echo "$focus" | grep -oP '(?<='\"width\":').*?(?=,)');
windowHeight=$(echo "$focus" | grep -oP '(?<='\"height\":').*');


maxWidth=$(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect["width"]');
maxHeight=$(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect["height"]');

if [ $windowWidth -gt $(( $maxWidth*90/100 )) ] && [ $windowHeight -gt $(( $maxHeight*90/100 )) ]; 
then i3-msg floating disable;
else i3-msg border pixel 7;
	i3-msg floating enable;
	i3-msg resize set $(echo "$maxWidth") $(echo "$maxHeight");
	i3-msg move position 0 0;
	i3-msg border pixel 1;
fi

