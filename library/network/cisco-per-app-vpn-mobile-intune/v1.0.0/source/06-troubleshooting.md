# Troubleshooting

Symptom-first fixes for Cisco Secure Client per-app VPN on managed iOS/Android via Intune. Work the
Intune side precisely; where a cause is clearly **Cisco head-end** (routing, address pool, posture,
ISE policy), that is **deferred to Cisco's official documentation** — this guide points you there but
does not fabricate Cisco menu paths.

Run `CPAVPN-Validation.ps1 -DeviceName your-device` and `CPAVPN-Discovery.ps1` first — they surface
most of these causes read-only.

---

## Symptom 1 — VPN not triggering for the app

The associated app opens but does **not** reach the internal resource / no tunnel starts.

**Check, in order:**
1. **Is the app Intune-managed?** The association only works for the **managed** instance. On iOS a
   personally installed copy will not tunnel. Confirm the app appears under Intune → **Apps → All
   apps** assigned to `PILOT – Per-App VPN Users`, and that the copy on the device is the managed one
   (requirement R2).
2. **Is the app actually associated?** Confirm the app references `Cisco Per-App VPN – iOS`
   (iOS: on the app assignment's **VPN** field or the profile's per-app list) or is in the
   `Cisco Per-App VPN – Android` **allow-list** by exact **package name** (Android). A typo'd bundle
   ID / package name silently drops the association. `CPAVPN-Validation.ps1` lists the associated apps.
3. **Is the profile applied to the device?** `CPAVPN-Validation.ps1` should show the profile present.
   If not, check assignment to `PILOT – Per-App VPN Users`, enrollment (R1), and iOS APNs / Android
   Managed Google Play (R6/R7). Force a **Sync**.
4. **On-demand rule missing (iOS).** If the profile is present but nothing connects, confirm the
   **On-demand** rule exists so the tunnel connects when the associated app needs the network
   (Implementation Phase 4, step 14).
5. **Client not installed.** Confirm **Cisco Secure Client** is installed and managed (R3) — the
   profile can't bind without it.
6. **Auth failing at the head-end.** If the tunnel starts then drops, this is usually authentication —
   see Symptom 4.

## Symptom 2 — All traffic tunneling (device-wide instead of per-app)

Public browsing and unassociated apps are going through the tunnel — the isolation gate (Testing
Gate 4) fails.

**Check, in order:**
1. **iOS profile is device-wide, not per-app.** In `Cisco Per-App VPN – iOS`, confirm **Automatic
   VPN → Type of automatic VPN = Per-app VPN** — **not** a device-wide On-demand VPN. A device-wide
   on-demand rule with a broad match will tunnel everything. Rebuild the automatic-VPN section per
   Implementation Phase 4, step 13.
2. **Android allow-list too broad / inverted.** In `Cisco Per-App VPN – Android`, confirm you used the
   **allowed apps (allow-list)** containing only your package names — not an empty allow-list (which
   can behave as "all"), and not an **excluded-apps** model that leaves everything else tunneling.
   Fix the list (Implementation Phase 5, step 22).
3. **Always-on device VPN set.** Confirm you did not enable a device-wide **always-on** VPN. Per-app
   on-demand should engage per app, not for the whole device.
4. **Split-tunnel at the head-end (Cisco side — deferred).** If the profile is correctly per-app but
   the *associated* app's traffic is pulling in more than expected, the head-end's split-tunnel /
   split-DNS policy may be sending broad routes. Review the head-end's tunnel policy **per Cisco
   docs**.

## Symptom 3 — App not associated

The app tunnels for no one, or the association simply won't stick / doesn't appear.

**Check, in order:**
1. **Exact identifier mismatch.** The association keys on the **bundle ID (iOS)** / **package name
   (Android)**. Confirm the identifier on the association exactly matches the app's real identifier
   (from `CPAVPN-Discovery.ps1`'s managed-apps list). One character off = no association.
2. **Association set in the wrong place (iOS).** iOS association can live on the **VPN profile's**
   per-app list **or** on the **app assignment's VPN field** — set it in the place your tenant
   exposes, and don't split it across both inconsistently (Implementation Phase 4, step 17).
3. **App not assigned to the same group.** The app and the VPN profile must both target
   `PILOT – Per-App VPN Users`. If the app is assigned to a different group than the profile, the
   device may have one without the other.
4. **Use remediation to reconcile.** Run
   `CPAVPN-Remediation.ps1 -IntendedApps your-bundle-id,your-package-name` (default `-WhatIf`) to see
   the ADD/REMOVE diff between the intended app set and what's currently associated, then re-run with
   `-Apply`.

## Symptom 4 — Tunnel starts then fails to authenticate

**Check, in order:**
1. **Certificate present?** Confirm `Cisco Per-App VPN – User Cert` (and the trusted root) deployed to
   the device (R5). An expired or missing client cert breaks every associated app at once.
2. **Cert subject/SAN/EKU mismatch.** The head-end expects a specific certificate shape. Match the
   Intune SCEP/PKCS profile's subject/SAN and EKU to the head-end's expectation (**per Cisco docs**).
3. **Wrong server / connection name.** Confirm the **Server** value in the VPN profile is the correct
   head-end **server address / connection name** from R4.
4. **Head-end policy (Cisco side — deferred).** If Intune-side auth material is correct but the
   head-end rejects the session, the connection profile / ISE authorization policy is the place to
   look — **deferred to Cisco documentation**.

## Symptom 5 — Profile not reaching the device at all

1. **iOS:** check **APNs** certificate validity and that the device is **supervised (ADE)** (R6);
   without APNs no iOS policy is delivered.
2. **Android:** check **Managed Google Play** is connected and the device is enrolled in Android
   Enterprise (R7).
3. **Assignment / compliance:** confirm the device's user/device is in `PILOT – Per-App VPN Users` and
   the device is compliant (R1). Force **Sync** from Company Portal / Intune.

---

### When to escalate to the Cisco side

If the Intune profile is correct (per-app mode, right association, right server, cert present) but
tunnels still misbehave — broad routing, posture blocks, address-pool exhaustion, or authorization
rejects — the cause is on the **Cisco head-end / ISE**. Escalate there and follow **Cisco's official
documentation**; keep the Intune profile's server address in sync with any head-end change.
