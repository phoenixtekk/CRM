# 1. Solution Overview — Workspace ONE to Intune: Policy & Compliance Translation

## What this solution is

This is a repeatable way to translate the policy and compliance layer of a Workspace ONE UEM
deployment into Microsoft Intune. It is not a device-enrollment migration and it is not an app
migration — it is the translation of the settings themselves: every configuration profile and every
compliance rule that defines how your devices are secured and managed, moved into Intune so the
effective posture is preserved.

The work has four parts: inventory the source policy, map each setting to its Intune equivalent per
platform, handle the settings that do not translate, and validate parity before cutover. The output
is a set of named, mapped Intune policy objects and a gap register that records every decision.

## Why the settings layer is the hard part (the why — stated once, here)

Enrollment moves a device; the policy layer is what makes that device safe. A Workspace ONE
configuration profile and a compliance policy each encode intent — a passcode length, an encryption
requirement, a Wi-Fi configuration, a jailbreak/root block that gates corporate access. Intune
expresses the same intents, but through different objects (the settings catalog, configuration
profiles, and compliance policies) with different names, different scopes, and a different
per-platform model. Re-typing settings by eye loses fidelity: a setting silently drops, maps to the
wrong control, or changes its effective value. When that happens at cutover the device looks managed
but is quietly weaker — or a profile conflict breaks a working feature. Translating deliberately,
recording every gap, and proving parity on a pilot before you scale is the only way to guarantee the
posture you had is the posture you keep. That is the entire reason this solution exists; the rest of
the guides simply execute it.

## The three Intune destinations a Workspace ONE policy maps to

- Settings catalog — the broadest, most granular surface; the default destination for most
  per-platform device configuration. Located at `Devices > Configuration > Create > New policy >
  (platform) > Settings catalog`.
- Configuration profiles (templates) — Intune's templated profiles (for example Wi-Fi, VPN,
  certificate, email, endpoint protection) for settings the settings catalog does not yet cover, at
  `Devices > Configuration > Create > New policy > (platform) > Templates`.
- Compliance policies — the rules that determine whether a device is compliant (passcode,
  encryption, OS version, jailbreak/root, threat level), which Conditional Access then enforces, at
  `Devices > Compliance > Create policy`.

## The per-platform model

Intune policy is created per platform, and a single Workspace ONE profile that spans platforms
becomes one Intune object per platform. Every platform in this solution is handled explicitly:
Windows, iOS/iPadOS, Android (Enterprise), and macOS. A setting that exists on the source for one
platform may have no equivalent on another — those become entries in the gap register, not silent
omissions.

## Workspace ONE internals are deferred to the vendor

This solution covers the Intune side with exact navigation. The mechanics of exporting or reading
Workspace ONE UEM profiles and compliance policies (console paths, the UEM REST API, the profile
XML/payload format) change between Workspace ONE versions and are owned by the vendor — consult the
current VMware/Omnissa Workspace ONE UEM documentation for the source-side export. The discovery
script flags this and shows where a source export plugs in.

## What you control

- Which Workspace ONE settings translate to the settings catalog, to a configuration profile
  template, or to a compliance policy, per platform.
- How unsupported settings and exceptions are handled (accept, substitute, or defer) — recorded in
  the gap register.
- The named, reusable Intune objects: the mapped policy sets, the compliance policies, the gap
  register, and the assignment groups.
- The parity gate: the criteria a mapped policy must meet against the source before cutover.

## Naming convention (used for every artifact in this solution)

Every artifact is named `<Purpose> - <Scope> - <Stage>` so objects are self-describing and reusable.
The names below are reused verbatim throughout the guides:

- `Mapped Config - Windows - Pilot`, `Mapped Config - iOS - Pilot`, `Mapped Config - Android -
  Pilot`, `Mapped Config - macOS - Pilot` — the translated configuration policy sets per platform.
- `Mapped Compliance - Windows - Pilot`, `Mapped Compliance - iOS - Pilot`, `Mapped Compliance -
  Android - Pilot`, `Mapped Compliance - macOS - Pilot` — the translated compliance policies per
  platform.
- `Policy Translation - All Platforms - Gap Register` — the record of every unsupported setting and
  exception decision.
- `Policy Scope - Pilot - Stage` and `Policy Scope - Production - Stage` — the Entra security groups
  that scope assignment by stage.

(At Expand, the `- Pilot` suffix becomes `- Production`; the names are otherwise identical.)

## Deployment model

Assess to Configure to Pilot to Validate to Expand, with a parity gate between Validate and Expand:
no platform expands to production until its mapped policy passes parity against the source on the
pilot.

## Limitations (be honest with buyers)

- Workspace ONE source export is vendor-owned and version-specific; this solution flags the export
  point and defers the source mechanics to VMware/Omnissa documentation.
- Not every Workspace ONE setting has a one-to-one Intune equivalent; some require a settings-catalog
  substitute, a custom/OMA-URI profile, or are accepted as a gap — each is recorded, not hidden.
- This solution translates policy and compliance; device enrollment, app deployment, and certificate
  authority migration are separate workstreams (referenced where they intersect).
- Compliance policies only gate access when paired with Conditional Access; configuring Conditional
  Access is a related but distinct task.
