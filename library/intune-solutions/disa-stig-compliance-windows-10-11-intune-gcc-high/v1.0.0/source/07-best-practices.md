# Best Practices — Government / GCC High edition

Operating principles for running a DISA STIG-alignment program on Intune in the **US Government cloud (GCC High / DoD)**. These assume you have implemented the solution per `03-implementation.md` and are now sustaining it.

## Sovereign-cloud discipline

- **Bookmark the `*.us` portals and delete the `.com` ones.** `intune.microsoft.us`, `portal.azure.us`, `portal.office365.us`, `security.microsoft.us`. The most common GCC High mistake is doing real work in the Commercial portal by muscle memory.
- **Pin `-Environment` in every script and runbook.** Never run Graph automation without an explicit **`-Environment USGov`** (GCC High) or **`-Environment USGovDoD`** (DoD). A default (`Global`) connection silently talks to the wrong cloud.
- **Never SSL-inspect `*.manage.microsoft.us`.** It is unsupported and breaks enrollment/check-in. Exclude it (and the Defender/EPM `*.dm.microsoft.us` hosts) from inspection.
- **Assume parity gaps until proven otherwise.** Before designing around any Intune feature, confirm it exists in GCC High/DoD today (see `gcc-high-parity-notes.md`). Treat every gap as **"verify for GCC High/DoD"** — the sovereign feature set moves.

## STIG content governance

- **DISA owns the rules; you own the delivery.** Always pull benchmarks from **`public.cyber.mil`** and read them in **STIG Viewer**. Do not hand-copy rule IDs or invent settings — map DISA's authoritative rules to Intune.
- **Version-pin everything.** Record the DISA **benchmark version/release date** in each profile's description, and keep a **benchmark-version → deployed-policy-version** ledger. Auditors ask "which STIG release is this fleet on?"
- **Track the DISA revision cadence.** When a new benchmark drops, treat it as a change: update the map, revise profiles, re-pilot the delta, then expand.
- **Separate enforce from audit.** Enforce with Settings Catalog/ADMX/custom profiles; use the **STIG audit baseline** (Advanced Analytics, GCC High, if licensed) as an **advisory assessment**, not as the control itself.

## Object hygiene

- **One naming convention, reused everywhere.** Use the names from `01-solution-overview.md` (`SG-STIG-Pilot-Devices`, `STIG-Win-SettingsCatalog-{domain}`, `STIG-Win-Compliance-Baseline`, …). Consistent names make rollback and audit surgical.
- **Split profiles by domain, not one mega-profile.** Account, Audit, Defender, etc. A conflict or rollback then touches one domain, not the whole STIG.
- **Group-based targeting, device groups for STIG.** Target device groups (`SG-STIG-*-Devices`) so posture follows the machine regardless of user.
- **Keep `SG-STIG-Prod-Devices` wave-managed.** Add in waves (10/25/50/100%); never assign a new lockdown to the whole fleet at once.

## Safe change management

- **`-WhatIf` first, always.** `STIGG-Remediation.ps1` and `STIGG-Set-ScopeTargeting.ps1` default to `-WhatIf`. Read the preview, get approval, then apply with `-WhatIf:$false`.
- **Evidence every phase.** Run `STIGG-Report.ps1` at Validate and after each Expand wave; retain the JSON/CSV per your IL4/IL5 change-control process.
- **Least privilege for operators.** Assign **Intune Administrator** in the Gov tenant; reserve **Global Administrator** for tenant-wide changes. Consider **scope tags** to fence STIG objects from other admins.
- **Pilot is not optional.** In an IL4/IL5 fleet, an over-broad lockdown is expensive to unwind. The gates exist to catch breakage in 5–15 pilot devices, not thousands.

## Reliability & operations

- **Design around missing servicing features.** GCC High/DoD lacks Intune Windows Update **feature/quality/expedite/driver** policies — plan patching via your available servicing path and **verify for GCC High/DoD** as Microsoft ships these.
- **Confirm connector availability before depending on it.** Only MTD/partner connectors valid in the Gov cloud appear when you sign in; don't make a Commercial-only integration a compliance dependency.
- **PowerShell 7+ on the admin workstation.** The Graph SDK's sovereign-cloud auth (and WAM workaround `Set-MgGraphOption -DisableLoginByWAM $true` from jumpboxes) is most reliable on PS7+.
- **Re-run Discovery before big changes.** A quick `STIGG-Discovery.ps1` catches drift and object collisions before you touch assignments.

## Documentation & handoff

- Keep the **rule→setting map**, the **benchmark-version ledger**, and the **per-wave evidence** together. That package *is* your STIG program's audit story.
- Note any rule delivered via **custom OMA-URI because the CSP wasn't yet in GCC High** — revisit those when the sovereign feature set catches up, and retire the workaround.
