# Implementation — Windows Always On VPN: User Tunnel with Conditional Access via Microsoft Intune

This is the ordered, click-by-click build. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Do **not** skip the pilot. Use the **exact object
names** shown — later steps, tests, troubleshooting, and scripts reference them verbatim.

> **Vendor boundary:** the VPN gateway / head-end (Windows Server **RRAS** or an **Azure VPN Gateway**),
> its IKEv2/SSTP listener, and EAP/certificate acceptance are **deferred to Microsoft's official
> documentation**. This guide covers the Intune and Entra side at full detail and *consumes* the
> head-end values (gateway FQDN, accepted auth, routes) and the PKI inputs (SCEP URL, issuing/root CA)
> as inputs.

> **Companion boundary:** the **device tunnel** and the **full certificate lifecycle** are the companion
> device-tunnel product. Here the **user** certificate (§2.2) and its trusted root (§2.1) are built
> **leanly** and cross-referenced — enough to authenticate the user tunnel, not a PKI course.

## Object naming convention (use verbatim)

| Object | Name |
|---|---|
| Pilot user group | `PILOT – AOVPN User Tunnel Users` |
| Production user group | `PROD – AOVPN User Tunnel Users` |
| Trusted Root CA profile | `AOVPN – User Tunnel – Trusted Root CA – Windows` |
| User SCEP certificate profile | `AOVPN – User Tunnel – User Cert (SCEP) – Windows` |
| VPN template profile | `AOVPN – User Tunnel – Profile – Windows` |
| Connection name shown to the user | `AOVPN User Tunnel` |
| Conditional Access policy | `CA – AOVPN User Tunnel Access` |
| Assignment filter (optional) | `Filter – AOVPN User Tunnel – Windows` |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Gather the head-end inputs (from your network/VPN team, per Microsoft docs):
   - **Gateway FQDN** (e.g. `vpn.your-company.com`)
   - **Connection type** — *Automatic* (IKEv2 with SSTP fallback), or *IKEv2*
   - **Authentication method** — **user certificate (EAP)**
   - **Split-tunnel routes**, **DNS suffix/servers**, and the **Trusted Network Detection** DNS suffix
   - The **SCEP server URL(s)** and the **root/issuing CA** for the user certificate
3. Decide the pilot audience (3–10 users on Windows 10/11 Enterprise/Education).
4. Run the discovery script to baseline readiness:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Discovery.ps1`
   Review its readiness table before building anything.

**Gate A (Assess):** All requirements pass, all head-end and PKI inputs recorded, discovery shows the
tenant is ready (a Windows compliance policy exists; Conditional Access is available). If not, stop and
remediate.

---

# Phase 2 — Configure

## 2.0 Create the target user groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Set-ScopeTargeting.ps1`
  (creates `PILOT – AOVPN User Tunnel Users` and `PROD – AOVPN User Tunnel Users` and adds the **users**
  you supply by UPN).
- **Portal:** Entra admin center → **Groups > New group > Security** → name `PILOT – AOVPN User Tunnel
  Users` → add pilot **users** → **Create**. Repeat for `PROD – AOVPN User Tunnel Users`.

## 2.1 Deploy the trusted root CA (build leanly)

The device must trust the issuing CA chain before the user certificate and the tunnel validate.

1. Intune → **Devices > Configuration > Create > New Policy**.
2. **Platform:** *Windows 10 and later*; **Profile type:** *Templates* → **Trusted certificate**.
3. Name it exactly `AOVPN – User Tunnel – Trusted Root CA – Windows`.
4. Upload the exported **root (and issuing, if separate) CA** `.cer` (from R5); set the destination store
   to **Computer certificate store – Root** (use an Intermediate profile as well if your issuing CA is
   separate).
5. **Assign** to `PILOT – AOVPN User Tunnel Users`. **Review + create.**

> Full PKI trust design (root vs. issuing, cross-signing, revocation) is the companion device-tunnel
> product; this step just establishes the trust the user tunnel needs.

## 2.2 Create the user SCEP certificate profile (build leanly)

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** → **Templates >
   SCEP certificate** (use **PKCS certificate** instead if that is your path).
2. Name it exactly `AOVPN – User Tunnel – User Cert (SCEP) – Windows`.
3. **Certificate type:** **User**.
4. **Subject name format** and **SAN** per your head-end's matching requirements (e.g. subject = CN of the
   user, SAN = UPN).
5. **Key usage** / key size / hash per your PKI; **Extended key usage:** include **Client Authentication**.
6. **Root Certificate:** select the `AOVPN – User Tunnel – Trusted Root CA – Windows` profile from §2.1.
7. **SCEP Server URLs:** the SCEP URL(s) from R4.
8. **Assign** to `PILOT – AOVPN User Tunnel Users`. **Review + create.** (The issuing CA must be trusted
   by the VPN gateway — head-end trust config is deferred to Microsoft docs.)

## 2.3 Build the user-tunnel VPN profile (built-in VPN template)

1. Intune → **Devices > Configuration > Create > New Policy** → **Windows 10 and later** → **Templates >
   VPN**.
2. Name it exactly `AOVPN – User Tunnel – Profile – Windows`.
3. **Connection name:** `AOVPN User Tunnel` (this is what the user sees).
4. **Servers:** add the **gateway FQDN** from R6; mark it **Default**.
5. **Connection type:** *Automatic* (IKEv2 with SSTP fallback), or *IKEv2* if you require IKEv2 only.
6. **Always On:** **Enable** — this makes it a user tunnel that connects automatically when the user signs
   in. Leave *device tunnel* **off** (device tunnel is the companion product).
