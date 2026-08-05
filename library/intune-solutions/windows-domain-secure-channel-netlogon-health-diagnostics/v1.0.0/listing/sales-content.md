# Sales Content — Windows Domain Secure-Channel & Netlogon Health Diagnostics Toolkit

## Hook
**Stop guessing at Netlogon Event ID 5719.** Find and fix the real cause of a broken domain secure
channel on any domain-joined Windows PC — DNS/DC-locator, Kerberos time skew, blocked DC ports, no DC
path, the boot-time NIC race, or an invalid IPv6 config — with read-only endpoint PowerShell you run
locally or fleet-wide via Intune Proactive Remediations.

## The problem
Devices are enrolled and joined, but they still fail to log on, drop mapped drives, or lose Group Policy
— and the System log fills with **5719: "There are currently no logon servers available."** That one
message has several distinct causes, and teams burn hours bouncing between Event Viewer, `nltest`,
`w32tm`, DNS, and the registry to find which. A common self-inflicted twist: someone once pasted a
"disable IPv6" tweak that set an **invalid** `DisabledComponents` value and quietly broke name
resolution — a fix that Microsoft doesn't even support.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — one **Discovery** pass reports every signal at once: 5719 events, secure channel, DC
  locator, DNS SRV, time sync, DC ports (88/135/389/445), and the IPv6 value. Every output folder and
  object is named and reused.
- **Cheaper** — one fixed price, not an open consulting meter; reusable on every device and every
  incident.
- **Tested** — the repeatable diagnostics arc (**Assess → Diagnose → Repair → Validate → Prevent**)
  with explicit pass/fail gates, read-only-by-default scripts, and a repair that previews before it
  changes anything.

## What's inside
- **Solution Overview, Requirements, Implementation, Testing, Troubleshooting, Best Practices** — the
  complete step-by-step guide, honest about every 5719 cause and the correct **IPv6 recommended
  configuration** (keep IPv6 enabled; only correct invalid `DisabledComponents` values — never disable
  it, which breaks DirectAccess/Remote Assistance/HomeGroup and is unsupported).
- **5 endpoint PowerShell scripts** — Discovery, Validation, Report, Collect (read-only) and
  Remediation (defaults to `-WhatIf`). In-box commands only; run locally or as SYSTEM via Intune
  Proactive Remediations (Validation = detection, Remediation = remediation).

## The repeatable way
Every solution follows the same repeatable shape, so each incident feels familiar and low-risk — buy
once, reuse the playbook for the next device and the next project.

## The bottom line
The true cause of Event ID 5719 identified and repaired on any domain-joined Windows device, IPv6
restored to a supported configuration, and a fleet-wide health check you can run on demand — without a
consulting engagement and without touching how devices are joined or enrolled.

*Delivered as a Word document and PDF, plus all PowerShell scripts in a single ZIP — yours to keep and
reuse across unlimited devices.*
