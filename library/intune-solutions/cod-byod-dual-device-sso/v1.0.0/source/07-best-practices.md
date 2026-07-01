# 7. Best Practices — Dual-Device (Personal + Corporate) Management with Single Sign-On

Field-proven guidance to keep one identity working cleanly across both device types.

## Identity & assignment model
- **Assign policies to user groups, scope with device filters.** This is the heart of the design:
  one assignment to the user, the right policy follows the device's ownership. Avoid mixing
  per-device group assignments that fight the filters.
- **Keep one Entra identity per user.** Never create a separate "BYOD account" — it splits policy and
  breaks Conditional Access logic.
- **Name groups and filters by intent** (e.g. *PILOT – COD-BYOD Users*, *Corporate Devices*,
  *Personal Devices*) so assignments are self-documenting.

## Ownership hygiene
- **Make ownership deterministic.** Use corporate enrollment programs and corporate device
  identifiers so COD tags **Corporate** automatically; let BYOD default to **Personal**.
- **Audit ownership regularly** with `DUALDEV-DeviceReport.ps1` — a device tagged the wrong way gets
  the wrong policy set.

## BYOD data protection
- **Prefer App Protection (MAM) without enrollment for BYOD.** It protects corporate data without
  managing the employee's personal device — better adoption, less privacy friction, strong
  data-leak controls.
- **Lock the data boundary:** block backup, restrict cut/copy/paste and "Save As" to managed apps,
  require a PIN, and enforce encryption within managed apps.
- **Only enroll a personal device (MDM) when you truly need device settings** — and keep it tagged
  **Personal** so it never receives corporate device policies.

## Corporate device management
- **Apply a real compliance baseline** (OS minimum, encryption, firewall) and gate access on it via
  Conditional Access.
- **Layer the zero-touch enrollment solutions** (Autopilot / Apple ADE / Android Enterprise) for
  hands-off COD provisioning; this solution unifies the model they all feed into.

## Conditional Access
- **One policy, "require one of."** Grant access when the request is from a **compliant** device
  **or** an **app-protection-protected** app — never require both, or you lock out one device type.
- **Always start report-only.** Read the sign-in logs for the pilot user before enforcing.
- **Add MFA** as part of the same access story for a complete Zero Trust posture.

## Rollout discipline
- **Pilot one user with two real devices** (a corporate and a personal one) — it's the only way to
  prove the single-identity experience end to end.
- **Expand in waves**, validating each with `DUALDEV-Validation.ps1` before widening.
- **Communicate the BYOD deal to employees:** what IT can and cannot see/do on a personal device
  under App Protection (data containment, *not* device surveillance) — clarity drives adoption.

## Operations & documentation
- **Keep a runbook** of the pilot/production groups, the two ownership filters, the compliance and
  app-protection policies, and the Conditional Access policy — the moving parts that define the model.
- **Report monthly** with `DUALDEV-DeviceReport.ps1`: device counts by ownership, users who have both
  a COD and a BYOD device, compliance, and app-protection coverage.
