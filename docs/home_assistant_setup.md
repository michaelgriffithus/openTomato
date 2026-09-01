# Connecting Home Assistant

OpenTomato reads sensors you already have in Home Assistant. It does not write
to Home Assistant and does not need any add-on.

## 1. Create a long-lived access token

In Home Assistant, open your profile (bottom of the left sidebar), scroll to
**Long-lived access tokens**, and create one named `OpenTomato`. Copy it; it is
shown only once.

## 2. Enter the connection

In OpenTomato, open **Settings → Home Assistant**:

- **Base URL**: the address you use on your home network, for example
  `http://homeassistant.local:8123` or `http://192.168.1.20:8123`.
- **Access token**: paste the token. It is stored in the device keychain, never in
  the app database.
- Tap **Test connection**, then turn on **Enabled**.

Plain `http` on your LAN is fine. If you use `https` with a self-signed
certificate, the connection will fail the TLS handshake; use `http` on the LAN or
a certificate your phone trusts.

## 3. Map a grow space

Open **Settings → Grow spaces** and edit the default space (or add one per
greenhouse, shelf, or bed). Pick the entity for:

- **Temperature** (required)
- **Humidity** (required)
- **VPD** (optional; OpenTomato recomputes VPD from temperature and humidity and
  only uses this as a fallback)
- **Soil moisture** (optional)

The picker lists sensors by their `device_class`. Check the value shown next to
each entity against the physical space before saving: a CPU temperature mapped
as air temperature will poison every derived number.

## How readings are recorded

Your phone is the recorder. While OpenTomato is open it listens to live state
changes over the Home Assistant WebSocket and stores a reading at most once a
minute. When you reopen the app it fills the gap since the last reading from
Home Assistant's history (up to 72 hours, in five-minute buckets), so the chart
and time-in-range stay continuous even though the app cannot run in the
background.
