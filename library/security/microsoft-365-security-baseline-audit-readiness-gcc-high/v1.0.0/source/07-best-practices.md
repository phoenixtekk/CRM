# Best Practices — Microsoft 365 Security Baseline & Audit Readiness (Government / GCC High)

These practices keep the posture you built from decaying and keep your audit evidence credible. They
are written for the **GCC High** sovereign cloud; where a practice differs from Commercial, that is
called out.

## Sovereign-endpoint discipline

- **Pin every tool to the `*.us` portals and US Gov Graph.** Bookmark `security.microsoft.us`,
  `compliance.microsoft.us`, `entra.microsoft.us`, `intune.microsoft.us`, `portal.office365.us`, and
  `portal.azure.us`. Delete Commercial bookmarks from the admin workstation so no one drifts to
  `*.com` out of habit.
- **Always `Connect-MgGraph -Environment USGov`.** Bake it into every runbook and script. Add a guard
  that aborts if `(Get-MgContext).Environment -ne 'USGov'` — a script run against Commercial produces
  wrong-but-plausible output, which is worse than a clean failure.
- **Reject downloaded Commercial scripts as-is.** Community Secure Score / Compliance scripts almost
  always hardcode `graph.microsoft.com` and `security.microsoft.com`. Re-point them to the sovereign
  endpoints before running, or use the scripts shipped with this solution.

## Pilot-first, always

- **Never make an auth-impacting change tenant-wide in one move.** MFA enforcement, blocking legacy
  auth, Conditional Access, and device-compliance gating all go **pilot → validate → expand**. In GCC
  High there is no Commercial fallback for locked-out cleared users.
- **Keep `SEC-Baseline-Pilot` populated with representative users** — at least one of each: admin,
  standard user, mobile-only user, and a service/shared-mailbox owner — so pilot surfaces real impact.
- **Write the rollback before you write the change.** Every change ticket names its own undo.

## Secure Score hygiene

- **Prioritize by risk, not just points.** Lead with identity (admin MFA, block legacy auth, admin
  role minimization) — highest real-risk reduction per unit of effort.
- **Don't chase phantom recommendations.** Some Commercial Secure Score actions **do not exist in GCC
  High**. Track only actions present in *your* tenant; annotate the backlog "N/A — GCC High parity"
  for the rest so auditors see it was a conscious decision, not an oversight.
- **Re-measure on a cadence.** Secure Score drifts as admins add exceptions and new services appear.
  Re-run `M365SECG-Report.ps1` monthly and diff against the last baseline.
- **Allow for refresh lag.** Score changes can take ~24–48 hours to reflect; don't declare failure the
  same day (**verify for GCC High** — Gov refresh cadence may differ).

## Compliance Manager & audit evidence

- **Start with the included baseline.** The **Microsoft Data Protection Baseline** is included for
  everyone; build the habit there before adding heavier templates.
- **Use the Gov-included frameworks you're entitled to.** With **G5 (Gov)**, **CMMC Levels 1–5** are
  included — create the assessment that matches your contractual obligation (e.g. CMMC Level 2 for
  many defense contractors) and map evidence to it.
- **Remember GCC High permission handling.** In **GCC High and DoD, Compliance Manager roles are set
  in Microsoft Entra ID**, not in the portal's own role UI. Manage those assignments in
  `entra.microsoft.us`.
- **Attach evidence, don't just check boxes.** For each improvement action, store the artifact (policy
  export, screenshot, script output) that proves it. The five scripts' outputs are audit-grade
  evidence — archive them with dates.
- **Expect a few CM features to lag.** Items like alerts/notifications and bulk-assessment automation
  may be *in development / rolling out* for GCC High; don't design a process that depends on a feature
  that isn't live yet (parity notes).

## Least privilege & operations

- **Assign the minimum role for the task** (Security Reader to read, Security Administrator to act,
  Compliance role for CM) and reserve **Global Administrator** for tenant-wide changes.
- **Use PIM for just-in-time elevation** where your Gov SKU supports it, so standing privilege is low.
- **Request only the Graph scopes you need.** Read scopes for discovery/validation/report; write scopes
  only for remediation, and only when executing.
- **Log and retain.** Keep Audit (Standard/Premium) on; retain the script evidence and change tickets
  for the retention period your framework requires.

## Change management & documentation

- **One named object, reused everywhere.** `SEC-Baseline-Pilot`, `CA-Baseline-*` policy names, and the
  named assessments are a shared vocabulary — reuse them across runbooks so the environment stays
  legible.
- **Keep a living posture log.** Date, action, pilot result, expansion waves, score delta. This log +
  the report outputs *is* your audit-readiness story.
- **Re-baseline after major service changes** (new SKU, new workload onboarded, tenant reconfiguration)
  — GCC High feature availability shifts over time as Microsoft closes parity gaps.
