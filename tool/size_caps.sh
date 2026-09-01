#!/usr/bin/env bash
# Enforces CONVENTIONS.md size caps on hand-written Dart files.
set -u
cd "$(dirname "$0")/.."
status=0
check() { # file cap label
  n=$(wc -l < "$1")
  if [ "$n" -gt "$2" ]; then echo "$1: $n lines (cap $2, $3)"; status=1; fi
}
while IFS= read -r f; do
  case "$f" in
    *.g.dart) continue ;;
    */daos/*) check "$f" 200 dao ;;
    */screens/*|*/widgets/*) check "$f" 400 widget ;;
    */providers/*) check "$f" 300 provider ;;
    */services/*|*/repositories/*|*/data/*) check "$f" 300 service ;;
  esac
done < <(find lib -name '*.dart')
[ $status -eq 0 ] && echo "size_caps: clean"
exit $status
