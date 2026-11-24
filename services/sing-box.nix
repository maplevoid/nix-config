{
  pkgs,
  ...
}:
{
  services.sing-box = {
    enable = true;
    # unstable carries 1.14.x; stable is still 1.13.x.
    package = pkgs.unstable.sing-box;
    # The live config stays hand-managed at /etc/sing-box/config.json so node
    # credentials never enter the store or git. settings stays empty, which
    # makes the unit read that directory instead of a generated file.
    settings = { };
  };

  # The tun table below needs the nftables module; the firewall follows it.
  networking.nftables.enable = true;

  # The unit runs as the sing-box user and -C reads every .json in the
  # directory, so the config must be group-readable and no backups may live
  # next to it.
  systemd.tmpfiles.rules = [
    "z /etc/sing-box/config.json 0640 root sing-box -"
    # clash_api serves its dashboard from <working dir>/ui.
    "L+ /var/lib/sing-box/ui - - - - ${pkgs.metacubexd}"
  ];

  # NixOS checks the reverse path at mangle+10, before sing-box restores its
  # mark (dstnat+2) on replies from the tun. Unmarked they look spoofed and
  # every UDP and ICMP reply is silently dropped.
  networking.nftables.tables.sing-box-tun-rpfilter = {
    family = "inet";
    content = ''
      chain prerouting {
        type filter hook prerouting priority mangle - 1;
        policy accept;
        iifname "tun0" ct mark 0x2023 meta mark set ct mark
      }
    '';
  };

  # TUN plus process-name rules need these caps. Same set as the upstream
  # sing-box.service; the NixOS module adds none of them.
  systemd.services.sing-box.serviceConfig = {
    AmbientCapabilities = [
      "CAP_NET_ADMIN"
      "CAP_NET_RAW"
      "CAP_NET_BIND_SERVICE"
      "CAP_SYS_PTRACE"
      "CAP_DAC_READ_SEARCH"
    ];
    CapabilityBoundingSet = [
      "CAP_NET_ADMIN"
      "CAP_NET_RAW"
      "CAP_NET_BIND_SERVICE"
      "CAP_SYS_PTRACE"
      "CAP_DAC_READ_SEARCH"
    ];
  };
}
