# Executive Summary

## The problem
On a managed Windows fleet, desktop support issues get **bounced between tiers** because there is
no standard way to triage them. Two technicians handed the same ticket diagnose it differently,
apply different fixes, escalate at different points, and capture different (or no) evidence. The
result is inconsistent resolutions, lost context on hand-off, and problems that are passed along
rather than **owned end to end**.

## The solution
The **Enterprise Desktop Support Runbook Library for Intune-Managed Windows** gives every
technician a repeatable, click-to-implement path for the common desktop categories. It is built for
an Intune + Entra + Windows environment and is deliberately white-label and vendor-neutral: the
Microsoft steps are documented at exact detail, and third-party product internals are deferred to
those vendors' own documentation.

Its foundation is one simple operating model applied everywhere:
**intake → triage → diagnose → resolve/escalate → document.** Each runbook has a fixed anatomy —
a **triage tree**, ordered **checks**, a **resolution**, an explicit **escalation gate**, and the
**evidence to collect** — so any technician reaches the same correct outcome.

## What's included
- **Six categorized runbooks:** sign-in/profile, OS/Windows Update, hardware/peripheral,
  application, network reachability, and enrollment/compliance.
- **Five PowerShell scripts:** endpoint health/context discovery, per-device state validation, a
  support-metrics/health report (all read-only), plus safe common-fix remediation and a
  target-group builder (both default to `-WhatIf`).
- **Requirements, Testing, Troubleshooting, and Best Practices** guides — with pass/fail gates per
  runbook and guidance for consistent triage, evidence, and escalation.

## Why it matters
- **Consistency:** every technician resolves the same issue the same way.
- **Ownership:** clear escalation gates mean issues are handed off with complete evidence, not just
  handed off.
- **Safety in a live environment:** least-disruptive fixes first; destructive actions require
  approval and backup; state-changing scripts default to `-WhatIf`.
- **Reuse and cost:** a library and scripts you keep and run across the fleet — a fraction of the
  cost of ad-hoc consulting.

## Bottom line
Give every technician a repeatable way to **triage it, resolve it, and own it** — end to end.
