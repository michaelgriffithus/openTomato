#!/usr/bin/env bash
# Sanity test for tool/leak_scan.sh: it must flag banned words and pass
# legitimate superstrings.
set -u
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ -f tool/leak_scan.local ]; then
  # shellcheck disable=SC1091
  . tool/leak_scan.local
fi
UNBOUNDED="${LEAK_SCAN_UNBOUNDED:-}"
BOUNDED="${LEAK_SCAN_BOUNDED:-}"
if [ -z "$UNBOUNDED" ] && [ -z "$BOUNDED" ]; then
  echo "leak_scan_test: no word list available; skipped"
  exit 0
fi
[ -z "$UNBOUNDED" ] && UNBOUNDED='[^\s\S]'
[ -z "$BOUNDED" ] && BOUNDED='[^\s\S]'
# Fixtures: LEAK_SCAN_OK_LINE must pass, LEAK_SCAN_BAD_LINE must be flagged.
: "${LEAK_SCAN_OK_LINE:=padding: EdgeInsets.all(8), indicator, budget, limit, constraint, secure}"
: "${LEAK_SCAN_BAD_LINE:?set LEAK_SCAN_BAD_LINE in tool/leak_scan.local}"

printf '%s\n' "$LEAK_SCAN_OK_LINE" > "$tmp/ok.txt"
printf '%s\n' "$LEAK_SCAN_BAD_LINE" > "$tmp/bad.txt"

fail=0
if rg -q -i -e "$UNBOUNDED" -e "$BOUNDED" "$tmp/ok.txt"; then echo "FAIL: false positive on ok.txt"; fail=1; fi
if ! rg -q -i -e "$UNBOUNDED" -e "$BOUNDED" "$tmp/bad.txt"; then echo "FAIL: missed bad.txt"; fail=1; fi
[ $fail -eq 0 ] && echo "leak_scan_test: ok"
exit $fail
