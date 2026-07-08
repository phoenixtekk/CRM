# Best Practices — Endpoint DLP for Windows

Field-tested guidance for running Windows Endpoint DLP well. It complements — does not replace — the
implementation steps and the pass/fail gates.

## Deploy the way the house model says — simulate, then enforce

- **Never enforce a channel you have not validated in simulation.** The single most common cause of a
  DLP incident is a **Block** rule that was moved to enforce without a simulation pass. Every channel
  goes **Audit/simulation → validate → enforce**, one ring at a time.
- **Small pilot ring first.** Onboard and scope a handful of devices (`DG-EDLP-Pilot`) before the
  estate. It is far cheaper to find a false positive on ten machines than ten thousand.
- **One change at a time.** Do not flip all five channels to **Block** together. Enforce the
  highest-risk channel first (often USB or cloud egress), validate, then the next.
- **Keep a rollback ready.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to
  simulation) or `-Mode Disable` stops enforcement instantly — know the command before you enforce.

## Key the rules on *sensitive* content, not everything

- **Condition on labels and/or SITs**, not "all content." An endpoint policy that blocks *any* USB
  copy will generate noise and workarounds; one that blocks **labeled/classified** content is
  defensible and proportionate.
- **Lead with sensitivity labels where they exist** — a label is an explicit business decision about
  sensitivity and travels with the file. Fall back to **sensitive information types** where labels
  are not yet adopted, and add label conditions as labeling matures.
- **Tune SIT confidence and count** to reduce false positives before you enforce.

## Get the endpoint global settings right — they are the vocabulary

- **Maintain the allow-list groups deliberately.** `USBG-Corporate`, `PRNG-Corporate`, and
  `NSG-Corporate` are what let you **block the bad path without blocking the business**. Review them
  on a schedule; a stale allow-list is both a false-positive source and a bypass.
- **Cover all three browsers.** Edge is native; **Chrome and Firefox need the Microsoft Purview
  browser extension** or their cloud-egress/clipboard-to-web activity is invisible. An un-extended
  browser is an open door — treat it as an **unallowed browser** until the extension is deployed.
- **Curate service domains vs sensitive service domains** so sanctioned SaaS uploads are allowed and
  personal/consumer cloud is controlled. Keep the list current as the business adopts new tools.
- **Use file-path exclusions sparingly** — each exclusion is a monitoring blind spot.

## Onboarding hygiene

- **Onboarding is shared with Defender for Endpoint** — coordinate so you do not double-manage or
  fight another team's onboarding/offboarding. Confirm devices in **Purview → Devices**, not by
  assumption.
- **Keep the Windows client and AV current** — endpoint sensing depends on it; unpatched devices
  under-report.
- **Offboard cleanly** using the offboarding package when a device leaves scope; do not just delete
  the record.

## Operate it, don't set-and-forget

- **Review Activity explorer (Devices) regularly** and roll up with `DLPWIN-Report.ps1`. Rising
  activity on a channel is a signal to review scope, tuning, or user education — not automatically a
  reason to block harder.
- **Watch override / business-justification trends.** A channel that is constantly overridden may be
  mis-scoped or may indicate a genuine business need that belongs in an allow-list, not a block.
- **Version and name policies clearly.** Move from `EDLP-Windows-Pilot` to a production `EDLP-Windows`
  as you exit pilot; keep a change log of scope and action changes.
- **Re-validate after portal changes.** The Purview portal and the endpoint restriction options
  evolve; re-run `DLPWIN-Validate.ps1` after Microsoft feature updates and confirm nothing regressed.

## Keep the roles and determinations where they belong

- **Least privilege, split duties.** DLP authoring and device onboarding are different roles — do not
  fold them into one over-privileged account.
- **Determinations stay with the owners.** *Which* data is sensitive, *which* channels to block, and
  *whether* an action is a violation are **compliance / security / HR-legal** calls. You provide the
  configuration and the evidence, not the judgement (see `global-requirements-purview.md` §5).
- **Communicate before you enforce.** Policy tips and user notice reduce friction and support the
  lawful, transparent operation of an endpoint control; surprise blocks generate tickets and
  workarounds.

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only
  add `-Commit`/`-Apply` when you intend to write, under change control.
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets.
- **Least-privilege connections.** Connect with the least-privilege role that the task needs, not a
  standing Global Administrator session.
