#!/usr/bin/env bash
# Fails when vocabulary or identifiers that must never appear in this public
# repo show up in the tree (or, with --history, in git history and file names).
# See CONVENTIONS.md "Vocabulary".
set -u
cd "$(dirname "$0")/.."

UNBOUNDED="${LEAK_SCAN_UNBOUNDED:-}"
BOUNDED="${LEAK_SCAN_BOUNDED:-}"

PATHS=(lib test tool docs README.md CONVENTIONS.md CHANGELOG.md pubspec.yaml ios android macos .github)
EXISTING=()
for p in "${PATHS[@]}"; do [ -e "$p" ] && EXISTING+=("$p"); done

scan() {
  rg -n -i -e "$UNBOUNDED" -e "$BOUNDED" \
    --glob '!tool/leak_scan*' --glob '!**/*.ttf' --glob '!**/*.png' \
    --glob '!ios/Pods/**' --glob '!**/Flutter/**' "$@"
}

status=0
if [ "${1:-}" = "--staged" ]; then
  files=$(git diff --cached --name-only --diff-filter=ACMR | grep -v '^tool/leak_scan' || true)
  if [ -n "$files" ]; then
    # shellcheck disable=SC2086
    if scan $files; then status=1; fi
  fi
else
  if scan "${EXISTING[@]}"; then status=1; fi
fi

if [ "${1:-}" = "--history" ] && [ -d .git ]; then
  if git log --all --format='%H %B' | rg -n -i -e "$UNBOUNDED" -e "$BOUNDED"; then
    echo "leak_scan: banned text in commit history" >&2; status=1
  fi
  if git ls-files | rg -n -i -e "$UNBOUNDED" -e "$BOUNDED"; then
    echo "leak_scan: banned text in a tracked file name" >&2; status=1
  fi
fi

if [ $status -ne 0 ]; then
  echo "leak_scan: FAILED (see matches above)" >&2
else
  echo "leak_scan: clean"
fi
exit $status
