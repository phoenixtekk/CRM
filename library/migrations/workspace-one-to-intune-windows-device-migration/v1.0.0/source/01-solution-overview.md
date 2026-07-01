# 1. Solution Overview — Workspace ONE to Intune (Windows Device Migration)

## What this migration is
This solution moves managed Windows devices from VMware Workspace ONE UEM to Microsoft Intune. Each
device is cleanly removed from Workspace ONE management, joined to (or confirmed in) Microsoft Entra
ID, and enrolled into Intune via Windows automatic enrollment — landing the same configuration,
compliance posture, and access it had before. The work is done in controlled rings so that risk is
contained to a small pilot before the fleet moves.

## Why it is done this way (the *why* — this section only)
A Windows device can only have one MDM authority at a time. If you enroll into Intune without first
removing Workspace ONE, you risk *dual management* — two MDMs fighting over the same settings,
producing unpredictable policy, broken compliance reporting, and confused users. If you remove
Workspace ONE without a confirmed Intune enrollment path, you risk an *unmanaged* device with no
policy and no compliance signal. And if you re-enroll without first rebuilding the device's
configuration and compliance in Intune, the device loses settings it depended on and may fail
Conditional Access, locking the user out of corporate resources.

The repeatable way removes all three risks in order:
1. Build configuration and compliance parity in Intune *first*, so the target is ready before any
   device moves.
2. Make access depend on Entra ID and Intune compliance — not on Workspace ONE — *before* cutover,
   so removing the old MDM never breaks sign-in.
3. Cut over in rings, unenrolling from Workspace ONE and enrolling into Intune one wave at a time,
   validating each device before the next ring begins.

## How it works
1. The target is prepared: Entra ID, Intune licensing, and Windows automatic enrollment are confirmed,
   and a `Parity Configuration – Windows – Migration` and `Compliance Policy – Windows – Migration`
   are built in Intune to match the Workspace ONE baseline.
2. Conditional Access is set so corporate access requires a compliant, Entra-joined device — call this
   `Conditional Access Continuity – Windows – Migration` — independent of Workspace ONE.
3. Devices are grouped: `Group – Migration Pilot – Windows` (a few representative devices) and
   `Group – Migration Broad – Windows` (the rest), with parity and compliance assigned to both up
   front so policy is waiting when each device enrolls.
4. Pilot devices unenroll from Workspace ONE (the unenrollment is performed per VMware's Workspace ONE
   documentation — see the vendor note below), join Entra ID, and enroll into Intune automatically.
5. Each migrated device is validated — enrollment state, parity configuration applied, compliance
   green, access working — using the included scripts.
6. Once the pilot passes its gate, the broad ring follows the same path; remediation handles any
   device left dual- or un-managed.

## The named artifacts (used verbatim throughout)
- `Parity Configuration – Windows – Migration` — the Intune configuration profile(s) that recreate the
  Workspace ONE Windows settings in the target.
- `Compliance Policy – Windows – Migration` — the Intune compliance policy that mirrors the source
  compliance bar (e.g. encryption, firewall, minimum OS).
- `Conditional Access Continuity – Windows – Migration` — the Conditional Access policy that ties
  access to a compliant, Entra-joined Windows device.
- `Migration Ring – Pilot – Windows` and `Migration Ring – Broad – Windows` — the cutover waves.
- `Group – Migration Pilot – Windows`, `Group – Migration Broad – Windows` — the Entra security groups
  the rings target.
- `Group – Workspace ONE Managed – Windows` — the inventory/exclusion group of devices still on the
  source, used to track progress and scope assignments.

## What you control
- The parity target (which Workspace ONE Windows settings are recreated in Intune).
- The compliance bar carried over to Intune.
- The Conditional Access policy that keeps access continuous through cutover.
- Ring membership and the order/pace of the cutover.

## Vendor boundary (read this)
Workspace ONE internals — how to unenroll a Windows device, retire/wipe behavior, the Workspace ONE
UEM console navigation, and any Workspace ONE Intelligent Hub steps — are owned by VMware and are
deferred to the official VMware Workspace ONE documentation. This solution gives exact navigation for
the Intune and Entra side and flags each point where a Workspace ONE action is required.

## Limitations (be honest with buyers)
- Parity is a *recreation*, not an export/import — Workspace ONE profiles do not convert to Intune
  profiles; you rebuild the equivalent settings in Intune.
- A device cannot be Intune-enrolled while Workspace ONE still holds MDM authority; the unenroll step
  is a hard prerequisite for each device.
- User-driven steps (sign-in, restart) may be required during cutover depending on your join method;
  plan communications accordingly.

## The deployment model
> `Build parity + compliance + Conditional Access continuity → group into rings → unenroll from
> Workspace ONE + enroll to Intune by ring → validate each device → expand.` Standard model:
> `Assess → Configure → Pilot → Validate → Expand.`
