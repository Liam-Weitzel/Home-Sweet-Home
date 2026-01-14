{ config, pkgs, lib, ... }:

# Complete homelab setup with Wi-Fi AP, AdGuard DNS/DHCP, Samba NAS, and Mullvad VPN
# This creates a local network accessible via Wi-Fi that provides:
# - Internet access through Mullvad VPN for privacy
# - AdGuard DNS filtering and DHCP management
# - Samba file shares (public, private, media, homes)
# - Host system also benefits from all services

let
  # Network interface configuration - CUSTOMIZE THESE FOR YOUR HARDWARE
  # Check available interfaces with: ip link show
  # WiFi interfaces usually named: wlo1, wlp3s0, wlan0, etc.
  # Ethernet interfaces usually named: enp4s0, eth0, eno1, etc.

  apInterface = "wlo1";        # WiFi interface for Access Point (must support AP mode)
  wanInterface = "enp4s0";     # Interface for internet connection (ethernet preferred)

  # Network configuration
  apGateway = "192.168.4.1";
  apNetwork = "192.168.4.0/24";
  apNetworkPrefix = "192.168.4."; # First 3 octets for Samba hosts allow
  dhcpRangeStart = "192.168.4.10";
  dhcpRangeEnd = "192.168.4.100";
  dhcpLeaseDuration = 43200;   # 12 hours in seconds

  # Wi-Fi AP configuration
  wifiSSID = "liam-w";
  wifiPassword = "REDACTED002";
  wifiCountryCode = "PL";
  wifiChannel = 6;

  # AdGuard configuration
  adguardUsername = "admin";
  adguardPasswordHash = "REDACTED006"; # Generate with: mkpasswd -m bcrypt 'your_password'

  # Samba NAS configuration
  sambaWorkgroup = "WORKGROUP";
  sambaServerName = "liam-w NAS";
  sambaNetbiosName = "liam-w-nas";
  sambaUser = "liam-w";              # Primary user for Samba shares
  sambaGroup = "users";              # Primary group for Samba shares

  # Mullvad VPN configuration
  mullvadIPs = [ "REDACTED007" "REDACTED008" ]; # Your assigned IPs from Mullvad
  mullvadListenPort = 51820;
  mullvadEndpointIP = "REDACTED009";  # Mullvad server IP
  mullvadPublicKey = "REDACTED010"; # Server's public key
  mullvadAllowedIPs = [ "0.0.0.0/0" "::/0" ];
