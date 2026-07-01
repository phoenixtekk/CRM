# Implementation Guide

Follow these steps in order. They implement the standard model — **Assess → Configure → Pilot →
Validate → Expand** — for Cisco Secure Client per-app VPN on iOS and Android via Intune. Object names
are fixed; reuse them **verbatim**.

> **Vendor boundary:** the Cisco head-end (server address, connection profile, address pool,
> split-tunnel/split-DNS, posture) is configured in Cisco's consoles per **Cisco's official
> documentation** and is a prerequisite (see requirement R4). Below, you consume its **server
> address / connection name** and **auth method**; you do not build the Cisco side here.

Throughout, "the associated managed apps" means the specific business apps you decided to tunnel.
Fill in your real list before you start, keeping their identifiers handy:

| Your app | iOS bundle ID | Android package name |
|---|---|---|
| (e.g. internal LOB app) | `com.yourorg.lob` | `com.yourorg.lob` |
| (e.g. managed browser) | `com.yourorg.browser` | `com.yourorg.browser` |
| (add rows as needed) | … | … |

---

## Phase 0 — Assess (read-only)

1. Run **`CPAVPN-Discovery.ps1`** (this solution) to inventory existing iOS/Android VPN profiles,
   managed apps, and assignments, and to confirm your Entra groups exist. Read-only; makes no changes.
2. Confirm every requirement in `02-requirements.md` is green — especially **R4** (head-end reachable
   and authenticating a test client) and **R5** (auth material / `Cisco Per-App VPN – User Cert`).
3. Confirm you have the head-end's exact **server address / connection name** and the **auth method**
   it expects (from Cisco docs / your network team).

**Gate:** do not proceed until the Cisco Secure Client can reach and authenticate to the head-end on
a single test device.

---

## Phase 1 — Configure the pilot targeting group

4. Ensure `PILOT – Per-App VPN Users` exists and contains your real testers' enrolled devices. Create/
   populate it in Entra (**Groups → New group → Security**) or run
   **`CPAVPN-Set-ScopeTargeting.ps1`**. Also create `BROAD – Per-App VPN Users` for later expansion.

## Phase 2 — Deploy the client and managed apps to the pilot

5. In Intune → **Apps → All apps**, confirm (or add) **Cisco Secure Client** for **iOS** (App Store /
   VPP) and **Android** (**Managed Google Play**), assigned **Required** to `PILOT – Per-App VPN
   Users` (requirement R3).
6. Confirm (or add) **each of your associated managed apps** for iOS (store/VPP/LOB) and Android
   (Managed Google Play), assigned to `PILOT – Per-App VPN Users` (requirement R2). Note each app's
   **bundle ID / package name**.

## Phase 3 — Deploy authentication material (if certificate auth)

7. Intune → **Devices → Configuration → Create → New policy**: deploy your issuing CA **Trusted
   certificate** root, assigned to `PILOT – Per-App VPN Users`.
8. Create a second policy of type **SCEP certificate** (or **PKCS certificate**) named
   `Cisco Per-App VPN – User Cert`, matching the subject/SAN and EKU the head-end expects, assigned to
   `PILOT – Per-App VPN Users`. Confirm the cert lands on a test device before building the VPN
   profile.

---

## Phase 4 — Build the per-app VPN profile for **iOS**

9. Intune → **Devices → Configuration → Create → New policy**.
   - **Platform:** iOS/iPadOS
   - **Profile type:** Templates → **VPN**
10. **Name:** `Cisco Per-App VPN – iOS`.
11. **Connection type:** **Cisco Secure Client** (formerly Cisco AnyConnect).
12. **Base VPN:**
    - **Connection name:** a label users see (e.g. `Corp Per-App VPN`).
    - **Server:** the head-end **server address / connection name** from R4 (set it as default).
    - **Authentication method:** **Certificates**, and select the client certificate profile
      `Cisco Per-App VPN – User Cert` (or your chosen method to match the head-end).
13. **Automatic VPN → Type of automatic VPN:** **Per-app VPN**. (This is the switch that makes the
    tunnel app-scoped rather than device-wide — do **not** choose On-demand-only/device-wide here.)
14. **On-demand rules:** add a rule so the VPN **connects on demand** when an associated app needs the
    network (e.g. action **Connect** for the associated app domains/traffic). Leave device-wide
    on-demand off.
15. **Safari domains (optional):** if a web app should trigger the tunnel in Safari, add its domain(s).
16. **Assignments:** assign to `PILOT – Per-App VPN Users`. **Create.**

