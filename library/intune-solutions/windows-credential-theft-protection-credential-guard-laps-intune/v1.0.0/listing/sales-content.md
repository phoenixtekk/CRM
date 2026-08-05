# Sales Content — Windows Credential Theft Protection (Credential Guard, LSASS Protection & Windows LAPS)

## Hook
**Stop pass-the-hash before it starts.** Deploy the endpoint-side credential-theft defense on Windows
10/11 with Microsoft Intune — Credential Guard, LSASS protection, WDigest off, Remote Credential Guard,
WinRM RunAs off, and Windows LAPS — readiness-gated and pilot-first.

## The problem
Windows quietly keeps reusable secrets where attackers can reach them. Land on one endpoint, dump
**LSASS**, and you walk away with NTLM hashes and Kerberos tickets to replay across the network; read the
**plaintext** WDigest cached; recover a machine-stored **WinRM RunAs** credential; and log into every
other box with the **identical local-admin password** baked into the image. Most security assessments
flag several of these — WinRM RunAs storage, unrestricted **credential delegation** to remote servers,
and **WDigest** plaintext — and they sit open because no one deployed the endpoint controls that close
them.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact, ordered Intune steps with full navigation paths; every profile you create is named
  (`Credential Guard - Pilot`, `LSASS Protection (RunAsPPL) - Pilot`, `WDigest Disabled - Baseline`,
  `Remote Credential Guard - Pilot`, `WinRM No RunAs Credentials - Baseline`, `Windows LAPS - Baseline`)
  and reused through testing and troubleshooting.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every wave and every new
  device fleet.
- **Tested** — a readiness-gated, pilot-first method (**Assess → Configure → Pilot → Validate → Expand**)
  with explicit pass/fail gates; Credential Guard lands only on TPM/UEFI/Secure-Boot-capable hardware and
  LSASS protection is audited before enforcement.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete click-by-click guide, honest about the hardware prerequisites (TPM 2.0 / UEFI / Secure Boot /
  virtualization), the UEFI-lock rollback trade-off, and the scope boundary against RDP-host hardening.
- **5 PowerShell scripts (Microsoft Graph)** — Discovery (tenant + on-device TPM/UEFI/Secure Boot/VBS
  readiness), Validation, Report (read-only), plus Remediation and Set-ScopeTargeting (default to
  `-WhatIf` preview).

## The repeatable way
Every solution follows the same repeatable shape, so each deployment feels familiar and low-risk — buy
once, reuse the playbook for the next wave and the next project.

## The bottom line
LSASS stops being a credential piñata: secrets isolated in VBS, LSASS a protected process, plaintext and
machine-stored credentials gone, delegation restricted, and a unique rotated local-admin password on
every device — proven on a pilot before you scale, and it closes real assessment findings on the way.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
