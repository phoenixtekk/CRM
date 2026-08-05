# 6. Troubleshooting

Quick fixes for the common Wi-Fi profile deployment failures. For **deep "the profile deployed but the
change isn't reflected on the device" diagnosis** (sync timing, per-setting conflicts, remediation of
stuck Wi-Fi changes), use the companion **Intune Wi-Fi Profile Remediation — "changes not applying"**
troubleshooting product rather than reproducing that full diagnostic here.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Profile shows **Conflict** on a device | Two Wi-Fi profiles target the **same SSID** on that device | Intune won't target two same-SSID profiles to one device. Remove/supersede the duplicate so only one active profile carries that SSID. |
| Profile shows **Not applicable** | Wrong platform or Android ownership mode for the profile | Confirm the device platform; for Android, confirm corporate-owned vs personally-owned work profile matches the profile type you created. |
| Device won't associate to the SSID | Wrong SSID or wrong pre-shared key | Re-check the **SSID** (exact broadcast name) and the **Pre-shared key** against the network facts; a single wrong character fails silently. |
| **Proxy not working / no internet on the network** | A URL/path was entered in the **manual** proxy address field | Manual proxy = **host/IP + port only** (no `http://`, no `/path`). Move any PAC URL to the **Automatic** field. |
| Automatic proxy ignored | PAC URL unreachable or malformed | Confirm the **PAC-file URL** loads from the device's network and returns a valid PAC script. |
| **Enterprise (802.1X) auth fails** though the profile deployed | Missing/mismatched certificate or trusted-root, or RADIUS not accepting EAP | Verify the client-cert and trusted-root profiles are assigned to the same devices and the RADIUS (e.g. Cisco ISE) policy accepts EAP for the SSID — see the companion **Cisco ISE 802.1X** solution. |
| Android work-profile EAP profile fails to deploy | Client certificate **SAN lacks the UPN** | Reissue the certificate so its Subject Alternative Name includes the user principal name (UPN). |
| Android device shows no manual proxy option | It's a **personally-owned work profile** | Manual proxy is unavailable on BYOD work profiles — use an **Automatic (PAC URL)** proxy instead. |
| Changed **trusted root**, devices dropped off Wi-Fi | No backup internet path to deliver the updated profile | Ensure devices have a second internet connection (e.g. cellular/another SSID) so the updated profile lands, then reconnect. |
| Change made in the console but device still on old settings | Device hasn't checked in yet | Wait for the next sync (or force a sync); if it persists, use the companion **"changes not applying"** troubleshooting product. |
| `WIFIMGT-*` script errors on connect | Wrong cloud environment or missing scopes | Re-run with `-Environment USGov`/`USGovDoD` for Government tenants; consent to the read scopes when prompted. |

## First diagnostic pass
1. Run `WIFIMGT-Validate-Assignment.ps1` — confirm the named profile is assigned to the pilot/prod
   group.
2. Run `WIFIMGT-Report-Connectivity.ps1` — see the Succeeded/Error/Conflict split across the fleet.
3. On one failing device, walk **Gate B** and **Gate C** from `05-testing.md` (device-side `netsh`
   checks on Windows; Settings on iOS/Android).
4. If the profile is assigned and shows **Succeeded** but the device behavior is wrong, hand off to the
   companion **"changes not applying"** troubleshooting product.
