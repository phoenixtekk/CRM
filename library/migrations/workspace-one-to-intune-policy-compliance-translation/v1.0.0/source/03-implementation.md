# 3. Implementation Guide — Workspace ONE to Intune: Policy & Compliance Translation

Follow these steps in order. The Intune work is done in the Microsoft Intune admin center
(`https://intune.microsoft.com`). The Workspace ONE source export is vendor-owned and is flagged at
Step 1 — perform it per the current VMware/Omnissa Workspace ONE UEM documentation.

Model: Assess (inventory the source) to Configure (map per platform, handle gaps) to Pilot (assign to
the pilot scope) to Validate (parity gate) to Expand (production). No platform passes Validate to
Expand until its mapped policy clears the parity gate.

The artifact names from the Overview are reused verbatim below.

## Step 1 — Assess: inventory the Workspace ONE source

1. Export the in-scope Workspace ONE UEM configuration profiles and compliance policies per platform.
   The console paths, UEM REST API, and payload format are vendor-owned and version-specific —
   follow the current VMware/Omnissa Workspace ONE UEM documentation. (Deferred to vendor docs.)
2. Save the export where `WS1POL-Discovery.ps1` expects it, and run `WS1POL-Discovery.ps1` to produce
   a normalized source inventory list (profiles and compliance rules by platform). This script is
   read-only.
3. Confirm the inventory is complete against the source console before proceeding — completeness here
   is what parity is later measured against.

## Step 2 — Assess: open the gap register

1. Create `Policy Translation - All Platforms - Gap Register` with one row per source setting and
   these columns: Source setting · Platform · Intune destination (settings catalog / template /
   compliance / none) · Decision (map / substitute / defer / accept-gap) · Effective-value note ·
   Owner.
2. Pre-populate it from the Step 1 inventory; every source setting gets a row before any mapping
   begins.

## Step 3 — Configure: build the policy-scope groups

1. Run `WS1POL-Set-PolicyScopeTargeting.ps1` to create `Policy Scope - Pilot - Stage` (and
   `Policy Scope - Production - Stage` for later), or create them manually at `Entra > Groups > New
   group > Security`.
2. Add a representative device for each in-scope platform to `Policy Scope - Pilot - Stage`.

## Step 4 — Configure: map configuration profiles to the settings catalog, per platform

Do this once per in-scope platform. The example is Windows; repeat for iOS/iPadOS, Android, macOS.

1. Go to `Devices > Configuration > Create > New policy`.
2. Platform: select the platform (for example Windows 10 and later). Profile type: Settings catalog.
   Select Create.
3. Name: `Mapped Config - Windows - Pilot` (use the matching platform name for each platform:
   `Mapped Config - iOS - Pilot`, `Mapped Config - Android - Pilot`, `Mapped Config - macOS -
   Pilot`). Select Next.
4. Select Add settings, then search the settings picker for each source setting's equivalent and add
   it, setting the same effective value as the Workspace ONE source. For each setting, mark its row
   in the gap register as map and note the effective value.
5. For any source setting with no settings-catalog equivalent, leave it for Step 5 (template) or
   Step 6 (gap) — do not approximate it silently.
6. Assignments: add `Policy Scope - Pilot - Stage`. Select Next, then Create.

## Step 5 — Configure: map template-only settings to configuration profiles, per platform

For source settings that the settings catalog does not cover (commonly Wi-Fi, VPN, certificates,
email, and some endpoint-protection settings):

1. Go to `Devices > Configuration > Create > New policy`.
2. Platform: the platform. Profile type: Templates, then select the matching template (for example
   Wi-Fi, VPN, or SCEP/PKCS certificate). Select Create.
3. Name it `Mapped Config - <Platform> - Pilot` with a template suffix that identifies it (for
   example `Mapped Config - Windows - Pilot (Wi-Fi)`), so it remains self-describing.
4. Enter the settings to match the source profile's effective values. Mark each mapped row in the gap
   register.
5. Assignments: add `Policy Scope - Pilot - Stage`. Select Next, then Create.

## Step 6 — Configure: handle unsupported settings and exceptions

For every gap-register row still unresolved:

1. Decide and record one of: substitute (a different Intune setting achieves the same effective
   posture — note it), defer (handled by a separate workstream such as certificate-authority or app
   migration — note the owner), or accept-gap (no equivalent and the risk is accepted — note who
   accepted it).
2. For settings that need a control Intune exposes only via custom configuration, use a custom /
   OMA-URI profile where the platform supports it, and record the OMA-URI in the register. Do not
   invent settings that do not exist.
3. The gap register, fully decided, is a deliverable in its own right — no source setting may remain
   undecided at the parity gate.

## Step 7 — Configure: map compliance policies, per platform

Do this once per in-scope platform.

1. Go to `Devices > Compliance > Create policy`.
2. Platform: select the platform. Select Create.
3. Name: `Mapped Compliance - Windows - Pilot` (and the matching platform name for each:
   `Mapped Compliance - iOS - Pilot`, `Mapped Compliance - Android - Pilot`,
   `Mapped Compliance - macOS - Pilot`).
4. Compliance settings: set each rule to match the Workspace ONE compliance policy's intent — for
   example minimum OS version, passcode/password requirements, encryption required,
   jailbreak/root (rooted device) block, and threat level where a Mobile Threat Defense connector is
   present. Record each mapped rule in the gap register.
5. Actions for noncompliance: set the same effective consequence as the source (for example mark
   noncompliant immediately or after a grace period).
6. Assignments: add `Policy Scope - Pilot - Stage`. Select Next, then Create.
7. Confirm with the identity owner that the Conditional Access policy requiring a compliant device
   covers these devices, so the compliance signal actually gates access.

## Step 8 — Pilot: apply and confirm on the pilot scope

1. Trigger a sync on a pilot device per platform (the device-side sync path differs per platform).
2. Run `WS1POL-Report.ps1` to confirm each `Mapped Config - <Platform> - Pilot` and
   `Mapped Compliance - <Platform> - Pilot` policy is deployed and shows assigned devices. This
   script is read-only.

## Step 9 — Validate: the parity gate

1. Run `WS1POL-Validation.ps1` to compare the source inventory (Step 1) against the deployed Intune
   policy, per platform, and produce a parity result: mapped, substituted, deferred, accepted-gap, or
   missing. This script is read-only.
2. Run `WS1POL-Report.ps1` for per-device compliance and configuration state on the pilot.
3. The parity gate passes for a platform when: every in-scope source setting is mapped, substituted,
   deferred, or accepted-gap (none missing); effective values match; and the compliance policy gates
   the same access. If anything is missing, resolve it in the gap register and re-map.
4. If a policy conflict is detected (a setting reported in conflict on a device), run
   `WS1POL-Remediation.ps1` to identify and, with confirmation, resolve the conflicting assignment.
   It defaults to `-WhatIf`.

## Step 10 — Expand: production

1. Once a platform clears the parity gate, change its mapped configuration and compliance policy
   assignments from `Policy Scope - Pilot - Stage` to `Policy Scope - Production - Stage`, or
   duplicate each policy to a `- Production` copy and assign the production group.
2. Add the fleet's devices to `Policy Scope - Production - Stage` in waves per the wave plan (global
   requirement G6).
3. Re-run `WS1POL-Validation.ps1` and `WS1POL-Report.ps1` after each wave to confirm parity holds and
   no device fell out of compliance.

---

### Order of operations

`Source inventory > Gap register > Scope groups > Map config (catalog) > Map config (templates) >
Handle gaps > Map compliance > Apply on pilot > Parity gate > Expand`
