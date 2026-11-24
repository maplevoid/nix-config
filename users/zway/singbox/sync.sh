#!/usr/bin/env bash
# Rebuild the sing-box config from the airport subscription and install it.
#
#   singbox-sync              fetch the subscription, convert, install, restart
#   singbox-sync --dry-run    stop after the config passes sing-box check
#   singbox-sync --from FILE  use a local file instead of the subscription
#
# The subscription URL is taken from $SINGBOX_SUB_URL, then
# ~/.config/singbox-sync/url, then the profile clash-verge-ReV last used.
set -Eeuo pipefail

SCRIPT_DIR=${SCRIPT_DIR:?}
CONFIG_FILE=${CONFIG_FILE:-/etc/sing-box/config.json}
CLASH_API=${CLASH_API:-http://127.0.0.1:9090}
CLASH_DATA=${CLASH_DATA:-$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev}
CLASH_UA=${CLASH_UA:-sing-box/1.14.3}

dry_run=0
source_file=
source_url=

die() {
    printf 'singbox-sync: %s\n' "$*" >&2
    exit 1
}

usage() {
    sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
    --dry-run) dry_run=1 ;;
    --from)
        [ $# -ge 2 ] || die "--from needs a path"
        source_file=$2
        shift
        ;;
    --url)
        [ $# -ge 2 ] || die "--url needs a value"
        source_url=$2
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *) die "unknown argument: $1" ;;
    esac
    shift
done

subscription_url() {
    if [ -n "${SINGBOX_SUB_URL:-}" ]; then
        printf '%s\n' "$SINGBOX_SUB_URL"
        return
    fi
    if [ -s "$HOME/.config/singbox-sync/url" ]; then
        awk 'NF && $1 !~ /^#/ { print; exit }' "$HOME/.config/singbox-sync/url"
        return
    fi
    if [ -s "$CLASH_DATA/profiles.yaml" ]; then
        # the profile clash-verge last used; its url field holds the token
        awk '
            /^- uid:/ { uid = $3; url = "" }
            /^  url:/ && url == "" { url = $2 }
            /^current:/ { current = $2 }
            { if (uid != "" && url != "") { urls[uid] = url } }
            END {
                if (current != "" && (current in urls)) { print urls[current]; exit }
                for (u in urls) { print urls[u]; exit }
            }
        ' "$CLASH_DATA/profiles.yaml"
        return
    fi
    die "no subscription URL: set SINGBOX_SUB_URL, write it to ~/.config/singbox-sync/url, or pass --from/--url"
}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

raw=$work/raw
if [ -n "$source_file" ]; then
    [ -r "$source_file" ] || die "cannot read $source_file"
    cp "$source_file" "$raw"
else
    url=${source_url:-$(subscription_url)}
    [ -n "$url" ] || die "empty subscription URL"
    printf 'fetching subscription\n'
    curl -fsSL --retry 3 --connect-timeout 15 -A "$CLASH_UA" -o "$raw" "$url" ||
        die "download failed (is the network up?)"
fi

[ -s "$raw" ] || die "subscription is empty"

candidate=$work/candidate.json
if grep -q '^[[:space:]]*{' "$raw"; then
    printf 'input: sing-box json\n'
    jq -f "$SCRIPT_DIR/apply-json-patch.jq" "$raw" >"$candidate"
else
    printf 'input: clash yaml\n'
    yq -o=json "$raw" >"$work/clash.json"
    python3 "$SCRIPT_DIR/clash2singbox.py" "$work/clash.json" "$SCRIPT_DIR/scaffold.json" "$candidate"
fi

sing-box check -c "$candidate" || die "sing-box rejected the generated config"

nodes=$(jq '[.outbounds[] | select(.type != "direct" and .type != "block" and .type != "selector" and .type != "urltest")] | length' "$candidate")
groups=$(jq '[.outbounds[] | select(.type == "selector" or .type == "urltest")] | length' "$candidate")
final=$(jq -r '.route.final // "?"' "$candidate")
printf 'ok: %s nodes, %s groups, final=%s\n' "$nodes" "$groups" "$final"

if [ "$dry_run" -eq 1 ]; then
    printf 'dry run: candidate left at %s\n' "$candidate"
    cp "$candidate" "${TMPDIR:-/tmp}/singbox-sync-candidate.json"
    printf 'copied to %s\n' "${TMPDIR:-/tmp}/singbox-sync-candidate.json"
    exit 0
fi

if getent group sing-box >/dev/null 2>&1; then
    install_args=(-m 0640 -o root -g sing-box)
else
    install_args=(-m 0644 -o root -g root)
fi

sudo install "${install_args[@]}" "$candidate" "$CONFIG_FILE"
sudo systemctl restart sing-box
sleep 2
systemctl is-active --quiet sing-box || die "sing-box did not stay up, check: journalctl -u sing-box -n 40"

if curl -fsS --max-time 3 "$CLASH_API/proxies" >/dev/null 2>&1; then
    now=$(curl -fsS --max-time 3 "$CLASH_API/proxies" | jq -r '.proxies["🔰 节点选择"].now // "?"')
    printf 'installed and restarted, selected node: %s\n' "$now"
else
    printf 'installed and restarted\n'
fi
