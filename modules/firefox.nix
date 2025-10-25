{ config, pkgs, lib, ... }:

let
  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  environment.sessionVariables = {
    # Firefox stuffs
    MOZ_ENABLE_WAYLAND=1;
    MOZ_USE_XINPUT2=1;
  };

  xdg.mime.defaultApplications = {
    "application/pdf" = "firefox.desktop";
    "text/html"="firefox.desktop";
    "x-scheme-handler/http"="firefox.desktop";
    "x-scheme-handler/https"="firefox.desktop";
    "x-scheme-handler/about"="firefox.desktop";
    "x-scheme-handler/unknown"="firefox.desktop";
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "de" "en-US" ];

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value= true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";

      ExtensionSettings = {
        "*".installation_mode = "blocked";
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
        };
        "firessb@malisipi.github.io" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/firessb/latest.xpi";
          installation_mode = "force_installed";
        };
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };
        "{b743f56d-1cc1-4048-8ba6-f9c2ab7aa54d}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/dracula-dark-colorscheme/latest.xpi";
          installation_mode = "force_installed";
        };
        "{7bb1f5d8-56c8-4c72-a7b9-0f539a7feefd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4581864/simple_otpmanager_browser-0.36.xpi";
          installation_mode = "force_installed";
        };
        "ncpasswords@mdns.eu" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4373288/nextcloud_passwords-2.7.0.xpi";
          installation_mode = "force_installed";
        };
        "css-override@scottco.co" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3419738/css_override-1.0.xpi";
          installation_mode = "force_installed";
        };
        "floccus@handmadeideas.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4431645/floccus-5.4.4.xpi";
          installation_mode = "force_installed";
        };
        "ctrl-shift-c-copy@jeffersonscher.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3717803/ctrl_shift_c_should_copy-0.1.0.xpi";
          installation_mode = "force_installed";
        };
        "{d963a14f-f7aa-4503-b651-fea11ff824dd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4468112/steam_game_revenue-1.1.2.xpi";
          installation_mode = "force_installed";
        };
        "firefox-extension@steamdb.info" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4493966/steam_database-4.16.xpi";
          installation_mode = "force_installed";
        };
        "linkhints@lydell.github.io" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4346988/linkhints-1.3.3.xpi";
          installation_mode = "force_installed";
        };
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4442132/sidebery-5.3.3.xpi";
          installation_mode = "force_installed";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4598130/sponsorblock-6.0.3.xpi";
          installation_mode = "force_installed";
        };
      };

      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };
        "browser.contentblocking.category" = { Value = "strict"; Status = "locked"; };
        "extensions.pocket.enabled" = lock-false;
        "extensions.screenshots.disabled" = lock-true;
        "browser.topsites.contile.enabled" = lock-false;
        "browser.formfill.enable" = lock-false;
        "browser.search.suggest.enabled" = lock-false;
        "browser.search.suggest.enabled.private" = lock-false;
        "browser.urlbar.suggest.searches" = lock-false;
        "browser.urlbar.showSearchSuggestionsFirst" = lock-false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = lock-false;
        "browser.newtabpage.activity-stream.feeds.snippets" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock-false;
        "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock-false;
        "browser.newtabpage.activity-stream.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.system.showSponsored" = lock-false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock-false;
        "ui.key.menuAccessKeyFocuses" = lock-false;
        "apz.allow_zooming" = lock-false;
        "browser.gesture.pinch.in" = { Value = "cmd_fullZoomReset"; Status = "locked"; };
        "browser.gesture.pinch.out" = { Value = "cmd_fullZoomReset"; Status = "locked"; };
      };
    };
  };

  # declarative injection of userChrome.css for Sidebery + no native tabs + padding for URL bar
  system.userActivationScripts.firefoxChrome = {
    text = ''
      profile_dir=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default*" | head -n1)
      mkdir -p "$profile_dir/chrome"
      cat > "$profile_dir/chrome/userChrome.css" <<'EOF'
      /* hides the native tabs */
      #TabsToolbar {
        visibility: collapse;
      }

      /* hides the title bar */
      #titlebar {
        visibility: collapse;
      }

      /* hides the sidebar */
      #sidebar-header {
        visibility: collapse !important;
      }

      /* Optional cleaner window controls area */
      #nav-bar {
        margin-top: 12px;
        margin-right: 0px;
        margin-bottom: 12px;
      }
      EOF
    '';
  };
}
