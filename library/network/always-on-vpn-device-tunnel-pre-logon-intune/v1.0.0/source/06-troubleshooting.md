# Troubleshooting — Windows Always On VPN Device Tunnel (Pre-Logon) via Intune

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Vendor boundary:** problems on the **VPN gateway head-end** (IKEv2 negotiation fails, the gateway
> rejects the certificate, the gateway's own server certificate/CA trust) are **deferred to
> Microsoft's official documentation and your network team**. This guide resolves the **Intune / Entra
> / Windows / PKI delivery** side and tells you when a failure points at the head-end.

---

## §Device tunnel absent — the `AOVPN Device Tunnel` profile never appears

**Symptom:** After sync/reboot, `Get-VpnConnection -AllUserConnection` does not list
`AOVPN Device Tunnel`, and Intune may still show the Custom profile *Succeeded* (or in error).

1. **Profile assigned to a USER group, not a DEVICE group.** This is the single most common cause. The
   OMA-URI is on the **`./Device/`** path (SYSTEM/device context), so
   `AOVPN – Device Tunnel – ProfileXML – Windows` **must** be assigned to a **device** group
   (`PILOT – AOVPN Device Tunnel – Devices`). A user-group assignment silently does nothing at the
   machine level. Re-assign to the device group (`AOVDT-Discovery.ps1` shows the assignment target;
   `AOVDT-Remediation.ps1 -FixMissingAssignments` adds the device-group assignment).
2. **Device not domain-joined / hybrid-joined, or wrong SKU.** The device tunnel is supported only on
   **Enterprise/Education (1709+)** that is **domain-joined or Entra hybrid-joined** (R2). Confirm with
   `winver` and `dsregcmd /status`. Pure Entra-joined device-tunnel support is emerging/edge — **verify
   for your build**; it may simply not apply.
3. **OMA-URI or profile name mismatch.** The OMA-URI must be exactly
   `./Device/Vendor/MSFT/VPNv2/AOVPN Device Tunnel/ProfileXML` and the profile name inside the XML must
   match `AOVPN Device Tunnel`. A mismatched name produces a profile you can't find by name.
4. **Device not synced.** Force a sync (Intune → device → **Sync**) and **reboot** — the device tunnel
   establishes at boot. Check the Intune Management Extension / MDM diagnostics if it persists.

## §Tunnel not connecting — profile present but `ConnectionStatus` is not Connected

**Symptom:** `AOVPN Device Tunnel` is listed by `Get-VpnConnection -AllUserConnection` but does not
connect at boot / stays *Disconnected*.

1. **Machine certificate missing or wrong.** The device tunnel authenticates with a **machine
   certificate** in `LocalMachine\My` with **Client Authentication** EKU. Run `AOVDT-Validation.ps1`;
   if the certificate is absent or the EKU is wrong, fix the SCEP profile
   (`AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows`) — **Certificate type = Device**, EKU =
   **Client Authentication** — and re-sync. See §Certificate issues.
2. **Head-end doesn't trust the issuing CA (head-end side).** If the client cert is correct but IKEv2
   still fails auth, the **gateway must trust the issuing CA** — this trust config is **head-end-side,
   deferred to Microsoft docs**. Provide your network team the issuing CA chain.
3. **Gateway server certificate / FQDN mismatch (head-end side).** The gateway must present a **Server
   Authentication** certificate whose subject matches the address/FQDN in the ProfileXML, chaining to a
   CA the device trusts (R5/R6). A mismatch or untrusted chain breaks IKEv2.
4. **IKEv2 not reachable.** There is **no SSTP fallback** — if IKEv2 (UDP 500/4500 path to the gateway)
   is blocked from the network the device boots on, the device tunnel simply won't come up. Confirm the
   path with your network team.
5. **Wrong gateway address/FQDN in the ProfileXML.** Verify `<Servers>` matches the head-end
   address/FQDN from R7 and the device can resolve/reach it.

## §Certificate issues

**Symptom:** `AOVPN – Device Tunnel – Machine Cert (SCEP) – Windows` fails, or the tunnel rejects the
certificate.

1. **Trusted root not deployed first.** The device must trust the issuing CA before the SCEP profile
   succeeds. Deploy `AOVPN – Device Tunnel – Trusted Root CA – Windows` **first**, then the SCEP
   profile.
2. **Certificate type is User, not Device.** A user certificate is useless at boot (no user). The SCEP
   profile's **Certificate type** must be **Device** so the cert lands in `LocalMachine\My`.
3. **Missing Client Authentication EKU.** The device tunnel requires **Client Authentication**
   (`1.3.6.1.5.5.7.3.2`) in the SCEP profile's EKU list. Add it and re-issue.
4. **SCEP infrastructure error.** Check NDES / Intune Certificate Connector health and the SCEP server
   URL(s) in the profile. Re-sync after fixing.
5. **Subject/SAN mismatch.** If the head-end matches on subject/SAN, ensure the SCEP profile's
   subject-name format and SAN produce what the head-end expects (coordinate the required format with
   your network team).
6. **Certificate expired (renewal too late).** If the tunnel worked and then stopped, the machine
   certificate may have lapsed. Set a comfortable **renewal threshold** (e.g. 20%) so it renews before
   expiry, and re-issue.

## §Two device tunnels — only one is allowed

**Symptom:** Conflicts / unpredictable device-tunnel behavior; a second ProfileXML also sets
`DeviceTunnel=true`.

1. **Windows allows only ONE device-tunnel profile per device.** Deploying two Custom profiles that
   each set `<DeviceTunnel>true</DeviceTunnel>` conflicts. Keep exactly one
   (`AOVPN – Device Tunnel – ProfileXML – Windows`); remove/scope any other device-tunnel ProfileXML.
   Use pilot vs prod **device** groups to stage — never duplicate the profile.

## §Reporting / script issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes. (`AOVDT-Validation.ps1` is local and needs **no** Graph scopes.)
2. **Objects show MISSING but exist in the portal.** The scripts match **by exact display name** —
   confirm the object is named to convention verbatim (including the en-dash `–` and spacing). Rename
   any drifted object to the convention.
3. **Discovery shows the ProfileXML assigned to a user group.** That is a real problem, not a script
   bug — re-assign to `PILOT – AOVPN Device Tunnel – Devices` (see §Device tunnel absent #1).
4. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions.

---

If a failure persists after the Intune/Entra/PKI side is confirmed healthy (validation PASS, both
certificate profiles *Succeeded*, machine cert present with Client Authentication EKU, ProfileXML
applied in device context) and the tunnel still won't establish or authenticate, treat it as a **VPN
gateway head-end issue** and continue with **Microsoft's official documentation** (RRAS / Azure VPN
Gateway) and your network team.
