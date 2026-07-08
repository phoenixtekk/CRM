# Best Practices — Browser & Network DLP (Microsoft Purview)

Field-tested guidance for running Browser & Network DLP well. It complements — does not replace — the
implementation steps and the pass/fail gates.

## Deploy the way the house model says — simulate, then enforce

- **Never enforce a web-upload block you have not validated in simulation.** The single most common
  cause of a DLP incident is an upload **Block** moved to enforce without a simulation pass — it breaks
  legitimate work and floods support. The control goes **Audit/simulation → validate → enforce**, one
  ring at a time.
- **Small pilot ring first.** Onboard and scope a handful of devices (`Browser & Network DLP Pilot Ring
  – Stage1`) before the estate. It is far cheaper to find a false positive on ten machines than ten
  thousand.
- **Escalate the action ladder deliberately.** Start the sensitive service domain group at **Audit**,
  move to **Warn (block with override + business justification)**, and only then **Block** the
  highest-risk destinations. Do not jump straight to Block.
- **Keep a rollback ready.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to
  simulation) or `-Mode Disable` stops enforcement instantly, and the domain-group action can be
  returned to **Audit** in the portal — know both before you enforce.

## Key the rule on *sensitive* content, not every upload

- **Condition on labels and/or SITs**, not "all content." A policy that flags *every* upload to a
  destination generates noise and workarounds; one that flags **labeled/classified** content going to
  an unsanctioned destination is defensible and proportionate.
- **Lead with sensitivity labels where they exist** — a label is an explicit business decision about
  sensitivity and travels with the file. Fall back to **sensitive information types** where labels are
  not yet adopted, and add label conditions as labeling matures.
- **Tune SIT confidence and count** to reduce false positives before you enforce.

## Get the browser & domain settings right — they are the vocabulary

- **Curate the sensitive service domain group deliberately.** `Unsanctioned & Personal Cloud – Domain
  Group` is what the upload restriction acts on. Build it from where uploads *actually* go (Activity
  Explorer, and any proxy / Defender for Cloud Apps discovery), and keep it current as the business
  adopts new tools. An incomplete list leaves egress paths uncontrolled; an over-broad one blocks
  sanctioned work.
- **Distinguish sanctioned from unsanctioned destinations.** Corporate OneDrive/SharePoint and approved
  SaaS are sanctioned and should not be in the restricted group; personal/consumer cloud and
  unsanctioned file-sharing are what you control.
- **Cover all three browsers.** Edge is native; **Chrome and Firefox need the Microsoft Purview browser
  extension** or their upload activity is invisible. An un-extended browser is an open door — treat it
  as an **unallowed browser** until the extension is deployed and confirmed.
- **Use the unallowed-browsers control as a steering tool, not a guarantee.** It steers users toward a
  browser Purview can see into; it is not a wall against a determined user on unmanaged equipment.

## Onboarding & extension hygiene

- **Onboarding is shared with Defender for Endpoint** — coordinate so you do not double-manage or fight
  another team's onboarding/offboarding. Confirm devices in **Purview → Devices**, not by assumption
  (`DLPBROWSER-ScopeHealth.ps1` reports a proxy count; the portal is authoritative).
- **Manage the extension through enterprise browser policy** (Group Policy / Intune / browser
  management) and verify it is actually installed and enabled on sample devices. Re-check after browser
  or extension updates — the extension name/ID can change.
- **Keep the endpoint client and OS current** — endpoint sensing depends on it; unpatched devices
  under-report.

## Operate it, don't set-and-forget

- **Review upload/egress activity regularly** (`DLPBROWSER-Report.ps1`, and Activity explorer filtered
  to Devices). Rising activity to a destination is a signal to review the domain group, tuning, or user
  education — not automatically a reason to block harder.
- **Watch override / business-justification trends.** A destination that is constantly overridden may be
  mis-scoped or may indicate a genuine business need that belongs in the sanctioned list, not a block.
- **Version and name policies clearly.** Move from `Browser & Network DLP – Devices – Pilot` to a
  production name as you exit pilot; keep a change log of domain-group, scope, and action changes.
- **Re-validate after portal changes.** The Purview portal and the Endpoint DLP browser/domain settings
  evolve; re-run `DLPBROWSER-Validate.ps1` after Microsoft feature updates and confirm nothing
  regressed.

## Keep the roles and determinations where they belong

- **Least privilege, split duties.** DLP authoring and device onboarding are different roles — do not
  fold them into one over-privileged account. Author with Compliance Administrator / Compliance Data
  Administrator, not standing Global Administrator.
- **Determinations stay with the owners.** *Which* data is sensitive, *which* destinations are
  "unsanctioned," and *whether* an upload is a violation are **compliance / security / HR-legal** calls.
  You provide the configuration and the evidence, not the judgement (see
  `global-requirements-purview.md` §5).
- **Communicate before you enforce.** Policy tips and user notice reduce friction and support the
  lawful, transparent operation of a web-upload control; surprise blocks generate tickets and
  workarounds.

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only add
  `-Commit` when you intend to write, under change control.
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets.
- **Least-privilege connections.** Connect with the least-privilege role the task needs, not a standing
  Global Administrator session; the assessment/health scripts need only Graph **read** scopes.
