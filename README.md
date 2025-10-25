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
    - Sidebery:
        - Should be on the right side, vertical
        - Tabs preview on
        - Disable history and bookmarks (navigation bar -> history sub panel, bookmarks sub panel)
        - Unbind ctrl+space (open new tab??)
    - Make sure to do this for both firefox profiles...
Log into vesktop -> plugins NotificationVolume -> restart
Configure waybar depending on screens
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

Set up Homelab (Wi-Fi AP + AdGuard + Samba NAS + Mullvad VPN):

    # 0. Configure network interfaces for your hardware:
    # Check your available interfaces: ip link show
    # Edit modules/homelab.nix and set:
    #   apInterface = "your_wifi_interface";    # e.g., "wlo1", "wlp3s0", "wlan0"
    #   wanInterface = "your_wan_interface";    # e.g., "enp4s0", "eth0", "wlo2"
    #
    # Hardware scenarios:
    #   • Ethernet + WiFi: wanInterface="enp4s0", apInterface="wlo1"
    #   • Dual WiFi adapters: wanInterface="wlo1", apInterface="wlo2"
    #   • USB WiFi dongle: wanInterface="enp4s0", apInterface="wlx001122334455"
    #
    # IMPORTANT: apInterface will be disconnected from current networks!

    # 1. Set AdGuard admin password:
    mkpasswd -m bcrypt 'your_password' | sudo tee /tmp/adguard_hash
    sudo vi modules/homelab.nix -> replace the bcrypt hash in adguard settings with output from above

    # 2. Configure Mullvad VPN:
    # Get WireGuard config from https://mullvad.net/en/account/wireguard-config
    # Login with your account and generate a config file, download and extract it
    # Extract PrivateKey, PublicKey, Endpoint, and Address from the config
    # Create private key file:
        sudo mkdir -p /etc/wireguard
        sudo echo "YOUR_PRIVATE_KEY_FROM_MULLVAD_CONFIG" > /etc/wireguard/mullvad-private.key
        sudo chmod 600 /etc/wireguard/mullvad-private.key
    # Update modules/homelab.nix with these values:
      - ips: use Address values (IPv4, IPv6 & Port)
      - publicKey: use server's PublicKey
      - endpoint: use server's Endpoint
      - IMPORTANT: Also update the routing IPs in postSetup/preShutdown scripts to match your endpoint IP

    # 4. Set up Samba user (for private share access):
    sudo smbpasswd -a liam-w

    # 5. Change Wi-Fi AP password:
    sudo vi modules/homelab.nix -> change "changeme123" in wifi settings to your desired password

    # Access points:
    # - AdGuard web interface: http://localhost:3000 (admin/your_password)
    # - Samba shares: \\192.168.4.1\public, \\192.168.4.1\private, \\192.168.4.1\media
    # - Also works with local / nas.local / homelab.local
    # - Wi-Fi network: "liam-w"
