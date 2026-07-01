# Executive Summary — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

## The situation

Many organizations standardizing on Microsoft 365 are carrying a second, separately-licensed endpoint platform — **VMware Workspace ONE UEM** — alongside the Microsoft stack they already own. Consolidating onto **Microsoft Intune** removes that duplicate spend and unifies endpoint management, identity, and compliance under one console and one Conditional Access model.

The critical, often-underestimated reality: a device has **one** active MDM enrollment per platform, and there is no in-place "convert" from Workspace ONE to Intune. Migrating means **un-enrolling each device from Workspace ONE, enrolling it into Intune, and rebuilding the management state** — profiles, compliance, and apps — to parity. Across thousands of live Windows, iOS, Android, and Mac devices, with zero tolerance for a user losing email or access mid-day, this is one of the highest-risk endpoint projects an organization can run.

## The solution

This program delivers a controlled, reversible, no-loss migration across **four platform workstreams — Windows, iOS/iPadOS, Android, and macOS** — using a phased methodology with named objects, an explicit pilot-wave gate, and per-device rollback at every cutover.

It follows the standard program model: **Discover → Assess → Plan → Configure the Intune target (identity, per-platform enrollment, rebuilt parity policy and apps) → Pilot → Validate (pilot-wave gate) → Expand wave by wave (coexistence → cutover → validate) → Decommission Workspace ONE.** Each platform has its own runbook reflecting its real cutover mechanics — Windows and BYOD typically re-enroll without a wipe; corporate Apple (Apple Business Manager / Automated Device Enrollment) and fully managed Android typically reset.

## The outcome

- **A single Microsoft-native endpoint stack** — Intune + Entra (and optionally Defender for Endpoint), one console, one compliance and Conditional Access model.
- **Licensing consolidated** — the separate Workspace ONE spend is retired once the fleet is fully migrated.
- **Controlled, low-surprise execution** — one coordinated program instead of four uncoordinated platform moves: shared discovery, one wave plan, pilots, parity validation, and a per-device rollback.
- **No device and no app left behind** — every Workspace ONE device is retired only after its Intune counterpart passes validation and a defined grace period elapses.

## What leadership must know

- **Enrollment plumbing gates the timeline.** Apple Push (APNs), Apple Business Manager, managed Google Play, and Windows automatic enrollment must be live first — these have real lead times.
- **Policies and apps are rebuilt, not migrated.** There is no native Workspace ONE → Intune configuration import; parity is re-authored and proven on a pilot before fleet cutover.
- **Some corporate devices reset.** Corporate Apple (ADE) and fully managed/dedicated Android devices commonly require a wipe to move enrollment cleanly — this drives the wave model and user communications.
- **Plan for weeks to months, not days.** A full multi-platform fleet migration is a phased program; users cut over wave by wave, with both platforms coexisting (each device managed by exactly one) during the transition.

## Investment

A flagship migration program kit: a complete phased playbook, four per-platform cutover runbooks with exact Intune / Entra / Apple Business Manager navigation, five operational PowerShell tools (discovery, validation, reporting, remediation, wave targeting), and the testing/acceptance and troubleshooting references that de-risk a high-stakes UEM exit across live production devices.
