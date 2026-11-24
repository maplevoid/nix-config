#!/usr/bin/env python3
"""Rebuild a sing-box config from the live mihomo profile.

Input:  mihomo/clash config as JSON (yq -o=json), and an existing sing-box
        config whose dns/route scaffolding is reused.
Output: sing-box config with fresh outbounds.

The clash groups that the sing-box route rules already reference keep their
sing-box tag, so the rules need no rewrite.
"""
import json
import sys

GROUP_RENAME = {
    "🔰 选择节点": "🔰 节点选择",
    "🛑 拦截广告": "🛑 全球拦截",
}
MEMBER_ALIAS = {
    "DIRECT": "DIRECT",
    "REJECT": "REJECT",
    "REJECT-DROP": "REJECT",
    "PASS": "DIRECT",
}
KEEP_FROM_BASE = {"DIRECT", "REJECT", "🎯 全球直连"}


def outbound_for(p):
    tag = p["name"]
    if p["type"] == "ss":
        return {
            "type": "shadowsocks",
            "tag": tag,
            "server": p["server"],
            "server_port": p["port"],
            "method": p["cipher"],
            "password": p["password"],
        }
    if p["type"] == "vmess":
        o = {
            "type": "vmess",
            "tag": tag,
            "server": p["server"],
            "server_port": p["port"],
            "uuid": p["uuid"],
            "alter_id": p.get("alterId", 0),
        }
        if p.get("cipher") not in (None, "auto"):
            o["security"] = p["cipher"]
        if p.get("tls"):
            tls = {"enabled": True}
            sni = p.get("servername") or p.get("sni")
            if sni:
                tls["server_name"] = sni
            if p.get("skip-cert-verify"):
                tls["insecure"] = True
            o["tls"] = tls
        if p.get("network") == "ws":
            ws = p.get("ws-opts") or {}
            t = {"type": "ws"}
            if ws.get("path"):
                t["path"] = ws["path"]
            if ws.get("headers"):
                t["headers"] = ws["headers"]
            o["transport"] = t
        return o
    raise SystemExit(f"unsupported proxy type: {p['type']} ({tag})")


def main(clash_path, base_path, out_path):
    clash = json.load(open(clash_path))
    base = json.load(open(base_path))

    outbounds = [o for o in base["outbounds"] if o["tag"] in KEEP_FROM_BASE]
    outbounds += [outbound_for(p) for p in clash["proxies"]]

    groups = []
    for g in clash["proxy-groups"]:
        if g["type"] not in ("select", "url-test", "fallback", "load-balance"):
            raise SystemExit(f"unsupported group type: {g['type']} ({g['name']})")
        tag = GROUP_RENAME.get(g["name"], g["name"])
        members = [MEMBER_ALIAS.get(m, GROUP_RENAME.get(m, m)) for m in g["proxies"]]
        o = {"type": "selector" if g["type"] == "select" else "urltest", "tag": tag}
        if g["type"] == "url-test":
            o["url"] = g.get("url", "http://www.gstatic.com/generate_204")
            o["interval"] = g.get("interval", "5m")
        o["outbounds"] = members
        if g["type"] == "select" and members:
            o["default"] = members[0]
        groups.append(o)

    outbounds += groups
    outbounds.append({"type": "selector", "tag": "GLOBAL", "outbounds": [g["tag"] for g in groups]})

    base["outbounds"] = outbounds

    # auto_detect_interface binds outbound sockets to the physical interface,
    # which is what keeps them out of the tun; it stays on.
    base["route"]["auto_detect_interface"] = True
    # tailscale traffic is bound to tailscale0 instead, and the DNS server for
    # ts.net detours through it.
    outbounds.insert(0, {"type": "direct", "tag": "ts-out", "bind_interface": "tailscale0"})
    base["route"]["rules"] = [
        {"ip_cidr": ["100.64.0.0/10"], "outbound": "ts-out"}
    ] + [r for r in base["route"]["rules"] if r.get("ip_cidr") != ["100.64.0.0/10"]]
    for s in base["dns"]["servers"]:
        if s["tag"] == "ts-dns":
            s["detour"] = "ts-out"
    # external_ui is served from <working dir>/ui, which the NixOS module
    # symlinks to metacubexd; cache_file keeps the selected node and fakeip
    # mappings across restarts.
    base["experimental"]["clash_api"]["external_ui"] = "ui"
    base["experimental"]["cache_file"] = {"enabled": True}
    for i in base["inbounds"]:
        if i["type"] == "tun":
            i["interface_name"] = "tun0"
            # 172.19.0.0/16 is taken by the command2api_default docker bridge.
            i["address"] = ["10.201.0.1/30"]

    json.dump(base, open(out_path, "w"), ensure_ascii=False, indent=2)
    print(f"nodes={len(clash['proxies'])} groups={len(groups)} outbounds={len(outbounds)}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
