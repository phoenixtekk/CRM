# 2. Requirements Guide — Netskope Client Troubleshooting & Diagnostics Toolkit

Verify **every** requirement before running the toolkit at scale. Each entry: **Description · Why ·
Verify · Implement-if-missing.** Category-wide prerequisites are in `global-requirements-network.md`.

## 2.1 Netskope client deployed on endpoints
**Description:** The Netskope client is installed and intended to run on the target endpoints.
**Why:** This toolkit triages an existing client; there is nothing to diagnose without it.
**Verify:** Run `NSDIAG-Discovery.ps1`; it reports the client's installed state, services, and processes.
**Implement:** Deploy the client through Intune (or your endpoint manager) per Netskope's deployment docs, then re-run discovery.

## 2.2 Local administrator rights on the endpoint
**Description:** The technician (or a script-run context) has local admin on the device under triage.
**Why:** Reading service state and certificates, and any restart/repair/re-enroll remediation, requires elevation.
**Verify:** Run an elevated PowerShell session; `NSDIAG-Discovery.ps1` completes without access-denied warnings.
**Implement:** Grant local admin for the support context (e.g. a privileged help-desk account or a managed elevation tool).

## 2.3 Access to client logs (for handoff)
**Description:** The ability to locate and collect the Netskope client's own log files for escalation.
**Why:** Cloud/console-side faults are diagnosed to the boundary, then escalated with vendor-specific logs.
**Verify:** Confirm the client log location per Netskope's documentation for your client version.
**Implement:** Document the log path from Netskope docs in your runbook; `NSDIAG-Report.ps1` flags this as a vendor-deferred collection step. (Do not hard-code a fabricated path.)

## 2.4 Microsoft Graph access for device context
**Description:** Read access to Microsoft Graph for managed-device context (compliance, last sync, OS).
**Why:** Device context distinguishes a client fault from an enrollment/compliance fault and helps fleet triage.
**Verify:** `NSDIAG-Report.ps1` can `Connect-MgGraph` with `DeviceManagementManagedDevices.Read.All`.
**Implement:** Install the Microsoft Graph PowerShell SDK and grant the read scope to the operator/app.

## 2.5 Network reachability from the endpoint
**Description:** The endpoint can resolve DNS and reach the internet / the Netskope cloud edge.
**Why:** Steering, authentication, and inspection all depend on reachable, resolvable, routable traffic.
**Verify:** `NSDIAG-Validation.ps1` runs DNS and TCP reachability checks and reports results.
**Implement:** Remediate DNS/egress; confirm the Netskope edge hostnames/ports (per Netskope docs) are allowed through any upstream proxy/firewall.

## 2.6 A diagnostics scope group (help-desk pilot)
**Description:** A Microsoft Entra security group scoping the pilot (help-desk devices/users).
**Why:** The toolkit is piloted with the help desk before wider rollout (deployment model gate).
**Verify:** Entra → **Groups**; the `Diagnostics Scope – Help Desk – Pilot` group exists, or run `NSDIAG-Set-ScopeTargeting.ps1` to create/confirm it.
**Implement:** Create the group via Entra or `NSDIAG-Set-ScopeTargeting.ps1` and add the pilot members.

## 2.7 Change control and a rollback path
**Description:** A change window and documented rollback for any remediation that restarts/repairs/re-enrolls the client.
**Why:** Restart/repair/re-enroll touch live steering and must be reversible and communicated.
**Verify:** A rollback (re-enroll undo / client reinstall / steering exception) is written and approved before remediation.
**Implement:** Define the rollback and run remediation with the default `-WhatIf` first to preview impact.

---
## Checklist
- [ ] Netskope client deployed — `NSDIAG-Discovery.ps1`
- [ ] Local admin on the endpoint
- [ ] Client log location documented for handoff (from Netskope docs)
- [ ] Microsoft Graph SDK + read scope for device context
- [ ] DNS/egress and Netskope edge reachability — `NSDIAG-Validation.ps1`
- [ ] `Diagnostics Scope – Help Desk – Pilot` group created
- [ ] Change control + rollback approved for remediation
