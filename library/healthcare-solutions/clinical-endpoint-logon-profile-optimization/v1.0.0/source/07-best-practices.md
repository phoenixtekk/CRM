# 7. Best Practices — Clinical Endpoint Logon & Profile Performance Optimization (FSLogix)

These practices keep the deployment fast, stable, and compliant across the lifecycle. They complement — they do not replace — your storage team's platform guidance, your Imprivata administrator's appliance guidance, and your compliance team's HIPAA/HITRUST requirements.

## Measure first, measure after

- **Always capture a baseline before changing anything.** Run `CLINLOGON-Set-FSLogixBaseline.ps1` on representative endpoints and record logon and profile-load time, with the target reduction agreed in writing (R6). A solution sold on speed must prove the speed.
- **Re-measure with the same method.** Use the identical measurement method (same script, same warm/cold conditions) before and after so the before/after comparison is honest, and capture repeated sign-ins, not a single warm-cache run.
- **Report continuously.** Run `CLINLOGON-Report.ps1` after each wave to track logon time, agent install state, and container sizes; investigate any endpoint that drifts.

## Storage and permissions

- **Get both permission layers right.** FSLogix attach fails if either the **share-level** permission or the **NTFS / Azure Files Kerberos** ACLs are wrong. Use the FSLogix-recommended model (Users create/list/read this-folder-only; Creator Owner modify subfolders/files) and, for Azure Files, enable identity-based Kerberos **and** assign the share-level RBAC role.
- **Defer storage-platform values to the storage team.** Share path, storage account, tier, quota, and backup/snapshot schedule are storage-team decisions — confirm them, don't invent them, and ensure the share is highly available (a single slow/failed share stalls every sign-in).
- **Back up containers and plan capacity.** Treat the profile share as production user data: snapshot/back it up, monitor free space, and size for peak concurrent containers plus growth (R7).

## Container bloat and corruption control

- **Use redirections/exclusions aggressively.** Keep volatile caches, temp, browser caches, and indexable content the clinician doesn't need across devices **out** of the VHD(X) via `redirections.xml`. This is the primary lever against bloat and the leading cause of small, fast, stable containers.
- **Prefer dynamic VHDX with a sane max size.** Dynamic disks keep share usage proportional to real data; set a per-container max that fits the clinical profile without inviting runaway growth.
- **Review container sizes on a schedule.** Containers that creep up signal a missing exclusion or an app caching into the profile — find it and add the exclusion rather than just raising the size.

## Fast-logon tuning

- **Delete stale cached profiles on shared devices.** Enable both *Delete cached copies of roaming profiles* and FSLogix *Delete Local Profile When VHD Should Apply* so every sign-in is clean and the local disk stays lean.
- **Trim what runs at sign-in.** Disable the first-sign-in animation and OOBE consumer experiences, and review startup/run items — each one is sign-in latency on a shared clinical device.
- **Remove legacy roaming-profile config.** FSLogix replaces roaming user profiles; leaving an old roaming-profile path in place makes the two models fight. Remove it for the clinical OU.

## Coexisting with Imprivata tap-and-go

- **Make the container detach between users.** On shared single-session WOWs, agree (with the Imprivata admin) a tap-out that performs a full sign-out so the FSLogix container detaches before the next clinician's attaches — the clean model for rapid switching.
- **Tune locked-VHD retries, not appliance policy.** Where fast switching causes occasional locked-VHD retries, raise FSLogix *Locked Retry Count/Interval* modestly. Do not set Imprivata policy from this solution — escalate to the Imprivata admin (separate solution).

## Deployment hygiene

- **Pilot before fleet, always.** Validate on the representative test device and `Clinical – Logon Optimization – Pilot` before adding the full `Clinical – Logon Optimization` group; expand in controlled waves within approved maintenance windows. For AVD, stage across the host pool with drain.
- **Pin and record versions.** Record the exact FSLogix agent version, install/uninstall command lines, and detection criteria in change control, and keep the Win32 app publisher set to `Microsoft Corporation`.
- **Use device-targeted assignments** for shared endpoints — assign the agent app and both configuration profiles to the device group, not to users, so the experience follows the shared device.
- **Keep a rehearsed rollback.** Maintain and periodically rehearse the back-out (disable Profile Container, remove tuning, uninstall agent, remove from group) so a logon/profile regression on a shared clinical endpoint can be reversed quickly — without deleting user containers.

## Data handling

- **No PHI in artifacts.** Keep reports, logs, and screenshots free of PHI. Use test accounts and test data for all validation, and never store PHI outside approved systems.
