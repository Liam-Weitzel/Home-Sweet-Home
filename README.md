# Home Sweet Home

My personal NixOS configuration with dotfiles, homelab setup, and application configurations.

## Initial Setup

### Prerequisites
1. Install NixOS on your PC and boot into it
2. Configure basic system:
   ```bash
   sudo nano /etc/nixos/configuration.nix
   ```
3. Enable flakes and install essential tools (git, vim)

### Installation Steps

1. **Clone the repository**:
   ```bash
   cd ~
   git clone https://github.com/Liam-Weitzel/Home-Sweet-Home.git
   cd Home-Sweet-Home
   ```

2. **Move hardware configuration**:
   ```bash
   sudo mv /etc/nixos/hardware-configuration.nix ./
   ```

3. **Initial build** (comment out citrix temporarily):
   ```bash
   sudo nixos-rebuild switch --flake .#liam-w
   ```

4. **Deploy dotfiles**:
   ```bash
   stow dotfiles-desktop dotfiles-server
   ```

5. **Restart and finalize**:
   ```bash
   sudo reboot
   # After restart, uncomment citrix and rebuild
   sudo nixos-rebuild switch --flake .#liam-w
   ```

## Application Configuration

### Firefox Setup

Create two Firefox profiles: `ssb` and `default`

#### General Settings (both profiles)
- Open previous windows and tabs
- Configure Passwords extension:
  - Preferences → Notifications: OFF
  - Auto fill: OFF
  - Close popup after pasting credentials: OFF

#### Extensions to Configure
- Floccus (bookmark sync)
- Nextcloud Passwords
- OTP Manager
- GitHub extension

#### Link Hints Shortcuts
| Action | Shortcut |
|--------|----------|
| Click | `Ctrl + E` |
| Open in new tab | `Ctrl + I` |
| Open in new tab & switch | `Ctrl + O` |
| Click many | `Ctrl + Shift + E` |
| Open many tabs | `Ctrl + Shift + I` |
| Select element | `Ctrl + Shift + L` |
| Swap selection end | `Ctrl + Shift + O` |

#### Sidebery Configuration
- Position: Right side, vertical
- Tabs preview: ON
- Disable: History and bookmarks panels
- Unbind: `Ctrl + Space`

> Note: Get SSB hash from a random website and update `.bash_scripts/view_in_firefox.sh`

### Media & Communication
- **Vesktop**: Install NotificationVolume plugin → restart
- **Waybar**: Configure based on screen setup
- **Nextcloud**: Login and choose sync folders
- **ncspot**: Login to Spotify
- **nchat**: Configure chat clients
- **Citrix**: Enterprise login

### Additional Tools
- **Trackpad-Color-Picker**: Follow its README.md
- **Email**: Configure in Firefox
- **GitHub**: Login and setup

## Email Setup (Neomutt)

1. **Generate GPG key**:
   ```bash
   gpg --full-gen-key
   ```

2. **Initialize pass**:
   ```bash
   pass init liam.weitzel@gmail.com
   ```

3. **Create app password**:
   - Visit: https://myaccount.google.com/apppasswords

4. **Configure mutt-wizard**:
   ```bash
   mw -a liam.weitzel@gmail.com -i imap.gmail.com -I 993
   ```

## Calendar Setup (Calcure)

1. **Copy config template**:
   ```bash
   cp ~/.config/vdirsyncer/config.example ~/.config/vdirsyncer/config
   ```

2. **Configure with app password**:
   ```bash
   vi ~/.config/vdirsyncer/config  # Replace REDACTED with nextcloud app password
   ```

3. **Initialize sync**:
   ```bash
   vdirsyncer discover events_personal
   vdirsyncer sync
   ```

## Nextcloud Deck Setup (tui-deck)

1. **Copy config template**:
   ```bash
   cp ~/.config/tui-deck/config_EXAMPLE.json ~/.config/tui-deck/config.json
   ```

2. **Configure with credentials**:
   ```bash
   vi ~/.config/tui-deck/config.json  # Replace REDACTED with nextcloud app password
   ```

## Homelab Setup

Complete Wi-Fi AP + AdGuard DNS + Samba NAS + Mullvad VPN setup.

### Step 1: Configure Variables

Edit the `let` block in `modules/homelab.nix` with your hardware-specific values:

