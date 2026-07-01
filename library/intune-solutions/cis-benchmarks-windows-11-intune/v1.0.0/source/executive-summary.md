# Executive Summary — CIS Benchmarks for Windows 11 (Microsoft Intune)

Security teams, auditors, and cyber-insurers increasingly require Windows 11 endpoints to meet the
**CIS Benchmarks** — but doing it by hand is brutal: hundreds of settings, Level 1 vs Level 2
decisions, controls that break business apps, and a benchmark that CIS *revises* every few months so
your hard-won baseline silently drifts out of compliance. This package implements the CIS Benchmark
for Windows 11 as Microsoft Intune policy, proves compliance, and gives you a documented process to
keep the baseline current every time CIS publishes a new version.

This is a complete, **deploy-it-today** package written for an administrator with no prior
hardening experience — and it is deliberately two solutions in one: **net-new implementation** and an
**ongoing update-and-maintain lifecycle**.

## What you get
- A plain-language **Solution Overview** of CIS Benchmarks, Level 1 vs Level 2, how controls map to Intune (settings catalog and imported ADMX), and how CIS differs from the Microsoft security baselines.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite, plus a consistent object-naming convention.
- An **Implementation Guide** of precise, click-by-click Intune steps to build, pilot, validate, and expand the baseline — with a pilot gate and a rollback note because hardening can break apps.
- A **Maintenance & Update Guide** — a first-class lifecycle for every new CIS benchmark version: obtain it, diff it against your live baseline, assess and approve, update in a controlled change, re-validate, and record the version.
- Five **PowerShell scripts** for CIS readiness discovery, per-device compliance validation, fleet posture and drift reporting, safe drift remediation, and benchmark-version comparison.
- **Testing** and **Troubleshooting** guides for confident rollout and ongoing operation.

## What this delivers
A **hardened, CIS-compliant Windows 11 fleet** built as Intune settings-catalog and imported-ADMX
policy at Level 1 (with optional, tested Level 2), provable per-device compliance, drift detection
and remediation, and a documented benchmark-version update lifecycle so the baseline never silently
falls behind.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — and, for each new benchmark version,
**Obtain → Diff → Assess/Approve → Update → Re-validate → Record.**

## Outcome
Every Windows 11 device hardened to the CIS Benchmark and provably compliant — kept current as CIS
revises it instead of silently drifting — deployable by a single administrator and validated on a
pilot before fleet rollout.
