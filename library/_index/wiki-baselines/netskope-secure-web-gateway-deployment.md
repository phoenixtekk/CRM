# Netskope Secure Web Gateway (SWG) Deployment & Web Filtering

> **Version 1.0.0** · Category: Network · Solution code: NSSWG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Netskope Secure Web Gateway (SWG) Deployment & Web Filtering

Web traffic is where most threats and most data loss start, yet many organizations still rely on
patchy filtering that remote users bypass the moment they leave the office. The result is
inconsistent policy, threats that slip in over HTTPS, and no control once a laptop is off the
corporate network.

The `Netskope Secure Web Gateway (SWG)` solves this by putting every user's web traffic behind one
cloud-delivered chokepoint: URL categorization, a web-filtering policy, threat and content controls,
and consistent enforcement whether the user is on or off the corporate network. This package stands
that gateway up the repeatable way — pilot-first and rollback-ready, because inline proxy affects
live traffic.

This is a complete, deploy-it-today package written for a competent network/security engineer with
no prior Netskope experience. The Microsoft side (identity, client and certificate delivery, and
steering scope) is given as exact navigation; the Netskope console internals are given as the correct
architectural and procedural steps with the precise control named, and deferred to Netskope's
official documentation for the exact current screen.

## What you get
- A plain-language `Solution Overview` of how a cloud SWG works: traffic steering, URL
  categorization, web-filtering policy, threat/content controls, and on/off-network enforcement.
- A `Requirements Guide` with verify / implement-if-missing for every prerequisite.
- An `Implementation Guide` of precise, ordered steps across Netskope, Entra ID, and Intune.
- Five `PowerShell scripts` for readiness discovery, client/steering validation, a web-traffic and
  policy-coverage report, safe remediation of mis-steered devices, and a steering-scope group builder.
- `Testing` and `Troubleshooting` guides with explicit pass/fail gates.

## What this delivers
A cloud secure web gateway with a named, reusable set of artifacts — a steering scope, a URL
categorization profile, a web-filtering policy, and threat/content controls — proven on a pilot group
before it is expanded fleet-wide, with a documented rollback at every stage.

## The deployment model
`Assess → Configure → Pilot → Validate → Expand`, with a pilot gate before any fleet rollout.

## Outcome
Every user's web traffic behind one cloud secure web gateway — categorized, filtered, and
consistently enforced wherever they work — proven on a pilot before you scale.


---


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


---


# 2. Requirements Guide — Netskope Secure Web Gateway (SWG)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-network.md` (a
Netskope tenant, Entra ID, Intune, admin roles, network/identity fundamentals, a pilot group, and
change control with a rollback path).

## 2.1 Netskope SWG module licensed
**Description:** The Netskope tenant has the Secure Web Gateway module (and SSL inspection) licensed.
**Why:** Web filtering, categorization, and threat controls are SWG features.
**Verify:** In the Netskope console, confirm the SWG / web policy and SSL decryption controls are
available to your admin; or run `NSSWG-Discovery.ps1` (queries tenant readiness via the REST API).
**Implement:** Engage your Netskope account team to enable the SWG and SSL inspection modules.

## 2.2 Identity-based steering ready
**Description:** Users/groups are present in Entra ID and the gateway can resolve user identity.
**Why:** Per-user/per-group web-filtering policy requires identified traffic.
**Verify:** Entra → **Users** / **Groups** show the target population; the Netskope tenant is
integrated with your identity provider (SSO / directory).
**Implement:** Sync directory to Entra ID; configure the Netskope tenant's identity integration per
Netskope's documentation (the exact integration screen is deferred to the vendor).

## 2.3 Steering-scope groups
**Description:** Entra security groups `Web Steering – Pilot – Stage 1` and
`Web Steering – Broad – Stage 2`.
**Why:** These scope who is steered into the gateway, staged pilot then broad.
**Verify:** Entra → **Groups**; both groups exist; or run `NSSWG-Validation.ps1`.
**Implement:** Create them with `NSSWG-Set-ScopeTargeting.ps1`, or Entra → **Groups → New group →
Security**.