#### Hardware Configuration
```bash
# Check available interfaces first
ip link show
```

```nix
# Hardware interfaces
apInterface = "wlo1";        # WiFi for Access Point
wanInterface = "enp4s0";     # Internet connection

# Common scenarios:
# • Ethernet + WiFi: wanInterface="enp4s0", apInterface="wlo1"
# • Dual WiFi: wanInterface="wlo1", apInterface="wlo2"
# • USB WiFi dongle: wanInterface="enp4s0", apInterface="wlx001122334455"
```

> **Warning**: `apInterface` will be disconnected from current networks!

#### Network Configuration
```nix
apGateway = "192.168.4.1";           # Gateway IP for AP clients
apNetwork = "192.168.4.0/24";        # Network range for AP
apNetworkPrefix = "192.168.4.";      # First 3 octets for Samba access
dhcpRangeStart = "192.168.4.10";     # DHCP pool start
dhcpRangeEnd = "192.168.4.100";      # DHCP pool end
dhcpLeaseDuration = 43200;           # DHCP lease time (12 hours)
```

#### Wi-Fi AP Configuration
```nix
wifiSSID = "liam-w";                 # Network name
wifiPassword = "your-secure-password"; # WiFi password
wifiCountryCode = "PL";              # Your country code
wifiChannel = 6;                     # WiFi channel (1-11 for 2.4GHz)
```

#### AdGuard Configuration
```nix
adguardUsername = "admin";           # Admin username
adguardPasswordHash = "...";         # Generated hash (see step 2)
```

#### Samba NAS Configuration
```nix
sambaWorkgroup = "WORKGROUP";        # Windows workgroup
sambaServerName = "liam-w NAS";      # Server description
sambaNetbiosName = "liam-w-nas";     # NetBIOS name
sambaUser = "liam-w";                # Primary user
sambaGroup = "users";                # Primary group
```

### Step 2: Generate AdGuard Password

```bash
mkpasswd -m bcrypt 'your_admin_password'
# Copy output to adguardPasswordHash variable
# Put the same password in /dotfiles-desktop/.local/share/applications/adguard.desktop
# Put the same password in /dotfiles-desktop/.config/waybar/config
```

### Step 3: Configure Mullvad VPN

1. **Get WireGuard config**:
   - Visit: https://mullvad.net/en/account/wireguard-config
   - Download and extract your config file

2. **Update variables** from your config:
   ```nix
   mullvadIPs = [ "10.x.x.x/32" "fc00::x/128" ];  # From Address field
   mullvadListenPort = 51820;                      # Usually 51820
   mullvadEndpointIP = "xxx.xxx.xxx.xxx";          # From Endpoint (IP only)
   mullvadPublicKey = "base64_public_key";         # From PublicKey
   mullvadAllowedIPs = [ "0.0.0.0/0" "::/0" ];    # Route all traffic
   ```

3. **Create private key file**:
   ```bash
   sudo mkdir -p /etc/wireguard
   sudo echo "YOUR_PRIVATE_KEY_FROM_CONFIG" > /etc/wireguard/mullvad-private.key
   sudo chmod 600 /etc/wireguard/mullvad-private.key
   ```

### Step 4: Setup Samba User

```bash
sudo smbpasswd -a liam-w
```

### Step 5: Apply Configuration

```bash
nixsw
```

## Access Points

Once setup is complete, access your services:

| Service | URL | Credentials |
|---------|-----|-------------|
| **AdGuard Web Interface** | http://192.168.4.1:3000 | admin / your-password |
| **Samba Shares** | `\\192.168.4.1\public`<br>`\\192.168.4.1\private`<br>`\\192.168.4.1\media` | liam-w / samba-password |
| **Alternative Access** | `\\local` `\\nas.local` `\\homelab.local` | Same credentials |
| **Wi-Fi Network** | SSID: `liam-w` | Your WiFi password |

## Notes

- All traffic routes through Mullvad VPN (kill switch enabled)
- AdGuard provides DNS filtering and DHCP
- Samba shares: public (guest), private (auth), media (auth), homes (auth)
- Host system benefits from all homelab services

## Known Issues

- If homelab module is active on startup, no internet connection possible
- You need to nixsw with the homelab commented out, then turn it back on again
