# 7. Best Practices — NTLM Elimination & SMB Signing (Legacy Auth Hardening)

These practices keep NTLM elimination and SMB-signing enforcement precise, safe, and reversible on
Intune-managed Windows 10/11 endpoints. They assume the deployment model in the Solution Overview: a
Settings Catalog policy that **audits NTLM first**, then refuses LM/NTLMv1, enforces NTLM SSP session
security and SMB signing on both ends, and closes insecure guest logons and unauthenticated RPC —
deployed pilot-first.

## Audit before you enforce — always
- **Never refuse NTLM blind.** Deploy **`NTLM Audit - Pilot`** (Restrict NTLM: Audit in-domain +
  outgoing) and let it run a **full business cycle** (1–2 weeks) so month-end jobs, backups, and periodic
  tasks show up.
- **Turn the audit into a plan.** Build the dependency table (system → protocol → owner → remediation)
  from the NTLM Operational log. Each NTLM user gets a decision — Kerberos, replace, or scope out —
  **before** enforcement reaches its population.
- **Keep auditing ahead of the wave.** Run the audit policy on each new wave first; only enforce once
  that population's dependencies are cleared.

## Move to Kerberos, don't just block NTLM
- **Fix the cause, not the symptom.** Refusing NTLM only helps if Kerberos works — fix SPNs and DNS so
  services authenticate over Kerberos (R8), and access services by **FQDN** (bare IP forces NTLM).
- **Kerberos-first aligns with Microsoft's roadmap.** NTLM is being deprecated; every dependency you move
  to Kerberos now is one you won't scramble to fix later.

## Get SMB signing right on both ends
- **Client and server both.** Enable *Digitally sign communications (always)* for **both** the Microsoft
  network **client** and **server** — signing on both ends is what defeats SMB relay.
- **Confirm server/NAS capability first.** Modern Windows Server signs by default; third-party NAS
  varies. Verify capability (R7) before enforcing client-side signing, or shares will fail.
- **Legacy appliances that can't sign** get a replacement plan or a documented exception — never a
  fleet-wide rollback of signing.

## Set RPC restriction conservatively
- **Use "Authenticated", not "Authenticated without exceptions".** `RestrictRemoteClients = 1`
  (Authenticated) closes the common exposure without breaking legitimate management RPC; the stricter
  `= 2` can break tooling — reserve it for a deliberate, tested decision.

## Own only your slice — cross-reference the baselines
- **Don't rebuild CIS/STIG.** This product owns the NTLM-elimination + SMB-signing controls. For the full
  Windows hardening baseline, deploy the **CIS Windows 11** and/or **DISA STIG** solutions.
- **One owning policy per setting.** If a full baseline already sets these NTLM/SMB values, decide the
  single owning policy and remove the duplicate from the other so the Settings Catalog does not report a
  **Conflict**.

## Deploy pilot-first and reversibly
- **Assign to a pilot group, never "All devices" first.** Expand in waves after each gate passes and each
  population's dependencies are cleared.
- **Rollback is unassignment.** Because this only adds a configuration policy, removing the assignment
  cleanly reverts to pre-hardening behavior — no re-imaging or account cleanup. Keep the policy so you can
  re-target quickly (R9).

## Operate and monitor
- **Report before you widen.** Run `NTLMHARD-Report.ps1` each wave; only broaden when coverage matches the
  assigned group.
- **Remediate with `-WhatIf` first.** `NTLMHARD-Remediation.ps1` and `NTLMHARD-Set-ScopeTargeting.ps1`
  preview by default — read the plan, then apply.
- **Watch the NTLM Operational log after enforcing.** A spike in refused NTLM to a specific target is a
  missed dependency — remediate it, don't relax the policy.

## Change control
- **Version scope changes.** When you adjust a setting or widen the assignment, note the date and reason;
  re-run Discovery and Report to confirm no regressions.
- **Review after major Windows upgrades.** Confirm the settings still apply and no new NTLM fallback
  appears after significant Windows feature updates before expanding further.
