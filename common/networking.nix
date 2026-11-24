{
  pkgs,
  config,
  hostname,
  ...
}:
{
  config = {
    # networking
    networking.firewall.enable = true;
    networking.hostName = hostname;
    networking.networkmanager.enable = true;
    networking.firewall.trustedInterfaces = [
      "tailscale0"
      # sing-box writes replies back into its tun, and conntrack calls those
      # SYN-ACKs invalid because it never saw the SYN. Accept tun0 before the
      # conntrack verdict, or every connection hangs in SYN-SENT.
      "tun0"
    ];
    networking.firewall.allowedTCPPorts = [
      22 # OpenSSH
      7897 # Clash Verge
    ];
    networking.firewall.allowedUDPPorts = [
      config.services.tailscale.port # Tailscale
      53 # DNS
      67 # DHCP server
    ];

    # bluetooth
    hardware.bluetooth.enable = true;

    # clash-verge-rev
    programs.clash-verge.package = pkgs.clash-verge-rev;
    programs.clash-verge.enable = true;
    # clash-verge-rev stays installed as a manual fallback; sing-box owns the
    # tun, so only one of them may run at a time.
    programs.clash-verge.autoStart = false;
    programs.clash-verge.tunMode = false;
    programs.clash-verge.serviceMode = false;
    # networking.proxy.allProxy = "http://127.0.0.1:7897";

    # tailscale
    services.tailscale.enable = true;
  };
}
