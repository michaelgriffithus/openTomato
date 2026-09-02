# Release runbook (iOS, App Store)

How an OpenTomato build gets from `main` to TestFlight and App Review. Public
document: it names environment variables, never their values.

## Rules

- **Identifiers live in the environment, never in the repo.** Team id, App
  Store Connect key id and issuer id, the `.p8` path, the signing repo URL, and
  its password are read from `~/.config/opentomato/release.env` (or the file
  named by `RELEASE_ENV`). The fastlane files contain no fallbacks.
- **Build number equals `AppDatabase.schemaVersion`.** The test
  `test/core/database/build_number_matches_schema_test.dart` enforces it. Every
  TestFlight upload therefore bumps both, by hand, in the same commit. An empty
  schema step needs no `onUpgrade` block. The wrapper refuses to build when they
  differ and never bumps anything itself.
- **Never `flutter build ipa`.** `scripts/release.sh` owns archive, export, and
  upload through fastlane.
- **No review-only code.** Screenshots come from a real garden entered through
  the UI. A feature that only exists in builds Apple cannot run counts as an
  undisclosed feature.

## Environment

| Variable | Used by | Meaning |
|---|---|---|
| `APP_STORE_CONNECT_KEY_ID` | all Apple lanes | App Store Connect API key id |
| `APP_STORE_CONNECT_KEY_FILEPATH` | all Apple lanes | path to the `.p8`, outside the repo |
| `APP_STORE_CONNECT_ISSUER_ID` | team keys | issuer id from the Team Keys page |
| `FASTLANE_TEAM_ID` | every lane | developer team id |
| `FASTLANE_ITC_TEAM_ID` | optional | only when the Apple ID belongs to several teams |
| `MATCH_GIT_URL`, `MATCH_PASSWORD` | `setup_signing`, `beta` | private git repo holding certificates and profiles |
| `FASTLANE_APPLE_ID` | `create_app` | Apple ID; produce has no API-key support and asks for the two-factor code |
| `APP_STORE_APP_NAME` | `create_app` | store name if "OpenTomato" is taken |
| `REVIEW_FIRST_NAME`, `REVIEW_LAST_NAME`, `REVIEW_EMAIL`, `REVIEW_PHONE` | `metadata` | App Review contact (personal data, env only); phone in E.164 form |
| `RELEASE_ENV` | wrapper | env file to source, default `~/.config/opentomato/release.env` |

Only a **team** App Store Connect key can run the provisioning endpoints that
match needs. An individual key uploads builds and metadata but cannot create
profiles; use an Apple ID session for signing in that case.

## Lanes

```sh
scripts/release.sh build_local     # archive + export an IPA, no upload
scripts/release.sh beta            # build, sign, upload to TestFlight
scripts/release.sh setup_signing   # create or refresh App Store signing assets
scripts/release.sh create_app      # register the bundle id + app record, once
scripts/release.sh metadata        # upload ios/fastlane/metadata + screenshots
```

The wrapper sources the env file, forces `LC_ALL=en_US.UTF-8` (gym crashes on
a non-UTF-8 locale while parsing xcodebuild output), checks the build number
against the schema version, runs the matching test, warns on a dirty tree, then
runs `bundle exec fastlane ios <lane>` from `ios/`. First run: `bundle install`
(gems go to `vendor/bundle`, git-ignored).

## Order of operations for a first release

Each step below that touches Apple or GitHub is outward-facing and gets an
explicit go-ahead first.

1. Public GitHub repo exists and GitHub Pages serves `docs/` from `main`, so
   the support URL (`/issues`) and privacy policy URL resolve.
2. `create_app`: registers `com.griffith.made.opentomato` with no capabilities
   (no push, no background modes, no App Groups) and creates the app record
   with SKU `opentomato`, primary language en-US.
3. `setup_signing`: App Store distribution certificate and profile via match.
4. In App Store Connect, App Information:
   - Primary category Lifestyle, secondary Utilities.
   - Age Rating questionnaire: every content question **None** (tomatoes only),
     **Age Assurance / In-App Controls: None**, **User-Generated Content: No**
     (the journal is private and device-local, never shared between users).
   - Content rights: no third-party content.
   - Privacy policy URL from `ios/fastlane/metadata/en-US/privacy_url.txt`.
5. Pricing and Availability: Free, all territories, no pre-order.
6. App Privacy: **Data Not Collected**, no tracking. Reasoning: the app has no
   server, no analytics, and no SDK that collects data. Assistant traffic goes
   from the device straight to a provider the user chose with their own key,
   containing text the user reviewed; the developer never receives it.
7. `metadata`: uploads the listing text from `ios/fastlane/metadata/en-US/`
   and the screenshots from `ios/fastlane/screenshots/en-US/`. Review notes
   are in `ios/fastlane/metadata/review_information/notes.txt`; "Sign-in
   required" is No.
8. `beta`: TestFlight internal group. Install on a physical iPhone, connect a
   real Home Assistant, add one real provider key, and walk every screen.
   Confirm with `sqlite3` that no key string exists in the app database.
9. Submit for review only after the checklist below is fully checked and the
   final "Add for Review / Submit" click has been explicitly approved.

## Privacy manifest

`ios/Runner/PrivacyInfo.xcprivacy` is registered in the Runner target's
Resources phase. It declares no tracking, no tracking domains, and no collected
data types. Accessed-API reasons cover what the app and its plugins touch:
file timestamps (`C617.1`, photo files the app itself wrote) and user defaults
(`CA92.1`, plugin preferences). `ITSAppUsesNonExemptEncryption` is `false` in
`Info.plist`: the app uses only HTTPS and the system keychain, which are exempt.

## Screenshots

6.9" iPhone set (1290 × 2796) captured on the iPhone 17 Pro Max simulator in
this order: Today (configured), Plants, Plant detail, Timeline, Grow space
editor, Assistant. Details in `ios/fastlane/screenshots/README.md`.

## Acceptance checklist

- [ ] `flutter analyze --fatal-infos`, `dart format`, tests, `tool/leak_scan.sh --history`, `tool/size_caps.sh` clean at the tagged commit.
- [ ] `pubspec.yaml` build number == `AppDatabase.schemaVersion` (test green).
- [ ] `PrivacyInfo.xcprivacy` present in the built `.app`; `ITSAppUsesNonExemptEncryption` false.
- [ ] No `print()`; no debug-only feature gates; no hidden surfaces.
- [ ] Icon set generated from the final artwork; launch screen matches the brand.
- [ ] Privacy policy URL and support URL resolve publicly.
- [ ] App Privacy answers, description, screenshots, review notes, and the binary describe the same product.
- [ ] Age rating None across the board; Age Assurance None; User-Generated Content No.
- [ ] Assistant consent and disclaimer gates verified on device before the first send.
- [ ] TestFlight build installed and exercised on a physical iPhone with a real Home Assistant and one real provider key.
- [ ] The final review submission has been explicitly approved.

## Troubleshooting

- `couldn't set additional authenticated data` from match: keep
  `force_legacy_encryption` on (already set in the Matchfile and lanes).
- gym fails while parsing xcodebuild output: the locale is not UTF-8; run
  through the wrapper, which exports `LC_ALL`.
- Export picks the wrong profile: match exports
  `sigh_<bundle id>_appstore_profile-name`; the Fastfile reads it and falls
  back to `match AppStore <bundle id>`.
- Provisioning endpoint errors during `setup_signing`: the API key is an
  individual key. Use a team key or an Apple ID session.
