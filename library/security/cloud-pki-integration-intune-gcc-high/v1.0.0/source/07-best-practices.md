# Best Practices — Cloud PKI Integration with Intune (Government / GCC High)

Field-proven guidance for the **assign-once, repeat-everywhere** certificate model on a **GCC High**
tenant, built on the **supported** path because **Cloud PKI is not yet available in GCC High**.

## Sovereign-cloud discipline (GCC High)

- **Bookmark the `.us` portals and never the `.com` ones.** Sign in at `login.microsoftonline.us`;
  administer at `intune.microsoft.us`, `security.microsoft.us`, `entra.microsoft.us`,
  `portal.office365.us`. A Commercial URL in a GCC High runbook is a defect.
- **Every script targets US Gov Graph** — `Connect-MgGraph -Environment USGov` (never `Global`).
  Bake this into the header of every runbook so no one connects to the wrong cloud.
- **Treat "the option isn't there" as a parity gap, not a bug.** Before opening a support case,
  check `gcc-high-parity-notes.md` — if a feature (above all **Cloud PKI**) is *planned / not
  available*, it genuinely is not present, and the fix is to use the GA alternative, not to
  troubleshoot.
- **Re-verify parity before each design.** Microsoft ships to GCC High continuously; **Cloud PKI is
  planned for GCC High and may become GA** — re-check the *Intune Government Service overview* and the
  Microsoft 365 Roadmap filtered to GCC High before assuming today's status.

## Cloud PKI specifically

- **Do not design on Cloud PKI in GCC High today** — it is **planned, not available**, and **not
  planned for DoD** at all. Any date you have heard is an **ETA**; treat it as such.
- **Build the profile layer so a future Cloud PKI migration is cheap.** Keep the **trusted-root** and
  **SCEP** profiles clean and standard; when Cloud PKI ships to GCC High you re-point them at a Cloud
  PKI issuing CA and retire NDES + the connector, rather than rebuilding.
- **When Cloud PKI does arrive, migrate as its own Assess→…→Expand cycle** — verify GA in *your*
  tenant, pilot the issuing-CA swap, then decommission the on-prem back-end.

## Certificate architecture (connector model)

- **Keep the trust chain minimal and explicit** — one `Trust-Root-CA` profile per platform (plus an
  intermediate profile if needed). Every SCEP/PKCS profile references it.
- **Match the profile to the AD CS template exactly** — subject/SAN, key usage, EKU (Client
  Authentication for Wi-Fi/VPN), validity, and renewal threshold must mirror the template, or
  issuance/renewal silently misbehaves.
- **Keep SCEP extensions standard** — the SCEP validation service **blocks unknown extension OIDs**
  (connector v6.2510.3.2002+). Do not add custom OIDs to SCEP profiles.
- **Name every object verbatim and reuse it** — `Trust-Root-CA`, `SCEP-Device-ClientAuth`,
  `PKCS-User-ClientAuth`, `SG-CPKI-Pilot`. Consistent names make the scripts, reports, and handover
  legible.
- **Prefer SCEP for device certs at scale** (key stays on-device; per-device enrollment) and **PKCS
  for user certs / S/MIME** (imported PFX for S/MIME). Choose per scenario, not by habit.

## Connector & NDES health

- **Keep the Certificate Connector on a supported version.** Each release is supported for **six
  months**; out-of-support connectors show **Warning→Error** and can stop issuing/revoking. Allow
  **auto-update** (`autoupdate.msappproxy.net:443`) or plan manual updates within the window.
- **Watch the connector Event logs** (Applications and Services → Microsoft → Intune → Certificate
  Connectors) — success/failure event IDs per flow (SCEP 4xxx, PKCS 1xxx, Revoke 3xxx, Health 5xxx).
- **Verify partner-CA support for GCC High** before relying on a non-Microsoft CA connector — it may
  be Commercial-only.
- **Protect NDES** — publish it through your Gov reverse proxy, not directly; keep the service
  account least-privileged with Enroll rights only.

## Rollout & operations

- **Always pilot first, expand group-by-group.** Certificate/Wi-Fi/VPN changes can take users
  offline; scope to `SG-CPKI-Pilot`, validate, then widen. Never assign tenant-wide on day one.
- **Every certificate/auth change is a change ticket** — approver, maintenance window, named pilot,
  documented rollback (per `global-requirements-security.md` G8).
- **Run the read-only scripts on a schedule** — `CPKIG-Discovery.ps1`, `CPKIG-Validation.ps1`,
  `CPKIG-Report.ps1` — to catch drift (an unassigned profile, an unhealthy connector, expiring
  certificates).
- **Keep change-tools in `-WhatIf` by default** — `CPKIG-Remediation.ps1` and
  `CPKIG-Set-ScopeTargeting.ps1` preview first; only run with `-Execute` / `-WhatIf:$false` after
  review and approval.
- **Least privilege:** author with **Intune Administrator** (or the custom certificate role), not
  Global Administrator.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
