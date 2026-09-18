{
  lib,
  pkgs,
  username,
  ...
}: let
  homeDirectory = "/home/${username}";
in {
  imports = [
    ../.shared/flatpak.nix
    ../.shared/fcitx5.nix
    ../.shared/niri.nix
    ../.shared/stylix.nix
    ../.shared/pi.nix
  ];

  home = {
    inherit username;
    inherit homeDirectory;
    stateVersion = "25.11";
    sessionVariables.QTSCRCPY_CONFIG_PATH = "${homeDirectory}/.config/qtscrcpy";

    packages = with pkgs; [
      entr
      conda
      virt-manager
      qemu
      vlc
      qtscrcpy
      mission-center
      ripgrep
      lm_sensors
      ffmpeg-full
      mosh

      # from unstable
      unstable.opencode
      unstable.hmcl
      unstable.vscode
    ];
  };

  home.activation.ensureQtScrcpyConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/qtscrcpy"
  '';

  services.flatpak.packages = [
    "com.qq.QQ"
    "com.tencent.WeChat"
    "com.getpostman.Postman"
    "com.github.tchx84.Flatseal"
    "com.moonlight_stream.Moonlight"
    "com.valvesoftware.Steam"
    "com.google.Chrome"
    "com.jetbrains.IntelliJ-IDEA-Community"
    "com.usebottles.bottles"
    "cn.feishu.Feishu"
    "org.localsend.localsend_app"
    "org.telegram.desktop"
    "org.mozilla.firefox"
    "org.qbittorrent.qBittorrent"
    "org.kde.okular"
    "net.codelogistics.clicker"
    "io.beekeeperstudio.Studio"
    "io.github.giantpinkrobots.flatsweep"
    "com.github.gmg137.netease-cloud-music-gtk"
  ];

  # bash shell
  programs.fastfetch.enable = true;
  programs.bash.enable = true;
  programs.bash.initExtra = "fastfetch -l linux";
  home.sessionPath = ["$HOME/.local/bin"];
  programs.bash.shellAliases = {
    nv = "nvidia-offload";
    nf = "nix flake new -t github:nix-community/nix-direnv";
    ug = "sudo nixos-rebuild switch --flake ~/.nix-config#thinkbook";
    up = "sudo nix flake update --flake ~/.nix-config && flatpak --user update -y";
    ut = "sudo nixos-rebuild test --flake ~/.nix-config#thinkbook";
    reboot-to-win = "sudo grub-reboot Windows && reboot";
    clean = "sudo nix-collect-garbage -d";
  };

  # starship
  programs.starship.enable = true;
  programs.starship.enableBashIntegration = true;

  # git config
  programs.git.enable = true;
  programs.git.settings.user.name = "zway";
  programs.git.settings.user.email = "zfungew1@gmail.com";

  # jj-vcs
  programs.jujutsu.enable = true;
  programs.jujutsu.settings.user.name = "zway";
  programs.jujutsu.settings.user.email = "zfungew1@gmail.com";

  # direnv
  programs.direnv.enable = true;
  programs.direnv.enableBashIntegration = true;
}
