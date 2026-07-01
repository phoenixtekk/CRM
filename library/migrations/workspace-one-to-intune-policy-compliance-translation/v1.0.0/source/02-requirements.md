# 2. Requirements Guide — Workspace ONE to Intune: Policy & Compliance Translation

Verify every requirement before you map anything. Category-wide prerequisites (target tenant, Intune
licensing, source access, inventory, enrollment plumbing, pilot group, change control) are in
`global-requirements-migrations.md` and are assumed here. The requirements below are specific to the
policy and compliance translation work. Each entry: Description · Why · Verify · Implement-if-missing.

## 2.1 Workspace ONE policy and compliance export

Description: A complete export or readable inventory of the in-scope Workspace ONE UEM configuration
profiles and compliance policies, per platform.

Why: You cannot map what you have not captured; the translation begins from a known, complete source
list, and parity later is measured against it.

Verify: You can produce, from Workspace ONE UEM, a list of every in-scope profile and compliance
policy with its settings and assignments. (Source-side export mechanics are vendor-owned — see the
current VMware/Omnissa Workspace ONE UEM documentation.)

Implement-if-missing: Obtain Workspace ONE UEM administrative read access and export the profile and
compliance inventory per the vendor documentation; place it where `WS1POL-Discovery.ps1` expects a
source export.

## 2.2 Intune configuration authoring rights

Description: An admin role that can create and assign device configuration policies (settings catalog
and templates) in the target tenant.

Why: The mapped policy sets are created in Intune; without authoring rights you cannot build them.

Verify: `https://intune.microsoft.com` loads and you can open `Devices > Configuration > Create`; you
hold Intune Administrator or Policy and Profile Manager.

Implement-if-missing: Have a Global Administrator assign Intune Administrator (or the least-privilege
Policy and Profile Manager role) to your account.

## 2.3 Intune compliance authoring rights and Conditional Access awareness

Description: Rights to create compliance policies, and awareness of which Conditional Access policies
will consume device-compliance signals.

Why: A translated compliance policy only enforces posture when Conditional Access requires a
compliant device; mapping compliance without knowing the gate leaves the rule inert.

Verify: You can open `Devices > Compliance > Create policy`; you can view the Conditional Access
policies that require device compliance in `Entra > Protection > Conditional Access`.

Implement-if-missing: Obtain compliance-policy authoring rights; confirm with the identity owner
which Conditional Access policies require compliant devices before cutover.

## 2.4 Per-platform mapping targets confirmed

Description: For each in-scope platform (Windows, iOS/iPadOS, Android Enterprise, macOS), the Intune
destination surface is confirmed available (settings catalog, the required template types, compliance
policy).

Why: Mapping is per platform; a platform whose enrollment or template prerequisites are not ready
cannot receive its translated policy.

Verify: For each platform, `Devices > Configuration > Create > New policy` offers the platform and
both Settings catalog and Templates; `Devices > Compliance > Create policy` offers the platform.

Implement-if-missing: Complete the platform enrollment prerequisites (global requirement G5) so the
platform's policy surfaces are available; remove any platform that is out of scope from the mapping
plan.

## 2.5 The gap register artifact

Description: A single, named record — `Policy Translation - All Platforms - Gap Register` — that
captures every source setting with no clean Intune equivalent and the decision made for it.

Why: Unsupported settings handled silently are exactly how posture is lost; the register makes every
gap an explicit, reviewable decision.

Verify: The gap register exists (a spreadsheet or document) with columns for source setting,
platform, Intune destination or "none", decision (accept/substitute/defer), and owner.

Implement-if-missing: Create `Policy Translation - All Platforms - Gap Register` from the template in
the Implementation Guide before mapping begins.

## 2.6 Policy-scope groups

Description: Microsoft Entra security groups that scope policy assignment by stage —
`Policy Scope - Pilot - Stage` first, `Policy Scope - Production - Stage` at expand.

Why: Translated policy must land on a controlled pilot before the fleet; stage-scoped groups make the
Pilot-then-Expand model concrete and reversible.

Verify: `Entra > Groups`; `Policy Scope - Pilot - Stage` exists and contains representative devices
across the in-scope platforms.

Implement-if-missing: Create the groups with `WS1POL-Set-PolicyScopeTargeting.ps1`, or manually at
`Entra > Groups > New group > Security`.

## 2.7 A parity baseline

Description: An agreed definition of what "parity" means for this migration — the setting-level
criteria a mapped Intune policy must meet against its Workspace ONE source to pass the gate.

Why: The parity gate at Validate needs an objective pass/fail definition, not a judgment call.

Verify: A written parity definition exists (for example: every in-scope source setting is mapped,
substituted, or registered as a gap; effective values match; compliance rules gate the same access).

Implement-if-missing: Define parity with the security owner before mapping; record it alongside the
gap register.

---

## Checklist

- [ ] Workspace ONE profile + compliance export captured (vendor docs)
- [ ] Intune configuration authoring rights
- [ ] Compliance authoring rights + Conditional Access consumers identified
- [ ] Per-platform mapping targets available (Windows / iOS / Android / macOS)
- [ ] `Policy Translation - All Platforms - Gap Register` created
- [ ] `Policy Scope - Pilot - Stage` group created with representative devices
- [ ] Parity baseline defined and agreed
