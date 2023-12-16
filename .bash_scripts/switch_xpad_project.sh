pkill xpad
sleep 0.5
curr_project="$(ls ~/.config/xpad/ | grep curr_)"
rm ~/.config/xpad/$curr_project/*
cp ~/.config/xpad/* ~/.config/xpad/$curr_project/
old_project="$(ls ~/.config/xpad/ | grep curr_ | cut -c6-)"
mv ~/.config/xpad/$curr_project ~/.config/xpad/$old_project

rm ~/.config/xpad/*
cp -r ~/.config/xpad/project$1/. ~/.config/xpad/
mv ~/.config/xpad/project$1 ~/.config/xpad/curr_project$1
