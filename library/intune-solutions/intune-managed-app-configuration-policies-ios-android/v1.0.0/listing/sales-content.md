# Sales Content — Intune Managed App Configuration Policies (iOS & Android)

## Hook
**Stop making users set up their own apps.** Every line-of-business app that asks a user to type a
server hostname, a tenant/realm, an environment, and an account is a help-desk ticket waiting to
happen — and a sign-in that never cleanly reaches your identity provider. Intune **App Configuration
Policies** push the app's own settings *to the app*, so it opens **already configured** and lands on
your **Microsoft Entra ID** sign-in, covered by Conditional Access.

## Run it yourself — simpler, cheaper, and proven
- **Simpler** — exact ordered steps with full navigation paths; every policy, profile, and group is
  named and reused through testing and troubleshooting.
- **Cheaper** — one fixed price vs an open meter; comparable consulting runs ~$1,500–$3,000/day.
  Reusable across unlimited apps and devices.
- **Tested** — pilot-first (Assess → Configure → Pilot → Validate → Expand) with pass/fail gates,
  centered on: a device opens the app pre-configured and routes to the Entra ID / Conditional Access
  sign-in.

## What's inside
- **Solution Overview** — two delivery channels (managed devices vs managed apps), enrolled-vs-MAM
  distinction, authoring key/value pairs (iOS **plist**, Android **managed-configuration schema**,
  configuration-designer vs enter-XML), SSO routing, coexistence with app protection and supersedence.
- **Requirements** — each prerequisite with Verify/Implement (Intune + Entra P1, APNs, managed Google
  Play, target app by exact publisher + bundle/package ID, the vendor's supported keys, Entra SSO
  plumbing, US Government endpoints).
- **Implementation** — build the policy for **iOS/iPadOS AND Android**, plus the full **SAP Ariba
  Procurement** worked example: pre-fill site/realm/environment/role and route sign-in to Entra ID —
  click-by-click, every object named.
- **5 PowerShell scripts** — Preflight, export policies+assignments, validate delivery, coverage
  report, guarded remediation (read-only / -WhatIf by default, cloud-aware Commercial + US Gov).
- **Templates** — sample iOS plist + Android managed-config JSON (generic + Ariba placeholder), vendor
  keys clearly flagged for confirmation.
- **Testing + Troubleshooting + Best Practices** — plist errors, key typos, "config not applying,"
  MAM-vs-MDM confusion, SSO-routing failures, supersedence.

## The bottom line
Apps that set themselves up correctly on first launch — host, realm, environment, and role pre-filled
— and route every sign-in to Microsoft Entra ID so Conditional Access can enforce access, proven on a
pilot device before you expand. Buy once, reuse across unlimited apps and devices.

## Pricing
| Tier | Price | SKU |
|---|---|---|
| Commercial | $2,295.00 | `PTK-APPCFG-COMM-001` |
| Non-Profit (40% off) | $1,377.00 | `PTK-APPCFG-NPO-001` |
| Government (15% off) | $1,950.75 | `PTK-APPCFG-GOV-001` |

## Accuracy note (internal)
SAP Ariba configuration **key names** are shown as clearly-labeled **placeholders** flagged "verify
against SAP Ariba documentation" (authoritative source: SAP Ariba Procurement Mobile App Guide →
"Configuring SAP Ariba Procurement mobile app in Mobile Device Management Tool"). Confirmed facts
used: Ariba is **not** MDM-certified on Android (iOS generic MDM only); realm = buyer subdomain. The
build/assign/validate mechanics are correct regardless of the exact keys.