### Associate the managed apps to the iOS profile

17. Associate each iOS managed app with `Cisco Per-App VPN – iOS` so **only those apps** use it:
    - **On the VPN profile:** some tenants expose a **per-app VPN** association list directly on the
      profile — add each app's **bundle ID** there; **or**
    - **On the app assignment:** Intune → **Apps → All apps → (the app) → Properties/Assignments →**
      edit the assignment for `PILOT – Per-App VPN Users` and set **VPN** = `Cisco Per-App VPN – iOS`.
    Do this for **every** app in your associated-apps table above, and **no others**.

**Gate (iOS):** each associated app now references `Cisco Per-App VPN – iOS`; unassociated apps
reference **none**.

---

## Phase 5 — Build the per-app VPN profile for **Android**

18. Intune → **Devices → Configuration → Create → New policy**.
    - **Platform:** Android Enterprise
    - **Profile type:** under the correct management mode (**Work profile** for BYOD, or **Fully
      managed / corporate-owned** for COBO/COPE) → **VPN**
19. **Name:** `Cisco Per-App VPN – Android`.
20. **Connection type:** **Cisco Secure Client** (Cisco AnyConnect).
21. **Base VPN:**
    - **Connection name:** a label (e.g. `Corp Per-App VPN`).
    - **Server:** the head-end **server address / connection name** from R4.
    - **Authentication method:** **Certificates**, selecting `Cisco Per-App VPN – User Cert` (or your
      head-end's method).
22. **Per-app VPN (the association):** set the profile to apply to specific apps — add each associated
    app's **package name** to the **allowed apps** list (allow-list model), so only those managed
    apps route through the tunnel. (If your scenario needs the inverse, use the **excluded apps** list
    instead — but the allow-list is the per-app default here.)
23. **Always-on / on-demand:** configure the desired behavior for the allow-listed apps (on-demand /
    always-on for those apps only — not a device-wide always-on VPN).
24. **Assignments:** assign to `PILOT – Per-App VPN Users`. **Create.**

**Gate (Android):** the allow-list on `Cisco Per-App VPN – Android` contains **exactly** your
associated package names — no more, no less.

---

## Phase 6 — Pilot

25. Let the pilot devices sync (or trigger **Sync** from Intune / Company Portal). Confirm on each
    pilot device:
    - **Cisco Secure Client** installed and managed,
    - the certificate present (if cert auth),
    - `Cisco Per-App VPN – iOS` / `Cisco Per-App VPN – Android` profile installed.
26. Run **`CPAVPN-Validation.ps1 -DeviceName your-pilot-device`** per pilot device to confirm the
    per-app VPN profile is present and the app association state is correct (Graph, read-only).

## Phase 7 — Validate (the pass/fail heart)

27. On a pilot device, **launch an associated app** and access an internal resource. It should connect
    **through the Cisco Secure Client tunnel** (on-demand). **PASS** = associated app reaches internal
    resource via the tunnel.
28. On the same device, use an **unassociated app / general browsing** to a public site. It must go
    **direct** (no tunnel). Confirm via the head-end's connected-client / session view or by checking
    the app's egress. **PASS** = other traffic is direct, not tunneled.
29. Work the full pass/fail matrix in `05-testing.md`. If **all** traffic tunnels, or the app does
    **not** tunnel, stop and use `06-troubleshooting.md` before expanding.

## Phase 8 — Expand

30. Populate `BROAD – Per-App VPN Users` (via `CPAVPN-Set-ScopeTargeting.ps1` or Entra) in waves.
31. Add `BROAD – Per-App VPN Users` to the **Assignments** of `Cisco Per-App VPN – iOS`,
    `Cisco Per-App VPN – Android`, the certificate profile, the Cisco Secure Client app, and each
    associated managed app.
32. Run **`CPAVPN-Report.ps1`** to measure per-app VPN coverage across managed mobile devices; expand
    wave by wave until the fleet is covered.

## Rollback

To revert: remove `PILOT – Per-App VPN Users` (and `BROAD – Per-App VPN Users`) from the
**Assignments** of `Cisco Per-App VPN – iOS` and `Cisco Per-App VPN – Android` (or remove the app↔VPN
association). Devices drop the profile on next sync and return to no-tunnel behavior. Optionally remove
the Cisco Secure Client app. Use **`CPAVPN-Remediation.ps1`** (default `-WhatIf`) to preview any
association fixes before applying.
