# 6. Troubleshooting — NTLM Elimination & SMB Signing

Work top-down: confirm the **policy is applied**, then whether a **hard NTLM/SMB dependency** (not the
policy) is the real cause, then **conflicts** with another baseline. Most "it broke something" cases are
a dependency the audit phase should have caught, a server/NAS that cannot sign SMB, or a Kerberos
(SPN/DNS) problem forcing NTLM fallback. Each symptom below gives the **likely cause** and the **fix**.

> **Before you start:** confirm you completed the **audit phase** (Restrict NTLM: Audit) and cleared the
> dependency table (R6). Enforcing without auditing is the single biggest cause of the failures below.

## Symptom: The hardening policy never applies to the device
**Likely cause:** Device not synced, not assigned, not enrolled, or unsupported edition.
**Fix:**
1. Confirm the device is in the **pilot group** and **`NTLM-SMB Hardening - Pilot`** is **assigned**
   (`NTLMHARD-Validation.ps1`).
2. Force a sync (**Settings → Accounts → Access work or school → Info → Sync**).
3. Check **Devices → Configuration → `NTLM-SMB Hardening - Pilot` → Device status** for an error.
4. Confirm the device is **Pro/Enterprise/Education** (R2) — Home/Core lacks some Local Security Options.

## Symptom: Policy shows "Error" / "Conflict" in Device status
**Likely cause:** A second policy (often a full **CIS Windows 11** or **DISA STIG** baseline) sets the
same NTLM/SMB values, or a duplicate hardening policy targets the device.
**Fix:**
1. Run `NTLMHARD-Discovery.ps1` to list policies touching these settings.
2. Decide the **single owning policy** for the NTLM/SMB values and remove them from the other so only one
   sets each — this product owns only the legacy-auth slice by design (Implementation Step 13).
3. Ensure only **one** policy targets the device with these settings.

## Symptom: File shares stop working after enforcement
**Likely cause:** The target file server/NAS cannot do **SMB signing** (R7), or the client now requires
signing the server won't provide.
**Fix:**
1. Confirm the server/NAS **supports and has SMB signing enabled** (modern Windows Server signs by
   default; third-party NAS varies).
2. Where the appliance cannot sign, plan replacement or an explicit, documented exception — **do not**
   drop client-side signing fleet-wide to accommodate one legacy device.
3. Re-test the share from the pilot device (Testing, Test 6).

## Symptom: An app or service that used NTLM now fails to authenticate
**Likely cause:** A hard NTLM dependency the audit phase surfaced (or missed), now refused by
`LmCompatibilityLevel = 5` / NTLM SSP session-security requirements.
**Fix:**
1. Check the **NTLM Operational** log on the device for the refused attempt (source app / target).
2. Move the service to **Kerberos** — fix its SPN and use **FQDN** access, not a bare IP (bare IP forces
   NTLM) (R8).
3. If it genuinely cannot use Kerberos, replace it or scope it out of enforcement until you can — this is
   exactly what the audit phase (R6) exists to plan for.

## Symptom: Repeated NTLM fallback even though Kerberos "should" work
**Likely cause:** SPN/DNS problems, or access by IP/short name, force NTLM.
**Fix:**
1. On the device, `klist` — confirm a Kerberos ticket is issued for the target service.
2. Fix duplicate/missing **SPNs** and ensure **DNS** resolves the service FQDN; access by **FQDN**.
3. Re-test; NTLM fallback should stop once Kerberos succeeds.

## Symptom: Legitimate RPC-based management breaks
**Likely cause:** *Restrict Unauthenticated RPC clients* was set too strictly.
**Fix:**
1. Confirm you selected **Authenticated** (`RestrictRemoteClients = 1`), **not** *Authenticated without
   exceptions* (`= 2`), which is more aggressive and can break management traffic.
2. Re-check the setting value in the policy (Implementation Step 6.7) and re-sync.

## Symptom: SMB signing works to some servers, not others
**Likely cause:** Mixed server capability — some sign, some don't.
**Fix:**
1. Inventory which servers/NAS support signing (R7); enable it where supported.
2. For non-signing legacy appliances, plan replacement or a documented exception; track them in the
   dependency table (R6).

## Symptom: Works for some devices, not others
**Likely cause:** Group membership, edition, or a device-specific conflicting policy.
**Fix:**
1. Confirm affected devices are in the assigned group (`NTLMHARD-Report.ps1`).
2. Confirm each is **Pro/Enterprise/Education** on a supported build (R2).
3. Check for a device-scoped conflicting baseline (first symptom above).

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or on an unsupported edition.
**Fix:**
1. Run `NTLMHARD-Report.ps1` to list which devices lack the applied policy.
2. Run `NTLMHARD-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R1) and edition (R2).

## Escalation checklist
Before opening a Microsoft support case, collect: the `NTLMHARD-Discovery.ps1` output, the policy's
Device status export, the exact settings and their applied registry values (Test 3), the NTLM
Operational log excerpts for the failing flow, the target server/NAS SMB-signing capability, `klist`
output, Windows edition/build, and whether the failure reproduces with the hardening policy **unassigned**
(isolates this policy from an unrelated Kerberos/DNS problem).
