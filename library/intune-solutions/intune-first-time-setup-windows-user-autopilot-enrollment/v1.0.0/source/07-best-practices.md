# 7. Best Practices — Microsoft Intune First-Time Setup for Windows

## Scope discipline (keep the first setup small)
- **Pilot first, always.** Enroll one PC each way, validate against the gates, then expand. Resist the
  urge to widen the auto-enrollment scope to **All** before the pilot passes.
- **Keep the ESP light on the pilot.** Do not require heavy apps in `INTBASE - ESP - Pilot` — a blocked
  ESP is the most common reason a first Autopilot run appears to "hang". Deep ESP tuning belongs to the
  advanced Autopilot solution.
- **Entra-joined only.** Do not mix in Hybrid Entra join here; it changes the identity model and is a
  separate solution.

## Naming and hygiene
- **Use the exact object names** throughout: `INTBASE - Windows Users - Pilot`,
  `INTBASE - Autopilot Devices`, `INTBASE - Autopilot - Pilot`, `INTBASE - ESP - Pilot`,
  `INTBASE - Windows Enrollment - Pilot`, `INTBASE - Compliance - Windows Pilot`. Consistent names make
  the setup auditable and easy to clean up.
- **One purpose per group.** Keep the pilot **user** group and the Autopilot **device** group separate —
  auto-enrollment/compliance target users; Autopilot profile/ESP target devices.

## The enrollment-time grouping rule (do not skip)
- The Autopilot device group is **Assigned**, and the **Intune Provisioning Client** service principal
  (AppId `f1346770-5b25-470b-88bd-d5744ab7952c`) must **own** it. Verify ownership before provisioning —
  it is the difference between a working zero-touch device and an empty group where nothing deploys.

## Enrollment method choice
- **User-driven** for PCs already in someone's hands (fastest to prove the tenant works).
- **Autopilot** for new/reset devices you want to ship zero-touch. Prefer **OEM/reseller registration at
  purchase** over manual hash import once you move past the pilot.

## Licensing and identity
- Assign the Intune license **via the pilot group** so new pilot users inherit it automatically.
- Use a **dedicated pilot user**, not an admin account, so the experience matches a real end user.

## Validation and evidence
- Keep the scripts **read-only** in normal use; run `INTBASE-Remediation.ps1` only with `-WhatIf` first
  and read the preview before applying.
- Save the output of `INTBASE-Report-Enrollment.ps1` as your record that both paths landed managed and
  compliant.

## Government tenants
- Use the `*.us` portals and `Connect-MgGraph -Environment USGov` for scripts. Treat Autopilot/enrollment
  feature timing in GCC High/DoD as **verify-before-relying**, not assumed parity.

## When to move up
- Ready for dynamic-group strategy, multi-profile Autopilot, pre-provisioning ("white glove"), deep ESP
  tuning, app packaging, or Conditional Access? Those are **out of scope here** by design — step up to
  the **Windows Autopilot** and **Cloud-First Autopilot Zero-Touch** solutions, which build directly on
  this foundation.
