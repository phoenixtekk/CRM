# 1. Solution Overview — GPO Rationalization & Cleanup with Group Policy Analytics

## Why rationalize before you migrate
A mature Active Directory estate accumulates Group Policy Objects over many years: GPOs created for
projects that ended, settings duplicated across several policies, audit settings configured three
different ways, conflicting values that resolve by link-order accident, and policies whose original
purpose nobody remembers. Lifting that estate into Intune unchanged simply re-creates the mess in a
modern console — and makes the migration look larger, riskier, and slower than it needs to be.

Rationalization is the foundational cleanup that comes first. You inventory every GPO, decide which
ones deserve to make the trip, eliminate the redundancy and conflicts, capture the intent, and hand
the migration team a clean, ordered backlog. The actual settings migration (translating supported
settings into the Intune settings catalog and imported ADMX) is a separate, later phase — this
solution makes that phase smaller and safer.

## How Group Policy analytics fits
Intune Group Policy analytics is a built-in report that ingests a GPO export and tells you, per GPO,
a migration readiness percentage and a per-setting breakdown of what is supported and mapped to an
MDM equivalent, what is deprecated or not supported in MDM, and what needs review. You do not use it
to migrate yet — you use it as the scoring engine for rationalization: high-readiness GPOs are
cheap to migrate and good early-backlog candidates; low-readiness GPOs flag re-implementation or
retirement work to plan deliberately.

## The rationalization workflow
1. Inventory every GPO and export each one (the export is both the analytics input and your
   retained record).
2. Import the exports into Group Policy analytics and read each GPO's migration readiness percentage
   and supported / not-supported / needs-review breakdown.
3. Classify every GPO into one of four dispositions: keep (migrate as-is), retire (dead or
   superseded — do not migrate), consolidate (merge duplicates/overlaps into one), or replace
   (re-implement via a modern Intune surface).
4. Resolve the cross-cutting problems: redundant audit settings configured in multiple places, and
   directly conflicting policy values.
5. Document the intent of every GPO you keep or consolidate, so the migration team knows what each
   policy is *for*.
6. Produce a sequenced migration backlog — what to migrate, in what order, with the scope groups
   already named — gated by a pilot scope.

## The four dispositions
- Keep — the GPO is still needed, has high readiness, and migrates with little change.
- Retire — the GPO is dead (unlinked, empty, superseded, or for a decommissioned system); it is
  intentionally not migrated and its links are removed after sign-off.
- Consolidate — two or more GPOs overlap or duplicate each other; they merge into one before
  migration so you migrate the intent once, not three times.
- Replace — the GPO contains settings with no direct MDM equivalent (logon scripts, drive maps,
  Group Policy Preferences) and is re-implemented later via a platform script, proactive
  remediation, or an endpoint security profile rather than a settings-catalog copy.

## What you control
- The inventory of every GPO, its links, status, and last-modified date.
- The readiness score and supported/unsupported breakdown for each GPO via Group Policy analytics.
- The disposition (keep / retire / consolidate / replace) recorded for every GPO in a rationalization
  register.
- The resolution of redundant audit settings and conflicting policy values.
- The sequenced migration backlog and the Entra scope groups that will drive the later migration.

## Limitations (be honest with buyers)
- This solution rationalizes and sequences; it does not perform the settings migration itself (that
  is the separate Group Policy to Intune settings migration phase).
- Group Policy analytics scores settings coverage; it does not judge business intent — a human must
  classify keep/retire/consolidate/replace.
- Remediation here is scoped to dead and duplicate GPO links (unlink/remove); it does not edit the
  settings inside a GPO.
- A few settings (preferences, scripts, drive maps) have no MDM equivalent and are flagged for
  re-implementation, not a like-for-like migration.

## The deployment model
> Inventory and export all GPOs to import to Group Policy analytics and read readiness to classify
> and resolve conflicts to document intent and build a sequenced backlog — proven on a pilot scope
> first. The repeatable way: Assess to Configure to Pilot to Validate to Expand.
