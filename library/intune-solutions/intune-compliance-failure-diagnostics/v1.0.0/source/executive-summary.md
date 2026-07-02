# Executive Summary

## The problem

A managed device flips to **non-compliant**. Conditional Access immediately blocks the user
from email, files, and apps. The help desk cannot say **which setting failed**, **why**, or
**when access will return** — so the fastest-looking fix becomes the most dangerous one:
disabling or loosening the compliance policy, which strips protection from the entire fleet
to unblock one person.

## The solution

**Intune Compliance-Failure Diagnostics & Remediation** replaces guesswork with a
**repeatable root-cause method** and a set of read-only-by-default PowerShell scripts. It
teaches exactly how Intune decides compliance — **policy → per-setting state → grace period
→ device state → Conditional Access gate** — and gives a symptom-driven decision tree to
read the **per-setting failure reason**, tell **evaluation lag from a real failure**, check
**grace expiry**, distinguish **built-in from Custom compliance** rules, and measure the
**Conditional Access blast radius**. Then it remediates the **cause** — safely, staged to a
pilot group — **without ever disabling policy fleet-wide**.

## What is included

- **Diagnostic Playbook** — the symptom tree, with exact Intune/Entra navigation and a
  script check at every branch.
- **Five PowerShell scripts** — compliance-state discovery, per-device per-setting failure
  validation, a fleet compliance + Conditional Access-impact report, safe remediation of
  common failures, and a pilot/target-group builder. Discovery, Validation, and Report are
  read-only; Remediation and Set-ScopeTargeting default to **-WhatIf** (preview first).
- **Requirements, Testing, Troubleshooting, and Best Practices** — including the three
  pass/fail gates (setting passes → device compliant → CA allows) and grace/staged-
  enforcement guidance.

## Business value

- **Faster resolution** — every non-compliant device explained to the exact failing setting,
  cutting help-desk time and user downtime.
- **No self-inflicted exposure** — the method fixes the cause without weakening compliance
  for everyone; safe to run mid-incident because the tools read by default.
- **Clear impact** — you can state the Conditional Access blast radius (who is blocked, by
  which policy) before you act.
- **A capability you keep** — a documented method and reusable scripts, at a fraction of the
  cost of engaging a consultant for each incident.

## Bottom line

Know exactly **why** a device is non-compliant — the failing setting, the timing and grace,
and the Conditional Access impact — and remediate it **safely**, using a method and scripts
your team keeps and reuses.
