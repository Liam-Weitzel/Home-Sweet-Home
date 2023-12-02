focused=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')
i3-msg [workspace=$1] move workspace $focused
