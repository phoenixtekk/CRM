# Executive Summary — Workspace ONE to Intune: macOS Device Migration

Moving a Mac fleet off Workspace ONE and onto Microsoft Intune is not a switch you flip — it is a
device handoff. Each Mac must be re-assigned in Apple Business Manager from the old MDM server to
Intune, re-enrolled, and then rebuilt to the same posture it had before: settings-catalog policies,
custom `.mobileconfig` profiles, and shell scripts, all at parity. Done ad hoc, it produces
half-managed Macs, dropped profiles, and unhappy users. Done the repeatable way, it is a controlled,
ringed cutover you can prove on a pilot before you scale.

This is a complete, deploy-it-today package for migrating macOS devices from Workspace ONE to
Microsoft Intune, written for an administrator with no prior migration experience. It treats
Workspace ONE internals as the vendor's domain (deferred to VMware documentation) and gives exact,
named steps for the Microsoft Intune and Apple Business Manager surfaces you control.

## What you get
- A plain-language Solution Overview of the macOS migration model — Apple Business Manager
  re-assignment, ADE / Account-driven re-enrollment, and rebuilding configuration for parity.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, ordered steps: connect ABM to Intune, build enrollment
  profiles, reassign Macs in ABM, re-enroll by ring, rebuild profile and shell parity, validate, expand.
- Five PowerShell scripts for migration-readiness discovery, per-device enrollment and parity
  validation, a migration status and parity report, safe remediation of stuck enrollments, and a
  migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates.

## What this delivers
A repeatable Workspace ONE to Intune macOS migration: each Mac re-assigned in Apple Business Manager,
re-enrolled into Intune via Automated Device Enrollment or Account-driven enrollment, and rebuilt to
full configuration parity, rolled out in migration rings with a pilot gate and a documented rollback.

## The standard deployment model
Assess to Configure to Pilot to Validate to Expand.

## Outcome
Macs moved from Workspace ONE to Intune — re-assigned in Apple Business Manager, re-enrolled, and
rebuilt to full macOS profile and shell-script parity — proven on a pilot ring before you scale.
