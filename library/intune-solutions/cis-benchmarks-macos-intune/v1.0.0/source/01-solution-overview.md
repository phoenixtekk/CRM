# 1. Solution Overview — CIS Benchmarks for macOS (Microsoft Intune)

## What the CIS Benchmarks are
The CIS Benchmarks are a set of consensus-developed, prescriptive security configuration
recommendations published by the Center for Internet Security. The CIS Apple macOS Benchmark is a
single document (published per macOS major version, for example a Sonoma or Sequoia benchmark)
containing hundreds of individual control recommendations — each one a specific setting, the
recommended value, the rationale, and the audit/remediation guidance. Auditors, cyber-insurers, and
security teams increasingly treat "meets the CIS Benchmark for macOS" as the bar for a hardened Mac.
This solution implements that benchmark as Microsoft Intune policy and then keeps it current as CIS
revises the benchmark over time.

## Level 1 vs Level 2
- **Level 1 (L1)** — the baseline. Practical, broadly safe hardening that reduces attack surface
  with minimal impact on day-to-day use. This is what most Mac fleets deploy first.
- **Level 2 (L2)** — defense-in-depth for high-security environments. Stronger, but more likely to
  break apps or workflows (for example stricter Gatekeeper, firewall, or removable-media controls,
  or disabling features users rely on). Apply L2 selectively, on top of L1, after extra testing.
- The macOS benchmark also covers areas such as FileVault disk encryption, the application firewall,
  Gatekeeper, software-update behaviour, and audit logging. Treat the encryption controls as an
  add-on profile, not a replacement for L1.

## How the controls map into Intune (the three macOS surfaces)
macOS is configured by Apple **configuration profiles** (`.mobileconfig` payloads) and by scripts —
not by Windows constructs. There is no ADMX and no Windows settings catalog on macOS. The CIS macOS
controls translate into Intune through three delivery surfaces:
1. **Settings catalog (Apple)** — the primary surface. Most CIS controls correspond to an Apple
   payload Microsoft exposes in the macOS settings catalog (Devices → macOS → Configuration →
   Create → Settings catalog), grouped by area (for example Login Window, Restrictions, Security,
   Software Update). You build one or more settings-catalog policies that carry the L1 (and
   optionally L2) values.
2. **Custom configuration profiles (`.mobileconfig`)** — for the minority of CIS controls whose
   Apple payload is not (yet) surfaced in the settings catalog, you author or obtain the matching
   `.mobileconfig` file and upload it via Devices → macOS → Configuration → Create → Templates →
   Custom. This delivers the raw Apple payload Intune's catalog cannot reach.
3. **macOS shell scripts** — a small number of CIS controls are only enforceable by running a
   command on the device (for example setting a value with `defaults` or toggling a service). These
   are delivered via Devices → macOS → Shell scripts, which run as root on a schedule.
A macOS **compliance policy** sits alongside these to evaluate and report the device's CIS-relevant
posture (for example FileVault on, firewall on, minimum OS version).

## CIS Benchmark vs the Microsoft / Apple defaults
Intune and Apple ship their own recommended settings and security defaults. They overlap with CIS
but are **not the same**: they reflect Microsoft's or Apple's recommendations, use their own
grouping, and revise on their own schedule. CIS is an independent consensus standard with its own
control numbering and its own L1/L2 split, and audits ask specifically for CIS. Do not assume a
vendor default satisfies a CIS audit — this solution builds the CIS controls explicitly so you can
prove the mapping.

## The compliance and drift model
Configuring the policy is only half the job. You also:
- **Prove compliance** — Intune reports per-profile and per-device configuration state, so you can
  show each Mac received the CIS values.
- **Detect drift** — a device can fall out of compliance (a conflicting profile, a removed profile,
  a failed apply, a user change a shell control no longer corrects). The included reporting and
  validation scripts surface drift so you can reapply.

## The benchmark-version maintenance lifecycle (why this solution is two solutions in one)
CIS revises the macOS Benchmark periodically — both for point revisions and, importantly, for each
new macOS major release (a new benchmark document ships with each new macOS). Each revision adds,
removes, renumbers, or changes the recommended value of controls. Without a process, your hard-won
baseline silently falls behind the current benchmark and an audit fails. This solution therefore
includes a first-class **Maintenance & Update Guide** (document 4): a repeatable lifecycle of
**Obtain → Diff → Assess/Approve → Update → Re-validate → Record version** that you run every time
CIS publishes a new version (or you move Macs to a new macOS major), plus a comparison script that
diffs a new CIS export against your live baseline to drive the change.

## Source-of-truth note (CIS membership content)
CIS publishes the Benchmark PDF and supporting content (and macOS hardening tooling) behind CIS
membership and on CIS WorkBench. The exact CIS control numbers, the `.mobileconfig` payload keys,
and the recommended values are the authoritative source — treat them as deferred to the official CIS
macOS Benchmark document and CIS WorkBench. This solution gives you the correct procedure to
translate the benchmark into the three Intune macOS surfaces; where a specific control is named it is
clearly marked as an example only.

## Benefits
- **Audit-ready hardening** — every Mac built to the CIS Benchmark, with evidence.
- **Right level, controlled risk** — deliberate L1 baseline with optional, tested L2 hardening.
- **Provable compliance** — per-device configuration state and a fleet posture report.
- **Stays current** — a documented version-update lifecycle so the baseline never silently drifts.
- **Safe rollout** — piloted before fleet-wide, with a rollback note because hardening can break apps and login.

## Limitations (be honest with buyers)
- The authoritative control list and values live in the CIS membership content; this solution is the
  Intune implementation and maintenance method, not a copy of the benchmark.
- Hardening can break apps and even sign-in — L2 especially. A pilot gate and rollback note are
  mandatory, not optional.
- Some CIS controls are out of scope for Intune (physical, procedural, or hardware items), and some
  require a custom `.mobileconfig` or a shell script because the settings catalog cannot reach them.
- Achieving 100% of controls may be neither possible nor desirable; documented break-glass
  exceptions are part of a healthy baseline.

## The deployment model
> Build the Level 1 (and optional Level 2) baseline as Intune settings-catalog policy, custom
> `.mobileconfig` profiles, and macOS shell scripts, assign to a pilot, prove compliance, then
> expand fleet-wide — and run the maintenance lifecycle on every new benchmark version. The
> repeatable way: **Assess → Configure → Pilot → Validate → Expand.**
