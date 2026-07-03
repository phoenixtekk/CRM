# Best Practices — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

Practices that keep this deployment correct, auditable, and low-risk on the US sovereign cloud.

## Set expectations on the parity gap first
- Communicate up front, in writing, that **Entra ⇄ ABM federation and SCIM auto-provisioning are not
  supported for national clouds** (Apple's statement). Stakeholders who expect "sign in to Apple with
  your GCC High work account, auto-provisioned by SCIM" will otherwise treat a documented limitation
  as a project failure. Frame the delivered outcome as **ABM ⇄ Intune Government enrollment** with
  **ABM-native Managed Apple IDs**.
- Re-check the Apple federated-authentication page periodically — the wording "isn't *currently*
  supported" implies it may change; revisit before any future re-scope.

## Always target the sovereign cloud
- Use only `*.us` portals (`entra.microsoft.us`, `endpoint.microsoft.us`, `portal.office365.us`).
  Bookmark them so no one accidentally lands on a Commercial URL.
- Every Graph call — script or manual — uses `Connect-MgGraph -Environment USGov`. Consider setting
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` in the admin profile so the
  Commercial endpoint is never hit by accident.

## Stage everything; never big-bang
- Follow **Assess → Configure → Pilot → Validate → Expand** with the gates in `05-testing.md`.
- Keep a small, named **`ABM-Apple-Pilot-Devices`** group and widen in waves, validating between each.
- Use `-WhatIf` first on `ABMPROVG-Set-ScopeTargeting.ps1` and `ABMPROVG-Remediation.ps1` — review the
  preview before applying.

## Protect sign-in with break-glass
- Maintain two cloud-only break-glass Global Administrators excluded from broad Conditional
  Access/MFA lockout, with monitored sign-ins. Enrollment and CA changes can lock admins out.

## Name and reuse objects
- Create named objects once and reuse them: `ABM-Apple-Pilot-Devices`, `ABM-Apple-Enroll-Users`,
  `ABM-ADE-Profile-Gov`, `Intune-Gov-MDM` (the ABM MDM server), and the documented
  `ABM-Managed-AppleID-Standard`. Consistent names make scripts, reports, and troubleshooting
  predictable.

## Manage the two annual expiries
- Both the **Apple MDM push certificate (APNs)** and the **ABM enrollment token** expire yearly.
  Calendar both renewals with 30-day lead time. Renew the APNs certificate with the **same Apple ID**
  — a different Apple ID forces re-enrollment of every device.
- Record the renewal owner and the Apple ID used, so a departing admin does not orphan the
  certificate.

## Keep Managed Apple ID lifecycle auditable
- With federation/SCIM unavailable, document how Managed Apple IDs are created (manual / SFTP / ABM
  API), named, suspended, and deleted. Tie suspension/deletion to your joiner-mover-leaver process
  even though it is a manual/ABM-side step rather than an Entra-driven one.

## Least privilege
- Use **Intune Administrator** for day-to-day enrollment work; reserve **Global Administrator** for
  one-time consent, then step down. Do not run routine operations as Global Administrator.

## Validate before you trust reporting
- Cross-check `ABMPROVG-Report.ps1` against the portals during the first few runs. Once you trust it,
  use it as your recurring health snapshot after each expansion wave and before each renewal.

## Compliance-boundary caution on any "hybrid tenant" workaround
- A design that uses a separate Commercial/GCC tenant solely to obtain ABM federation (with GCC High
  for everything else) is **not a documented Microsoft path** and may violate your CMMC/ITAR/DFARS
  boundary. Treat it as a security/compliance decision to evaluate with your ISSO — never adopt it
  silently to "make federation work."

## Re-verify sources before implementation
- Sovereign-cloud capabilities move. Before each deployment, re-read the cited Apple and Microsoft
  pages in `gcc-high-parity-notes.md` and confirm nothing has changed.