in {

  #----=[ Mullvad VPN Configuration ]=----#

  # Enable WireGuard
  networking.wireguard.enable = true;

  # Mullvad WireGuard configuration
  networking.wireguard.interfaces = {
    mullvad = {
      # Interface will be created automatically
      ips = mullvadIPs;
      listenPort = mullvadListenPort;

      # Your private key
      privateKeyFile = "/etc/wireguard/mullvad-private.key";

      peers = [
        {
          # Mullvad server - replace with your preferred server
          publicKey = mullvadPublicKey;
          allowedIPs = mullvadAllowedIPs;
          endpoint = "${mullvadEndpointIP}:${toString mullvadListenPort}";
          persistentKeepalive = 25;
        }
      ];

      # Post-up and pre-down scripts for routing
      postSetup = ''
        # Save current default routes (IPv4 and IPv6)
        ${pkgs.iproute2}/bin/ip route show default > /tmp/default_route_backup || true
        ${pkgs.iproute2}/bin/ip -6 route show default > /tmp/default_route6_backup || true

        # Add route for Mullvad server via original gateway (IPv4)
        ORIGINAL_GW=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk 'NR==1{print $3}')
        ${pkgs.iproute2}/bin/ip route add ${mullvadEndpointIP}/32 via $ORIGINAL_GW || true

        # Set VPN as default route with higher priority (lower metric)
        ${pkgs.iproute2}/bin/ip route add default dev mullvad metric 50 || true
        ${pkgs.iproute2}/bin/ip -6 route add default dev mullvad metric 50 || true

        # Ensure ISP routes have lower priority (higher metric)
        ORIGINAL_GW6=$(${pkgs.iproute2}/bin/ip -6 route show default | ${pkgs.gawk}/bin/awk 'NR==1{print $3}')
        ORIGINAL_DEV=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk 'NR==1{print $5}')
        ${pkgs.iproute2}/bin/ip route replace default via $ORIGINAL_GW dev $ORIGINAL_DEV metric 200 || true
        ${pkgs.iproute2}/bin/ip -6 route replace default via $ORIGINAL_GW6 dev $ORIGINAL_DEV metric 200 || true
      '';

      preShutdown = ''
        # Clean up VPN routes
        ${pkgs.iproute2}/bin/ip route del default dev mullvad || true
        ${pkgs.iproute2}/bin/ip -6 route del default dev mullvad || true

        # Remove Mullvad server route
        ORIGINAL_GW=$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk 'NR==1{print $3}')
        ${pkgs.iproute2}/bin/ip route del ${mullvadEndpointIP}/32 via $ORIGINAL_GW || true

        # Restore original ISP routes with normal metric
        if [ -f /tmp/default_route_backup ]; then
          ORIGINAL_GW=$(cat /tmp/default_route_backup | ${pkgs.gawk}/bin/awk '{print $3}')
          ORIGINAL_DEV=$(cat /tmp/default_route_backup | ${pkgs.gawk}/bin/awk '{print $5}')
          ${pkgs.iproute2}/bin/ip route replace default via $ORIGINAL_GW dev $ORIGINAL_DEV metric 100 || true
        fi
        if [ -f /tmp/default_route6_backup ]; then
          ORIGINAL_GW6=$(cat /tmp/default_route6_backup | ${pkgs.gawk}/bin/awk '{print $3}')
          ORIGINAL_DEV=$(cat /tmp/default_route6_backup | ${pkgs.gawk}/bin/awk '{print $5}')
          ${pkgs.iproute2}/bin/ip -6 route replace default via $ORIGINAL_GW6 dev $ORIGINAL_DEV metric 100 || true
        fi
      '';
    };
  };

  # Disable systemd-resolved since AdGuard handles DNS
  services.resolved.enable = false;

  # Use AdGuard for host DNS resolution
  networking.nameservers = [ "127.0.0.1" ];
  networking.resolvconf.useLocalResolver = true;

  # WireGuard interface is automatically managed by NixOS
  # No separate service needed - the interface is brought up by systemd-networkd

  # Policy routing to ensure AP traffic goes through VPN
  networking.iproute2 = {
    enable = true;
    rttablesExtraConfig = ''
      200 vpn
    '';
  };

  # Additional routing rules for AP clients
  systemd.services.mullvad-routing = {
    description = "Mullvad VPN Routing Setup";
    after = [ "network-online.target" "wireguard-mullvad.service" ];
    wants = [ "wireguard-mullvad.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Wait for VPN to be up
      sleep 5

      # Route AP subnet through VPN (IPv4 and IPv6)
      ${pkgs.iproute2}/bin/ip rule add from ${apNetwork} table vpn priority 100 || true
      ${pkgs.iproute2}/bin/ip route add default dev mullvad table vpn || true
      ${pkgs.iproute2}/bin/ip -6 route add default dev mullvad table vpn || true
      ${pkgs.iproute2}/bin/ip route add ${apNetwork} dev ${apInterface} table vpn || true

      # Flush route cache
      ${pkgs.iproute2}/bin/ip route flush cache
    '';

    preStop = ''
      # Clean up routing rules
      ${pkgs.iproute2}/bin/ip rule del from ${apNetwork} table vpn || true
      ${pkgs.iproute2}/bin/ip route flush table vpn || true
      ${pkgs.iproute2}/bin/ip route flush cache
    '';
  };

  #----=[ Wi-Fi Access Point Configuration ]=----#

  # Force NetworkManager to release and ignore the AP interface
  networking.networkmanager.unmanaged = [ apInterface ];

  # SystemD service to forcibly disconnect NetworkManager from AP interface
  systemd.services.release-ap-interface = {
    description = "Release AP interface from NetworkManager";
    wantedBy = [ "multi-user.target" ];
    before = [ "hostapd.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Force disconnect the interface from NetworkManager
      ${pkgs.networkmanager}/bin/nmcli device disconnect ${apInterface} || true

      # Set interface unmanaged
      ${pkgs.networkmanager}/bin/nmcli device set ${apInterface} managed no || true

      # Bring interface down and back up to reset state
      ${pkgs.iproute2}/bin/ip link set ${apInterface} down || true
      sleep 2
      ${pkgs.iproute2}/bin/ip link set ${apInterface} up || true

      # Remove any existing IP addresses and assign static IP
      ${pkgs.iproute2}/bin/ip addr flush dev ${apInterface} || true
      ${pkgs.iproute2}/bin/ip addr add ${apGateway}/24 dev ${apInterface} || true
    '';
  };

  # AP interface IP is assigned by release-ap-interface service

  # Enable hostapd for Wi-Fi AP
  services.hostapd = {
    enable = true;
    radios.${apInterface} = {
      countryCode = wifiCountryCode;
      band = "2g";
      channel = wifiChannel;
      networks.${apInterface} = {
        ssid = wifiSSID;
        authentication = {
          mode = "wpa3-sae";
          saePasswords = [ { password = wifiPassword; } ];
        };
      };
    };
  };

  # Enable IP forwarding and AP routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    # Enable proxy ARP on AP interface for proper client connectivity (override default)
    "net.ipv4.conf.${apInterface}.proxy_arp" = lib.mkForce 1;
    # Additional ARP settings for AP
    "net.ipv4.conf.${apInterface}.arp_filter" = lib.mkForce 0;
    "net.ipv4.conf.${apInterface}.arp_announce" = lib.mkForce 2;
    "net.ipv4.conf.${apInterface}.arp_ignore" = lib.mkForce 1;
  };

  # NAT for internet access through VPN ONLY - NO FALLBACK
  networking.nat = {
    enable = true;
    internalInterfaces = [ apInterface ];
    # ONLY use VPN interface - traffic blocked if VPN is down (kill switch)
    externalInterface = "mullvad";

    # Clear all existing NAT rules and rebuild only what we need
    extraCommands = ''
      # Flush all NAT rules to start clean
      ${pkgs.iptables}/bin/iptables -t nat -F POSTROUTING

      # Add only the VPN NAT rule we need
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${apNetwork} -o mullvad -j MASQUERADE
    '';

    extraStopCommands = ''
      # Clean up on service stop
      ${pkgs.iptables}/bin/iptables -t nat -F POSTROUTING
    '';
  };

  #----=[ AdGuard DNS & DHCP Configuration ]=----#

  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
    openFirewall = true;
    settings = {

      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;

        # Upstream DNS servers - Quad9, Google, Cloudflare with DoH
        upstream_dns = [
        "https://dns.quad9.net/dns-query"
        "https://dns.google/dns-query"
        "https://dns.cloudflare.com/dns-query"
        "tls://dns.quad9.net"
        ];


        # Bootstrap DNS for DoH/DoT - Quad9 IPv4 and IPv6
        bootstrap_dns = [
          "9.9.9.9:53"
          "149.112.112.112:53"
          "2620:fe::fe:53"
          "2620:fe::9:53"
        ];

        # Enable DNS-over-HTTPS
        upstream_dns_file = "";

        # Query logging - 1 hour retention
        querylog_enabled = true;
        querylog_file_enabled = true;
        querylog_interval = "1h";
        querylog_size_memory = 1000;
        anonymize_client_ip = true;


        # Statistics - 1 hour retention
        statistics_interval = "1h";

        # Disable AdGuard browsing security (using Quad9 instead)
        safe_browsing_enabled = false;
        parental_enabled = false;

        # Block adult content
        safesearch_enabled = false;

        # Enable filtering with 1 hour update interval
        filtering_enabled = true;
        filters_update_interval = 1;

        # DNS security settings
        enable_dnssec = true;
        disable_ipv6 = false;
        rate_limit = 0;
        blocked_response_ttl = 10;

        # Cache settings
        cache_size = 4194304; # 4MB
        cache_ttl_min = 0;
        cache_ttl_max = 0;
        cache_optimistic = false;
      };

      # Web interface authentication (change these!)
      users = [
        {
          name = adguardUsername;
          password = adguardPasswordHash;
        }
      ];

      # Comprehensive filtering configuration
      filters = [
        # Built-in General Lists
        {
          enabled = true;
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://filters.adtidy.org/extension/chromium/filters/14.txt";
          name = "AdGuard DNS Popup Hosts filter";
          id = 2;
        }
        {
          enabled = true;
          url = "https://filters.adtidy.org/extension/chromium/filters/17.txt";
          name = "AWAvenue Ads Rule";
          id = 3;
        }
        {
          enabled = true;
          url = "https://someonewhocares.org/hosts/zero/hosts";
          name = "Dan Pollock's List";
          id = 4;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.plus.mini.txt";
          name = "HaGeZi's Pro++ Blocklist";
          id = 5;
        }
        {
          enabled = true;
          url = "https://big.oisd.nl/";
          name = "OISD Blocklist Big";
          id = 6;
        }
        {
          enabled = true;
          url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=1&mimetype=plaintext";
          name = "Peter Lowe's Blocklist";
          id = 7;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
          name = "Steven Black's List";
          id = 8;
        }
        # Security Lists
        {
          enabled = true;
          url = "https://malware-filter.gitlab.io/malware-filter/phishing-filter.txt";
          name = "Phishing URL Blocklist";
          id = 9;
        }
        {
          enabled = true;
          url = "https://gitlab.com/DandelionSprout/adfilt/-/raw/master/Dandelion%20Sprout's%20Anti-Malware%20List.txt";
          name = "Dandelion Sprout's Anti-Malware List";
          id = 10;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/hoster.txt";
          name = "HaGeZi's Badware Hoster Blocklist";
          id = 11;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/dyndns.txt";
          name = "HaGeZi's DynDNS Blocklist";
          id = 12;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/spam-tlds.txt";
          name = "HaGeZi's Most Abused TLDs";
          id = 13;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/tif.txt";
          name = "HaGeZi's Threat Intelligence Feeds";
          id = 14;
        }
        # Custom Lists
        {
          enabled = true;
          url = "https://v.firebog.net/hosts/Admiral.txt";
          name = "Admiral";
          id = 15;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts";
          name = "Ad Wars";
          id = 16;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt";
          name = "anudeepND's Blacklist";
          id = 17;
        }
        {
          enabled = true;
          url = "https://badblock.celenity.dev/abp/badblock.txt";
          name = "My BadBlock";
          id = 18;
        }
        {
          enabled = true;
          url = "https://sysctl.org/cameleon/hosts";
          name = "CAMELEON";
          id = 19;
        }
      ];

      # DHCP settings for Wi-Fi AP clients
      dhcp = {
        enabled = true;
        interface_name = apInterface;
        local_domain_name = "home.local";

        dhcpv4 = {
          gateway_ip = apGateway;
          subnet_mask = "255.255.255.0";
          range_start = dhcpRangeStart;
          range_end = dhcpRangeEnd;
          lease_duration = dhcpLeaseDuration;
          dns = [ apGateway ];
        };
      };

      # Local DNS entries for easy access
      filtering = {
        rewrites = [
          {
            domain = "local";
            answer = apGateway;
          }
          {
            domain = "nas.local";
            answer = apGateway;
          }
          {
            domain = "homelab.local";
            answer = apGateway;
          }
        ];
      };

      # Allowlists/Whitelists
      whitelist_filters = [
        {
          enabled = true;
          url = "https://badblock.celenity.dev/abp/whitelist.txt";
          name = "BadBlock Whitelist";
          id = 1001;
        }
        {
          enabled = true;
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/whitelist-urlshortener.txt";
          name = "HaGeZi's URL Shorteners";
          id = 1002;
        }
      ];

      # Log configuration
      log = {
        file = "";
        max_backups = 0;
        max_size = 100;
        max_age = 3;
        compress = false;
        local_time = false;
        verbose = false;
      };
    };
  };

  #----=[ Samba NAS Configuration ]=----#

  # Samba NAS configuration
  services.samba = {
    enable = true;
    openFirewall = true;

    # Global Samba settings
    settings = {
      global = {
        "workgroup" = sambaWorkgroup;
        "server string" = sambaServerName;
        "netbios name" = sambaNetbiosName;
        "security" = "user";
        "hosts allow" = "${apNetworkPrefix} 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";

        # Performance optimizations
        "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
        "read raw" = "yes";
        "write raw" = "yes";
        "server signing" = "auto";
        "use sendfile" = "yes";
        "aio read size" = "16384";
        "aio write size" = "16384";

        # Modern SMB protocol
        "min protocol" = "SMB2";
        "max protocol" = "SMB3";

        # Logging
        "log file" = "/var/log/samba/log.%m";
        "max log size" = "1000";
        "log level" = "0";
      };

      # Public share (no authentication required)
      "public" = {
        "path" = "/srv/samba/public";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0664";
        "directory mask" = "0775";
        "force user" = sambaUser;
        "force group" = sambaGroup;
      };

      # Private share
      "private" = {
        "path" = "/srv/samba/private";
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0660";
        "directory mask" = "0770";
        "valid users" = sambaUser;
        "force user" = sambaUser;
        "force group" = sambaGroup;
      };

      # Home directory share
      "homes" = {
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0700";
        "directory mask" = "0700";
        "valid users" = "%S";
      };

      # Media share for streaming
      "media" = {
        "path" = "/srv/samba/media";
        "browseable" = "no";
        "read only" = "no";
        "guest ok" = "no";
        "valid users" = sambaUser;
        "force user" = sambaUser;
        "force group" = sambaGroup;
      };
    };
  };

  # Note: Samba users must be added manually with: sudo smbpasswd -a liam-w

  # Network discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  # Create Samba directories and set permissions
  systemd.services.samba-setup = {
    description = "Set up Samba directories";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Create directories
      mkdir -p /srv/samba/{public,private,media}

      # Set ownership
      chown -R ${sambaUser}:${sambaGroup} /srv/samba

      # Set permissions
      chmod 775 /srv/samba/public
      chmod 770 /srv/samba/private
      chmod 775 /srv/samba/media
    '';
  };

  # Enable user namespaces for better security
  users.users.${sambaUser}.extraGroups = [ "sambashare" ];
  users.groups.sambashare = {};

  # Ensure AdGuard starts after AP interface is configured
  systemd.services.adguardhome = {
    after = [ "release-ap-interface.service" "hostapd.service" ];
    wants = [ "release-ap-interface.service" "hostapd.service" ];
  };

  #----=[ Firewall Configuration ]=----#

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ apInterface "mullvad" ];
    allowedTCPPorts = [
      53 67 68        # DNS, DHCP
      3000            # AdGuard web interface
      139 445         # Samba
      5357            # WS-Discovery
    ];
    allowedUDPPorts = [
      53 67 68        # DNS, DHCP
      51820           # WireGuard
      137 138         # NetBIOS
      3702            # WS-Discovery
    ];
  };

  #----=[ System Packages ]=----#

  environment.systemPackages = with pkgs; [
    # Network tools
    hostapd
    iptables
    iproute2

    # VPN tools
    wireguard-tools
    mullvad

    # DNS tools
    dig

    # Samba tools
    samba
    cifs-utils
  ];
}
