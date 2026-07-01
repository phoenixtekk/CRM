# 7. Best Practices — Workspace ONE to Microsoft Intune Migration Program (Windows, iOS/iPadOS, Android, macOS)

Program-grade practices for a UEM exit across live, enrolled production devices. These reduce risk, protect user access, and produce the evidence a controlled migration requires.

## Program & wave planning

- **Lead with enrollment plumbing, not policy.** APNs (Apple), Apple Business Manager + ADE token, managed Google Play, and Windows automatic enrollment (R3) have real lead times and gate every cutover for their platform. Stand them up first.
- **Pilot every platform end-to-end.** `Wave 00 Devices – All – Pilot` must include each in-scope platform **and** both ownership types so the pilot exercises every cutover mechanic (no-wipe re-enroll and ADE/fully-managed reset). The pilot-wave gate is the program's go/no-go.
- **Keep cohorts intact.** Group a user, their device(s), and their department into the same wave so collaboration and shared resources move together.
- **Sequence low-disruption first.** Windows and BYOD cohorts (no wipe) before corporate Apple/Android reset cohorts (most comms, most user action).
- **Right-size waves to support capacity.** Cap each wave to what the helpdesk can shepherd through re-enrollment in the window.

## Parity discipline (the thing that breaks access)

- **Rebuild to parity, don't approximate.** Build the parity matrix (R6) and treat **Wi-Fi, VPN, and certificate** profiles as High complexity — a missing Wi-Fi cert or VPN profile breaks access the moment the device leaves Workspace ONE.
- **Validate parity on the pilot before trusting it.** A profile that shows **Succeeded** in Intune but doesn't actually grant access is a FAIL — test real access (T1.2 / T2.2 / T3.2 / T4.2), not just policy status.
- **Reuse the naming convention verbatim.** `Parity Policy Set – <Platform> – Target`, `Compliance Policy – <Platform> – Target`, `ADE Enrollment Profile – <Platform> – Target`, and `Wave NN Devices – <Scope> – Wave NN` so discovery, planning, validation, and reporting cross-reference cleanly.

## Identity & Conditional Access

- **Resolve identity first.** Users (and hybrid Windows device objects) must exist and authenticate in Entra before Intune can target them (R4).
- **Make Conditional Access do-no-harm during coexistence.** Stage CA changes **report-only**, keep coexisting (un-migrated) cohorts accessing resources, and tighten to require Intune compliance **only** as cohorts cut over (R8, Phase 9). Never require Intune compliance fleet-wide before the fleet is migrated.

## Apps

- **Re-package, don't expect export.** Win32 apps need the Content Prep Tool and a silent install/detection; managed store apps need VPP / managed Google Play. Identify store apps by **exact publisher name and bundle/package ID** to avoid the wrong near-identical app.
- **Carry managed app configuration across.** If Workspace ONE delivered per-app config (e.g. mail, VPN-per-app), rebuild it as Intune managed app config — apps installing without config is a partial migration.

## Cutover mechanics

- **A device is single-MDM, always.** Target only migrated devices with the production assignment, via `Wave NN Devices – <Scope> – Wave NN`. Never assign the same device to both platforms (T6.1) — that is the failure mode the wave model exists to prevent.
- **Plan the reset cohorts deliberately.** Corporate ADE Apple and fully managed/dedicated Android typically wipe; confirm backup/restore and comms before their wave (R11, R12).
- **Re-assign ADE in Apple Business Manager.** ABM is the system of record for ADE device-to-MDM-server assignment; change the MDM server there, then release the device from the source.

## Communications

- **Per-wave cadence:** announce → pre-cutover steps (re-enroll vs. reset, sign-in URL, MFA, app reinstall) → cutover-complete confirmation.
- **Tell users what they'll see.** Re-enrollment is user-visible and some platforms reset; clear instructions prevent the helpdesk flood that fails a wave.

## Coexistence & rollback

- **Define rollback per platform and per device (R13).** The rollback is "re-enroll to Workspace ONE / revert the Intune assignment," usable **inside the change window** before the source assignment is removed. Rehearse it once during pilot (T6.2).
- **Keep the source warm through a grace period.** Hold migrated devices read-only in Workspace ONE for a defined window (e.g. 14–30 days) after a wave passes before releasing them — that window is your rollback path.

## Decommission discipline

- **Validate before you retire.** No Workspace ONE device or assignment is decommissioned until its wave passes its acceptance gate and the grace period elapses (Phase 10).
- **Release the ADE/DEP token last**, so Apple Business Manager assignment is fully owned by Intune before the source is gone.
- **Export retained records first**, then reclaim/cancel Workspace ONE licensing — coordinate console steps with the platform owner (deferred to VMware docs).

## Documentation & evidence

- **Keep the program register current as you go** — named objects, wave plan, change records, and per-gate results. A complete, dated record of who moved what, how parity was proven, and how each cutover was validated (and could be rolled back) is the deliverable that makes the program auditable.
