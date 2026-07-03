# Executive Summary — Conditional Access Integration (Government / GCC High)

**White-label · Intune Solutions · US Sovereign Cloud (GCC High)**

Device compliance and MFA only protect you if access is actually *gated* on them. **Conditional
Access** is the enforcement engine: it evaluates every sign-in against your rules — is the device
compliant? has the user passed MFA? is this legacy authentication? — and allows, challenges, or
blocks accordingly. Integrated with Microsoft Intune, it turns device compliance into a hard access
requirement.

This is the **Government (GCC High) edition**. A GCC High tenant is a **separate US sovereign cloud**
— it uses different admin portals (`entra.microsoft.us`, `portal.azure.us`, `intune.microsoft.us`,
`security.microsoft.us`), a different sign-in endpoint (`login.microsoftonline.us`), and a different
Microsoft Graph endpoint (`graph.microsoft.us`, reached in PowerShell with
`Connect-MgGraph -Environment USGov`). Some capabilities also lag, are limited, or are **absent**
versus Commercial. Running Commercial steps on a GCC High tenant sends you to the wrong URLs and to
features that silently do not exist. This package delivers Conditional Access for the sovereign
cloud with the **correct portals and endpoints** and the **Commercial-vs-GCC-High parity gaps called
out** at the step where they matter.

## What you get
- A plain-language **Solution Overview** of how Conditional Access evaluates and enforces sign-ins,
  including an explicit **Commercial vs GCC High — what's different** section.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite, on the `*.us`
  endpoints.
- An **Implementation Guide** of precise, click-by-click steps in the required order — on the GCC
  High portals, Report-only first, with parity caveats inline.
- Five **PowerShell scripts** (discovery, validation, reporting, safe remediation, and scope
  targeting) — all connecting to **US Gov Graph** (`-Environment USGov`).
- A **GCC High Parity Notes** reference plus **Testing** and **Troubleshooting** guides for
  confident, lockout-free rollout.

## What this delivers
A baseline Conditional Access posture on GCC High: **require a compliant (or Entra-joined) device**
for Microsoft 365, **require MFA**, **block legacy authentication**, and (for mobile) **require app
protection** — all piloted in Report-only mode before enforcement, with break-glass accounts
excluded, and with GCC-High-specific gaps (e.g. **Global Secure Access is not available**; use
IP-based named locations) handled up front.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero Trust access enforcement deployed **correctly on GCC High** — right portals, right endpoints,
parity gaps handled — that only admits healthy, authenticated devices and users, without locking
anyone out.
