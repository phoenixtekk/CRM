# Executive Summary — macOS Enrollment, SSO & FileVault Troubleshooting & Diagnostics Toolkit

**White-label · Infrastructure Solutions**

When a Mac won't finish enrolling, won't sign in through Platform/Extensible SSO, throws a
SecureToken/FileVault error, is marked compliant yet still blocked, or locks a user out after
enrollment, the cause hides across three systems at once — the **Apple** enrollment profile, the
**Intune** policy, and the **Entra** identity. Technicians burn hours guessing which layer is at
fault, and too many stuck Macs get wiped when they needed a one-line fix.

This solution is a structured, symptom-driven **diagnostic playbook** plus tooling for the macOS +
Microsoft Intune stack. It models the signal path as layers — **ADE/enrollment → configuration
profiles → SSO → SecureToken/FileVault → compliance/Conditional Access** — and gives you a root-cause
tree that classifies the symptom, confirms each layer **top-down**, and reads the one authoritative
signal per layer, so you isolate the failing layer in minutes. It is written for a competent Intune
administrator or Mac technician who needs a proven method instead of trial and error.

## What you get
- A plain-language **Solution Overview** of the macOS-Intune signal path, the layered model behind the
  root-cause tree, the five failure classes, and the diagnose-then-resolve method.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite — Intune and
  Microsoft Graph read access, the Apple Business/School Manager vantage point, on-Mac diagnostic
  access, and device logs.
- A **Diagnostic Playbook** — the symptom tree with a branch for each class (ADE not assigned /
  enrollment stuck, SSO won't sign in, SecureToken/FileVault error, compliant-but-denied, user locked
  out) and the exact checks and fixes per branch.
- Five **PowerShell scripts** (Microsoft Graph SDK) for device discovery, per-layer validation, a
  fleet health and escrow-coverage report, safe Sync-based remediation, and a scope/target-group
  builder — read-only where it matters, with the two write-capable scripts defaulting to `-WhatIf`.
- **Testing** and **Troubleshooting** guides with explicit pass/fail gates, plus **Best Practices**
  for evidence-based escalation.

## What this delivers
A diagnostic capability your team keeps: every macOS ticket is triaged the same way — classified,
confirmed top-down, and resolved at the layer that actually failed — so Macs stop getting wiped on a
hunch and knowledge stops walking out the door. Pilot the playbook on real failures, prove it, then
make it the standard.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
The failing layer of a stuck Mac isolated in minutes — enrollment, SSO, SecureToken/FileVault, or
compliance — with a repeatable playbook and scripts you keep and reuse, validated on real failures
before you scale it across the support team.
