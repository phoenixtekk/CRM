# 1. Solution Overview — Conditional Access Integration (Government / GCC High)

## What Conditional Access is
Conditional Access (CA) is Microsoft Entra's policy engine that evaluates each sign-in and
decides whether to **allow**, **challenge** (e.g. require MFA), or **block** it. Policies combine
**signals** (user/group, target app, device state, named location, client app, sign-in risk) with
**access controls** (require MFA, require compliant device, require Entra-joined device, require
app protection policy, or block).

This is the **Government (GCC High) edition** of the Conditional Access Integration solution. The
policy *concepts* are the same as Commercial, but a GCC High tenant is a **separate US sovereign
cloud** with its **own admin portals, sign-in endpoint, and Graph endpoint**, and a handful of
capabilities that lag, are limited, or are **absent** versus Commercial. Following Commercial steps
on a GCC High tenant leads you to the wrong URLs and to features that silently do not exist. This
edition gives you the correct sovereign-cloud portals and the parity gaps called out at the step
where they matter.

## How it integrates with Intune
Intune (in GCC High, the admin center is `https://intune.microsoft.us`) marks devices **Compliant**
(via device compliance policies) and applies **app protection policies** to mobile apps.
Conditional Access consumes those signals: "**require a compliant device**" means only devices
Intune has verified as healthy can reach Microsoft 365 — and "**require app protection policy**"
means only managed mobile apps can access corporate data. The **Conditional Access** node inside
the Intune admin center is the *same* node as in Microsoft Entra, so you do not need to switch
portals to build these policies. [Microsoft — Use Conditional Access with Intune compliance
policies](https://learn.microsoft.com/en-us/intune/device-security/conditional-access-integration/overview)

## How it works
1. A user attempts to sign in to a protected app (e.g. Outlook) — authentication goes to
   `https://login.microsoftonline.us` (the GCC High sign-in endpoint), **not**
   `login.microsoftonline.com`.
2. Entra evaluates the applicable CA policies against the sign-in's signals.
3. If controls are satisfied (compliant device, MFA passed), access is granted; otherwise the user
   is challenged or blocked.
4. **Report-only** mode evaluates policies and logs what *would* happen without enforcing — the
   safe way to pilot. Report-only is available in GCC High. [Microsoft — CA network
   signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network)

## The baseline policies this delivers
- **Require compliant or Entra-joined device** for Microsoft 365.
- **Require MFA** for all users.
- **Block legacy authentication** (the channel that bypasses MFA).
- **Require app protection policy** for mobile email/apps.
- **Break-glass exclusions** so emergency-access accounts are never locked out.

## Commercial vs GCC High — what's different
This is the section a Commercial-trained admin must read first. The **policy building blocks are
identical**; what changes are the **URLs, endpoints, and a few capabilities**.

| Area | Commercial | Government (GCC High) |
|---|---|---|
| Entra admin center | `entra.microsoft.com` | **`entra.microsoft.us`** |
| Azure portal (app registrations) | `portal.azure.com` | **`portal.azure.us`** |
| Intune admin center | `intune.microsoft.com` | **`intune.microsoft.us`** |
| Microsoft 365 admin | `admin.microsoft.com` | **`portal.office365.us`** |
| Defender portal | `security.microsoft.com` | **`security.microsoft.us`** |
| Purview / compliance | `compliance.microsoft.com` | **`compliance.microsoft.us` / `purview.microsoft.us`** |
| Sign-in / auth endpoint | `login.microsoftonline.com` | **`login.microsoftonline.us`** |
| Microsoft Graph endpoint | `graph.microsoft.com` | **`graph.microsoft.us`** |
| Graph PowerShell connect | `Connect-MgGraph` | **`Connect-MgGraph -Environment USGov`** |
| Conditional Access itself | ✅ | **✅ available** |
| Report-only mode | ✅ | **✅ available** |
| Named locations (IP-based) | ✅ | **✅ available** — use these instead of legacy MFA Trusted IPs |
| ID Protection risk detections (sign-in/user risk) | ✅ | **✅ available** (P2) — one exception below |
| Microsoft Entra threat intelligence risk detection | ✅ | **❌ not available** in US Gov |
| Global Secure Access (GSA) / network-based CA | ✅ (preview/GA in Commercial) | **❌ not available in GCC High** |
| CA policy PowerPoint export | ✅ | **❌ Commercial-only** (GCC High planned) |
| Delegated user management portal (My Staff) | ✅ | **❌ not available** |
| Feature rollout timing | first | **typically 2–6 weeks later** |

Sources: [Entra feature availability in Azure for US
Government](https://learn.microsoft.com/en-us/entra/identity/authentication/feature-availability) ·
[GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)
· [Global Secure Access known
limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)
· [Graph national cloud deployments](https://learn.microsoft.com/en-us/graph/deployments). Where a
specific control is not listed on a Microsoft US Gov availability page, **verify for GCC High** in
your own tenant before you design a policy that depends on it.

## Benefits
- **Enforcement** — compliance and MFA become hard requirements, not suggestions.
- **Phishing/legacy resistance** — block legacy auth and require MFA.
- **Safe rollout** — Report-only mode and break-glass accounts prevent lockouts.
- **Zero Trust** — access decisions based on real-time device and identity signals.
- **Sovereign-correct** — the right `*.us` portals and endpoints, so nothing silently mis-targets.

## Limitations (be honest with buyers)
- Conditional Access requires **Microsoft Entra ID P1** (P2 for risk-based policies); in GCC High
  this is typically delivered via **Microsoft 365 G3 / G5 (Government)**.
- "Require compliant device" depends on the **Device Compliance** solution being in place.
- Misconfigured policies *can* lock users (or admins) out — hence break-glass accounts and
  Report-only piloting.
- **Global Secure Access is not available in GCC High**, so any network/CA design that assumes GSA
  must be re-planned around IP-based named locations. [Microsoft —
  GSA limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)
- Some risk detections (e.g. **Entra threat intelligence**) are not present in US Gov — see the
  parity table and `gcc-high-parity-notes.md`.

## The standard deployment model
> **Create break-glass accounts → build policies in Report-only → review impact → enable →
> expand.** The repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
