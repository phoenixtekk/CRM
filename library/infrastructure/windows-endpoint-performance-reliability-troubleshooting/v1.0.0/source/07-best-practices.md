# Best Practices — Baselining & Repeatable Performance Triage

Troubleshooting one machine is firefighting. The value of this solution compounds when you make it
**repeatable** and **baselined**, so the next slow-PC ticket takes minutes and every fix is evidence-
based. These are the habits that turn the playbook into an operating standard.

## 1. Baseline before you troubleshoot

- **Establish a fleet baseline first.** Run **WINPERF-Discovery.ps1** (or read Endpoint analytics)
  across a healthy sample and record the *normal* ranges for boot time, sign-in time, startup-app
  count, and steady-state CPU/RAM/disk. "Slow" only means something relative to normal.
- **Tune the gates in 05 — Testing to your baseline.** The defaults are starting points. Replace them
  with your fleet's real numbers and write the chosen values down.
- **Re-baseline after major changes** — a Windows feature update, a new image, a new security agent —
  because these shift the normal ranges.

## 2. Measure first, always

- **Never change anything before a measurement points at it.** A reboot that "fixes" nothing wastes a
  troubleshooting opportunity and the evidence.
- **Sample over a window, not a moment.** A one-second spike is not a chronic problem; the 60-second
  counter window in the Resource branch exists to avoid false alarms.
- **Rule out storage early.** A failing or full disk masquerades as many different symptoms — check
  Branch E health/free-space before spending time in Boot, Sign-in, or Resource.

## 3. Isolate to one named cause

- **Follow the tree to a single branch.** Resist the urge to apply three fixes at once — you will not
  know which one worked, and you will not learn.
- **Name the culprit** (this driver, this service, this process, this drive), not a category. "A
  service is slow" is not actionable; "the *XYZ Sync* service adds 22 s to boot" is.

## 4. Fix safely and reversibly

- **Always preview remediation.** Run **WINPERF-Remediation.ps1** with its default `-WhatIf` first and
  read exactly what it would change (which startup items, how much temp space, which profile caches)
  before committing with `-Confirm`/explicit apply.
- **Prefer the least-destructive fix.** Delayed-start a service before disabling it; clear a cache
  before rebuilding a profile; reschedule a background task before killing it.
- **Back up before any drive or profile action.** Storage-health FAILs and full profile rebuilds touch
  user data — protect it first.

## 5. Pilot before you scale

- **Use scoped targeting.** Build a pilot Entra group with **WINPERF-Set-ScopeTargeting.ps1** (default
  `-WhatIf`) and validate any fleet-wide remediation on the pilot first — Assess → Configure → Pilot →
  Validate → Expand.
- **Expand only after the pilot passes its gates**, then widen the group in stages.

## 6. Re-measure and record

- **Prove every fix with a before/after number** against the pass gate — this is the difference between
  "I did something" and "the problem is measurably gone."
- **Keep a per-device record** of symptom → measured cause → fix → before/after. Over time this becomes
  your fastest triage tool: recurring causes jump out.
- **Feed patterns back into the baseline.** If the same driver or app crashes across many devices,
  that is a fleet action (update the image, block the app), not a per-device fix.

## 7. Escalate hardware honestly

- A drive predicting failure, insufficient RAM proven by the memory gate, or an HDD where an SSD is
  expected are **hardware** outcomes. Deliver them as a **measured recommendation** (with the numbers),
  not as a software workaround — a worn drive cannot be fixed in software.

## 8. Automate the repeatable parts

- Deliver **Discovery** and **Validation** through **Intune → Scripts and remediations** on a schedule
  so you have current signals *before* the ticket arrives.
- Run **WINPERF-Report.ps1** periodically to watch the fleet trend — a rising boot-time or crash rate
  is a problem forming, caught before users complain.
