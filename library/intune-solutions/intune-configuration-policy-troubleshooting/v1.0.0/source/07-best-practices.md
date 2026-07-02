# 7. Best Practices — Intune Device Configuration & Policy Troubleshooting

Field-proven habits that prevent the failures the Diagnostic Playbook diagnoses. Adopt these and
most "policy isn't applying" tickets never happen.

## Naming (so scope is obvious at a glance)
- **Name policies for their scope and intent**, e.g. `INTCFG-Win11-Corp-BitLocker` — reading the name
  tells you the platform, audience, and purpose without opening it.
- **Name groups by context**, splitting device from user: use **`INTCFG-Pilot-Devices`** and
  **`INTCFG-Pilot-Users`** verbatim, and follow the same `-Devices` / `-Users` suffix in production.
  This single habit prevents the #1 Branch-A cause: device-context settings assigned to user groups.
- **Name filters by what they match**, e.g. **`INTCFG-Filter-Windows-Corporate`** — never leave a
  filter called "New filter 1." A named filter's rule is knowable and reusable.
- **Reuse names verbatim** across policies, scripts, and documentation so diagnostics line up.

## Filters (so scope is predictable)
- **Prefer one, well-understood filter** per platform over many overlapping ad-hoc filters.
- **Always Preview/Evaluate** a filter against real devices before assigning — confirm the intended
  devices are on the correct side of Include/Exclude.
- **Filter on stable properties** (ownership, OS edition, enrollment profile) rather than volatile
  ones; document what each filter is meant to match.
- **Remember Exclude beats Include** at both the group and filter level — check for accidental
  excludes first when a device is missing.

## Conflict-free design (so settings don't fight)
- **One setting, one owner.** Each setting should live in **exactly one** assigned policy. Overlap is
  the root of every conflict — there is no reliable "priority wins" for configuration profiles.
- **Consolidate, don't stack.** Prefer fewer, broader well-scoped policies over many small policies
  that touch the same settings.
- **Scope to non-overlapping groups** when two policies must coexist, so no device receives both.
- **Run `INTCFG-Report.ps1` before and after changes** to catch overlapping settings early.

## Operating discipline (so diagnosis stays fast)
- **Pilot before production.** Assign to `INTCFG-Pilot-Devices` first, validate, then expand in waves.
- **Read the report first, always.** Device status + per-setting status tells you the failing layer
  before you touch anything.
- **Diagnose top-down** — assignment → filter → sync → CSP — matching the order settings travel.
- **Keep a known-good device** to compare against; it separates policy faults from device faults.
- **Force a sync deliberately**, don't wait blindly — but never re-push a policy as a "fix" before
  you've isolated the layer; blind re-pushing is what this toolkit replaces.
- **Document ownership** — record which policy owns which settings, and the group/filter scheme, so
  the next admin (and the scripts) can follow it.
