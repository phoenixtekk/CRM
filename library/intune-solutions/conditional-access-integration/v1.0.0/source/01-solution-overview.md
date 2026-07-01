# 1. Solution Overview — Conditional Access Integration

## What Conditional Access is
Conditional Access (CA) is Microsoft Entra's policy engine that evaluates each sign-in and
decides whether to **allow**, **challenge** (e.g. require MFA), or **block** it. Policies combine
**signals** (user/group, target app, device state, location, client app, sign-in risk) with
**access controls** (require MFA, require compliant device, require Entra-joined device, require
app protection policy, or block).

## How it integrates with Intune
Intune marks devices **Compliant** (via device compliance policies) and applies **app protection
policies** to mobile apps. Conditional Access consumes those signals: "**require a compliant
device**" means only devices Intune has verified as healthy can reach Microsoft 365 — and
"**require app protection policy**" means only managed mobile apps can access corporate data.

## How it works
1. A user attempts to sign in to a protected app (e.g. Outlook).
2. Entra evaluates the applicable CA policies against the sign-in's signals.
3. If controls are satisfied (compliant device, MFA passed), access is granted; otherwise the user is challenged or blocked.
4. **Report-only** mode evaluates policies and logs what *would* happen without enforcing — the safe way to pilot.

## The baseline policies this delivers
- **Require compliant or Entra-joined device** for Microsoft 365.
- **Require MFA** for all users.
- **Block legacy authentication** (the channel that bypasses MFA).
- **Require app protection policy** for mobile email/apps.
- **Break-glass exclusions** so emergency-access accounts are never locked out.

## Benefits
- **Enforcement** — compliance and MFA become hard requirements, not suggestions.
- **Phishing/legacy resistance** — block legacy auth and require MFA.
- **Safe rollout** — Report-only mode and break-glass accounts prevent lockouts.
- **Zero Trust** — access decisions based on real-time device and identity signals.

## Limitations (be honest with buyers)
- Conditional Access requires **Microsoft Entra ID P1**.
- "Require compliant device" depends on the **Device Compliance** solution being in place.
- Misconfigured policies *can* lock users (or admins) out — hence break-glass accounts and Report-only piloting.
- Some controls (app protection) require the managed mobile apps and enrollment posture.

## The standard Phoenixtekk deployment model
> **Create break-glass accounts → build policies in Report-only → review impact → enable →
> expand.** Phoenixtekk pattern: **Assess → Configure → Pilot → Validate → Expand.**
