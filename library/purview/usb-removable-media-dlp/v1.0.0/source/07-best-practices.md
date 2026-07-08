# Best Practices — USB & Removable-Media DLP

Field-tested guidance for running USB / removable-media control well. It complements — does not
replace — the implementation steps and the pass/fail gates.

## Run both layers, and know what each one is for

- **Endpoint DLP is content-aware; device control is device-aware.** Use them together: Endpoint DLP
  stops *sensitive content* from reaching removable media; device control governs *the medium* (allow
  / read-only / block by device group) regardless of content. Neither alone gives the full picture.
- **Lead with the layer that matches the intent.** If the goal is "sensitive data must not leave on a
  stick," the Endpoint DLP content rule is primary. If the goal is "only corporate USBs are usable,"
  the device-control layer is primary. Most organizations want both.

## Deploy the way the house model says — simulate/audit, then enforce

- **Never enforce a control you have not validated in simulation/audit.** The single most common cause
  of a removable-media incident is a **Block** or **read-only** setting pushed without a
  simulation/audit pass. Each layer goes **simulation/audit → validate → enforce**, one ring at a time.
- **Small pilot ring first.** Onboard and scope a handful of devices (`DG-USB-Pilot`) before the
  estate. It is far cheaper to find a false positive on ten machines than ten thousand.
- **One layer at a time to enforce.** Do not flip both content-block and device-block on together.
  Enforce one, validate, then the other.
- **Keep a rollback ready.** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to
  simulation) or `-Mode Disable` stops DLP enforcement instantly; reverting the device-control policy
  to **audit** in your management tool stops that layer. Know both before you enforce.

## Curate the removable-storage device group deliberately

- **`USBG-Corporate` is what lets you block the bad path without blocking the business.** Keep it
  accurate and review it on a schedule — a stale allow-list is both a false-positive source and a
  bypass (an unapproved device slipping in, or a retired device still trusted).
- **Choose device-matching properties that are hard to spoof** where your standard allows (serial
  number / device instance) rather than only broad vendor IDs, so "corporate" really means corporate.
- **Use file-path exclusions sparingly** — each exclusion is a monitoring blind spot.

## Key the content rule on *sensitive* content, not everything

- **Condition on labels and/or SITs**, not "all content." An Endpoint DLP rule that blocks *any* USB
  copy generates noise and workarounds; one that blocks **labeled/classified** content is defensible
  and proportionate. (If you want to stop *all* USB use, that is the **device-control** layer's job,
  not a content rule keyed to "all content.")
- **Lead with sensitivity labels where they exist** — a label is an explicit business decision about
  sensitivity and travels with the file. Fall back to **sensitive information types** where labels are
  not yet adopted, and tune SIT confidence/count to reduce false positives before you enforce.

## Onboarding hygiene

- **Onboarding is shared with Defender for Endpoint** — coordinate so you do not double-manage or
  fight another team's onboarding/offboarding. Confirm devices in **Purview → Devices**, not by
  assumption. **No onboarding, no removable-media control.**
- **Keep the client and AV current** — endpoint sensing depends on it; unpatched devices under-report.
- **Offboard cleanly** using the offboarding package when a device leaves scope; do not just delete
  the record.

## Operate it, don't set-and-forget

- **Review Activity explorer (Devices) and device-control audit regularly** and roll up with
  `DLPUSB-Report.ps1`. Rising removable-media activity is a signal to review scope, tuning, or user
  education — not automatically a reason to block harder.
- **Watch override / business-justification trends.** Constant overrides may mean a genuine business
  need that belongs in `USBG-Corporate` (or a scoped exception), not a block.
- **Version and name policies clearly.** Move from `EDLP-USB-Pilot` / `DC-RemovableStorage-Pilot` to
  production names as you exit pilot; keep a change log of scope and action changes across **both**
  the Purview policy and the management-tool device-control policy.
- **Re-validate after portal / management-tool changes.** The Purview portal and the device-control
  surfaces evolve; re-run `DLPUSB-Validate.ps1` after Microsoft feature updates and confirm nothing
  regressed.

## Keep the roles and determinations where they belong

- **Least privilege, split duties.** DLP authoring, device onboarding, and device-control deployment
  are different roles — do not fold them into one over-privileged account.
- **Determinations stay with the owners.** *Which* data is sensitive, *which* devices are approved,
  and *whether* an action is a violation are **compliance / security / HR-legal** calls. You provide
  the configuration and the evidence, not the judgement (see `global-requirements-purview.md` §5).
- **Communicate before you enforce.** Policy tips and user notice reduce friction and support the
  lawful, transparent operation of a removable-media control; surprise blocks generate tickets and
  workarounds.

## Security & handling of the tooling

- **Read-only / `-WhatIf` by default.** Run the provided scripts in their safe default first; only add
  `-Commit`/`-Apply` when you intend to write, under change control.
- **No secrets in code.** The scripts use interactive modern-auth (`Connect-IPPSSession` /
  `Connect-MgGraph`); never hardcode credentials, tokens, or app secrets. The scripts **report** on
  the device-control policy but never invent a cmdlet to deploy it.
- **Least-privilege connections.** Connect with the least-privilege role that the task needs, not a
  standing Global Administrator session.
