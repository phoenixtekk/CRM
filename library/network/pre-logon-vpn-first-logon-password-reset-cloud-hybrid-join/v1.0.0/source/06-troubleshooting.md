# Troubleshooting — Pre-Logon VPN: First-Logon & Off-Network Password Reset

Common failures and fixes, grouped by symptom. Object names match the Implementation guide. Work
top-down within a section — the first cause listed is the most common.

> **Scope boundary:** the pre-logon tunnel itself is built in the **companion products** (device
> tunnel / SBL-PLAP) and gateway/head-end internals are deferred to those products and the vendor's
> official documentation. This guide resolves the **decision + scenario** problems — first-logon,
> off-network password change, join-type confusion, and DC reachability — and tells you when a failure
> points back at the companion build or the network.

---

## §First logon still fails — the never-logged-on user can't sign in off-network

**Symptom:** A freshly provisioned device with a user who has never signed in shows "There are
currently no logon servers available to service the logon request" (or similar) off-network.

1. **Tunnel not up *before* credentials are submitted.** The DC path must exist **at** the credential
   prompt. For the **device tunnel**, confirm it comes up automatically at boot/logon screen
   (`Get-VpnConnection -AllUserConnection` shows it; it must be a **device/machine** tunnel, not a user
   tunnel). For **SBL/PLAP**, the user must bring up the pre-logon VPN at the logon screen **first**,
   then submit credentials — if they type credentials before connecting, there is no DC path yet.
2. **DC not reachable through the tunnel.** Even with the tunnel up, the DC subnets/DNS may not route
   through it. Run `PREVPN-Validation.ps1` (DC check) or `nltest /dsgetdc:<domain>` with the tunnel up.
   Fix routes/split-tunnel and DNS so the DC is reachable, and open the AD ports (DNS 53, Kerberos 88,
   LDAP 389, etc.) from the VPN client range to the DCs (network/companion task).
3. **Wrong approach for the join type.** If the device is **Entra-joined (cloud-only)**, it does **not**
   use an on-prem DC and does not need a pre-logon tunnel — a "failure" here usually means the device
   was mis-identified. Confirm with `dsregcmd /status` (`AzureAdJoined=YES` + `DomainJoined=NO` =
   Entra-joined). If it is genuinely hybrid/domain-joined, ensure the chosen approach's object is
   deployed and assigned.
4. **(Device tunnel) machine cert missing/invalid.** No valid **LocalMachine\My** cert that the gateway
   trusts → the silent tunnel never authenticates, so no DC path at logon. Fix the machine-cert profile
   in the companion device-tunnel product (`PREVPN-Validation.ps1 -RequireCertificate` confirms).
5. **(Device tunnel) OS SKU not Enterprise/Education.** The device tunnel is unsupported on Windows
   Pro/Home. Confirm the SKU (R6) or switch that device to SBL/PLAP.
6. **Cached-credential misunderstanding.** Cached credentials only help a user who has **already**
   signed in on that device. A never-logged-on user has nothing cached and **requires** a live DC path
   — this is expected, not a bug; the fix is the pre-logon tunnel, not cached-credential settings.

## §Password change fails — expired password won't change off-network

**Symptom:** At the logon/lock screen off-network, the user cannot change an expired password
("Unable to update the password. The value provided … does not meet …" is a *policy* error; "no DC"
is a *reachability* error).

1. **No DC path at the moment of change.** The AD password change must reach a DC. Bring the pre-logon
   tunnel up **first** (device tunnel should already be up; SBL/PLAP the user connects first), then
   change the password. Confirm DC reachability with `PREVPN-Validation.ps1`.
2. **Clock skew.** Kerberos rejects password operations when device time is too far from the DC's
   (default tolerance five minutes). Correct the device clock/time zone and retry.
3. **SSPR assumed to be enough (it isn't, for hybrid/domain-joined).** SSPR resets the **directory**
   password in the cloud; with writeback it updates the on-prem directory — but the **local interactive
   change at the Windows lock screen still expects a DC path**. Use SSPR/TAP for the cloud-capable
   paths, but for a hybrid/domain-joined device's lock-screen change, the DC path via the tunnel is
   still required. Validate the real behavior (T2).
4. **Password policy rejection (not a network problem).** If the tunnel and DC are fine but the change
   is refused on complexity/history/age, it is an AD **policy** rejection — the user must pick a
   compliant password; this is not a pre-logon-VPN issue.

## §Entra-joined confusion — "do cloud-only devices need this?"

**Symptom:** Uncertainty about whether an Entra-joined device needs a pre-logon tunnel; or a pre-logon
tunnel was deployed to cloud-only devices unnecessarily.

1. **Entra-joined devices authenticate against the cloud, not a DC.** A first sign-in works over
   ordinary internet and the password lives in Entra — **no pre-logon tunnel is needed**. Cached
   **cloud** credentials (PRT/Web Account Manager) cover subsequent sign-ins.
2. **Confirm the join type before deploying anything.** `dsregcmd /status`: `AzureAdJoined=YES`,
   `DomainJoined=NO`, `EnterpriseJoined=NO` = **Entra-joined**. `DomainJoined=YES` +
   `AzureAdJoined=YES` = **hybrid-joined** (needs a DC path). `PREVPN-Discovery.ps1` reports the mix.
3. **Remove over-deployment.** If a device tunnel/SBL was targeted at Entra-joined devices, exclude
   them from the chosen approach's assignment — they don't need it and it only adds surface/support.
4. **Password path for Entra-joined:** use **SSPR** and **TAP**; there is no on-prem DC dependency.

## §Pre-logon path not present — validation says no tunnel

**Symptom:** `PREVPN-Validation.ps1` reports no device tunnel and no SBL/PLAP provider on a device
that should have one.

1. **Chosen approach's object not deployed/assigned.** Confirm `AOVPN – Device Tunnel – ProfileXML –
   Windows` (device tunnel) or `Cisco Secure Client – Pre-Logon (SBL) – Win32` (SBL) exists and is
   assigned to the device's group — deploy/assign it via the **companion product**.
2. **Device not in the segmentation group.** Confirm the device/user is in `PILOT – Pre-Logon
   First-Logon Users` (or the prod group) so the companion product's assignment reaches it. Use
   `PREVPN-Remediation.ps1` to add lacking devices/users, then sync.
3. **Not yet synced.** Force a sync and allow time for the companion product's profile/app to land,
   then re-run validation.

## §Script / reporting issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph
   -Scope CurrentUser`) and consent to the scopes each script lists in its header. Read-only scripts
   need only `.Read.All` scopes. (`PREVPN-Validation.ps1` needs no Graph — it runs locally.)
2. **Join type shows unknown.** `PREVPN-Validation.ps1` parses `dsregcmd /status`; run it in a normal
   user context on the device. `PREVPN-Discovery.ps1` derives join type from Entra device
   `trustType` — a device missing from Entra shows unknown until it registers.
3. **Remediation "made no changes."** By design — it defaults to **-WhatIf**. Re-run with
   `-WhatIf:$false` after reviewing the previewed actions. Remember it only adjusts **group
   membership** for the chosen approach; it never creates VPN profiles.

---

If first-logon or password-change still fails after the decision side is confirmed healthy (right
approach for the join type, pre-logon path present, DC reachable, clock in sync), treat it as a
**companion-product / network / vendor head-end issue** and continue with that product's
troubleshooting and the **vendor's official documentation**.
