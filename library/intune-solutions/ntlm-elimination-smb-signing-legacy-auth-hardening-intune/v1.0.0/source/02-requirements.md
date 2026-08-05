# 2. Requirements — NTLM Elimination & SMB Signing (Legacy Auth Hardening)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to hardening NTLM and
SMB on Windows 10/11 endpoints via the Settings Catalog.

> **Scope reminder.** These requirements are for the **endpoint (client/member) side** legacy-auth
> hardening policy. They deliberately do **not** include domain-controller NTLM policy, Kerberos
> infrastructure, or a full CIS/STIG baseline (cross-referenced, separate solutions).

## R1. Windows 10/11 devices enrolled in Intune
**Description:** The target devices are Intune-enrolled Windows 10 (21H2+) or Windows 11 endpoints.
**Why:** The Settings Catalog policy is delivered by Intune MDM; it only reaches enrolled devices.
**Verify:** Intune admin center (`https://intune.microsoft.com`) → **Devices → Windows → Windows
devices**; the device is listed and **managed / compliant**.
**Implement:** Enroll via Automatic Enrollment (Entra join + MDM auto-enroll) or Autopilot so the device
appears under **Devices → Windows**. (Enrollment itself is covered by the enrollment solutions.)

## R2. Supported Windows edition and build
**Description:** Windows 10 21H2+ or Windows 11, **Pro / Enterprise / Education** edition, current
updates.
**Why:** The **Local Policies\Security Options** controls (LAN Manager level, NTLM SSP session security,
SMB signing) require a business edition; Home/Core does not expose all of them.
**Verify:** On the device, `winver` (build) and `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows
NT\CurrentVersion' EditionID`; or Intune → device → **Hardware**. `NTLMHARD-Discovery.ps1` reports both.
**Implement:** Upgrade older builds via **Update rings**; move Home/Core devices to Pro/Enterprise/
Education before applying the hardening policy.

## R3. Settings Catalog hardening policy (created during deployment)
**Description:** A Windows **Settings Catalog** policy named **`NTLM-SMB Hardening - Pilot`** carrying
the seven legacy-auth settings.
**Why:** This policy is what applies and scopes the hardening.
**Verify:** Intune → **Devices → Configuration**; a Settings Catalog policy named **`NTLM-SMB Hardening
- Pilot`** exists and is assigned to your pilot group. `NTLMHARD-Discovery.ps1` confirms the settings are
present.
**Implement:** Create it during deployment (Implementation Guide, Phase 3), or scaffold/assign it with
the included `NTLMHARD-Remediation.ps1` / `NTLMHARD-Set-ScopeTargeting.ps1`.

## R4. NTLM audit policy (audit-first)
**Description:** A Windows **Settings Catalog** policy named **`NTLM Audit - Pilot`** enabling *Network
security: Restrict NTLM: Audit NTLM authentication in this domain* and *Audit Outgoing NTLM traffic to
remote servers*.
**Why:** NTLM must be **audited before it is refused** so you find every dependency (apps, appliances,
services) before enforcement breaks them.
**Verify:** The audit policy exists and is assigned to the pilot group; NTLM operational events are
appearing in the endpoints' event logs (Implementation Phase 2).
**Implement:** Create it during deployment (Implementation Guide, Phase 2). Keep it in place through the
pilot; you can retire it once enforcement is stable.

## R5. Access to NTLM operational event logs
**Description:** A way to read the **Applications and Services Logs → Microsoft → Windows → NTLM →
Operational** event log on pilot endpoints (locally, or centrally via an event collector / log
analytics).
**Why:** The audit phase writes NTLM usage events there; you need them to build the dependency list.
**Verify:** On a pilot device, open **Event Viewer → Applications and Services Logs → Microsoft →
Windows → NTLM → Operational** and confirm events appear after the audit policy applies.
**Implement:** Enable the NTLM operational log (it is present by default) and, ideally, forward it to a
central collector (WEF) or Microsoft Sentinel / Log Analytics for fleet-wide visibility.

## R6. Inventory of NTLM/SMB dependencies (built during audit)
**Description:** A short list of known **NTLM- or unsigned-SMB-dependent** systems — legacy apps, NAS
appliances, scanners/MFPs, backup agents, line-of-business services.
**Why:** Refusing NTLM or requiring SMB signing can break a device that talks to one of these; you must
know them before enforcing.
**Verify:** You have a table of (system → protocol used → owner → remediation plan) derived from the
audit events (R5).
**Implement:** Build it during the audit phase (Implementation Phase 2). For each item, plan to move it
to Kerberos / signed SMB, replace it, or scope it out — before fleet enforcement.

## R7. SMB signing readiness on file servers / NAS (awareness)
**Description:** Awareness that requiring SMB signing on the **client** means every server/NAS the client
talks to must **support** SMB signing.
**Why:** Enforcing *client: digitally sign (always)* against a server that cannot sign will fail the
connection.
**Verify:** Confirm your Windows file servers (modern Windows Server signs by default) and any third-party
NAS support SMB signing; test a share from a pilot device (Testing, Test 6).
**Implement:** Enable SMB signing on file servers/NAS that support it; for appliances that cannot,
plan replacement or an explicit exception before fleet rollout.

## R8. Kerberos/DNS health for the Kerberos-first posture (recommended)
**Description:** Healthy Kerberos authentication and DNS so that refusing NTLM does not simply fail —
clients fall back to **Kerberos**.
**Why:** NTLM elimination assumes Kerberos works; broken SPNs/DNS make services silently fall back to
NTLM (which you're now refusing), causing outages.
**Verify:** On a pilot device, `klist` shows Kerberos tickets for accessed services; name resolution for
those services uses FQDNs (not bare IPs, which force NTLM).
**Implement:** Fix SPNs and DNS so target services authenticate over Kerberos; prefer FQDN access. (Deep
Kerberos infrastructure work is adjacent/out of scope — flag it to your identity team.)

## R9. Change-control / rollback plan
**Description:** A documented rollback: unassign the **`NTLM-SMB Hardening - Pilot`** policy to revert.
**Why:** Legacy-auth enforcement can surface unexpected dependencies; a clean revert path is required
before enforcing.
**Verify:** You know how to unassign the policy (Intune → Devices → Configuration → policy →
Assignments) and confirm the device reverts after a sync.
**Implement:** Keep the policy (do not delete) so you can re-target quickly; document the unassign step
in your change ticket.

## R10. Pilot user and pilot device
**Description:** At least one pilot user with a licensed Entra identity and one enrolled pilot Windows
10/11 device that exercises real SMB/NTLM workloads (file shares, apps).
**Why:** Every solution is validated on a pilot before fleet rollout — and legacy-auth hardening must be
proven against real workloads.
**Verify:** The pilot device is enrolled (R1), on a supported edition/build (R2), and reaches the file
shares and apps users actually use.
**Implement:** Add the pilot user/device to the **pilot security group** (Global Requirement G5) used for
the policy assignment.
