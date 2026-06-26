#!/usr/bin/env bash
# Create/update a stable symlink to the CPU temperature input (Intel coretemp or AMD k10temp).
# Intended for Waybar "temperature" module hwmon-path, so it doesn't depend on hwmonX numbering.

set -euo pipefail

LINK_DIR="/tmp/waybar"
LINK_PATH="$LINK_DIR/coretemp_temp_input"

# Find the hwmon directory for CPU temperature (coretemp on Intel, k10temp on AMD)
hwmon_dir=""
for name in coretemp k10temp; do
  for d in /sys/class/hwmon/hwmon*; do
    [[ -f "$d/name" ]] || continue
    if [[ "$(cat "$d/name")" == "$name" ]]; then
      hwmon_dir="$d"
      break
    fi
  done
  [[ -n "$hwmon_dir" ]] && break
done

[[ -n "$hwmon_dir" ]] || { notify-send "ERROR: CPU hwmon (coretemp/k10temp) not found" >&2; exit 1; }

# Prefer the tempN_input whose tempN_label matches a known CPU package label
target=""
shopt -s nullglob
for in_file in "$hwmon_dir"/temp*_input; do
  base="$(basename "$in_file")"          # e.g. temp2_input
  n="${base#temp}"; n="${n%_input}"      # e.g. 2
  label_file="$hwmon_dir/temp${n}_label"
  if [[ -f "$label_file" ]]; then
    label="$(cat "$label_file")"
    if [[ "$label" == "Package id 0" || "$label" == "Tctl" || "$label" == "Tdie" ]]; then
      target="$in_file"
      break
    fi
  fi
done
shopt -u nullglob

# Fallbacks if label is missing or doesn't match (varies by platform/driver)
if [[ -z "$target" ]]; then
  [[ -f "$hwmon_dir/temp1_input" ]] && target="$hwmon_dir/temp1_input" || true
fi
if [[ -z "$target" ]]; then
  target="$(ls -1 "$hwmon_dir"/temp*_input 2>/dev/null | head -n 1 || true)"
fi

[[ -n "$target" ]] || { echo "ERROR: no temp*_input under $hwmon_dir" >&2; exit 1; }

mkdir -p "$LINK_DIR"
ln -sf "$target" "$LINK_PATH"