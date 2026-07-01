# Troubleshooting — Cisco Secure Client (AnyConnect) VPN via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **Cisco head-end** (tunnel-group rejects the cert, ISE posture
> denies access, gateway config) are **deferred to Cisco's official documentation and your Cisco
> admin**. This guide resolves the **Intune/Entra delivery** side and tells you when a failure points
> at the Cisco side.

---

## §Install failures — the app won't install

**Symptom:** Intune shows `Cisco Secure Client – VPN – (platform)` as *Failed* or stuck *Pending*.

1. **Device not synced / not in the group.** Confirm the device's user (or device) is a member of
   `PILOT – Cisco VPN Users` and the assignment intent is **Required**. Force a sync (Company Portal
   → **Sync**, or `CSCVPN-Remediation.ps1 -RetryFailedInstalls`).
2. **(Windows) Detection rule wrong.** If detection doesn't match what the installer actually writes,
   Intune reports *Failed* even when the client installed. Fix the detection rule (MSI product code
   or the Secure Client core binary path/version) on `Cisco Secure Client – VPN – Win32`.
3. **(Windows) Install command / silent switches wrong.** Verify the install command line installs
   the intended modules silently and returns success (exit 0/3010). Check the Intune Management
   Extension log (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`).
4. **(Windows) Missing module dependency or order.** If you deploy multiple Secure Client modules,
   confirm Core VPN installs first and prerequisites are met.
5. **(macOS) PKG not signed / Gatekeeper.** The PKG must be Cisco-signed (R10). An unsigned/altered
   PKG fails. Re-upload the official signed `.pkg` to `Cisco Secure Client – VPN – macOS PKG`.
6. **(macOS) Bundle-ID/version mismatch for detection.** Supply the exact bundle ID(s)/version Cisco
   documents so Intune detects the install.
7. **(iOS) APNs expired.** If the store app never installs on iOS, check **Tenant administration >
   Connectors and tokens > Apple MDM Push certificate** — renew if expired (R8).
8. **(Android) Managed Google Play not connected / app not approved.** Confirm the connector is
   bound and the Cisco Secure Client app is approved and synced (R9); re-**Sync** apps.

## §Profile not applying — the VPN profile doesn't show up

**Symptom:** `Cisco Secure Client – VPN – Profile – (platform)` shows *Error*/*Conflict*, or the VPN
connection entry never appears on the device.

1. **Profile not assigned to the group.** Confirm the profile is assigned to `PILOT – Cisco VPN
   Users`. `CSCVPN-Discovery.ps1` flags UNASSIGNED profiles; `CSCVPN-Remediation.ps1
   -FixMissingAssignments` adds the assignment.
2. **App not installed yet.** The VPN profile configures the *client*; if the app isn't installed,
   the connection entry may not materialize. Resolve §Install failures first, then re-sync.
3. **Conflicting VPN profile.** Another VPN profile (or a leftover Cisco config) targeting the same
   device can conflict. Remove/scope the conflicting profile so only
   `Cisco Secure Client – VPN – Profile – (platform)` applies.
4. **Wrong connection type / platform.** Ensure the profile's connection type is *Cisco AnyConnect /
   Cisco Secure Client* and the profile platform matches the device OS.
5. **(Windows) Bundled XML vs Intune profile disagree.** If you ship the VPN client profile XML in
   the Win32 package *and* push an Intune VPN profile, keep them consistent (same gateway/behavior);
   contradictions produce confusing client state. Validate with `CSCVPN-Validation.ps1`.
6. **(iOS/Android) VPN permission not granted.** The MDM VPN payload is delivered silently, but the
   user may need to open the client once and allow the VPN configuration. Have the pilot user launch
   the app and accept the prompt.

## §Certificate issues (cert-auth deployments)

**Symptom:** `Cisco Secure Client – VPN – Device Cert (SCEP)` fails, or the VPN rejects the cert.

1. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Deploy the **Trusted certificate** profile, then the SCEP profile.
2. **SCEP infrastructure error.** Check the NDES/Intune Certificate Connector health and the SCEP
   server URL(s) in the profile. Re-sync after fixing.
3. **Subject/SAN mismatch.** If the head-end matches on subject/SAN, ensure the SCEP profile's
   subject-name format and SAN produce what the head-end expects (coordinate the required format with
   your Cisco admin).
4. **Head-end doesn't trust the issuing CA (Cisco side).** If the cert is issued correctly but the
   VPN still rejects it, the **Cisco head-end must trust the issuing CA** — this trust config is
   **Cisco-side, deferred to Cisco docs**. Provide your Cisco admin the issuing CA chain.

## §VPN won't connect — client installed, profile present, but no tunnel

**Symptom:** The user opens Cisco Secure Client, tries to connect, and it fails or times out.

1. **Confirm the delivery side is green first.** Run `CSCVPN-Validation.ps1` on the device: client
   installed + profile present must both PASS. If not, resolve the sections above — this is a
   delivery problem, not a connection problem.
2. **Wrong gateway FQDN / unreachable.** Verify the profile's server matches the gateway from R6 and
   the device can resolve/reach it (DNS + network path). A typo or unreachable gateway is common.
3. **Authentication rejected (Cisco side).** If the tunnel starts but auth fails (cert/SAML/RADIUS
   rejected), the decision is on the **head-end / ISE** — **deferred to Cisco docs**. Capture the
   exact Secure Client error message and the tunnel-group name, and work it with your Cisco admin.
   Common cert cause is head-end CA trust (see §Certificate issues #4).
4. **SAML/Entra SSO loop or failure.** For SAML auth, confirm the head-end's SAML app in Entra is
   configured and the user has access; the Intune side only delivers client+profile.
5. **Split/full tunnel or Per-App scope surprises.** If the tunnel is up but an internal resource is
   unreachable, check the tunnel mode and Per-App VPN scope in the profile (R6) — the app/resource
   may not be routed through the tunnel.
6. **Client/head-end version mismatch.** If the head-end requires a newer/older client than deployed,
   align the packaged version (R4) with what the head-end supports and re-pilot.

## §Reporting/script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** —
   confirm the object is named to convention verbatim (including the en-dash `–` and spacing).
   Rename any drifted object to the convention.
3. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions.

---

If a failure persists after the Intune/Entra side is confirmed healthy (validation PASS, profile
*Succeeded*, cert issued) and the tunnel still won't establish or authenticate, treat it as a
**Cisco head-end issue** and continue with **Cisco's official documentation** and your Cisco admin.
