# Best Practices — Cloud-First Autopilot Zero-Touch Provisioning (Government / GCC High)

Practices tuned for the **US sovereign cloud**. Where a practice exists because of a GCC
High parity gap, that is called out.

## Portals & tooling

- **Bookmark the `*.us` portals** and remove Commercial bookmarks from the admin's browser
  profile to prevent muscle-memory mistakes: `intune.microsoft.us`, `entra.microsoft.us`
  *(verify for GCC High)*, `portal.azure.us`, `portal.office365.us`,
  `login.microsoftonline.us`.
- **Always connect Graph with `-Environment USGov`.** A script that silently connects to
  Commercial Graph will read an empty/foreign tenant. Every script in this solution does
  this and prints the environment on connect — verify it says **USGov**.
- **Treat "missing blade" as "not available in GCC High"** first, not as a bug. Cross-check
  `gcc-high-parity-notes.md` before opening a support case.

## Provisioning design (the supported path only)

- **Design on Autopilot *device preparation*, never classic Autopilot.** Classic Autopilot
  (hardware-hash registration, deployment profiles, self-deploying kiosks) does not exist
  in GCC High. Do not carry a Commercial hardware-hash CSV process into this tenant.
- **Use an *Assigned* device security group** and make the **Intune Provisioning Client**
  (`f1346770-5b25-470b-88bd-d5744ab7952c`) an **owner** of it. This is the single most
  common failure point — verify ownership after every group change with
  `CFAPG-Validation.ps1`.
- **Keep the OOBE app/script list short.** Microsoft deliberately limits apps during OOBE
  in device preparation for stability. Deliver the minimum during provisioning; push the
  rest post-OOBE via assignment to `CFAPG-Autopilot-Devices`.
- **Entra join only.** Plan on-prem resource access (if needed) as a *post-provisioning*
  add-on (cloud Kerberos trust / hybrid access), not as hybrid Autopilot join — which is
  unsupported by device preparation.
- **Do not plan self-deploying, pre-provisioning, or OOBE device-rename** — all "planned"
  but not yet available in GCC High. Rename devices post-provisioning if required.

## Servicing (no Autopatch in GCC High)

- **Service via Update rings for Windows 10 and later.** Autopatch and the newer
  feature/quality/expedite/driver update policies are **not available** in GCC High.
  Standardize on rings (`CFAPG-UpdateRing-Pilot` and successors) with staged deferrals.
- **Do not build reporting or SLAs on feature-update reports** — those reports are not
  available in GCC High.
- **Do not rely on Delivery Optimization Win32 peer caching** — not available; size network
  egress for per-device cloud downloads.

## Compliance & security

- **Write compliance rules that evaluate locally** (BitLocker, Secure Boot, OS build,
  Defender). **Do not** require **Device Health Attestation** results — DHA is not
  available in GCC High.
- **Cloud PKI is not available in GCC High** — if you need certificate provisioning, plan
  SCEP/PKCS with your own PKI/NDES rather than Intune Cloud PKI.
- **Remote Help is not available** — pre-select an approved alternative remote-assist tool
  for post-provisioning support, and document it in your runbook.
- **WHfB PIN recovery:** the hosted Microsoft PIN reset service is unavailable in Azure
  Government. Configure PIN reset via allowed sign-in URLs (Intune/CSP) and test it *(verify
  for GCC High for your build)*.

## RBAC & governance

- **Run day-to-day with the least-privilege role** `CFAPG Device Preparation
  Administrator` (only the permissions device preparation needs), not Global/Intune Admin.
- **Apply the `CFAPG` scope tag** to this solution's objects and role assignment so
  government segregation-of-duties is auditable.
- **Consider the GCC High STIG.** Microsoft points GCC High admins to the DISA STIG for MDM
  hardening — align your compliance and configuration baselines to it.

## Operations & change control

- **Gate every expansion.** Keep the `Assess → Configure → Pilot → Validate → Expand`
  discipline; widen scope only with `CFAPG-Set-ScopeTargeting.ps1` after previewing with
  `-WhatIf`.
- **Re-validate after any Entra group edit** — a lost owner on the device group silently
  breaks all future provisioning.
- **Watch the docs for GCC High parity changes.** GCC High capability is expanding
  (device preparation itself is recent); re-check `gcc-high-parity-notes.md` items marked
  "planned" or "verify for GCC High" each quarter.
- **Never inspect SSL on `*.manage.microsoft.us`** or Defender endpoints — it breaks
  management and is unsupported.

## Sources

- Microsoft, *Intune Government Service overview* (not-available / planned features).
- Microsoft, *Windows Autopilot device preparation — overview & requirements* (OOBE app
  limit, Entra-join only, assigned group + provisioning-client owner, RBAC).
- Microsoft, *Network endpoints for US government deployments* (no SSL inspection on
  `*.manage.microsoft.us`).
