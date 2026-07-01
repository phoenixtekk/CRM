# Executive Summary — AppLocker to WDAC (App Control for Business) Migration

AppLocker has served its time, but it enforces application control late in the boot/run chain and
is increasingly outpaced by modern threats. `WDAC` — now branded App Control for Business — enforces
deeper, at the OS code-integrity layer, and aligns with current security practice. The risk in
switching is real: get a WDAC policy wrong and you lock users out of the apps they need. This
solution is the controlled migration from AppLocker to WDAC, delivered through Microsoft Intune.

This is a complete, deploy-it-today package for migrating application control off AppLocker and onto
WDAC / App Control for Business, written for an administrator with no prior WDAC experience.

## What you get
- A plain-language Solution Overview of why WDAC beats AppLocker, the migration model (translate to audit to enforce), AppLocker/WDAC coexistence, and managed-installer / ISG trust.
- A Requirements Guide with verify / implement-if-missing for every prerequisite, including the existing AppLocker policy export and a pilot ring.
- An Implementation Guide of precise, ordered Intune steps: export and translate AppLocker rules, author the WDAC policy, deploy in audit mode, close gaps, enforce by ring, and retire AppLocker.
- Five PowerShell scripts for current-state discovery, audit-event and policy validation, a migration coverage and would-block report, safe audit-mode revert, and a migration-ring group builder.
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
A WDAC policy translated from your existing AppLocker rules, deployed first in audit mode so it
catches every gap before it can block anyone, then promoted to enforcement in rings — pilot first,
fleet last — with AppLocker kept coexisting until the WDAC policy is proven, then retired. No user
lockouts: enforcement is never turned on until the audit log is clean of legitimate blocks.

## The deployment model
Assess to Configure to Pilot to Validate to Expand — with a mandatory audit gate before any
enforcement and a documented rollback at every stage.

## Outcome
Application control moved from AppLocker to WDAC — translated, audited, and enforced in rings with no
user lockouts — and AppLocker retired, proven on a pilot before you scale.
