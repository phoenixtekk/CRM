# 1. Solution Overview — macOS Compliance & Conditional Access for Zero-Trust Access

## The problem this solves
A Mac shouldn't reach corporate resources just because someone typed the right password. Under
**Zero Trust**, every access request is verified against **who** the user is *and* **what state
the device is in** — encrypted, patched, firewalled, and free of active threats. This solution
builds the Mac-specific half of that gate: **macOS device compliance signals in Microsoft Intune**
wired to a **named Conditional Access policy in Microsoft Entra**, so only trusted, compliant Macs
get in.

> This solution is **Mac-focused**. If you also run Windows and want the general Conditional Access
> baseline (require MFA, block legacy auth, break-glass accounts), deploy the separate **Conditional
> Access Integration** solution alongside it — this guide references those safety practices but does
> not re-teach them.

## The two halves and how they connect
1. **macOS device compliance (Intune).** A **compliance policy** evaluates each enrolled Mac against
   rules — disk encryption (FileVault), minimum macOS version, firewall on, and Microsoft Defender
   **machine-risk** below a chosen threshold — and marks the Mac **Compliant** or **Not compliant**.
2. **Conditional Access (Entra).** A **CA policy** with the grant control **Require device to be
   marked as compliant** consumes that signal. A compliant Mac is allowed; a non-compliant Mac is
   blocked (or challenged) when it tries to reach the targeted resources.

The Mac's compliance state is the bridge: Intune produces it, Entra enforces on it.

## The macOS compliance signals this delivers
| Signal | What it proves | Intune compliance setting |
|---|---|---|
| **FileVault / disk encryption** | Data at rest is protected if the Mac is lost or stolen | *Require FileVault* / *Encryption of data storage* |
| **Minimum macOS version** | The Mac is patched to a supported, non-vulnerable OS | *Minimum OS version* |
| **Firewall enabled** | The device rejects unsolicited inbound connections | *Firewall* (via macOS settings/compliance) |
| **Microsoft Defender machine risk** | No active/high-severity threat on the device | *Require the device to be at or under machine-risk score* (Defender for Endpoint connector) |

Each signal that a Mac fails flips it **Not compliant**, and the CA policy then denies access — Zero
Trust in action.

## How it works, end to end
1. A Mac is enrolled in Intune and receives the macOS **compliance policy**.
2. Intune evaluates the Mac against the four signals and reports **Compliant** / **Not compliant**.
3. A user on that Mac signs in to a protected resource (e.g. Outlook on the web).
4. Entra evaluates the **Conditional Access policy** — *Require device to be marked as compliant*.
5. **Compliant → allowed. Not compliant → blocked** (Zero Trust: no healthy device, no access).
6. During pilot, the CA policy runs in **Report-only** so you can see *what would happen* before it
   actually blocks anyone.

## Named objects this solution creates (and reuses)
You will build these exact objects and reuse them by name throughout the guide:
- **Compliance policy:** `macOS - Zero-Trust Compliance`
- **Conditional Access policy:** `CA - macOS - Require Compliant Device`
- **Pilot group (Entra security group):** `macOS-ZeroTrust-Pilot`
- **(Optional) exclusion group:** `macOS-ZeroTrust-Exclusions` (for break-glass / service exceptions)

## Benefits
- **Device-state enforcement for Macs** — access is gated on encryption, patch level, firewall, and
  threat state, not just a password.
- **Zero Trust, least privilege** — a Mac earns access only while it stays healthy.
- **Safe rollout** — Report-only mode plus a small pilot group means you validate before you block.
- **Auditable** — named policies and the included reports show exactly which Macs are compliant and
  which sign-ins were allowed or denied.

## Limitations (be honest with buyers)
- Conditional Access requires **Microsoft Entra ID P1**.
- The **Require compliant device** control depends on **this macOS compliance policy** being deployed
  and Macs being **Intune-enrolled and Entra-registered** first.
- The **Defender machine-risk** signal requires **Microsoft Defender for Endpoint on macOS** onboarded
  and the **Intune ↔ Defender connector** turned on (a companion prerequisite, flagged below).
- Available macOS compliance settings evolve; exact setting labels can differ slightly by Intune
  service version. Where a label may vary, this guide flags it — verify against the live console.
- A misconfigured CA policy can block legitimate users. That is why this solution pilots in
  **Report-only** on a small group and keeps break-glass/exclusion accounts out of scope.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand.**
> Build the compliance policy → map it to a Report-only CA policy on the pilot group → confirm
> compliant Macs are allowed and non-compliant Macs are (would-be) blocked → enable enforcement →
> expand to all Macs.
