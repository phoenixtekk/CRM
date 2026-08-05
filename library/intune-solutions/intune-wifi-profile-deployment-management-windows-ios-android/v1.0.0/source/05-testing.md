# 5. Testing & Validation

Validate on the pilot ring before expanding. There are three gates per device: **(A) the profile
deployed**, **(B) the device joined the SSID automatically**, and **(C) the proxy applied correctly**.
Run gate A from the Intune console + scripts; run gates B and C on the device itself. Do **not** expand
to `WIFIMGT - Production Devices` until every gate PASSes on at least one device per platform.

## Gate A — The Wi-Fi profile deployed (console + Graph)

**Console check.** Intune admin center > **Devices** > **Manage devices** > **Configuration** > open
`WIFIMGT - Corp WiFi - Windows - Pilot` (repeat for iOS and Android) > **Device status**.

| PASS | FAIL |
| --- | --- |
| Each pilot device shows **Succeeded**. | Any pilot device shows **Error** / **Conflict** / **Not applicable**. |

- **Conflict** almost always means a second Wi-Fi profile targets the **same SSID** on that device —
  remove the duplicate (see Troubleshooting).
- **Not applicable** usually means the device is the wrong platform/ownership for the profile.

**Script check.** Run the assignment validator (read-only):

```
powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Validate-Assignment.ps1 -ProfileNames `
  'WIFIMGT - Corp WiFi - Windows - Pilot','WIFIMGT - Corp WiFi - iOS - Pilot','WIFIMGT - Corp WiFi - Android - Pilot'
```

**PASS:** each profile lists `WIFIMGT - Pilot Devices` as an assigned group and the expected device
count. **FAIL:** a profile is UNASSIGNED or missing the pilot group.

## Gate B — The device joins the SSID automatically

**Windows.** On a pilot Windows device (do not manually type the password):

1. Open **Settings > Network & Internet > Wi-Fi** — the corporate SSID appears and connects.
2. Confirm the pushed profile exists: `netsh wlan show profiles` lists the SSID.
3. Confirm it is connected: `netsh wlan show interfaces` shows **State : connected** to the SSID.

| PASS | FAIL |
| --- | --- |
| Device auto-connects to the SSID; profile present via `netsh`. | SSID absent from `show profiles`, or device won't associate. |

**iOS/iPadOS.** On a pilot device: **Settings > General > VPN & Device Management** shows the
management profile; **Settings > Wi-Fi** shows the corporate SSID connected without the user entering a
key. **PASS:** connected automatically. **FAIL:** SSID not present or prompts for a password.

**Android Enterprise.** On a pilot device: **Settings > Network & internet > Internet** shows the
corporate SSID connected. **PASS:** connected automatically. **FAIL:** SSID absent or shows
"authentication error" (for Enterprise, check the certificate/RADIUS chain — Requirement R7).

## Gate C — The proxy applied correctly

Only if a proxy is configured in the profile.

**Windows.**
- **Manual proxy:** `netsh winhttp show proxy` (or **Settings > Network & Internet > Proxy**) shows the
  **host + port** you entered — **not** a URL. Confirm the host resolves and the port is reachable.
- **Automatic (PAC):** the PAC URL is shown under **Automatic proxy setup**; browse to an internal site
  and confirm it routes via the proxy.

| PASS | FAIL |
| --- | --- |
| Proxy host+port (manual) or PAC URL (automatic) is present and traffic honors it. | Manual field shows a URL/path (misconfigured), or DNS fails to resolve the "host". |

> **Key check:** if the manual proxy "address" contains a scheme (`http://`) or a path (`/proxy.pac`),
> it is wrong — the whole string is treated as a hostname and fails. Move a PAC URL to the
> **Automatic** field.

**iOS/iPadOS & Android.** Load an internal-only resource that requires the proxy; it succeeds via the
proxy. For manual proxy, confirm the address is a bare host/IP and the port is separate; for automatic,
confirm the PAC URL loads.

## Whole-fleet coverage snapshot

Before and after expansion, run the connectivity/coverage report (read-only):

```
powershell -ExecutionPolicy Bypass -File .\WIFIMGT-Report-Connectivity.ps1
```

**PASS:** reported deployment-state counts for the three profiles trend to **Succeeded** across the
assigned devices with few/no Errors. **FAIL:** a rising Error/Conflict count — investigate before
widening assignment.

## Exit criteria (all must be true to expand)

- [ ] Gate A: all three profiles **Succeeded** on their pilot devices (console + script).
- [ ] Gate B: one device per platform auto-joins the SSID.
- [ ] Gate C: proxy (if any) applied correctly — manual = host+port, automatic = PAC URL.
- [ ] `WIFIMGT-Report-Connectivity.ps1` shows no unexplained Errors/Conflicts.
