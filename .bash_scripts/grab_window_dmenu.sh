unfocused=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==false).name' | cut -d '"' -f 2)
focused=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')
workspace=$(echo "$unfocused" | dmenu)
i3-msg [workspace=$workspace] move workspace $focused
