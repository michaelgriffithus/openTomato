#!/usr/bin/env bash
# Single entry point for App Store builds and uploads. Wraps fastlane.
#
#   scripts/release.sh build_local     archive + export an IPA, no upload
#   scripts/release.sh beta            build and upload to TestFlight
#   scripts/release.sh setup_signing   create/refresh signing assets with match
#   scripts/release.sh create_app      register the bundle id + app record (once)
#   scripts/release.sh metadata        upload listing text + screenshots, no binary
#
# Apple identifiers are never stored in this public repo. They are read from
# the environment, by default from ~/.config/opentomato/release.env (override
# with RELEASE_ENV).
# See docs/release.md for the variable names. Never run `flutter build ipa`
# directly; the lanes own archive, export, and upload.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LANE="${1:-}"
RELEASE_ENV="${RELEASE_ENV:-${XDG_CONFIG_HOME:-${HOME}/.config}/opentomato/release.env}"

usage() {
  cat <<'USAGE'
Usage: scripts/release.sh <build_local|beta|setup_signing|create_app|metadata>

Required by every lane that uses the App Store Connect API (beta, setup_signing, metadata):
  APP_STORE_CONNECT_KEY_ID
  APP_STORE_CONNECT_KEY_FILEPATH   path to the .p8, outside the repo
  FASTLANE_TEAM_ID

Optional:
  APP_STORE_CONNECT_ISSUER_ID      required for team keys
  FASTLANE_ITC_TEAM_ID             only when the Apple ID belongs to several teams
  MATCH_GIT_URL + MATCH_PASSWORD   git-backed signing; required by setup_signing
  FASTLANE_APPLE_ID                Apple ID for create_app (interactive 2FA session)
  APP_STORE_APP_NAME               store name for create_app (default OpenTomato)
  RELEASE_ENV                      env file to source (default ~/.config/opentomato/release.env)
USAGE
}

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: ${name}" >&2
    exit 1
  fi
}

require_key_file() {
  if [[ ! -f "${APP_STORE_CONNECT_KEY_FILEPATH}" ]]; then
    echo "APP_STORE_CONNECT_KEY_FILEPATH does not exist: ${APP_STORE_CONNECT_KEY_FILEPATH}" >&2
    exit 1
  fi
}

require_apple_auth() {
  require_env APP_STORE_CONNECT_KEY_ID
  require_env APP_STORE_CONNECT_KEY_FILEPATH
  require_env FASTLANE_TEAM_ID
  require_key_file
}

# The pubspec build number must equal AppDatabase.schemaVersion
# (test/core/database/build_number_matches_schema_test.dart). A TestFlight
# upload therefore bumps both, by hand, in the same commit. This wrapper never
# bumps anything; it refuses to build when they differ.
check_build_matches_schema() {
  local pubspec_version build schema
  pubspec_version="$(grep '^version:' "${ROOT_DIR}/pubspec.yaml" | sed 's/version:[[:space:]]*//')"
  build="${pubspec_version##*+}"
  schema="$(grep -E 'int get schemaVersion => [0-9]+;' "${ROOT_DIR}/lib/core/database/database.dart" | grep -oE '[0-9]+')"
  if [[ -z "${build}" || -z "${schema}" ]]; then
    echo "Could not read the build number or schemaVersion." >&2
    exit 1
  fi
  if [[ "${build}" != "${schema}" ]]; then
    cat >&2 <<MSG
Build number ${build} (pubspec.yaml) != schemaVersion ${schema} (lib/core/database/database.dart).
Bump both to the same value in one commit before building. An empty schema
step needs no onUpgrade block; see CONVENTIONS.md "Release".
MSG
    exit 1
  fi
  echo "Version ${pubspec_version}: build number matches schemaVersion ${schema}."
}

if [[ -f "${RELEASE_ENV}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${RELEASE_ENV}"
  set +a
fi

# gym parses xcodebuild output and crashes on a non-UTF-8 locale.
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

case "${LANE}" in
  build_local)
    require_env FASTLANE_TEAM_ID
    ;;
  beta)
    require_apple_auth
    if [[ -n "${MATCH_GIT_URL:-}" ]]; then
      require_env MATCH_PASSWORD
    fi
    ;;
  setup_signing)
    require_apple_auth
    require_env MATCH_GIT_URL
    require_env MATCH_PASSWORD
    ;;
  create_app)
    require_env FASTLANE_APPLE_ID
    require_env FASTLANE_TEAM_ID
    ;;
  metadata)
    require_apple_auth
    ;;
  -h|--help|help|"")
    usage
    [[ -n "${LANE}" ]] && exit 0
    exit 1
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

cd "${ROOT_DIR}"

export PATH="${ROOT_DIR}/vendor/bundle/bin:${ROOT_DIR}/.fvm/flutter_sdk/bin:/opt/homebrew/opt/ruby/bin:/opt/homebrew/bin:/usr/local/bin:${PATH}"

if [[ "${LANE}" == "build_local" || "${LANE}" == "beta" ]]; then
  check_build_matches_schema
  flutter test test/core/database/build_number_matches_schema_test.dart
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "Warning: working tree is not clean; the build will not match a tagged commit." >&2
  fi
fi

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler is required. Install Ruby with bundler, then run: bundle install" >&2
  exit 1
fi

export BUNDLE_GEMFILE="${ROOT_DIR}/Gemfile"
export BUNDLE_PATH="${BUNDLE_PATH:-${ROOT_DIR}/vendor/bundle}"

if ! bundle check >/dev/null 2>&1; then
  echo "Bundled gems not found; running bundle install first."
  bundle install
fi

cd "${ROOT_DIR}/ios"
bundle exec fastlane ios "${LANE}"
