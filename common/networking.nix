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
    ];
    networking.firewall.allowedUDPPorts = [
      config.services.tailscale.port # Tailscale
    ];

    # bluetooth
    hardware.bluetooth.enable = true;

    # tailscale
    services.tailscale.enable = true;
  };
}
