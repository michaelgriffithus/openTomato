# App Store screenshots

Captured by hand on the iPhone 17 Pro Max simulator (native 1320 × 2868, which
App Store Connect accepts for the 6.9" slot). The garden is invented and was
entered through the UI: two plants with generated photos, stage changes, and
journal entries. Readings come from a small fake Home Assistant and the chat answer from a
fake OpenAI-compatible server (Python scripts kept outside the repo, pointed at
through the app's own base-URL field), so no real host, token, key, or entity
id appears anywhere. No seed flag or review-only data
ships in the binary. Status bar set with
`xcrun simctl status_bar <udid> override --time 9:41 ...`.

| File | Screen |
|---|---|
| `en-US/01_today.png` | Today, live readings in range, time-in-range, VPD trace |
| `en-US/02_plants.png` | Plants |
| `en-US/03_plant_detail.png` | Plant detail (Sungold, flowering, photo) |
| `en-US/04_timeline.png` | Timeline |
| `en-US/05_grow_space.png` | Grow space editor with sensors mapped |
| `en-US/06_assistant_setup.png` | AI provider settings, key saved (placeholder string), extra instructions |
| `en-US/07_assistant_consent.png` | Consent screen showing the exact context block |
| `en-US/08_assistant_chat.png` | A conversation (answer served by a fake OpenAI-compatible server) |
| `en-US/09_settings.png` | Settings |
| `en-US/10_privacy.png` | Privacy screen |

`scripts/release.sh metadata` uploads whatever is here alongside the listing
text in `../metadata`.
