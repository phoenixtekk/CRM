# 7. Best Practices — Mandatory vs Recommended Labeling Policy Design

Field-tested practices for deciding **where to require a label versus where to suggest one** — getting
high classification rates **without a user revolt**. These complement the Implementation and Testing
guides.

## Choosing mandatory vs recommended
- **Mandatory forces *a* label, not the *right* one.** A hard requirement guarantees content is labelled, but under pressure users pick the first (usually lowest) label to dismiss the prompt — which quietly corrupts your classification data. Pair mandatory with a **sensible default** and **recommended prompts** so the *easy* choice is also the *right* one.
- **Recommend where a nudge is enough.** For content that isn't uniformly sensitive, a **recommend** prompt ("this looks like financial data — apply Confidential?") raises correct-label rates without the backlash. Reserve mandatory for populations/content where an unlabelled item is a real risk.
- **Default label is your floor, not your answer.** Set the default to a **low, non-encrypting** label (commonly `General`) so nothing is ever silently unlabelled — but never default to a protected/encrypting label (surprise encryption is the fastest way to lose user trust).
- **Layer the levers.** The strongest design is usually *default `General` + recommend the right higher label on matching content + mandatory so nothing escapes unlabelled + downgrade justification for evidence* — not mandatory alone.

## Rollout discipline (no simulation — so pilot is everything)
- **There is no simulation mode for these settings.** Unlike service-side auto-labeling, mandatory/default/downgrade settings apply the moment you commit them. The **pilot ring is your only safety net** — always configure on `LabelPolicy – Pilot – Ring1` first and validate friction before touching `LabelPolicy – Broad – AllUsers`.
- **`-WhatIf` before every commit.** Every provided config action previews with `-WhatIf` and changes nothing until `-Commit`. Keep it that way; read the preview.
- **Relax Outlook first, tighten later.** Blocking every email send is the loudest adoption complaint. Start with mandatory on **documents**, Outlook **relaxed** (`DisableMandatoryInOutlook`), and only tighten Outlook if adoption data shows it's needed.
- **Measure pilot friction, not just correctness.** Track ticket volume, send-blocking complaints, and mislabel rate on the pilot. Acceptable friction — not just "the setting works" — is the gate to expand.

## Defaults, downgrade, and evidence
- **Downgrade justification is cheap and high-value.** Requiring a typed justification to lower/remove a label deters careless downgrades and produces an **audit trail** for investigations — turn it on early.
- **Confirm the default classification with governance.** The enterprise default label is a real business decision (§2.6), not a technical default — get it signed off; the wrong default over- or under-classifies everything.
- **Keep the default non-encrypting.** A default that encrypts will encrypt content users never intended to protect. Default to marking-only tiers.

## Avoiding policy conflicts
- **One coherent policy per population.** Overlapping label policies with **different** mandatory/default values create unpredictable behaviour (priority decides, opaquely). Run `IPMANREC-Health.ps1` to catch users covered by conflicting policies.
- **Mind policy priority.** When users are in scope of multiple policies, order/priority resolves which default and mandatory value wins — verify it resolves the way you intend, don't assume.
- **Retire the pilot policy cleanly.** Once broad rollout is validated, decide whether the pilot policy stays (as a fast ring for future changes) or is removed — don't leave an orphaned pilot policy mandating for a group that no longer exists.

## Program & change management
- **Communicate before you mandate.** The ticket flood comes from surprise. Tell users what will change (the prompt on save, the justification on downgrade), why, and where to get help — before you commit the broad policy.
- **Document a rollback per setting.** Each setting is reversible: remove mandatory (`-DisableMandatory`), unset the default, unpublish the policy (`Remove-LabelPolicy`), or set a recommend label back from Automatic. Know the exact command before you commit.
- **Re-baseline periodically.** Run `IPMANREC-Discovery.ps1` / `IPMANREC-Reporting.ps1` on a cadence to catch policy drift, conflicting defaults, and labels silently flipped from Recommend to Automatic.

## Security & safety hygiene
- **No credentials in code.** All scripts authenticate interactively via `Connect-IPPSSession`; never embed secrets. Store any exported evidence securely.
- **Read-only or `-WhatIf` by default.** Discovery/validation/reporting/health scripts are read-only; the config script defaults to `-WhatIf` and requires `-Commit` for any write. Keep it that way.
- **Verify licensing/tenant before relying on recommended prompts.** Client-side recommend labeling with advanced conditions is plan-gated and the portal evolves — flag, don't assume.
