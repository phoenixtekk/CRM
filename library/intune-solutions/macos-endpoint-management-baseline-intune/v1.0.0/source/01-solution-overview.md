# 1. Solution Overview — macOS Endpoint Management Baseline (Microsoft Intune)

## What this solution is
This is the **foundational macOS management baseline** for Microsoft Intune: the deliberate set of
configuration profiles, device restrictions, a compliance policy, and a macOS software-update policy
that every corporate Mac should receive the moment it is under management. Macs enrolled in Intune
without a baseline drift into inconsistent, non-compliant states — some have a screen-saver password,
some don't; some auto-update, some sit years behind; nobody can say which Macs meet the corporate
standard. This solution establishes that standard as named Intune policy, deploys it pilot-first, and
proves it, so every Mac lands on a consistent, compliant, predictable configuration.

This is the **general baseline**. It is intentionally *not* an enrollment/Automated Device Enrollment
(ADE) build, and it is *not* the CIS hardening benchmark — those are separate solutions. This one
assumes your Macs are already enrolled and gives them a sensible, corporate-standard configuration.
Where enrollment or a formal benchmark is relevant, this guide references it rather than duplicating
it.

## The macOS management model in Intune
macOS is not Windows. There is no ADMX, no Windows settings catalog, no Group Policy. Apple manages a
Mac through the **MDM protocol**, and Intune configures it by delivering Apple **configuration
profiles** — declarative payloads the Mac's management framework applies. Intune reaches a Mac only
after two things exist: an **Apple MDM Push (APNs) certificate** (the trust channel between your
tenant and Apple) and an **enrollment** that has brought the Mac under management. Once those are in
place, everything in this baseline is delivered as Intune policy over that channel.

## The two ways to configure macOS: settings catalog vs custom `.mobileconfig`
Every setting on this baseline is delivered as an Apple configuration-profile payload. There are two
ways to author those payloads in Intune, and knowing which to use is central to this solution:

1. **Settings catalog (Apple)** — the primary, preferred surface. In
   **Devices → macOS → Configuration → Create → New Policy → Settings catalog**, Microsoft exposes
   Apple's payloads in a searchable picker grouped by area (Login Window, Restrictions, Security,
   Software Update, Privacy Preferences, and more). You add settings and set their values in the GUI;
   Intune builds the `.mobileconfig` for you. Use the settings catalog for everything it can express —
   it is discoverable, versioned, and reports per-setting status.
2. **Custom configuration profile (`.mobileconfig`)** — the escape hatch. A minority of Apple payloads
   are not (yet) surfaced in the settings catalog. For those, you author or obtain the raw
   `.mobileconfig` file and upload it via
   **Devices → macOS → Configuration → Create → New Policy → Templates → Custom**. This delivers the
   exact Apple payload the catalog cannot reach. Use it only when the catalog cannot express the
   setting, because a custom profile is opaque (Intune reports "applied", not per-setting detail).

A third surface — **macOS shell scripts** (Devices → macOS → Shell scripts) — exists for the rare
control that is only enforceable by a command. The general baseline in this solution is built entirely
from configuration profiles and does not require shell scripts; they are noted only so you know the
surface exists.

## Device restrictions
**Restrictions** are a specific, high-value slice of configuration-profile settings that turn features
on or off at the OS level — for example controlling AirDrop, content caching, iCloud document sync,
Game Center, or requiring a password after the screen saver begins. In the modern Intune console,
macOS restrictions are authored **inside the settings catalog** (the older "Device restrictions"
template is being consolidated into the catalog), so this solution builds them as a dedicated
settings-catalog policy you can reason about and assign independently of the broader baseline.

## Compliance policies
A **compliance policy** does not configure the Mac — it *evaluates* it and reports a
compliant / non-compliant verdict. A macOS compliance policy checks conditions such as minimum OS
version, whether **FileVault** disk encryption is on, whether the **firewall** is on, and system
integrity. Compliance is what makes the baseline provable and what other systems (notably Conditional
Access, a separate solution) consume to allow or block access. This baseline includes a macOS
compliance policy so every Mac's posture is measured and reported, not just configured.

## macOS software-update management
Keeping Macs current is part of the baseline, not an afterthought. Intune manages macOS updates
through the **Software Update** payload (in the settings catalog) and, on modern macOS, through
**Declarative Device Management (DDM)** update enforcement, where supported. You define whether the
Mac downloads and installs OS and security updates automatically, and you can require a **minimum OS
version** and set a **deadline** so updates are not indefinitely deferred. This solution builds a
named macOS software-update policy so update behaviour is deliberate and consistent instead of
left to each user.

> **Version note:** the exact Software Update payload keys and the availability of DDM update
> enforcement depend on the macOS version and Apple's current MDM capabilities. Configure from the
> options Intune presents for your macOS releases; where a capability is version-dependent this guide
> flags it rather than assuming it.

## The compliance and drift model
Configuring the baseline is only half the job. You also:
- **Prove application** — Intune reports per-profile and (for settings-catalog policies) per-setting
  state, so you can show each Mac received the baseline.
- **Prove compliance** — the compliance policy gives each Mac a compliant / non-compliant verdict.
- **Detect drift** — a Mac can fall out of the intended state (a conflicting profile, a removed
  assignment, a failed apply, a user change). The included reporting and validation scripts surface
  drift so you can reapply.

## The deployment model
> Build the named baseline configuration profiles, the restrictions policy, the compliance policy, and
> the macOS software-update policy as Intune settings-catalog policies (with a custom `.mobileconfig`
> only where the catalog cannot reach a payload), assign to a pilot, prove application and compliance,
> then expand fleet-wide. The repeatable way: **Assess → Configure → Pilot → Validate → Expand.**

## Benefits
- **Consistency** — every Mac lands on the same corporate-standard configuration instead of drifting.
- **Provable compliance** — per-device configuration state plus a compliant / non-compliant verdict.
- **Current by design** — a deliberate macOS software-update policy instead of per-user chaos.
- **Discoverable and maintainable** — built primarily in the settings catalog, named consistently, and
  assigned by group.
- **Safe rollout** — piloted before the fleet, with a rollback note, because even a baseline change can
  surprise a workflow.

## Limitations (be honest with buyers)
- This is the **general baseline**, not enrollment/ADE setup and not a formal hardening benchmark
  (CIS/STIG) — those are separate solutions referenced here, not duplicated.
- Some Apple payloads are not in the settings catalog and require a custom `.mobileconfig`; the exact
  payload keys and values are deferred to Apple's public MDM documentation.
- Software-update enforcement capabilities (especially DDM-based) are **macOS-version-dependent**;
  configure from what Intune offers for your releases.
- A baseline reduces drift but does not replace ongoing operations — you still detect and remediate
  drift over time (the included scripts help).
