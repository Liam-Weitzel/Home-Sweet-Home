#!/bin/sh

focused=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')

i3-msg "$(i3-msg -t get_tree | jq -r --arg trg "$1" '
.nodes[1:][].nodes[1].nodes | map( 
  select(.num? == ($trg|tonumber) and (..|.focused?))) |
if isempty(.[]) then "workspace number \($trg)" else
  [..|select(.type? == "con" and .window_type?)]
  | .[(paths(.focused?)[0]+1) % (.|length)]
  | "[con_id=\(.id)] focus"
end
')"

i3-msg move container to workspace $focused
i3-msg workspace number $focused
