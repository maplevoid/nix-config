{
  config,
  pkgs,
  ...
}: let
  homeDirectory = config.home.homeDirectory;
in {
  home.file = {
    # flatpak font/icon fixes
    # ".local/share/fonts".source = mkOutOfStoreSymlink "/run/current-system/sw/share/X11/fonts";
    # ".icons".source = "${pkgs.bibata-cursors}/share/icons";

    # QQ's launcher reads flags from $XDG_CONFIG_HOME/qq-flags.conf.
    # Force the x11 ozone platform, otherwise the leaked NIXOS_OZONE_WL=1
    # session variable makes Chromium pick wayland and crash.
    ".var/app/com.qq.QQ/config/qq-flags.conf".text = ''
      --ozone-platform=x11
      --enable-wayland-ime
      --wayland-text-input-version=3
    '';
  };

  # temporarily fix nix-flatpak icon issue
  xdg.systemDirs.data = [
    "/var/lib/flatpak/exports/share"
    "${homeDirectory}/.local/share/flatpak/exports/share"
  ];

  # flatpak shared settings
  services.flatpak.update.auto.enable = false;
  services.flatpak.uninstallUnmanaged = true;

  # QQ's wayland rendering is broken on niri (pure wayland), window never shows.
  # Force it onto XWayland: only grant the x11 socket (removes wayland),
  # see https://github.com/flathub/com.qq.QQ/issues/172
  # Use strings, not lists: nix-flatpak's list merge prefixes a leading ';'
  # and Flatpak 1.18.4 SIGSEGVs in flatpak_permissions_from_strv on that.
  services.flatpak.overrides = {
    "com.qq.QQ".Context = {
      sockets = "!wayland;x11";
      devices = "all";
      filesystems = "!home;xdg-download";
    };

    "com.qq.QQ".Environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "x11";
      DISPLAY = ":0";
    };

    global = {
      Context = {
        filesystems = [
          # fix flaptak fonts issue
          "${homeDirectory}/.local/share/fonts:ro"
          "${homeDirectory}/.icons:ro"
          "/nix/store:ro"
          "/run/current-system/sw/share/X11/fonts:ro"
          "${pkgs.bibata-cursors}/share/icons:ro"
        ];
      };

      Enviroment = {
        # force correct theme
        GTK_THEME = "Adwaita:dark";
      };
    };
  };
}
