# 8. Deliverables Summary — Windows Credential Theft Protection

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case in one page: how credential-theft / pass-the-hash attacks
  harvest secrets from LSASS and static local-admin passwords, the six controls that close those doors,
  and the ~3 assessment findings this resolves directly.
- **Solution Overview** — the attack chain and why each control exists; how Credential Guard (VBS/LSA
  isolation), LSASS protection (RunAsPPL/PPL), WDigest, Remote Credential Guard, WinRM, and Windows LAPS
  work; and the explicit scope boundary against RDP-host hardening and full baselines.
- **Requirements Guide** — every Intune/Entra/Windows/hardware prerequisite with how to **verify** and
  how to **implement if missing** (TPM/UEFI/Secure Boot/virtualization readiness, LAPS build + Entra
  feature, retrieval permissions, UEFI-lock rollback awareness), plus the category-level Global
  Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across six phases: assess readiness,
  configure Credential Guard, configure LSASS protection (audit-first), configure WDigest / Remote
  Credential Guard / WinRM, configure Windows LAPS, then pilot / validate / expand — every object named
  and reused.
- **Testing & Validation** — ten tests with explicit pass/fail gates (readiness, Credential Guard
  running, LSASS audit-then-enforce, WDigest, Remote Credential Guard, WinRM, LAPS backup/retrieval,
  coverage, reversibility) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for VBS-won't-start, driver/plug-in incompatibility, WDigest
  persistence, RDP breakage, and LAPS backup/retrieval issues.
- **Best Practices** — readiness-gating, deliberate lock-mode rollout, audit-first LSASS, cheap-win
  low-risk controls, Windows LAPS operations, and reversible pilot-first deployment.

## PowerShell scripts (Microsoft Graph) — `CREDGUARD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK); each
has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and Report
are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** (preview first, then
apply).

1. **`CREDGUARD-Discovery.ps1`** — tenant readiness: the six credential-protection profiles are present
   and correctly configured, and (with `-LocalReadiness`) an on-device **TPM 2.0 / UEFI / Secure Boot /
   VBS** hardware-readiness check for Credential Guard.
2. **`CREDGUARD-Validation.ps1`** — validates a named profile's **assignment** and per-device **applied**
   state, with a clear PASS/FAIL summary.
3. **`CREDGUARD-Report.ps1`** — tenant-wide CSV report of Windows devices and whether the
   credential-protection controls are applied (plus readiness/VBS-running state where available) — the
   coverage report.
4. **`CREDGUARD-Remediation.ps1`** — safe remediation of the flagship gap: creates the **Credential
   Guard** endpoint-protection profile (VBS + Credential Guard, UEFI lock by default) and assigns it to
   a target group, then **previews** the remaining controls (LSASS RunAsPPL, WDigest, Remote Credential
   Guard, WinRM, LAPS) with the exact values to set per the guide. **`-WhatIf` by default**; applies
   only when re-run with `-WhatIf:$false`.
5. **`CREDGUARD-Set-ScopeTargeting.ps1`** — sets/adjusts the profile group assignment (include/exclude
   target-group builder) for wave-based rollout. **`-WhatIf` by default.**

## Hero image
- **`CREDGUARD-hero.png`** — the product image used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