## 2.4 Client deployment to managed devices
**Description:** The Netskope client (steering agent) deployed to target devices via Intune as
`SWG Client Deployment – Managed Devices – Production`.
**Why:** The client steers device web traffic into the gateway and applies the steering config.
**Verify:** Intune → **Apps → Windows**; the app exists and shows installs; or run
`NSSWG-Validation.ps1` (checks the client/service on the device).
**Implement:** Package the Netskope client per Netskope's deployment guidance and deploy it from
Intune (the client package and its tenant parameters are obtained from your Netskope tenant).

## 2.5 Decryption (root) certificate trusted on devices
**Description:** The Netskope SSL decryption certificate deployed via Intune as
`Decryption Certificate – Managed Devices – Production` and trusted in the device root store.
**Why:** HTTPS inspection fails (certificate errors) unless the decryption certificate is trusted.
**Verify:** On a device, the certificate is in **Trusted Root Certification Authorities**; or run
`NSSWG-Validation.ps1`.
**Implement:** Export the certificate from your Netskope tenant and deploy it as a Trusted Certificate
profile in Intune.

## 2.6 Network and egress allow the gateway
**Description:** Outbound HTTPS to the Netskope cloud is permitted; no upstream proxy strips/blocks it.
**Why:** Steered traffic must reach the gateway; an upstream proxy can break steering or double-proxy.
**Verify:** From a target device, the Netskope client connects (steering active); DNS resolves and the
internet is reachable.
**Implement:** Allow the Netskope cloud endpoints through firewall/proxy per Netskope's published
ranges; remove conflicting upstream proxy settings for steered devices.

