#!/usr/bin/env bash
# Part of Mari's AI Setup by Mari Svennevik Notland · https://github.com/Mariisno/maris-ai-setup · MIT License
# quota.sh — the remaining quota of the Claude account the status line last ran on, one line.
# Reads the snapshot the status line writes (<LOLA_USAGE_DIR>/snapshot.json).
# The number is as fresh as the last status-line render, so its age is shown.
#
#   quota.sh              one line
#   quota.sh --raw        machine-readable: "<7d %> <5h %>" (0 if the window has reset, - if unknown)
set -u
here="$(cd -P "$(dirname "$(readlink "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=../plugins/lola/lib/lola-config.sh
. "$here/../plugins/lola/lib/lola-config.sh"
now=$(date +%s)
age() { local s=$1; if [ "$s" -lt 3600 ]; then printf '%d min' $((s/60)); elif [ "$s" -lt 86400 ]; then printf '%d h' $((s/3600)); else printf '%d d' $((s/86400)); fi; }
when() { date -r "$1" '+%a %H:%M' 2>/dev/null || date -d "@$1" '+%a %H:%M'; }
int() { case "$1" in ''|*[!0-9.]*) echo -;; *) printf '%d' "${1%%.*}";; esac; }   # round DOWN; decimals break bash arithmetic

mode="${1:-}"; f="$LOLA_USAGE_DIR/snapshot.json"
if [ ! -f "$f" ]; then
  case "$mode" in --raw) echo "- -";; *) echo "no numbers yet (the status line has not rendered a weekly limit)";; esac
  exit 0
fi
read -r h5 h5r d7 d7r cap < <(jq -r '[.rate_limits.five_hour.used_percentage // "-", .rate_limits.five_hour.resets_at // 0,
    .rate_limits.seven_day.used_percentage // "-", .rate_limits.seven_day.resets_at // 0, (.capturedAt // 0 | floor)] | @tsv' "$f" 2>/dev/null)
h5=$(int "${h5:-}"); d7=$(int "${d7:-}"); h5r=${h5r%%.*}; d7r=${d7r%%.*}
case "${h5r:-}" in ''|*[!0-9]*) h5r=0;; esac; case "${d7r:-}" in ''|*[!0-9]*) d7r=0;; esac; case "${cap:-}" in ''|*[!0-9]*) cap=$now;; esac
# A window that has passed its reset since the number was read stands at 0 % in reality.
h5s=$h5; [ "$h5r" -gt 0 ] && [ "$h5r" -le "$now" ] && h5s="0*"
d7s=$d7; [ "$d7r" -gt 0 ] && [ "$d7r" -le "$now" ] && d7s="0*"
d7n=$d7; [ "$d7s" = "0*" ] && d7n=0; h5n=$h5; [ "$h5s" = "0*" ] && h5n=0
case "$mode" in
  --raw) echo "$d7n $h5n" ;;
  *) printf '5h %4s %%  ·  7d %4s %%  ·  resets %s  ·  read %s ago\n' "$h5s" "$d7s" "$( [ "$d7r" -gt 0 ] && when "$d7r" || echo '?')" "$(age $((now - cap)))"
     case "$h5s$d7s" in *\**) echo "* the window has reset since the number was read" ;; esac ;;
esac
