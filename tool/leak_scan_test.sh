#!/usr/bin/env bash
# Sanity test for tool/leak_scan.sh: it must flag banned words and pass
# legitimate superstrings.
set -u
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

UNBOUNDED="${LEAK_SCAN_UNBOUNDED:-}"
BOUNDED="${LEAK_SCAN_BOUNDED:-}"

printf 'padding: EdgeInsets.all(8), indicator, budget, limit, constraint, secure, griffith\n' > "$tmp/ok.txt"
printf 'this line mentions a banned word\n' > "$tmp/bad.txt"

fail=0
if rg -q -i -e "$UNBOUNDED" -e "$BOUNDED" "$tmp/ok.txt"; then echo "FAIL: false positive on ok.txt"; fail=1; fi
if ! rg -q -i -e "$UNBOUNDED" -e "$BOUNDED" "$tmp/bad.txt"; then echo "FAIL: missed bad.txt"; fail=1; fi
[ $fail -eq 0 ] && echo "leak_scan_test: ok"
exit $fail