## 2.7 SSL decryption bypass list prepared
**Description:** A list of sites/categories to **exclude** from decryption (certificate-pinned apps,
sensitive/regulated categories such as health or banking, per your policy).
**Why:** Some apps break under inspection, and some categories should not be decrypted for privacy.
**Why it matters at planning time:** decrypting everything on day one causes breakage and complaints.
**Verify:** A documented bypass list is approved before enabling decryption broadly.
**Implement:** Build the bypass list and apply it in the decryption policy (the exact control is named
in the Implementation Guide; the screen is deferred to Netskope's documentation).

## 2.8 Change control and rollback (inline traffic)
**Description:** A change window and a written rollback — remove the pilot scope from steering,
disable the filtering policy, or uninstall the client.
**Why:** Inline proxy and decryption affect live traffic; every stage must be reversible.
**Verify:** The rollback is written and approved before steering any production users (see G7).
**Implement:** Document the rollback and a user-comms plan; rehearse removing
`Web Steering – Pilot – Stage 1` from steering.

---
## Checklist
- [ ] Netskope SWG + SSL inspection licensed — `NSSWG-Discovery.ps1`
- [ ] Identity integration ready; users/groups in Entra ID
- [ ] Steering groups `Web Steering – Pilot – Stage 1` / `Web Steering – Broad – Stage 2`
- [ ] Client `SWG Client Deployment – Managed Devices – Production` deployed
- [ ] Certificate `Decryption Certificate – Managed Devices – Production` trusted
- [ ] Network/egress allows the Netskope cloud
- [ ] SSL decryption bypass list prepared and approved
- [ ] Change window + rollback approved


---


# Global Requirements — Network (category-level)

These requirements apply to **every** solution in the **Network** category (SASE/SSE, secure web
gateway, Zero Trust network access, and related network-security work — Netskope-centric). They are
published once at the category level so individual listings stay small. Confirm these before deploying
*any* Network solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

> **Vendor note:** these solutions are authored at the correct architectural and procedural level.
> Exact, current **Netskope console** screens, menu paths, and tenant-specific options change over
> time and are **deferred to the official Netskope documentation and your Netskope tenant** — follow
> the named step and confirm the precise control in your console.

## G1. A Netskope tenant
**Description:** An active, licensed Netskope tenant with admin access.
**Why:** It is the control plane for SWG, ZTNA, SSL inspection, and policy.
**Verify:** Sign in to your Netskope tenant admin console as an administrator.
**Implement:** Engage your Netskope account team / reseller to provision a tenant and the required modules.

## G2. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** Identity is the backbone for SSO, identity-based policy, and user/group steering.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G3. Endpoint management (Intune)
**Description:** Microsoft Intune (or an equivalent) able to deploy the client and certificates to endpoints.
**Why:** The Netskope client, root/decryption certificates, and steering config are delivered to managed devices.
**Verify:** `https://intune.microsoft.com` loads and target devices are enrolled and compliant.
**Implement:** Assign an Intune-bearing license plan and enroll the target devices.

## G4. Administrative roles
**Description:** Appropriate admin roles in Netskope, Entra ID, and Intune for the operator.
**Why:** Creating policies, app definitions, and deployments requires elevated rights in each plane.
**Verify:** Confirm an admin role in each console (Netskope admin; Entra/Intune admin).
**Implement:** Assign least-privilege admin roles; reserve Global Administrator for tenant-wide changes.

## G5. Network and identity fundamentals in place
**Description:** Working DNS, routing/egress, and an identity source (Entra ID / Active Directory) for users and groups.
**Why:** Traffic steering, SSL inspection, and identity-based policy depend on resolvable, routable, identified traffic.
**Verify:** Endpoints resolve DNS and reach the internet; users/groups are present in Entra ID.
**Implement:** Remediate DNS/egress; sync Active Directory to Entra ID if hybrid.

## G6. A pilot group
**Description:** A Microsoft Entra security group of pilot users/devices for staged rollout.
**Why:** Every solution is piloted before fleet rollout to validate steering, policy, and performance.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group → Security** → add members.

## G7. Change control and a rollback path
**Description:** A change window and a documented rollback (disable steering / remove client / revert policy).
**Why:** Inline proxy, decryption, and ZTNA changes affect live traffic and must be reversible.
**Verify:** A rollback procedure is written and approved before enabling inline enforcement.
**Implement:** Define the rollback (e.g. steering exception, client uninstall, policy disable) and a comms plan.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Netskope Secure Web Gateway (SWG)

Follow these steps **in order**. Microsoft-side steps give exact navigation in the Microsoft Entra
admin center (`https://entra.microsoft.com`) and the Microsoft Intune admin center
(`https://intune.microsoft.com`). Netskope-side steps name the exact control to configure but defer
the precise current console screen to Netskope's official documentation — find the named control in
your tenant.

> **Model:** Configure categorization, filtering, and threat/content policy first; steer only the
> `Web Steering – Pilot – Stage 1` scope; validate enforcement and user experience; then expand the
> steering scope to `Web Steering – Broad – Stage 2`. The gateway is inline — never steer production
> users before the pilot gate passes.
>
> **Rollback at any stage:** remove the affected scope group from steering, or disable the
> `Web Filtering Policy – All Users – Production` policy, or uninstall the client — restoring
> direct-to-internet traffic.

## Step 1 — Confirm tenant and identity
1. Sign in to the Netskope console as an administrator and confirm the SWG and SSL inspection modules
   are available (the named area is the web/SWG policy and the SSL decryption policy).
2. Confirm the tenant's identity integration resolves users (SSO / directory). The exact integration
   screen is deferred to Netskope's documentation; verify by confirming a test user is identified.
3. Run `NSSWG-Discovery.ps1` to record tenant readiness before changing anything.

## Step 2 — Create the steering-scope groups (Entra)
1. Entra → **Groups → New group** → **Group type: Security** → **Name:** `Web Steering – Pilot – Stage 1`
   → add a few representative pilot devices/users → **Create**.
2. Repeat for `Web Steering – Broad – Stage 2` (the rest of the fleet) → **Create**.
   (You can create both with `NSSWG-Set-ScopeTargeting.ps1`.)

## Step 3 — Deploy the decryption certificate (Intune)
1. Export the Netskope SSL decryption (root) certificate from your tenant (the certificate-download
   control; screen deferred to Netskope's documentation).
2. Intune → **Devices → Configuration → Create → New policy** → **Platform: Windows 10 and later** →
   **Profile type: Templates → Trusted certificate** → **Create**.
3. **Name:** `Decryption Certificate – Managed Devices – Production`. Upload the certificate;
   **Destination store: Computer certificate store – Root**. **Next**.
4. **Assignments → Add groups →** `Web Steering – Pilot – Stage 1`. **Next → Create**.

## Step 4 — Deploy the Netskope client (Intune)
1. Obtain the Netskope client package and its tenant enrollment parameters from your Netskope tenant
   (the client-download/parameters control; screen deferred to Netskope's documentation).
2. Intune → **Apps → Windows → Add** → choose the appropriate Windows app type for the package →
   upload the package and set the install/enrollment parameters.
3. **Name:** `SWG Client Deployment – Managed Devices – Production`.
4. **Assignments → Required → Add groups →** `Web Steering – Pilot – Stage 1`. **Create.**

## Step 5 — Build the URL categorization profile (Netskope)
1. In the Netskope console, create a URL categorization profile named
   `URL Categorization Profile – Standard – Production`.
2. Select the categories your `Web Filtering Policy` will reference — at minimum a block set
   (malware, phishing, command-and-control, and other security categories) and any
   acceptable-use categories (for example gambling, adult, illegal) per your policy.
3. The exact categorization screen is deferred to Netskope's documentation; the control to find is the
   URL category list / custom categories used by web policy.

## Step 6 — Configure SSL decryption with the bypass list (Netskope)
1. In the SSL decryption policy, enable decryption for steered traffic so HTTPS can be inspected.
2. Apply the **decryption bypass list** prepared in Requirement 2.7 (certificate-pinned apps and
   sensitive/regulated categories) so those flows are **not** decrypted.
3. The control to find is the SSL decryption (inspection) policy and its bypass/exception list; the
   screen is deferred to Netskope's documentation.

## Step 7 — Create the threat and content control (Netskope)
1. Create a threat/content control named `Threat & Content Control – All Users – Production` that
   blocks threat-classified destinations and risky file types for steered traffic.
2. The control to find is the threat-protection / file-type policy applied to web traffic; the screen
   is deferred to Netskope's documentation.

## Step 8 — Create the web-filtering policy (Netskope)
1. Create a web-filtering policy named `Web Filtering Policy – All Users – Production` that references
   `URL Categorization Profile – Standard – Production`.
2. Define rule actions: **block** the security/unacceptable categories, **coach** (warn) any
   borderline categories per your policy, and **allow** the rest.
3. Scope the policy to the steered users (identity-based). Order the rules so block rules precede
   allow rules. The control to find is the real-time/web protection policy; the screen is deferred to
   Netskope's documentation.

## Step 9 — Steer the pilot scope
1. In the Netskope steering configuration, add `Web Steering – Pilot – Stage 1` to the active steering
   scope so only pilot devices are steered into the gateway. The control to find is the steering
   configuration / user-group scope; the screen is deferred to Netskope's documentation.
2. On a pilot device, confirm the client shows steering active and the decryption certificate is
   trusted; run `NSSWG-Validation.ps1`.

## Step 10 — Validate the pilot (gate)
1. Run `NSSWG-Validation.ps1` on pilot devices → client running, steering active, certificate trusted.
2. Run `NSSWG-Report.ps1` → confirms pilot web activity is flowing through the gateway and policy
   coverage (which steering groups exist and are scoped).
3. Browse known-category test sites from a pilot device and confirm block/coach/allow behavior matches
   `Web Filtering Policy – All Users – Production`. Complete the Testing Guide.
4. **Pilot gate:** do not proceed until the pilot passes and no user-impacting breakage remains.

## Step 11 — Expand the steering scope
1. Add `Web Steering – Broad – Stage 2` to the active steering scope in Netskope.
2. Add `Web Steering – Broad – Stage 2` to the **Assignments** of
   `SWG Client Deployment – Managed Devices – Production` and
   `Decryption Certificate – Managed Devices – Production` in Intune so broad devices receive the
   client and certificate.
3. Re-validate with `NSSWG-Report.ps1`; remediate any mis-steered or non-compliant devices with
   `NSSWG-Remediation.ps1` (default `-WhatIf`).

---
### Order of operations
`Confirm tenant + identity → steering groups → certificate → client → categorization profile →
SSL decryption + bypass → threat/content control → web-filtering policy → steer pilot → validate
(gate) → expand`


---


# 5. Testing Guide — Netskope Secure Web Gateway (SWG)

Run after the pilot scope is steered (Implementation Step 10) and again after expanding to broad.

## Test 1 — Client deployed and steering active
**Do:** On a pilot device run `NSSWG-Validation.ps1` (checks the client/service and steering state).
**Expected:** The Netskope client is installed and running and steering is active.

## Test 2 — Decryption certificate trusted
**Do:** `NSSWG-Validation.ps1`, or check **Trusted Root Certification Authorities** on the device.
**Expected:** `Decryption Certificate – Managed Devices – Production` is present and trusted; HTTPS
sites load without certificate errors through the gateway.

## Test 3 — Categorization and block action
**Do:** From a pilot device, browse a site in a category you set to **block** in
`Web Filtering Policy – All Users – Production` (use a known test category, not a live malicious site).
**Expected:** The request is blocked and the gateway block/notification page is shown.

## Test 4 — Coach (warn) action
**Do:** Browse a site in a category set to **coach**.
**Expected:** The user sees the coaching/warning page and can proceed per policy.

## Test 5 — Allowed traffic flows normally
**Do:** Browse normal business sites in allowed categories.
**Expected:** Sites load normally; the activity appears in the tenant's web logs.

## Test 6 — Decryption bypass honored
**Do:** Open an app/site on the decryption bypass list (certificate-pinned or sensitive category).
**Expected:** The flow works without inspection errors (not decrypted).

## Test 7 — On/off-network consistency
**Do:** Repeat Tests 3 and 5 with the device off the corporate network (e.g. on a home/hotspot link).
**Expected:** The same block/allow behavior applies off-network as on-network.

## Test 8 — Coverage and activity report
**Do:** Run `NSSWG-Report.ps1`.
**Expected:** Steered scope groups are listed and pilot web activity (per-category counts) is present,
confirming traffic is flowing through the gateway.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–7 pass on `Web Steering – Pilot – Stage 1`; no user-impacting breakage; rollback rehearsed |
| **Broad pass** | Tests 1–3, 5, 8 pass for `Web Steering – Broad – Stage 2` after expansion |


---


# 6. Troubleshooting Guide — Netskope Secure Web Gateway (SWG)

Use `NSSWG-Validation.ps1` for device state, `NSSWG-Discovery.ps1` for readiness,
`NSSWG-Report.ps1` for coverage/activity, and `NSSWG-Remediation.ps1` (default `-WhatIf`) for safe
fixes. The exact Netskope console screens referenced below are deferred to Netskope's documentation;
the named control is given so you can find it in your tenant.

## A. Device not steered / traffic bypassing the gateway
| Symptom | Cause | Remediation |
|---|---|---|
| Web activity not appearing in the tenant for a device | Client not installed, or device not in a steered scope | Run `NSSWG-Validation.ps1`; if not steered, add the device to `Web Steering – Pilot – Stage 1` / `Web Steering – Broad – Stage 2` and re-sync with `NSSWG-Remediation.ps1` |
| Client installed but steering inactive | Client not enrolled to the tenant, or upstream proxy interfering | Re-deploy `SWG Client Deployment – Managed Devices – Production`; remove conflicting upstream proxy for steered devices |
| Steering active on-network only | Steering scope/config not applied off-network | Confirm the steering configuration covers off-network in the Netskope steering control |

## B. HTTPS certificate errors
- Browsers show certificate warnings on inspected sites → the decryption certificate is not trusted.
  Confirm `Decryption Certificate – Managed Devices – Production` is in **Trusted Root Certification
  Authorities** (run `NSSWG-Validation.ps1`); re-deploy the Intune trusted-certificate profile.

## C. An app breaks under inspection
- A certificate-pinned app fails only when steered/decrypted → add it to the **SSL decryption bypass
  list** (the SSL decryption policy's exception control) so the flow is not inspected. Re-test.

## D. Wrong block / site miscategorized
| Symptom | Cause | Remediation |
|---|---|---|
| A legitimate site is blocked | Category set to block, or site miscategorized | Confirm the category in `URL Categorization Profile – Standard – Production`; submit a category-correction request and add a documented allow exception in `Web Filtering Policy – All Users – Production` |
| A site that should be blocked is allowed | Rule order or missing category | Reorder so block rules precede allow rules; add the category to the block set |

## E. Coaching/notification page not shown
- A coached category just blocks or allows with no page → confirm the rule action is **coach** (not
  block/allow) and that the gateway notification template is enabled for that action.

## F. Off-network policy inconsistent with on-network
- Off-network users get different behavior → confirm the same `Web Filtering Policy – All Users –
  Production` and steering scope apply regardless of network; identity-based (not IP-based) policy
  follows the user.

## G. Diagnostics quick reference (device side)
```powershell
Get-Service | Where-Object { $_.Name -like '*stagent*' -or $_.DisplayName -like '*Netskope*' }   # client service
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like '*Netskope*' }            # decryption cert trusted
Resolve-DnsName www.example.com                                                                    # DNS works
```
Use `NSSWG-Validation.ps1` for a single pass/fail summary of the above.

## H. When to escalate
If the device shows the client running, steering active, and the certificate trusted, but traffic is
still not filtered as expected, collect the client logs and the policy/steering configuration and open
a Netskope support case (Netskope tenant-side policy evaluation is outside device-level remediation).


---


# 7. Best Practices — Netskope Secure Web Gateway (SWG)

- **Pilot first, always.** The gateway is inline — a small `Web Steering – Pilot – Stage 1` scope
  catches wrong blocks and decryption-compatibility problems before they hit the fleet. This is the
  single most important practice.
- **Rehearse the rollback before you steer.** Know exactly how to remove a scope group from steering,
  disable `Web Filtering Policy – All Users – Production`, or uninstall the client — and time it.
- **Start decryption with a bypass list.** Never decrypt everything on day one. Bypass
  certificate-pinned apps and sensitive/regulated categories (health, banking) to avoid breakage and
  privacy issues.
- **Block the security categories, coach the borderline ones.** Block malware, phishing, and
  command-and-control outright; use coach (warn) for acceptable-use grey areas so users self-correct.
- **Deploy the certificate before (or with) the client.** HTTPS inspection throws certificate errors
  if `Decryption Certificate – Managed Devices – Production` is not trusted first.
- **Keep policy identity-based.** Scope `Web Filtering Policy – All Users – Production` to users/groups,
  not IP ranges, so it follows the user on and off network.
- **Order rules deliberately.** Put block rules before allow rules so a broad allow can't shadow a
  security block.
- **Watch coverage.** Run `NSSWG-Report.ps1` to confirm steered scope and per-category activity, and
  to catch devices that should be steered but are not.
- **Handle miscategorization quickly.** Maintain a process for category-correction requests and
  documented allow/block exceptions so user trust holds.
- **Communicate to users.** A short note about the block/coach pages and who to contact dramatically
  reduces tickets at rollout.
- **Document the artifacts.** Record the names and intent of the steering scope, categorization
  profile, filtering policy, and threat/content control for audits and repeatability.


---


# 8. Deliverables Summary — Netskope Secure Web Gateway (SWG)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What an SWG is, steering, categorization, filtering, threat/content, on/off-network model, named artifacts, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Network) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps across Netskope, Entra, and Intune |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `NSSWG-Discovery.ps1` | Records SWG readiness: Entra steering groups, Intune client/cert deployment, and (optional) Netskope tenant readiness via REST. Read-only |
| `NSSWG-Validation.ps1` | On a device, confirms the Netskope client is running, steering is active, and the decryption certificate is trusted. Read-only |
| `NSSWG-Report.ps1` | Reports steering-scope coverage (Graph) and, optionally, per-category web activity from the Netskope REST API. Read-only |
| `NSSWG-Remediation.ps1` | Safely fixes mis-steered/non-compliant devices (re-sync, re-add to steering scope). Default `-WhatIf` |
| `NSSWG-Set-ScopeTargeting.ps1` | Creates/populates the `Web Steering – Pilot – Stage 1` and `Web Steering – Broad – Stage 2` groups (Graph) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Every user's web traffic behind one cloud secure web gateway — categorized, filtered, and consistently
enforced on or off network — proven on a pilot before it scales, with a documented rollback at every
stage.
