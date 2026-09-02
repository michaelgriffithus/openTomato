#!/usr/bin/env bash
# Fails when words or identifiers that must never appear in this public repo
# show up in the tree (or, with --history, in git history and file names).
# See CONVENTIONS.md "Vocabulary".
set -u
cd "$(dirname "$0")/.."

# The word list is private: it lives in tool/leak_scan.local (git-ignored) or
# in LEAK_SCAN_UNBOUNDED / LEAK_SCAN_BOUNDED (CI secrets). Without either the
# scan is skipped rather than failed, so forks and fresh clones still build.
if [ -f tool/leak_scan.local ]; then
  # shellcheck disable=SC1091
  . tool/leak_scan.local
fi
UNBOUNDED="${LEAK_SCAN_UNBOUNDED:-}"
BOUNDED="${LEAK_SCAN_BOUNDED:-}"
if [ -z "$UNBOUNDED" ] && [ -z "$BOUNDED" ]; then
  echo "leak_scan: no word list available (tool/leak_scan.local or env); skipped"
  exit 0
fi
[ -z "$UNBOUNDED" ] && UNBOUNDED='[^\s\S]'
[ -z "$BOUNDED" ] && BOUNDED='[^\s\S]'

# The universe is what git could commit: tracked files plus untracked files
# that are not ignored. Binaries and vendored trees are dropped by name.
BINARY_OR_VENDORED='\.(png|jpg|jpeg|gif|ttf|otf|jar|p8|p12|cer|mobileprovision|ipa|zip)$|^ios/Pods/|/Flutter/|^tool/leak_scan'

scan() {
  # shellcheck disable=SC2046
  rg -n -i -e "$UNBOUNDED" -e "$BOUNDED" "$@"
}

status=0
if [ "${1:-}" = "--staged" ]; then
  files=$(git diff --cached --name-only --diff-filter=ACMR | grep -v -E "$BINARY_OR_VENDORED" || true)
else
  files=$(git ls-files --cached --others --exclude-standard | grep -v -E "$BINARY_OR_VENDORED" || true)
fi
if [ -n "$files" ]; then
  # shellcheck disable=SC2086
  if scan $files; then status=1; fi
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
