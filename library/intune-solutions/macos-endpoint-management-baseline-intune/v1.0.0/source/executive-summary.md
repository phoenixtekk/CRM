# Executive Summary — macOS Endpoint Management Baseline (Microsoft Intune)

Macs enrolled in Microsoft Intune **without a deliberate baseline drift** into inconsistent,
non-compliant states — some have a screen-saver password, some don't; some auto-update, some sit years
behind; ad-hoc profiles pile up and nobody can say which Macs meet the corporate standard. This
package establishes the **foundational macOS management baseline** in Intune — configuration profiles
(settings catalog and, where needed, custom `.mobileconfig`), device restrictions, a compliance
policy, and a macOS software-update policy — so every Mac meets corporate standards for security,
performance, and user experience, deployed pilot-first and rollback-ready.

This is a complete, **deploy-it-today** package written for an administrator with **no prior macOS
management experience**. It is the *general* baseline — deliberately **not** enrollment/ADE setup and
**not** a formal hardening benchmark (CIS/STIG); those are separate solutions this guide references
rather than duplicates.

## What you get
- A plain-language **Solution Overview** of how Intune manages macOS (MDM protocol, the Apple MDM Push
  certificate, configuration profiles), the crucial choice between the **settings catalog** and a
  **custom `.mobileconfig`**, device restrictions, compliance policies, and macOS software-update
  management.
- A **Requirements Guide** with why / verify / implement-if-missing for every prerequisite — including
  the Apple MDM Push (APNs) certificate, macOS enrollment, and the pilot/production groups — plus a
  consistent object-naming convention.
- An **Implementation Guide** of precise, click-by-click Intune steps to build the named baseline
  configuration profile, restrictions policy, software-update policy, and compliance policy; assign to
  a pilot; validate; and expand — with a pilot gate and a rollback note.
- Five **PowerShell scripts** for baseline readiness discovery, per-device applied-state validation,
  fleet posture and drift reporting, safe drift remediation, and repeatable group targeting.
- **Testing** and **Troubleshooting** guides for confident rollout and ongoing operation.

## What this delivers
A **consistent, compliant Mac fleet** built as Intune settings-catalog configuration profiles (with a
custom `.mobileconfig` only where the catalog cannot reach a payload), a device-restrictions policy, a
macOS software-update policy, and a compliance policy — with provable per-device state, drift detection
and remediation, and a pilot-first rollout.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every Mac on a consistent, compliant Intune baseline — secure, performant, and predictable — proven on
a pilot before you scale, and deployable by a single administrator.
