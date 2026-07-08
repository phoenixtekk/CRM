# Best Practices — Teams Chat & Channel DLP

Field-tested guidance for running Teams DLP well. It complements — does not replace — the
implementation steps and the pass/fail gates.

## Cover messages AND files — the single most common gap

- **Enable all three locations.** A "Teams DLP" policy that only enables the **Teams chat and channel
  messages** location leaves **shared files uncovered** — those files live in **SharePoint** (channel
  files) and **OneDrive** (chat files). Always enable **Teams messages + SharePoint + OneDrive** so
  the control is complete. `DLPTEAMS-Validate.ps1` gate **A3** exists precisely to catch this.
- **Say so if you deliberately scope to messages only.** If files are out of scope for a phase,
  document it — otherwise stakeholders will assume "Teams DLP" covered the confidential file someone
  dropped in a channel.

## Deploy the way the house model says — simulate, then enforce

- **Never enforce a rule you have not validated in simulation.** The most common cause of a Teams DLP
  incident is a **block** moved to enforce without a simulation pass. Every rule goes
  **Audit/simulation → validate → enforce**, one ring at a time.
- **Small pilot ring first.** Scope a pilot user group (`SG-TeamsDLP-Pilot`) before the tenant. It is
  far cheaper to find a false positive on ten users than ten thousand.
- **Enforce messages and files separately.** Do not flip both rules to block together — enforce the
  higher-risk path first (often external message sharing), validate, then the other.
- **Keep a rollback ready.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to
  simulation) or `-Mode Disable` stops enforcement instantly — know the command before you enforce.

## Get the internal-vs-external logic right

- **Differentiate recipients deliberately.** A very common, proportionate posture is **audit / policy
  tip for internal** sharing but **block when shared externally / with everyone**. Decide this with
  compliance (R6) — it balances protection against disrupting normal internal collaboration.
- **Treat external/federated participants as the higher-risk path.** Sensitive content leaving to a
  guest or federated tenant is the exposure most Teams DLP programs exist to stop.

## Key the rules on *sensitive* content, not everything

- **Condition on labels and/or SITs**, not "all content." A Teams rule that blocks *any* message with,
  say, a number pattern will generate noise and workarounds; one that blocks **labeled/classified**
  content is defensible and proportionate.
- **Lead with sensitivity labels where they exist** — a label is an explicit business decision about
  sensitivity and travels with the file. Fall back to **sensitive information types** where labels are
  not yet adopted, and tune SIT confidence/count to reduce false positives before you enforce.

## Write a clear policy tip

- **A good policy tip reduces tickets.** Tell the user *what* happened and *what to do* ("This message
  contains sensitive information and wasn't delivered to external recipients; remove it or contact
  compliance"). Get it approved (R8) before enforce.
- **Use override/business-justification thoughtfully** where the business genuinely needs a path — and
  make sure the override is **logged** for the evidence pack.

## Operate it, don't set-and-forget

- **Review Activity explorer and DLP reports regularly** and roll up with `DLPTEAMS-Report.ps1`.
  Rising match volume on a path is a signal to review scope, tuning, or user education — not
  automatically a reason to block harder.
- **Mind the default Teams DLP policy.** Tenants may have a **default** Teams DLP policy — know whether
  it exists and how it interacts with yours (`DLPTEAMS-Discovery.ps1` lists policies and their
  locations) so you do not double-apply or conflict.
- **Version and name policies clearly.** Move from `DLP-Teams-Pilot` to a production `DLP-Teams` as you
  exit pilot; keep a change log of scope and action changes.
- **Re-validate after portal changes.** The Purview portal and the Teams DLP scope (e.g. private/
  shared channel coverage) evolve; re-run `DLPTEAMS-Validate.ps1` after Microsoft feature updates and
  confirm nothing regressed.

## Keep the roles and determinations where they belong

- **Least privilege.** DLP authoring uses a specific compliance role — do not run it from a standing
  Global Administrator session.
- **Determinations stay with the owners.** *Which* data is sensitive, *which* paths to block, and
  *whether* a message/share is a violation are **compliance / security / HR-legal** calls. You provide
  the configuration and the evidence, not the judgement (see `global-requirements-purview.md` §5).
- **Communicate before you enforce.** Policy tips and user notice reduce friction and support the
  lawful, transparent operation of a Teams control; surprise blocks generate tickets and workarounds.

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only add
  `-Commit`/`-Apply` when you intend to write, under change control.
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets.
- **Least-privilege connections.** Connect with the least-privilege role that the task needs, not a
  standing Global Administrator session.
