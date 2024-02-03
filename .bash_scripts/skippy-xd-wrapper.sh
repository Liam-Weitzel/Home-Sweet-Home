#!/usr/bin/env bash

pid=$(pidof skippy-xd)
if [ -z "$pid" ]
then 
  focused=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')
  maxWidth=$(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect["width"]');
  maxHeight=$(i3-msg -t get_workspaces | jq -r 'map(select(.focused))[0].rect["height"]');

  i3-msg [workspace="20"] floating enable
  i3-msg [workspace="20"] border pixel 7;
  i3-msg [workspace="20"] resize set $(echo "$maxWidth") $(echo "$maxHeight");
  i3-msg [workspace="20"] move position 0 0;
  i3-msg [workspace="20"] border pixel 2;
 
  i3-msg workspace number 20
  skippy-xd

  if [ $? == 0 ]; then
    i3-msg move container to workspace $focused
  fi  

  i3-msg workspace number $focused
else pkill skippy-xd
fi
