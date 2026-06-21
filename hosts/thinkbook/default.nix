{
  inputs,
  pkgs,
  username,
  ...
}: {
  imports = [
    # include the results of the hardware scan
    ./hardware.nix

    # common
    ../../common/i18n.nix
    ../../common/networking.nix
    ../../common/audio.nix

    # services
    ../../services/flatpak.nix
    ../../services/gdm.nix
    ../../services/niri.nix
    ../../services/sunshine.nix
  ];

  # flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # nix settings and cachix
  nix.settings.trusted-users = [
    "root"
    username
  ];

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # overlays
  nixpkgs.overlays = [
    inputs.chinese-fonts.overlays.default
    (import ../../overlays/hmcl.nix)
    (import ../../overlays/pkgs-unstable.nix {inherit inputs;})
  ];

  # list packages installed in system profile
  environment.systemPackages = with pkgs; [
    nil
    neovim
    wget
    git
    cachix
    unzip
    zip
    fd
    file
    tree
    alejandra
    inputs.agenix.packages.${stdenv.hostPlatform.system}.default
  ];

  # obs
  programs.obs-studio.enable = true;
  programs.obs-studio.enableVirtualCamera = true;

  # define a user account. don't forget to set a password with 'passwd'.
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
  };

  # bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # systemd
  systemd.user.extraConfig = ''
    DefaultTimeoutStartSec=30s
    DefaultTimeoutStopSec=30s
  '';

  # zswap
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # 16 GB
      options = ["discard"]; # equivalent to swapon --discard
    }
  ];
  # this is needed for zswap lz4 algorithm
  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = ["lz4"];
  boot.kernelParams = [
    "zswap.enabled=1" # enables zswap
    "zswap.compressor=lz4" # compression algorithm
    "zswap.max_pool_percent=20" # maximum percentage of RAM that zswap is allowed to use
    "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
    "zswap.pool=zsmalloc" # zswap backend to use
  ];

  # virtualization
  virtualisation.docker.enable = true;
  virtualisation.docker.package = pkgs.docker_29;
  virtualisation.libvirtd.enable = true;

  # graphics
  hardware.graphics.enable = true;

  # enable CUPS to print documents.
  services.printing.enable = true;

  # enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
