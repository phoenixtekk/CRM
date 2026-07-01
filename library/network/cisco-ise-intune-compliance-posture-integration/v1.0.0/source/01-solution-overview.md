# Solution Overview

## What this solution does

A device can hold a valid network certificate and still be dangerous: unencrypted, out of
date, jailbroken, or unenrolled from management. A certificate proves *identity*; it says
nothing about *health*. This solution closes that gap by wiring **Cisco ISE** (Identity
Services Engine) to **Microsoft Intune** so that ISE asks Intune, in real time, *"Is this
exact device enrolled and compliant right now?"* and grants or denies network / VPN access
on the answer.

The link between them is the **MDM compliance connection** — ISE's built-in ability to call
a Mobile Device Management provider (here, Intune) over its Graph API. ISE authenticates to
your Microsoft Entra tenant using a dedicated **Entra app registration**, reads each device's
enrollment and compliance state, and feeds that state into its authorization rules as just
another condition. Compliant and enrolled devices pass; non-compliant or unmanaged devices
are denied or quarantined.

This document explains how the pieces fit. The exact click-by-click work on the **Intune,
Entra, and Graph** side is authored in full in this solution. The **Cisco ISE console** side
(External MDM server setup, authorization policy editing) is described at the architectural
level and **deferred to Cisco's official documentation** — ISE menu paths change between
releases and must be followed from the vendor's current docs, not fabricated here.

## The moving parts

| Component | Role in this integration |
|-----------|--------------------------|
| **Microsoft Intune** | Source of truth for device enrollment and compliance. Compliance policies define what "healthy" means. |
| **Microsoft Entra ID** | Hosts the **app registration** ISE uses to authenticate, and holds the Graph API permissions that authorize ISE to read device state. |
| **Microsoft Graph** | The API surface ISE calls to read `managedDevices` / compliance state. Intune data is exposed through Graph. |
| **Cisco ISE** | The policy enforcement brain. Holds the **External MDM server** definition pointing at Intune, and the **authorization rules** that turn compliance into an access decision. |
| **Network access devices** (VPN headend, switches, wireless controllers) | Enforce the decision ISE returns — grant, deny, or quarantine. |

## How the signal flows

```
Device connects (VPN / 802.1X / wireless)
        │
        ▼
Network access device  ──RADIUS──▶  Cisco ISE
                                        │
                    ISE authenticates the app registration to Entra
                                        │
                          ISE calls Microsoft Graph ("is this device
                          enrolled + compliant?")  ◀── Intune data
                                        │
                    Compliance/enrollment state returned to ISE
                                        │
             ISE authorization rule evaluates the state
                                        │
        ┌───────────────────────────────┴───────────────────────────────┐
        ▼                                                                ▼
  COMPLIANT + ENROLLED                                     NON-COMPLIANT / UNENROLLED
   → access granted                                          → access denied /
   (full network / VPN)                                        quarantine / remediation VLAN
```

## The compliance and enrollment signals ISE reads

ISE does not re-evaluate the device itself. It reads the verdict Intune has already computed
and the enrollment facts Intune holds. The signals that matter for an access decision are:

- **Registration / enrollment state** — is the device enrolled in Intune (MDM-managed) at
  all? An unenrolled device is unmanaged and should not be trusted.
- **Compliance state** — Intune's rolled-up `compliant` / `noncompliant` / `inGracePeriod`
  verdict for the device, computed from every assigned compliance policy.
- **Per-signal posture** — the underlying facts that drive compliance, such as disk
  encryption on, OS/patch level at or above a floor, no jailbreak / root, and a required
  password / PIN. These are configured as **compliance policy** rules in Intune (authored in
  this solution) and roll up into the single compliance verdict ISE consumes.

Because Intune computes compliance continuously, the decision ISE enforces is **real-time**:
a device that drifts out of compliance (encryption disabled, patch missed) flips to
non-compliant in Intune, and its *next* ISE-mediated access attempt is denied.

## How signals map to authorization

On the ISE side, the MDM compliance dictionary attributes (device registered, device
compliant, and related fields) become **conditions** inside ISE authorization rules. The
mapping pattern this solution standardizes on is:

- **Registered = true AND Compliant = true** → authorization result **grants** full access.
- **Registered = true AND Compliant = false** → authorization result **denies** or sends the
  device to a **remediation / quarantine** VLAN with limited reachability.
- **Registered = false (unmanaged)** → authorization result **denies** or redirects the user
  to an enrollment portal.

The specific ISE authorization-profile and rule construction is done in the ISE console per
Cisco's documentation. This solution provides the exact Intune/Entra/Graph configuration that
makes those signals *available and trustworthy*, the named compliance policies that define
"compliant," the pilot scoping, and the pass/fail validation that proves non-compliant
devices are actually denied before you expand.

## Named objects this solution creates

To keep the build repeatable and auditable, every object is named to a fixed convention and
reused verbatim throughout the guides:

- **Entra app registration:** `ISE-Intune-Compliance-Connector`
- **Compliance policies:**
  - `Compliance – Windows – Baseline`
  - `Compliance – iOS – Baseline`
  - `Compliance – Android – Baseline`
  - `Compliance – macOS – Baseline`
- **Pilot group:** `PILOT – ISE Posture Devices`
- **Expansion group:** `PROD – ISE Posture Devices`

## Deployment model

This solution follows the standard staged model with explicit pass/fail gates:

**Assess → Configure → Pilot → Validate → Expand.**

- **Assess** — confirm prerequisites (compliance policies, licensing, reachability).
- **Configure** — register the app, grant Graph permissions, connect ISE to Intune, author
  the named compliance policies, and build the ISE authorization mapping.
- **Pilot** — assign to `PILOT – ISE Posture Devices` only.
- **Validate** — prove compliant devices are granted access and non-compliant devices are
  denied (the pass/fail gate).
- **Expand** — roll out to `PROD – ISE Posture Devices` and the fleet.
