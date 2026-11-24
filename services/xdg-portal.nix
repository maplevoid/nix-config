{ pkgs, ... }:
{
  # flatpak, niri and screen sharing all need the same portals; keep them in
  # one place so the backends cannot drift apart.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      # recommended by upstream, required for screencast support
      # https://github.com/YaLTeR/niri/wiki/Important-Software#portals
      xdg-desktop-portal-gnome
    ];
    config.common.default = "gnome";
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.GlobalShortcuts" = [ "none" ];
    };
  };
}
