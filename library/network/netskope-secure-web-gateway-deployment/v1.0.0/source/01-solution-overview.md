# 1. Solution Overview — Netskope Secure Web Gateway (SWG)

## What a Secure Web Gateway is
A Secure Web Gateway (SWG) is a cloud-delivered inline proxy that sits between your users and the
web. Every web request is steered to the gateway, where it is identified (which user/group), decrypted
(for HTTPS inspection), categorized (what kind of site), and evaluated against a web-filtering policy
before it is allowed, blocked, or coached. The Netskope SWG provides this as part of a SASE/SSE
platform, so the same policy follows the user on or off the corporate network.

## How it works
1. Traffic is **steered** into the Netskope cloud. On managed devices this is done by the Netskope
   client (steering config from your tenant); on networks it can be done by a forward proxy or
   tunnel. This solution uses **client-based steering** delivered to managed devices.
2. The gateway **identifies the user** via the identity tied to the client enrollment / SSO, so
   policy can be written per user and per group.
3. For HTTPS sites, the gateway performs **SSL/TLS decryption** (inspection) so it can categorize and
   filter encrypted traffic. A decryption (root) certificate must be trusted on the device.
4. The request URL is matched to a **URL category** (for example, malware, phishing, gambling,
   social media, productivity) using the gateway's categorization engine.
5. A **web-filtering policy** evaluates the category, the user/group, and threat/content signals, then
   **allows, blocks, or coaches** (warns the user) the request.
6. Activity is logged in the tenant, giving you per-user, per-category web visibility and the data the
   reporting script summarizes.

## What you can control
- **URL categorization** — which categories exist and how sites are classified (a categorization
  profile that the filtering policy references).
- **Web-filtering policy** — allow / block / coach by category, user, and group; the order of rules.
- **Threat and content controls** — block known-malicious categories, risky file types, and
  threat-classified destinations.
- **SSL/TLS decryption scope** — which traffic is inspected vs. bypassed (for privacy/compatibility).
- **Steering scope** — which users/devices are steered into the gateway, staged from pilot to fleet.

## The named artifacts this solution creates
Use these names verbatim across the console, the scripts, and your change records:

| Artifact | Name | Where |
|---|---|---|
| Entra steering scope (pilot) | `Web Steering – Pilot – Stage 1` | Entra group |
| Entra steering scope (broad) | `Web Steering – Broad – Stage 2` | Entra group |
| Client deployment (app) | `SWG Client Deployment – Managed Devices – Production` | Intune app |
| Decryption certificate profile | `Decryption Certificate – Managed Devices – Production` | Intune cert profile |
| URL categorization profile | `URL Categorization Profile – Standard – Production` | Netskope |
| Web-filtering policy | `Web Filtering Policy – All Users – Production` | Netskope |
| Threat/content control | `Threat & Content Control – All Users – Production` | Netskope |

## Benefits
- **One chokepoint** — every user's web traffic is categorized and filtered in one place.
- **Consistent on/off network** — the same policy applies wherever the user works.
- **Threat reduction** — known-malicious categories and risky content are blocked inline.
- **Visibility** — per-user, per-category web activity for reporting and investigation.
- **Repeatable** — assign the steering scope once, expand everywhere, with a pilot gate.

## Limitations (be honest with buyers)
- An SWG is an **inline proxy**: it sits in the live traffic path, so changes affect users in real
  time and must be piloted and reversible.
- **HTTPS inspection requires a trusted decryption certificate** on the device; sites with
  certificate pinning may need decryption bypass.
- Categorization is **best-effort**; miscategorized sites need exception handling.
- The SWG controls **web (and, depending on licensing, cloud-app) traffic** — it is not a full
  firewall replacement for all protocols.

## Why pilot-first
Because the gateway is inline, a wrong block or a decryption-compatibility problem hits real users
immediately. Steering a small `Web Steering – Pilot – Stage 1` group first lets you validate
enforcement, user experience, and the rollback before any of the fleet is affected.

## The standard deployment model
> **Confirm tenant + identity → configure categorization, filtering, and threat/content policy →
> steer the pilot scope → validate enforcement and user experience → expand the steering scope
> fleet-wide.** Model: **Assess → Configure → Pilot → Validate → Expand.**