7. **Authentication method:** **EAP** → **user certificate**; select/point at the user certificate issued
   by `AOVPN – User Tunnel – User Cert (SCEP) – Windows` (the EAP XML references a client cert in
   `CurrentUser\My`).
8. **Trusted Network Detection:** add the corporate **DNS suffix** (from R6) so the tunnel suppresses on
   the corporate LAN.
9. **Split tunnel / routes:** add the corporate **routes** and **DNS** from R6 (enable split tunneling for
   the corporate ranges).
10. **Assign** to `PILOT – AOVPN User Tunnel Users`. Optionally attach `Filter – AOVPN User Tunnel –
    Windows` to scope by Windows edition/ownership. **Review + create.**

## 2.4 Create the Conditional Access policy (gate the tunnel)

Create the policy in **report-only** first so you can watch its impact before enforcing.

1. Entra admin center → **Protection > Conditional Access > Policies > New policy**.
2. Name it exactly `CA – AOVPN User Tunnel Access`.
3. **Users:** *Include* → **Select users and groups** → `PILOT – AOVPN User Tunnel Users`. Under
   *Exclude*, add your break-glass/emergency-access accounts.
4. **Target resources:** *Cloud apps* → **Select apps** → choose the corporate cloud app(s) reached over
   the tunnel (and, where you use it, the VPN server's Entra app). Do **not** target "All cloud apps"
   during the pilot.
5. **Conditions (optional):** scope **Device platforms** to **Windows** if you want this policy Windows-only.
6. **Grant:** **Grant access** → check **Require multifactor authentication** *and* **Require device to be
   marked as compliant** (add **Require Microsoft Entra hybrid joined device** with the **Require one of
   the selected controls** option if you support hybrid-joined). This ties access to a compliant/trusted
   device (R8).
7. **Enable policy:** **Report-only** for the pilot.
8. **Create.**

**Gate B (Configure):** The trusted-root profile, the user SCEP profile, the VPN profile (named to
convention and assigned to `PILOT – AOVPN User Tunnel Users`), and the Conditional Access policy
`CA – AOVPN User Tunnel Access` (report-only, scoped to the pilot users) all exist. Re-run
`AOVUT-Discovery.ps1` — every expected object should now be found.

---

# Phase 3 — Pilot

1. Ensure the pilot users are members of `PILOT – AOVPN User Tunnel Users`, signed in on enrolled,
   **compliant** Windows 10/11 Enterprise/Education devices.
2. Trigger a sync (Company Portal → **Sync**, or Intune → device → **Sync**) to pull the trusted root, the
   user certificate, and the VPN profile.
3. Allow time for the certificate to issue and the profile to apply (minutes). Have the pilot user **sign
   out and back in** so the user tunnel evaluates and auto-connects.
4. Confirm the connection `AOVPN User Tunnel` appears under **Settings > Network & internet > VPN** and
   shows **Connected** after sign-in.

**Gate C (Pilot):** Every pilot device shows the user SCEP cert *Succeeded*, the VPN profile *Succeeded*,
and the `AOVPN User Tunnel` connection auto-connects in Intune monitoring / on the device. If any fail, go
to `06-troubleshooting.md` before proceeding.

---

# Phase 4 — Validate

1. On a pilot device, signed in as the pilot user, run:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Validation.ps1`
   It confirms the `AOVPN User Tunnel` VPN connection is present (Always On) and a valid **user**
   certificate is in `CurrentUser\My` on *this* device.
2. Perform the manual tests in `05-testing.md` — the tunnel auto-connects on sign-in, the Conditional
   Access challenge behaves, and an internal-only resource is reachable **only** from a compliant device.
3. Review the **Conditional Access > Insights and reporting (report-only)** workbook for
   `CA – AOVPN User Tunnel Access` to confirm it *would* grant compliant devices and block non-compliant
   ones — with no unexpected lockouts.
4. Run the fleet report to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\AOVUT-Report.ps1`

**Gate D (Validate):** On the pilot, the user certificate issues, the VPN profile applies, the tunnel
**auto-connects on sign-in**, an internal resource is reachable, and the report-only Conditional Access
policy shows the intended compliant-allow / non-compliant-block behavior with no false lockouts. All
Testing guide pass/fail gates are green. Only then proceed.

---

# Phase 5 — Expand

1. For the trusted-root, user SCEP, and VPN profiles, **add** `PROD – AOVPN User Tunnel Users` to the
   assignment. Keep `PILOT – AOVPN User Tunnel Users` assigned (pilot users stay covered).
2. Edit `CA – AOVPN User Tunnel Access`: add `PROD – AOVPN User Tunnel Users` to the included users, then
   switch **Enable policy** from **Report-only** to **On**. Keep the break-glass exclusion.
3. Expand in waves if the fleet is large (add production sub-groups over several days) and watch the
   report and the Conditional Access sign-in logs between waves.
4. Monitor with `AOVUT-Report.ps1` for coverage and with Intune **Devices > Configuration** for profile
   success and Entra **Sign-in logs** for Conditional Access results.
5. Remediate stragglers with `AOVUT-Remediation.ps1` (defaults to **-WhatIf** preview — review, then
   re-run with `-WhatIf:$false` to act).

**Rollback (any phase):** Remove/exclude the target group from the VPN, SCEP, and trusted-root profile
assignments; flip `CA – AOVPN User Tunnel Access` back to **Report-only** (or exclude the affected group)
to stop enforcement immediately. Unassigning the profiles removes the tunnel and user certificate.

**Gate E (Expand):** Fleet coverage meets your target (e.g. ≥ 95% of assigned users' devices with the VPN
profile *Succeeded* and a valid user cert), the Conditional Access policy is **On** with no unexpected
lockouts, and remaining failures are triaged. Deployment is complete.
