# Testing — Pass/Fail Gates

Test on **real** enrolled pilot devices in `PILOT – Per-App VPN Users` — at least one **iOS** and one
**Android** device. Each gate has an explicit **PASS** and **FAIL**. Do not expand to
`BROAD – Per-App VPN Users` until every gate passes on both platforms.

> The core acceptance criterion for this whole solution: **the associated managed apps tunnel;
> everything else stays direct.**

---

## Gate 1 — Client and profile delivered

**Test:** On a pilot device, confirm **Cisco Secure Client** is installed/managed and the profile
`Cisco Per-App VPN – iOS` (or `Cisco Per-App VPN – Android`) is installed. Optionally run
`CPAVPN-Validation.ps1 -DeviceName your-pilot-device`.
**PASS:** Client present and managed; the named per-app VPN profile is present on the device.
**FAIL:** Client missing/unmanaged, or the profile absent → check app assignment (R3), enrollment
(R1), and iOS APNs / Android Managed Google Play (R6/R7). Return to `03-implementation.md` Phase 2.

## Gate 2 — Authentication succeeds

**Test:** Trigger the tunnel (launch an associated app) and confirm it authenticates to the head-end.
**PASS:** The tunnel establishes; the head-end shows a connected session for the test user/device.
**FAIL:** Auth error / no session → verify the certificate profile `Cisco Per-App VPN – User Cert`
landed and its subject/SAN/EKU match what the head-end expects; confirm server address (R4/R5). Cisco
head-end auth policy is deferred to Cisco docs.

## Gate 3 — Associated app tunnels (the primary gate)

**Test:** Launch an **associated managed app** and reach an **internal resource** (intranet host,
internal API, file share URL) that is only reachable via the corporate network.
**PASS:** The internal resource loads **through the Cisco Secure Client tunnel** (on-demand), with a
corresponding session on the head-end.
**FAIL:** Internal resource unreachable / app not tunneling → the app is likely **not associated** or
**not managed**. Confirm the app is Intune-managed and appears in the association (iOS) / allow-list
(Android). See `06-troubleshooting.md` → "VPN not triggering for the app."

## Gate 4 — Other traffic stays direct (the isolation gate)

**Test:** On the **same** device, browse a public site or use an **unassociated** app.
**PASS:** The traffic goes **direct** — **no** tunnel session appears on the head-end for that
traffic, and the device's public egress is its normal internet path, not the corporate egress.
**FAIL:** Public/other traffic is tunneling → the profile is behaving **device-wide**, not per-app.
Confirm iOS **Automatic VPN = Per-app VPN** (not device-wide on-demand) and the Android **allow-list**
contains only your apps. See `06-troubleshooting.md` → "All traffic tunneling."

## Gate 5 — On-demand behavior

**Test:** Close the associated app / let it idle; then reopen it.
**PASS:** The tunnel starts on demand when the associated app needs the network and does not persist
as an always-connected device VPN for unrelated apps.
**FAIL:** Tunnel never starts (on-demand rule missing) or is always-on device-wide (wrong mode) →
revisit on-demand rules (iOS) / always-on-per-app settings (Android) in Phase 4/5.

## Gate 6 — Scope containment

**Test:** Confirm a device/user **outside** `PILOT – Per-App VPN Users` receives **no** per-app VPN
profile.
**PASS:** Only pilot members have the profile; non-members are untouched.
**FAIL:** Non-pilot devices got the profile → check assignment targeting; ensure only
`PILOT – Per-App VPN Users` is assigned during pilot.

## Gate 7 — Coverage report is sane

**Test:** Run `CPAVPN-Report.ps1`.
**PASS:** Reported per-app VPN coverage matches the pilot membership (right devices covered, right
apps associated); no unexpected devices.
**FAIL:** Coverage over/under-reaches expectation → reconcile assignments and associations, re-run.

## Gate 8 — Rollback works

**Test:** In a controlled window, remove `PILOT – Per-App VPN Users` from the profile assignments;
sync a pilot device.
**PASS:** The profile is removed on next sync; associated apps stop tunneling and behave as normal
(direct) apps.
**FAIL:** Profile lingers → force sync / retire-and-re-check; confirm assignment removal saved.

---

### Exit criteria (all must be true, on both iOS and Android)

- Associated managed apps reach internal resources through the tunnel (Gate 3).
- All other traffic is direct (Gate 4).
- On-demand behavior is correct (Gate 5).
- Scope is contained to the pilot group (Gate 6) and the coverage report is accurate (Gate 7).
- Rollback is proven (Gate 8).

Only then assign `BROAD – Per-App VPN Users` and expand in waves.
