# Executive Summary — Microsoft Intune First-Time Setup for Windows

This solution takes an organization from **Intune turned on but no Windows devices under management**
to **its first Windows devices enrolled two ways** — through **user-driven enrollment** (a user joins
their PC to Microsoft Entra ID and it auto-enrolls into Intune) and through **basic Windows Autopilot**
(a new or reset device provisions itself, zero-touch, into a managed state during the out-of-box
experience). It is deliberately the **beginner on-ramp**: Windows only, **Microsoft Entra ID–joined
only**, and scoped to a first pilot rather than a full production hardening.

## The outcome
When you finish, you have:
- **Automatic Windows enrollment** enabled so Entra-joined PCs enroll into Intune with no manual step.
- **One Windows PC enrolled by a user** (the user-driven path) — managed and compliant.
- **One Windows PC provisioned by Autopilot** (Entra join, user-driven) — managed and compliant.
- A named, auditable set of objects (enrollment profile, ESP, device group, compliance policy) you can
  find, review, and clean up later.
- Read-only PowerShell scripts that verify prerequisites, capture an Autopilot hardware hash, confirm a
  device enrolled and is compliant, and report enrolled Windows devices by enrollment method.

## Where this sits in the journey
This is the **middle step** of a three-step path, each in the same repeatable house style:

1. **Enable Microsoft Intune (Quick-Start)** — turn Intune on for the tenant (free first-mile).
2. **This solution** — get your **first Windows devices enrolled, two ways** (user-driven + basic
   Entra-joined Autopilot). *You are here.*
3. **Windows Autopilot** and **Cloud-First Autopilot Zero-Touch** — the deeper, production-scale
   Autopilot products (advanced/multi-profile Autopilot, deep Enrollment Status Page tuning,
   dynamic-group strategy, app packaging, Conditional Access).

## Two ways to buy
- **Essentials (Self-Deploy)** — the complete click-by-click documentation, do it yourself.
- **Plus (We-Deploy)** — the documentation **plus** ready-to-run PowerShell scripts and configuration
  templates, **and** a done-for-you deployment: after checkout we reach out within one business day to
  schedule and run your basic Intune stand-up and first Windows enrollments with you.

## What is intentionally out of scope
Hybrid Microsoft Entra join, advanced or multi-profile Autopilot, deep Enrollment Status Page tuning,
dynamic-group strategy, co-management, and application packaging are **deliberately not** covered here.
Each is its own catalog solution; this guide points to the deeper Autopilot products where those belong.

## The deployment model (the same across every solution)
> **Assess → Configure → Pilot → Validate → Expand**
