# 5. Testing & Validation — NTLM Elimination & SMB Signing

Validate against a **pilot device** before expanding. Each test has an explicit **pass/fail gate**. Use
the included PowerShell scripts (Microsoft Graph) for tenant-side checks and the on-device steps for the
enforcement behavior.

> **What "pass" means here:** the pilot endpoint refuses LM/NTLMv1, requires strong NTLM SSP session
> security and SMB signing on both ends, disables insecure guest logons, and restricts unauthenticated
> RPC — **without** breaking the real workloads you cleared in the audit phase.

## Test 1 — Tenant readiness
**Procedure:** Run `NTLMHARD-Discovery.ps1`.
**Pass:** A Settings Catalog policy named **`NTLM-SMB Hardening - Pilot`** exists carrying the seven
legacy-auth settings; the pilot devices are on a supported edition/build.
**Fail:** Missing policy, missing settings, or unsupported edition → resolve before piloting.

## Test 2 — Audit phase produced a dependency list
**Procedure:** Confirm **`NTLM Audit - Pilot`** ran and you have the NTLM operational events / dependency
table (R6).
**Pass:** You have a concrete list of NTLM users (or a confident "none") for the pilot population, each
with a plan.
**Fail:** No audit data → do not enforce yet; keep the audit policy running (Implementation Phase 2).

## Test 3 — Policy applied on the device
**Procedure:** On the pilot device, confirm the settings are in effect (registry anchors):
- `HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\LmCompatibilityLevel` = **5**
- `...\Lsa\MSV1_0\NtlmMinClientSec` = **0x20080000** and `NtlmMinServerSec` = **0x20080000**
- `...\LanmanWorkstation\Parameters\RequireSecuritySignature` = **1** and
  `...\LanmanServer\Parameters\RequireSecuritySignature` = **1**
- `...\LanmanWorkstation\Parameters\AllowInsecureGuestAuth` = **0**
- `...\Rpc\RestrictRemoteClients` = **1**

(or Intune → policy → **Device status** = **Succeeded**).
**Pass:** All anchors match and Intune shows **Succeeded**.
**Fail:** Any value wrong / policy Error → check Device status and a conflicting baseline (Troubleshooting).

## Test 4 — Profile assignment
**Procedure:** Run `NTLMHARD-Validation.ps1` (or check **Devices → Configuration → `NTLM-SMB Hardening -
Pilot` → Assignments**).
**Pass:** The policy is assigned to the intended **pilot group** and to no unintended broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct the assignment (Implement Step
7 / `NTLMHARD-Set-ScopeTargeting.ps1`).

## Test 5 — LM/NTLMv1 refused, Kerberos succeeds
**Procedure:** From the pilot device, access a Kerberos-capable service (FQDN); then attempt a
scenario that would require LM/NTLMv1.
**Pass:** Kerberos access succeeds silently; LM/NTLMv1 is **refused** (the weak fallback no longer
authenticates).
**Fail:** Kerberos access fails → likely SPN/DNS (R8), not this policy — fix Kerberos before enforcing
fleet-wide. Weak auth still succeeding → confirm `LmCompatibilityLevel = 5` applied (Test 3).

## Test 6 — SMB signing enforced (both ends), shares still work
**Procedure:** From the pilot device, open a share on a signing-capable file server/NAS; then confirm an
unsigned SMB session fails.
**Pass:** Signed SMB to capable servers works; an unsigned/relayed SMB session is rejected.
**Fail (share broken):** The server/NAS cannot sign (R7) → enable signing on it or plan replacement/
exception; do not remove client signing to "fix" it fleet-wide.

## Test 7 — Insecure guest logons and unauthenticated RPC closed
**Procedure:** Attempt an SMB connection that would fall back to a **guest** logon; confirm RPC clients
must authenticate.
**Pass:** Insecure guest SMB access is denied (`AllowInsecureGuestAuth = 0`); unauthenticated RPC is
restricted (`RestrictRemoteClients = 1`) without breaking legitimate authenticated RPC.
**Fail:** Guest access still succeeds → confirm the *Enable insecure guest logons = Disabled* setting
applied (Step 6.6). Legitimate RPC broken → confirm you selected **Authenticated**, not
**Authenticated without exceptions** (Troubleshooting).

## Test 8 — Coverage report
**Procedure:** Run `NTLMHARD-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **policy applied**; counts match the assigned group.
**Fail:** Devices missing from the report → run `NTLMHARD-Remediation.ps1` (`-WhatIf` first) to fix
assignment/scoping.

## Test 9 — No baseline conflict (negative test)
**Procedure:** Confirm no *other* policy (e.g. a full CIS/STIG baseline) also sets these NTLM/SMB values
on the pilot device.
**Pass:** Only **`NTLM-SMB Hardening - Pilot`** owns these settings on the device; Device status shows no
**Conflict**.
**Fail:** A conflict is reported → decide the single owning policy and remove the duplicate from the
other (Troubleshooting), so the two solutions do not fight.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot device, Test 9 confirms no baseline
conflict, and a real pilot user confirms their file shares, apps, and services still work with LM/NTLMv1
refused and SMB signing required.
