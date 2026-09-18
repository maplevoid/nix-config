{username, ...}: {
  config = {
    services.displayManager.ly.enable = true;

    # NixOS does not set session_log, so ly 1.4.1 falls back to ~/ly-session.log.
    # Keep Wayland session stdout/stderr under XDG state instead.
    services.displayManager.ly.settings.session_log = ".local/state/ly-session.log";

    services.displayManager.autoLogin.enable = true;
    services.displayManager.autoLogin.user = username;
  };
}
