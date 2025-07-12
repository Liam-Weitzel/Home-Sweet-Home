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
    #Firefox stuffs
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
  programs = {
    firefox = {
      enable = true;
      languagePacks = [ "de" "en-US" ];

      /* ---- POLICIES ---- */
      # Check about:policies#documentation for options.
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
        DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
        DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
        SearchBar = "unified"; # alternative: "separate"

        /* ---- EXTENSIONS ---- */
        # Check about:support for extension/add-on ID strings.
        # Valid strings for installation_mode are "allowed", "blocked",
        # "force_installed" and "normal_installed".
        ExtensionSettings = {
          "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
          };
          # Privacy Badger:
          "jid1-MnnxcxisBPnSXQ@jetpack" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
            installation_mode = "force_installed";
          };
          # FireSSB:
          "firessb@malisipi.github.io" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/firessb/latest.xpi";
            installation_mode = "force_installed";
          };
          # Dark Reader:
          "addon@darkreader.org" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
            installation_mode = "force_installed";
          };
          # Dracula theme:
          "{b743f56d-1cc1-4048-8ba6-f9c2ab7aa54d}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/dracula-dark-colorscheme/latest.xpi";
            installation_mode = "force_installed";
          };
          # OTP manager:
          "{7bb1f5d8-56c8-4c72-a7b9-0f539a7feefd}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4368602/simple_otpmanager_browser-0.35.xpi";
            installation_mode = "force_installed";
          };
          # Password manager:
          "ncpasswords@mdns.eu" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4373288/nextcloud_passwords-2.7.0.xpi";
            installation_mode = "force_installed";
          };
          # CSS override:
          "css-override@scottco.co" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/3419738/css_override-1.0.xpi";
            installation_mode = "force_installed";
          };
          # Floccus:
          "floccus@handmadeideas.org" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4431645/floccus-5.4.4.xpi";
            installation_mode = "force_installed";
          };
          # Ctrl-Shift-C-Should-Copy
          "ctrl-shift-c-copy@jeffersonscher.com" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/3717803/ctrl_shift_c_should_copy-0.1.0.xpi";
            installation_mode = "force_installed";
          };
          # Steam Game Revenue
          "{d963a14f-f7aa-4503-b651-fea11ff824dd}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4468112/steam_game_revenue-1.1.2.xpi";
            installation_mode = "force_installed";
          };
          # SteamDB
          "firefox-extension@steamdb.info" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4493966/steam_database-4.16.xpi";
            installation_mode = "force_installed";
          };
          # Vimium
          "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/file/4524018/vimium_ff-2.3.xpi";
            installation_mode = "force_installed";
          };
        };
  
        /* ---- PREFERENCES ---- */
        # Check about:config for options.
        Preferences = { 
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
  };
}
