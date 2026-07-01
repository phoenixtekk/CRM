# Executive Summary — CIS Benchmarks for macOS (Microsoft Intune)

Security teams, auditors, and cyber-insurers increasingly require Macs to meet the **CIS Benchmarks**
— but doing it by hand is brutal: hundreds of settings split across configuration profiles, controls
the Intune GUI can't reach (so you need custom `.mobileconfig` payloads and shell scripts), Level 1
vs Level 2 decisions, controls that break apps or even login, and a benchmark that CIS *revises*
regularly (and re-publishes for every new macOS release) so your hard-won baseline silently drifts
out of compliance. This package implements the CIS Benchmark for macOS as Microsoft Intune policy,
proves compliance, and gives you a documented process to keep the baseline current every time CIS
publishes a new version.

This is a complete, **deploy-it-today** package written for an administrator with no prior hardening
experience — and it is deliberately two solutions in one: **net-new implementation** and an **ongoing
update-and-maintain lifecycle**.

## What you get
- A plain-language **Solution Overview** of CIS Benchmarks, Level 1 vs Level 2, how controls map to the three Intune macOS surfaces (settings catalog, custom `.mobileconfig` profiles, and shell scripts), and how CIS differs from vendor defaults.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite — including the Apple MDM Push (APNs) certificate and macOS enrollment — plus a consistent object-naming convention.
- An **Implementation Guide** of precise, click-by-click Intune steps to build, pilot, validate, and expand the baseline — with a pilot gate and a rollback note because hardening can break apps and login.
- A **Maintenance & Update Guide** — a first-class lifecycle for every new CIS benchmark version: obtain it, diff it against your live baseline, assess and approve, update in a controlled change, re-validate, and record the version.
- Five **PowerShell scripts** for CIS readiness discovery, per-device compliance validation, fleet posture and drift reporting, safe drift remediation, and benchmark-version comparison.
- **Testing** and **Troubleshooting** guides for confident rollout and ongoing operation.

## What this delivers
A **hardened, CIS-compliant Mac fleet** built as Intune settings-catalog policy, custom
`.mobileconfig` profiles, and macOS shell scripts at Level 1 (with optional, tested Level 2),
provable per-device compliance, drift detection and remediation, and a documented benchmark-version
update lifecycle so the baseline never silently falls behind.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — and, for each new benchmark version,
**Obtain → Diff → Assess/Approve → Update → Re-validate → Record.**

## Outcome
Every Mac hardened to the CIS Benchmark and provably compliant — kept current as CIS revises it
instead of silently drifting — deployable by a single administrator and validated on a pilot before
fleet rollout.
