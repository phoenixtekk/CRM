# Troubleshooting — Windows Always On VPN: User Tunnel with Conditional Access via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **VPN gateway / head-end** (RRAS or Azure VPN Gateway rejects the
> EAP handshake, IP pool exhausted, routing/NAT) are **deferred to Microsoft's official documentation and
> your network admin**. This guide resolves the **Intune/Entra delivery + Conditional Access** side and
> tells you when a failure points at the head-end.

> **Companion boundary:** deep certificate-lifecycle problems (issuing-CA design, NDES/Cloud PKI health,
> revocation) are covered by the companion device-tunnel product; this section resolves the **user
> certificate delivery** needed for the tunnel.

---

## §Tunnel not auto-connecting — profile present but no automatic connection

**Symptom:** `AOVPN User Tunnel` appears under **Settings > Network & internet > VPN** but stays
*Disconnected* until the user clicks Connect (or never connects).

1. **Always On not enabled.** The most common cause. Confirm the VPN profile
   `AOVPN – User Tunnel – Profile – Windows` has **Always On = Enable**. Re-save and re-sync; have the
   user sign out and back in so the tunnel re-evaluates.
2. **Trusted Network Detection matches the current network.** If the **Trusted Network Detection** DNS
   suffix (R6) matches the network the device is on, Windows **intentionally suppresses** the tunnel
   (you're "already inside"). Test from an external network, or confirm the suffix is your *corporate*
   suffix, not the current one.
3. **User certificate missing / not selected.** Auto-connect needs a valid **user** cert in
   `CurrentUser\My`. Run `AOVUT-Validation.ps1`; if the cert is missing, resolve §Certificate issues.
4. **Signed in with the wrong user / cert not for this user.** The user tunnel is per-user; confirm the
   signed-in user is a member of `PILOT – AOVPN User Tunnel Users` and holds the user cert.
5. **EAP configuration mismatch.** If the profile's EAP/authentication doesn't match what the head-end
   expects, the tunnel starts and drops. Confirm the connection type (Automatic/IKEv2) and EAP-cert
   settings against R6; if the handshake reaches the gateway and fails there, it's a **head-end** issue
   (deferred to Microsoft docs).

## §Profile not applying — the VPN profile doesn't show up

**Symptom:** `AOVPN – User Tunnel – Profile – Windows` shows *Error*/*Conflict*, or the `AOVPN User
Tunnel` connection never appears on the device.

1. **Profile not assigned to the user group.** Confirm the profile is assigned to `PILOT – AOVPN User
   Tunnel Users`. `AOVUT-Discovery.ps1` flags UNASSIGNED profiles; `AOVUT-Remediation.ps1
   -FixMissingAssignments` adds the assignment.
2. **Assigned to a device group instead of a user group.** The **user** tunnel must be **user-assigned**.
   If you targeted a device group, the profile may not materialize for the user tunnel — reassign to the
   user group.
3. **Conflicting VPN profile.** Another VPN profile (or a leftover AOVPN config) on the device can
   conflict. Remove/scope the conflicting profile so only `AOVPN – User Tunnel – Profile – Windows`
   applies.
4. **Wrong platform / template.** Ensure the profile is **Windows 10 and later → Templates → VPN** and
   the device is Windows 10/11 Enterprise/Education.

## §Certificate issues — the user certificate won't issue or the tunnel rejects it

**Symptom:** `AOVPN – User Tunnel – User Cert (SCEP) – Windows` fails, or the tunnel rejects the cert.

1. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Confirm `AOVPN – User Tunnel – Trusted Root CA – Windows` shows *Succeeded*, then re-sync the
   SCEP profile.
2. **Certificate type not User.** The user tunnel needs a **User** certificate. Confirm the SCEP profile's
   **Certificate type = User** (not Device).
3. **SCEP infrastructure error.** Check the NDES/Intune Certificate Connector (or Cloud PKI) health and
   the SCEP server URL(s) in the profile. (Full PKI health is the companion device-tunnel product.)
4. **Subject/SAN mismatch.** If the head-end matches on subject/SAN, ensure the SCEP profile's
   subject-name format and SAN produce what the head-end expects (e.g. SAN = UPN).
5. **Missing Client Authentication EKU.** The cert must include the **Client Authentication** EKU for EAP;
   add it to the SCEP profile and re-issue.
6. **Head-end doesn't trust the issuing CA (Microsoft side).** If the cert is issued correctly but the
   tunnel still rejects it, the **VPN gateway must trust the issuing CA** — head-end trust config is
   **deferred to Microsoft docs**. Provide your network admin the issuing CA chain.

## §Conditional Access blocking legitimate users

**Symptom:** Pilot users on compliant devices are blocked from the corporate app the tunnel fronts, or see
repeated MFA/compliance prompts.

1. **Policy scope too broad.** Confirm `CA – AOVPN User Tunnel Access` targets the **specific** cloud
   app(s) — not "All cloud apps" — and only `PILOT – AOVPN User Tunnel Users` during the pilot.
2. **Device not actually compliant.** The grant **Require device to be marked as compliant** needs a
   compliance policy (R8) that the device passes. Check Intune → **Devices > Compliance**; a device that
   isn't evaluated compliant will be blocked. Fix compliance or add **hybrid joined** as an alternative
   grant.
3. **Grant requires controls the device can't meet.** If you require compliant **AND** hybrid-joined on an
   Entra-joined (not hybrid) device, it fails. Use **Require one of the selected controls** so either
   satisfies.
4. **Enforced before validation.** Always run the policy **Report-only** first (Implementation §2.4) and
   review the Insights workbook; only turn it **On** after T6 passes. To stop enforcement instantly, flip
   it back to **Report-only**.
5. **Break-glass excluded?** Confirm your emergency-access accounts are in the policy's **Exclude** list so
   a misconfiguration can never lock everyone out.

## §SSTP used instead of IKEv2

**Symptom:** The tunnel connects but over **SSTP** (TCP 443) rather than the preferred **IKEv2**.

1. **UDP 500/4500 blocked on the path.** IKEv2 needs **UDP 500 and 4500**; if a firewall/NAT on the
   client's network blocks them, Windows falls back to **SSTP** (this is by design when connection type is
   *Automatic*). Allow UDP 500/4500 end to end to prefer IKEv2, or accept SSTP fallback where that's not
   possible.
2. **Connection type is Automatic (expected fallback).** With *Automatic*, SSTP fallback is intended
   behavior. If you require IKEv2 only, set the profile's connection type to **IKEv2** — but then clients
   on UDP-blocked networks won't connect at all.
3. **Head-end SSTP/IKEv2 listener config.** Which protocols the gateway offers is a **head-end** setting
   (deferred to Microsoft docs); confirm both IKEv2 and SSTP are configured if you want fallback.

## §Reporting/script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph -Scope
   CurrentUser`) and consent to the scopes each script lists in its header. Reading the Conditional Access
   policy needs `Policy.Read.All`; read-only inventory needs only `.Read.All` scopes.
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** — confirm
   the object is named to convention verbatim (including the en-dash `–` and spacing). Rename any drifted
   object to the convention.
3. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with `-WhatIf:$false`
   after reviewing the previewed actions.

---

If the tunnel still won't establish after the Intune/Entra side is confirmed healthy (validation PASS,
profile *Succeeded*, user cert issued and chaining) and the handshake reaches the gateway and fails there,
treat it as a **VPN gateway / head-end issue** and continue with **Microsoft's official documentation**
and your network admin.
