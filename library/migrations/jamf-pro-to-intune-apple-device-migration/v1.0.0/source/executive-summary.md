# Executive Summary

**The goal.** Move an Apple fleet — **macOS, iPadOS, and iOS/iPhone** — off **Jamf Pro** and onto
**Microsoft Intune**, ending with every device managed, compliant, and carrying its apps and
configuration, and Jamf cleanly retired.

**Why it takes a program, not a switch.** An Apple device can be enrolled in **only one MDM at a
time** — Jamf and Intune cannot co-manage the same device — so every device must **leave Jamf and
enroll into Intune**. For corporate **supervised / Automated Device Enrollment** devices that means an
**erase**: after you re-assign the device to Intune's MDM server in **Apple Business Manager**, it
enrolls into Intune on the next Setup Assistant. **BYOD / user-enrolled** devices migrate without a
wipe. On top of enrollment, app licenses (**VPP**) must be moved, and Jamf configuration profiles,
policies, and — on macOS — **FileVault escrow** and **SSO** must be rebuilt in Intune, because none of
it transfers automatically.

**The approach.** This program does it in **validated waves**: inventory Jamf and confirm Intune/ABM/VPP
readiness; build the Intune target per platform (ADE profiles, configuration and compliance, apps via
VPP, FileVault escrow, SSO, certificates); pilot a small mixed wave (Macs, iPads, iPhones); then roll
production rings and decommission Jamf. Jamf stays live for un-migrated devices the whole time, so
rollback is cheap and blast radius is small. Five PowerShell tools export the Jamf inventory, check
Intune readiness, report ABM assignments, validate each wave, and track progress to zero pending.

**The outcome.** A fully migrated Apple estate on Intune, delivered in controlled waves with the wipe
scope known in advance, apps and policies preserved, and evidence for every step — instead of a risky
big-bang cutover.

**Scope.** All three Apple platforms in one program. The mechanics are identical in Commercial and
US-sovereign (GCC / GCC High / DoD) Intune — only the portal host differs — so a single deliverable
applies. Delivered as click-by-click documentation plus tested scripts, at a fraction of an
open-ended consulting engagement.
