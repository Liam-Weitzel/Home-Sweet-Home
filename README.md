1. Install nixos on pc & boot into it
2. sudo nano /etc/nixos/configuration.nix
3. get git, vim, and enable flakes
4. go to home dir
5. git clone https://github.com/Liam-Weitzel/Home-Sweet-Home.git
6. sudo mv /etc/nixos/hardware-configuration.nix ./
7. comment out citrix... will install after
8. sudo nixos-rebuild switch --flake .#liam-w
9. stow dotfiles-desktop & server
10. restart
11. uncomment citrx & nixsw

Create a new firefox profile called ssb & one called default
    - Open previous windows and tabs
    - Passwords for nextcloud extension -> preferences -> notifications off -> auto fill off -> close popup after pasting credentials off
    - Log into floccus, nc passwords, otp manager, github extension
    - Copy a random website ssb to get the hash and put that in .bash_scripts/view_in_firefox.sh
    - Link hints:
        - Click = ctrl + e
        - Open link in new tab = ctrl + i
        - Open link in new tab and switch to it = ctrl + o
        - Click many = ctrl + shift + e
        - Open many tabs = ctrl + shift + i
        - Select element = ctrl + shift + l
        - Swap which end of a text selection to work on = ctrl + shift + o
    - make sure to do this for btoh firefox profiles...
Log into vesktop -> plugins NotificationVolume -> restart
Log into nextcloud -> choose what to sync
Log into ncspot
Log into nchat
Log into citrix
Log into emails on firefox
Log into github
Set up Trackpad-Color-Picker (read the readme.md)
Set up neomutt
    gpg --full-gen-key
    pass init liam.weitzel@gmail.com
    Create app passwords at: https://myaccount.google.com/apppasswords
    mw -a liam.weitzel@gmail.com -i imap.gmail.com -I 993
Set up calcure:
    cp ~/.config/vdirsyncer/config.example ~/.config/vdirsyncer/config
    vi ~/.config/vdirsyncer/config -> replace REDACTED with app password
    vdirsyncer discover events_personal
    vdirsyncer sync
Set up tui-deck:
    cp ~/.config/tui-deck/config_EXAMPLE.json ~/.config/tui-deck/config.json
    vi ~/.config/tui-deck/config.json -> replace REDACTED with app password
