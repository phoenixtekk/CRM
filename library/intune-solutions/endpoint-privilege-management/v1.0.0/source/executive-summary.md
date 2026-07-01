# Executive Summary — Endpoint Privilege Management (Microsoft Intune)

**Phoenixtekk Workplace Marketplace · Intune Solutions**

Standing local administrator rights are one of the largest unmanaged risks on a Windows fleet.
A user who is a permanent local admin can install anything, disable security tooling, and turn a
single phished click into a full device compromise — and most help desks hand out admin rights
simply because a few applications and tasks demand elevation. **Microsoft Intune Endpoint
Privilege Management (EPM)** breaks that trade-off: users run as **standard users every day**, and
only the *specific* actions you approve are allowed to elevate — automatically, with a justification
prompt, or via an explicit support approval — all centrally governed and fully audited.

This solution is a complete, **deploy-it-today** package for rolling out Endpoint Privilege
Management on Intune-managed Windows devices. It is written for an administrator with little or no
prior EPM experience: every requirement (including the **Intune Suite / EPM add-on license**) is
verified before it is used, every configuration step is exact and in order, and every result is
testable.

## What you get
- A plain-language **Solution Overview** so you understand what EPM is, the three elevation types, and why running standard-user-by-default is the goal.
- A **Requirements Guide** that tells you exactly what must be true before you start — licensing, the EPM client extension, supported Windows — and how to fix anything that isn't.
- An **Implementation Guide** of precise, click-by-click Intune steps in the required order: enable EPM, deploy the base policy, build elevation rules, pilot, and expand.
- Five **PowerShell scripts** for device readiness discovery, deployment validation, tenant-wide elevation reporting (Microsoft Graph), safe remediation, and generating signed/hash-based elevation rules from a target application.
- A **Testing Guide** that proves elevations behave exactly as your rules intend — and that nothing else can elevate.
- A **Troubleshooting Guide** for the issues that actually occur in the field.

## The Phoenixtekk deployment model
Every Phoenixtekk Intune solution follows the same shape: **Assess → Configure → Pilot →
Validate → Expand.** You will recognize this pattern in every solution you buy from us, so each
new deployment feels familiar and low-risk.

## Outcome
A measurable move toward **least privilege**: local admin rights removed from everyday users,
the handful of legitimate elevations allowed in a controlled and audited way, and a complete record
of every privileged action on the fleet — achievable by a single administrator in a controlled
pilot within a day.
