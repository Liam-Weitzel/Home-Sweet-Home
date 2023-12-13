focus=$(i3-msg -t get_tree | grep -oP '(?<='\"focused\":true,').*?(?=})');
windowWidth=$(echo "$focus" | grep -oP '(?<='\"width\":').*?(?=,)');
windowHeight=$(echo "$focus" | grep -oP '(?<='\"height\":').*');


maxWidth=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/' | sed -E  's/(.*)x{1}(.*)/\1/');
maxHeight=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/' | sed -E  's/(.*)x{1}(.*)/\2/');

if [ $windowWidth -gt $(( $maxWidth*90/100 )) ] && [ $windowHeight -gt $(( $maxHeight*90/100 )) ]; 
then i3-msg floating disable;
else i3-msg border pixel 7;
	i3-msg floating enable;
	i3-msg resize set $(echo "$maxWidth") $(echo "$maxHeight");
	i3-msg move position 0 0;
	i3-msg border pixel 1;
fi

