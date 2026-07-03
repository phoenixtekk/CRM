# Executive Summary — Windows 365 Cloud PC Deployment & Management, Government / GCC High (Microsoft Intune)

Government agencies, public entities, and cleared contractors need a corporate Windows desktop that
lives in a US sovereign cloud — but standing up Windows 365 on a **GCC High** tenant is *not* the
Commercial process with a different sign-in. The sovereign admin and end-user URLs differ, and several
Windows 365 and Intune capabilities lag, are limited, or are absent versus Commercial. Deploy with
Commercial steps and it silently fails: empty-looking portals, unavailable options, and features you
designed around that don't exist in GCC High.

This is a complete, **deploy-it-today** package for standing up **Windows 365 Enterprise (Government)
Cloud PCs** on a **GCC High** tenant with the **government Microsoft Intune** instance, written for an
administrator with no prior Cloud PC or sovereign-cloud experience. It turns a pile of one-off Cloud
PCs into a repeatable, governed deployment on the correct `.us` portals — provisioning policies that
build desktops by group membership, a network connection you understand, a hardened image, and Intune
configuration, compliance, and security applied to Cloud PCs exactly as they are to laptops — with
every **Commercial-vs-GCC-High** difference called out so the government tenant is configured
correctly.

## What you get
- A plain-language **Solution Overview** of Windows 365 Enterprise (Government) — the
  provisioning-policy model, Azure (Government) Network Connection vs. the Microsoft-hosted network,
  gallery vs. custom images, Intune management — **plus an explicit "Commercial vs GCC High — what's
  different" section**.
- A **GCC High Parity Notes** reference: the full Commercial→`.us` portal/endpoint map and every
  cited Windows 365 / Intune feature-parity gap, with anything unconfirmed flagged "verify for GCC
  High."
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite (GCC High tenant,
  Government licensing including G3/G5, roles, sovereign portal access, `.us` endpoints through
  filtering).
- An **Implementation Guide** of precise, click-by-click steps in the required order using the **`.us`
  government portals**, with GCC-High-only caveats inline at the step where they matter.
- Five **PowerShell scripts** — discovery, validation, reporting, safe remediation, and a targeting
  group builder — all connecting to **Microsoft Graph US Gov** endpoints (`-Environment USGov`).
- **Testing** and **Troubleshooting** guides with pass/fail gates and GCC-High-specific gotchas.

## What this delivers
A **policy-driven Cloud PC service on GCC High**: a named provisioning policy that builds a dedicated
Windows desktop for every member of a target group, on a network of your choosing, from a known image,
secured by Conditional Access and managed by the same government Intune compliance and configuration
profiles as your physical endpoints — hosted in US government data centers and proven on a pilot
before you scale.

## The deployment model
**Assess → Configure → Pilot → Validate → Expand** — with a pilot gate before production.

## Outcome
Every eligible user with a dedicated, always-on Windows Cloud PC in the US sovereign cloud —
provisioned by policy, reached via `windows365.microsoft.us`, secured and managed in the government
Intune instance alongside physical devices — deployable by a single administrator, with the Commercial
pitfalls and GCC High parity gaps handled, and validated before fleet rollout.
