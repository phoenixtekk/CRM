# 1. Solution Overview — DISA STIG Compliance for Windows 10 & 11 (Microsoft Intune)

## What the DISA STIG is
A STIG (Security Technical Implementation Guide) is a hardening standard published by the Defense
Information Systems Agency (DISA) for the U.S. Department of Defense. The Windows 10 STIG and the
Windows 11 STIG are documents containing hundreds of individual rules — each one a specific setting,
its required value, the discussion/rationale, and check/fix guidance. In defense and federal
environments, "meets the DISA STIG for Windows" is a mandatory bar for an Authority to Operate (ATO),
and assessors expect proof. This solution implements the applicable Windows STIG as Microsoft Intune
policy and then keeps it current as DISA revises the STIG over time.

## CAT I / CAT II / CAT III severities
Every STIG rule carries a severity category that drives priority and risk acceptance:
- CAT I (High) — a weakness that could directly and immediately result in loss of confidentiality,
  availability, or integrity. Address these first; open CAT I findings are the hardest to get accepted.
- CAT II (Medium) — a weakness that could result in loss if exploited; the bulk of the STIG.
- CAT III (Low) — a weakness that degrades defense-in-depth but is lower risk on its own.
Deploy by severity: CAT I and CAT II broadly, CAT III where practical, and track anything you cannot
meet as a POA&M exception (see below).

## How the rules map into Intune
The Windows STIG rules translate into two Intune policy types:
1. Settings catalog — the primary surface. Most STIG rules correspond to a setting in the Intune
   settings catalog (the same CSP/ADMX-backed settings Microsoft exposes), grouped by area (Account
   Policies, Local Policies, Defender, etc.). You build one or more settings-catalog policies that
   carry the required STIG values, organized by CAT severity.
2. Imported ADMX — a minority of STIG rules map to administrative templates not yet in the settings
   catalog. For those you import the relevant ADMX/ADML files into Intune and configure them as
   administrative-template settings.
A small number of STIG rules (BitLocker, Credential Guard, advanced audit policy) are best delivered
through the matching dedicated Intune surface (endpoint security disk encryption, account protection)
and referenced from your baseline.

## The STIG vs the Microsoft security baselines
Intune ships Microsoft-authored security baselines. They overlap with the STIG but are not the same:
they reflect Microsoft's recommendations, use Microsoft's grouping, and revise on Microsoft's
schedule. The DISA STIG is the DoD standard with its own rule IDs (Group/Rule/Vuln IDs), its own CAT
severities, and its own check/fix text — and DoD assessors ask specifically for the STIG. Do not
assume a Microsoft baseline satisfies a STIG assessment; this solution builds the STIG rules
explicitly so you can prove the mapping.

## SCAP and the STIG Viewer are the authority
The authoritative artifacts are the DISA-published STIG (the STIG Viewer `.stig`/XCCDF content) and
the matching SCAP benchmark used for automated scanning. Treat the STIG Viewer and SCAP content as the
source of truth for exact rule IDs, required values, and check/fix procedures — do not work from
memory. This solution gives you the correct procedure to translate the STIG into Intune; where a
specific rule is named it is clearly marked as an illustrative example only.

## The compliance and drift model
Configuring the policy is only half the job. You also:
- Prove compliance — Intune reports per-setting and per-device configuration state, so you can show
  each device received the STIG values; you reconcile that against a STIG Viewer / SCAP scan.
- Detect drift — a device can fall out of compliance (a conflicting policy, a local change, a failed
  apply). The included reporting and validation scripts surface drift so you can reapply.

## Exceptions are tracked as POA&M
No fleet meets 100% of a STIG cleanly. Any rule you cannot implement (it breaks a mission app, the
hardware lacks a feature, an operational constraint) is documented as a POA&M (Plan of Action &
Milestones): the finding, the risk, the compensating control, the owner, and the remediation
milestone/date. A documented POA&M is the accepted way to carry an open finding — a silent gap is not.

## The STIG-release maintenance lifecycle (why this is two solutions in one)
DISA revises the Windows STIGs periodically (typically quarterly). Each release adds, removes,
renumbers, or changes the required value of rules. Without a process, your hard-won baseline silently
falls behind the current STIG and the next assessment fails. This solution therefore includes a
first-class Maintenance & Update Guide (document 4): a repeatable lifecycle of
Obtain → Diff → Assess/Approve → Update → Re-validate → Record version that you run every time DISA
publishes a new STIG release, plus a comparison script that diffs a new STIG export against your live
baseline to drive the change.

## Benefits
- Assessment-ready hardening — every Windows 10/11 device built to the DISA STIG, with evidence.
- Right priority, controlled risk — CAT I/II first, CAT III where practical, piloted before fleet-wide.
- Provable compliance — per-device configuration state plus a fleet posture report, reconciled to SCAP.
- Stays current — a documented STIG-release update lifecycle so the baseline never silently drifts.
- Honest exceptions — anything you cannot meet is carried as a tracked POA&M, not a silent gap.

## Limitations (be honest with buyers)
- The authoritative rule list, values, and check/fix text live in the DISA STIG / STIG Viewer / SCAP
  content; this solution is the Intune implementation and maintenance method, not a copy of the STIG.
- Hardening can break mission applications — a pilot gate and rollback note are mandatory, not optional.
- Some STIG rules are out of scope for Intune settings (physical, procedural, or hardware items).
- Achieving 100% of rules may be neither possible nor desirable; documented POA&M exceptions are part
  of a healthy, assessable baseline.

## The deployment model
> Build the DISA STIG baseline (CAT I / CAT II / CAT III) as Intune settings-catalog and imported-ADMX
> policy, assign to a pilot, prove compliance, then expand fleet-wide — and run the maintenance
> lifecycle on every new STIG release. The repeatable way:
> Assess → Configure → Pilot → Validate → Expand.
