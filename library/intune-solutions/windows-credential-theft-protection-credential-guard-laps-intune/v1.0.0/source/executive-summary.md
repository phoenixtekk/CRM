# Executive Summary — Windows Credential Theft Protection (Credential Guard, LSASS Protection & Windows LAPS)

Most credential-theft attacks on Windows do not break cryptography — they **steal secrets that Windows
leaves sitting in memory or on disk**. An attacker who lands on one endpoint dumps **LSASS** for cached
password hashes and Kerberos tickets, replays them with **pass-the-hash / pass-the-ticket** to move
laterally, harvests **plaintext passwords** WDigest still cached, and pivots through **static local
administrator passwords** that are identical on every machine. This solution closes those doors on
**Windows 10/11** endpoints managed by **Microsoft Intune** — no domain controllers to touch, no
third-party agent, deployed pilot-first and reversible.

It is the **credential-theft / pass-the-hash defense** pack. It deploys, in one coherent playbook, the
six controls that together take LSASS off the table as an easy source of credentials:

- **Windows Defender Credential Guard (with UEFI lock)** — isolates secrets (NTLM hashes, Kerberos
  TGTs) inside **virtualization-based security (VBS)** so even a SYSTEM-level attacker cannot read them
  from LSASS.
- **LSASS protection / RunAsPPL** — runs LSASS as a **protected process (PPL)** so unsigned code and
  common dumping tools can't open its memory. Deployed **audit-first** so incompatible plug-ins surface
  before enforcement.
- **Disable WDigest (`UseLogonCredential = 0`)** — stops Windows from caching reusable **plaintext**
  passwords in LSASS.
- **Restrict delegation of credentials / Remote Credential Guard** — keeps credentials from being
  **delegated to remote servers** over outbound RDP, so a compromised jump host can't harvest them.
- **Disallow WinRM from storing RunAs credentials (`DisableRunAs = 1`)** — removes a machine-stored
  credential an attacker could recover.
- **Windows LAPS** — backs up, rotates, and retrieves a **unique local administrator password per
  device** in Entra ID, ending the identical-local-admin-password lateral-movement path.

**Why this matters commercially.** A typical security assessment flags several of these directly — most
commonly **WinRM RunAs credential storage**, **unrestricted credential delegation to remote servers**,
and **WDigest plaintext caching**. This package **resolves those ~3 findings outright** and, with
Credential Guard and Windows LAPS on top, **materially raises the endpoint's credential-theft posture**
rather than just checking a box.

**A deliberately scoped, distinct capability.** This is **endpoint-side credential-theft hardening** via
Intune. Credential Guard requires **TPM 2.0, UEFI, Secure Boot, and virtualization** and can break some
legacy drivers/apps under VBS — so the package includes a **readiness/prerequisite assessment** and a
**phased rollout** rather than a fleet-wide flip. The **RDP host-side** settings (Restricted Admin on
the target server, NLA, etc.) belong to the separate **RDP hardening** solution and are cross-referenced,
not duplicated here.

The package delivers the complete, field-tested method — written so a single administrator can follow it
end to end:

- **Named, reusable Intune objects** — `Credential Guard - Pilot`, `LSASS Protection (RunAsPPL) - Pilot`,
  `WDigest Disabled - Baseline`, `Remote Credential Guard - Pilot`, `WinRM No RunAs Credentials -
  Baseline`, and `Windows LAPS - Baseline`, all assigned to the `Credential Protection - Pilot` group.
- **Readiness before enforcement** — a TPM/UEFI/Secure Boot/VBS assessment so Credential Guard only lands
  on capable devices, and audit-first LSASS protection so nothing breaks silently.
- **Five ready-to-run PowerShell scripts (Microsoft Graph)** — discovery (tenant + device readiness),
  validation, coverage reporting (read-only), plus remediation and scope-targeting that **default to a
  safe `-WhatIf` preview**.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune steps, a requirements guide that tells you how to **verify** *and*
**fix** each prerequisite, and testing/troubleshooting guides with clear pass/fail gates.

**Outcome:** LSASS stops being a credential piñata. Secrets are isolated in VBS, LSASS is a protected
process, plaintext caching and machine-stored credentials are gone, credential delegation is restricted,
and every device has a unique, rotated local-admin password — proven on a pilot before you scale, without
a consulting engagement.
