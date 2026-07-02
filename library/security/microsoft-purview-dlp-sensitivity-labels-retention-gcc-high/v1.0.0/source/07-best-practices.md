# Best Practices — Purview DLP, Labels & Retention (Government / GCC High)

Field-proven guidance for the **assign-once, repeat-everywhere** model on a **GCC High** tenant.

## Sovereign-cloud discipline (GCC High)

- **Bookmark the `.us` portals and never the `.com` ones.** Sign in at `login.microsoftonline.us`;
  administer at `compliance.microsoft.us` (→ `purview.microsoft.us`), `security.microsoft.us`,
  `entra.microsoft.us`, `portal.office365.us`. A Commercial URL in a GCC High runbook is a defect.
- **Every script targets US Gov Graph** — `Connect-MgGraph -Environment USGov` (never `Global`).
  Bake this into the header of every runbook so no one connects to the wrong cloud.
- **Treat "the option isn't there" as a parity gap, not a bug.** Before opening a support case,
  check `gcc-high-parity-notes.md` — if the feature is *in development / on backlog*, it genuinely
  is not present, and the fix is to use the GA alternative, not to troubleshoot.
- **Re-verify parity before each design.** Microsoft ships to GCC High continuously; a feature on
  the backlog last quarter may be GA now (and vice-versa). The live *Plan for Microsoft Purview —
  GCC High deployments* page is the source of truth.

## Taxonomy & labels

- **Keep the taxonomy short** — four or five labels (`Public`, `General`, `Confidential`,
  `Confidential \ CUI`) beat a sprawling tree nobody applies correctly. Get **data-owner sign-off**
  on what each label *means* before publishing.
- **Name every object verbatim and reuse it** — `LP-Purview-Pilot`, `AL-CUI-ServiceSide`,
  `DLP-CUI-Baseline`, `Ret-CUI-7yr`. Consistent names make the scripts, reports, and handover
  legible.
- **Use the label as the currency:** make `Confidential \ CUI` a **DLP condition** and a
  **retention/auto-apply condition** so one classification drives protection *and* retention —
  "label once, enforce everywhere."
- **Prefer GA classification building blocks** — built-in SITs, **Exact Data Match**, keyword
  dictionaries, regex. **Do not design on named-entity SITs** (not available in GCC High).
  Trainable classifiers are fine for **client-side sensitivity auto-labeling**, but **not** for
  auto-applying *records* labels in GCC High.

## DLP

- **Always audit before you enforce.** Ship every DLP policy in **test/audit** mode, tune out false
  positives against the pilot, and only then add **Block/Restrict** — under change control (G8).
- **Scope to the pilot group first**, expand group-by-group. A tenant-wide block on day one is how
  you take users offline.
- **Turn on policy tips and clear user justification** so users self-correct instead of filing
  tickets.
- **Endpoint DLP only covers onboarded devices** — reconcile onboarding coverage before claiming
  device protection.
- **Adaptive Protection** (risk-based DLP) is **rolling out to Gov clouds** — adopt it only after
  confirming it is present in your tenant; do not assume it from Commercial docs.

## Retention & records

- **Separate baseline retention from targeted retention:** an org-wide `RP-Baseline-Retain` for the
  floor, plus targeted `Ret-CUI-7yr` for regulated content.
- **Use adaptive scopes** (Available) to target by attribute instead of hand-maintaining locations.
- **Records need immutability:** enable **Mark as record** and **Preservation Lock** where the
  schedule must be defensible — but remember Preservation Lock cannot be undone.
- **Plan end-of-life around GA behavior:** "apply retention *label* action at end of period" is
  **not available** in GCC High — use retain-then-delete or disposition review instead.
- **Don't build record automations on Power Automate/Graph** yet — records Power Automate and records
  Graph APIs are **not available** in GCC High.

## Operations

- **Run the read-only scripts on a schedule** — `PURVIEWG-Discovery.ps1`, `PURVIEWG-Validation.ps1`,
  `PURVIEWG-Report.ps1` — to catch drift (an unscoped label, a disabled DLP rule, missing retention).
- **Keep change-tools in `-WhatIf` by default** — `PURVIEWG-Remediation.ps1` and
  `PURVIEWG-Set-ScopeTargeting.ps1` preview first; only run with `-Execute`/`-WhatIf:$false` after
  review and approval.
- **Every enforcement change is a change ticket** — approver, maintenance window, named pilot,
  documented rollback (per `global-requirements-security.md` G8).
- **Least privilege:** author with **Compliance Administrator** + **Information Protection** role
  groups, not Global Administrator.

**The deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**
