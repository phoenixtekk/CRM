# 1. Solution Overview — CIS Benchmarks for Windows 11 (Microsoft Intune)

## What the CIS Benchmarks are
The CIS Benchmarks are a set of consensus-developed, prescriptive security configuration
recommendations published by the Center for Internet Security. The Windows 11 Benchmark is a single
document containing hundreds of individual control recommendations — each one a specific setting,
the recommended value, the rationale, and the audit/remediation guidance. Auditors, cyber-insurers,
and security teams increasingly treat "meets the CIS Benchmark for Windows 11" as the bar for a
hardened endpoint. This solution implements that benchmark as Microsoft Intune policy and then keeps
it current as CIS revises the benchmark over time.

## Level 1 vs Level 2
- **Level 1 (L1)** — the baseline. Practical, broadly safe hardening that reduces attack surface
  with minimal impact on day-to-day use. This is what most fleets deploy first.
- **Level 2 (L2)** — defense-in-depth for high-security environments. Stronger, but more likely to
  break business applications or workflows (e.g. stricter PowerShell, network, or removable-media
  controls). Apply L2 selectively, on top of L1, after extra testing.
- There is also a **BitLocker / Next Generation Windows Security (NG)** profile in the benchmark for
  devices that meet the hardware prerequisites. Treat it as an add-on profile, not a replacement.

## How the controls map into Intune
The CIS Windows 11 controls translate into two Intune policy types:
1. **Settings catalog** — the primary surface. Most CIS controls correspond to a setting in the
   Intune settings catalog (the same CSP/ADMX-backed settings Microsoft exposes), grouped by area
   (Account Policies, Local Policies, Defender, etc.). You build one or more settings-catalog
   policies that carry the L1 (and optionally L2) values.
2. **Imported ADMX** — a minority of CIS controls map to administrative templates that are not yet
   in the settings catalog. For those you import the relevant ADMX/ADML files into Intune and
   configure them as administrative-template settings.
A small number of CIS items (BitLocker, Credential Guard, audit policy) are best delivered through
the matching dedicated Intune surface (endpoint security disk encryption, account protection) and
referenced from your baseline.

## CIS Benchmark vs the Microsoft security baselines
Intune ships Microsoft-authored security baselines. They overlap with CIS but are **not the same**:
they reflect Microsoft's recommendations, use Microsoft's grouping, and revise on Microsoft's
schedule. CIS is an independent consensus standard with its own control numbering and its own L1/L2
split, and audits ask specifically for CIS. Do not assume a Microsoft baseline satisfies a CIS
audit — this solution builds the CIS controls explicitly so you can prove the mapping.

## The compliance and drift model
Configuring the policy is only half the job. You also:
- **Prove compliance** — Intune reports per-setting and per-device configuration state, so you can
  show each device received the CIS values.
- **Detect drift** — a device can fall out of compliance (a conflicting policy, a local change, a
  failed apply). The included reporting and validation scripts surface drift so you can reapply.

## The benchmark-version maintenance lifecycle (why this solution is two solutions in one)
CIS revises the Windows 11 Benchmark periodically (typically every several months). Each revision
adds, removes, renumbers, or changes the recommended value of controls. Without a process, your
hard-won baseline silently falls behind the current benchmark and an audit fails. This solution
therefore includes a first-class **Maintenance & Update Guide** (document 4): a repeatable lifecycle
of **Obtain → Diff → Assess/Approve → Update → Re-validate → Record version** that you run every time
CIS publishes a new version, plus a comparison script that diffs a new CIS export against your live
baseline to drive the change.

## Source-of-truth note (CIS membership content)
CIS publishes the Benchmark PDF and a Microsoft Intune "Build Kit" / GPO content behind CIS
membership. The exact CIS control numbers and the Build Kit internals are the authoritative source —
treat them as deferred to the official CIS Benchmark document and CIS WorkBench. This solution gives
you the correct procedure to import and translate the benchmark into Intune; where a specific control
is named it is clearly marked as an example only.

## Benefits
- **Audit-ready hardening** — every Windows 11 device built to the CIS Benchmark, with evidence.
- **Right level, controlled risk** — deliberate L1 baseline with optional, tested L2 hardening.
- **Provable compliance** — per-device configuration state and a fleet posture report.
- **Stays current** — a documented version-update lifecycle so the baseline never silently drifts.
- **Safe rollout** — piloted before fleet-wide, with a rollback note because hardening can break apps.

## Limitations (be honest with buyers)
- The authoritative control list and values live in the CIS membership content; this solution is the
  Intune implementation and maintenance method, not a copy of the benchmark.
- Hardening can break business applications — L2 especially. A pilot gate and rollback note are
  mandatory, not optional.
- Some CIS controls are out of scope for Intune settings (physical, procedural, or hardware items).
- Achieving 100% of controls may be neither possible nor desirable; documented break-glass
  exceptions are part of a healthy baseline.

## The deployment model
> Build the Level 1 (and optional Level 2) baseline as Intune settings-catalog and imported-ADMX
> policy, assign to a pilot, prove compliance, then expand fleet-wide — and run the maintenance
> lifecycle on every new benchmark version. The repeatable way:
> **Assess → Configure → Pilot → Validate → Expand.**
