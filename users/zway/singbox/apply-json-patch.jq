# Turn a provider-supplied sing-box config into one that fits this host.
#
# The provider owns the nodes and the routing; this only adds what the host
# needs: the tun device, the tailscale path, the dashboard, and a cache so the
# selected node and the fakeip mappings survive a restart.
.
| (if has("log") then . else .log = {"disabled": false, "level": "info", "timestamp": true} end)
| .experimental = (.experimental // {})
| .experimental.clash_api = ((.experimental.clash_api // {}) + {
    "external_controller": (.experimental.clash_api.external_controller // "127.0.0.1:9090"),
    "external_ui": "ui"
  })
| .experimental.cache_file = {"enabled": true}
| .route = (.route // {})
| .route.auto_detect_interface = true
| .inbounds = ([.inbounds // [] | .[] | if .type == "tun" then
      . + {"interface_name": "tun0", "address": ["10.201.0.1/30"]}
    else . end])
| .outbounds = ([{"type": "direct", "tag": "ts-out", "bind_interface": "tailscale0"}]
    + [.outbounds // [] | .[] | select(.tag != "ts-out")])
| .route.rules = ([{"ip_cidr": ["100.64.0.0/10"], "outbound": "ts-out"}]
    + [.route.rules // [] | .[] | select((.ip_cidr // []) != ["100.64.0.0/10"])])
| if (.dns // null) != null then
    .dns.servers = ([.dns.servers // [] | .[] | select(.tag != "ts-dns")]
      + [{"tag": "ts-dns", "type": "udp", "server": "100.100.100.100", "detour": "ts-out"}])
    | .dns.rules = ([{"domain_suffix": ["ts.net"], "server": "ts-dns"}]
      + [.dns.rules // [] | .[] | select((.domain_suffix // []) != ["ts.net"])])
  else . end
