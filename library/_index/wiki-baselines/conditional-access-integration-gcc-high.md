# Conditional Access Integration — Government (GCC High)

> **Version 1.0.0** · Category: Intune · Solution code: CAIG

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


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


---


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


---


# 2. Requirements Guide — Conditional Access Integration (Government / GCC High)

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

> **Government note:** all portal/verify URLs below are the **US sovereign cloud** (`*.us`)
> endpoints. If a step sends you to a `*.com` portal, you are on the wrong cloud for a GCC High
> tenant.

## 2.1 GCC High tenant (separate US sovereign cloud)
**Description:** An active Microsoft 365 / Entra **GCC High** tenant (`*.onmicrosoft.us`).
**Why:** GCC High is a distinct sovereign cloud; it is not your Commercial or GCC tenant with a
different sign-in. Portals, endpoints, and some features differ.
**Verify:** Sign in to **`https://entra.microsoft.us`** as an administrator; the tenant domain ends
in `.onmicrosoft.us`.
**Implement:** Provision a GCC High tenant through an authorized government/agreement path (this is
a separate tenant from any Commercial/GCC tenant you hold). [Microsoft — GCC High
endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 2.2 Government licensing (Entra ID P1 / P2)
**Description:** Microsoft Entra ID **P1** (or **P2** for risk-based policies), typically via
**Microsoft 365 G3 / G5 (Government)**.
**Why:** Conditional Access is a P1 feature; sign-in/user-risk conditions need P2.
**Verify:** M365 admin center **`https://portal.office365.us`** → **Billing → Licenses** — confirm a
Government plan carrying Entra ID P1/P2.
**Implement:** Assign M365 G3/G5 (Government) or standalone Entra ID P1/P2 (Gov) to targeted users.

## 2.3 Break-glass (emergency access) accounts
**Description:** Two cloud-only Global Administrator accounts excluded from all CA policies.
**Why:** They guarantee you can always sign in if a CA policy misfires — the #1 lockout safeguard.
**Verify:** `https://entra.microsoft.us` → **Users** — two dedicated emergency accounts exist; run
**`CAIG-Validation.ps1`** (which includes a break-glass exclusion check).
**Implement:** Create two cloud-only `.onmicrosoft.us` Global Admins with long random passwords
stored offline; exclude them from every CA policy.

## 2.4 Administrative roles (sovereign portal access)
**Description:** Conditional Access Administrator (or Security Administrator) plus the ability to
open the `*.us` portals.
**Why:** Creating/editing CA policies requires the right role; the operator must also be able to
reach the sovereign portals through any filtering.
**Verify:** `https://entra.microsoft.us` → **Roles and administrators**; confirm **Conditional
Access Administrator** (and **Reports Reader / Security Reader** for log review).
**Implement:** Assign **Conditional Access Administrator**; reserve Global Administrator for
break-glass and tenant-wide changes.

## 2.5 Device compliance (for "require compliant device")
**Description:** Intune device compliance policies in place in the GCC High tenant.
**Why:** The "require compliant device" control needs Intune to be marking devices Compliant.
**Verify:** Intune **`https://intune.microsoft.us`** → **Devices → Compliance**; devices report
Compliant.
**Implement:** Deploy the **Device Compliance Policies (GCC High)** solution first.

## 2.6 MFA registration
**Description:** Users are able to register MFA methods.
**Why:** "Require MFA" challenges users; they must have a method registered.
**Verify:** `https://entra.microsoft.us` → **Protection → Authentication methods**.
**Implement:** Enable authentication methods and (optionally) the registration campaign or SSPR.
Confirm each method is available in GCC High before relying on it.

## 2.7 Sign-in logs / reporting
**Description:** Access to Entra sign-in logs in the GCC High tenant.
**Why:** Report-only impact is reviewed in the sign-in logs before enforcing.
**Verify:** `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs** loads.
**Implement:** Ensure the operator has **Reports Reader** / **Security Reader**.

## 2.8 App protection (optional — mobile)
**Description:** Intune app protection policies for mobile apps.
**Why:** The "require app protection policy" control needs them defined.
**Verify:** Intune `https://intune.microsoft.us` → **Apps → App protection policies**.
**Implement:** Create app protection policies for iOS/Android (optional companion work; deploy the
**MAM App Protection (GCC High)** solution).

## 2.9 Network access to US Gov endpoints
**Description:** Outbound HTTPS to the GCC High service/admin endpoints through any proxy/firewall.
**Why:** Blocking `.us` domains breaks authentication, Graph, and the admin portals for a GCC High
tenant.
**Verify:** From an admin workstation, reach **`login.microsoftonline.us`**, **`graph.microsoft.us`**,
`entra.microsoft.us`, `intune.microsoft.us`, and `security.microsoft.us`.
**Implement:** Allow the published **GCC High URL & IP ranges** through filtering. [Microsoft —
GCC High endpoints](https://learn.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-u-s-government-gcc-high-endpoints)

## 2.10 Microsoft Graph PowerShell (US Gov) for the scripts
**Description:** Microsoft Graph PowerShell SDK, connected with **`-Environment USGov`**.
**Why:** The reporting/validation scripts must target `graph.microsoft.us`, not the Commercial
endpoint. A missing `-Environment USGov` connects to the wrong cloud and returns nothing (or errors).
**Verify:** `Get-MgEnvironment` lists **USGov** (Graph `https://graph.microsoft.us`); run
**`CAIG-Discovery.ps1`**.
**Implement:** `Install-Module Microsoft.Graph -Scope CurrentUser`, then always
`Connect-MgGraph -Environment USGov -Scopes '<scopes>'`. [Microsoft — Graph national cloud
deployments](https://learn.microsoft.com/en-us/graph/deployments)

---
## Checklist
- [ ] **GCC High tenant** (`.onmicrosoft.us`) — `entra.microsoft.us` loads
- [ ] Government Entra ID P1/P2 licensing (M365 G3/G5) assigned
- [ ] **Two break-glass admins created and excluded** — `CAIG-Validation.ps1`
- [ ] Conditional Access Administrator role held; sovereign portals reachable
- [ ] Device compliance policies in place (GCC High)
- [ ] MFA methods enabled / users can register
- [ ] Sign-in log access for review
- [ ] `.us` endpoints allowed through filtering
- [ ] Graph PowerShell connects with **`-Environment USGov`** — `CAIG-Discovery.ps1`
- [ ] Pilot Entra group created (`CA-Pilot-Gov`)


---


# Global Requirements — Intune Solutions (category-level)

These requirements apply to **every** solution in the **Intune Solutions**
category. They are published once at the category level so individual listings stay small.
Confirm these before deploying *any* Intune solution. Each entry: **Description · Why · Verify · Implement-if-missing.**

## G1. Microsoft Entra ID tenant
**Description:** An active Microsoft Entra ID (Azure AD) tenant.
**Why:** It is the identity backbone for every cloud and Intune-managed resource.
**Verify:** Sign in to `https://entra.microsoft.com` as an administrator.
**Implement:** Create a Microsoft 365/Azure subscription, which provisions a tenant.

## G2. Microsoft Intune subscription
**Description:** An Intune-bearing license plan.
**Why:** Intune delivers all configuration, compliance, and security policies.
**Verify:** `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
**Implement:** Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
**Description:** Appropriate Entra/Intune admin roles for the operator.
**Why:** Creating policies and enrollment settings requires elevated rights.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator**.
**Implement:** Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
**Description:** Targeted Windows devices are enrolled and manageable.
**Why:** Policies only reach enrolled devices.
**Verify:** Intune → **Devices → All devices**; the device appears and is **compliant**.
**Implement:** Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
**Description:** A Microsoft Entra security group for pilot/targeted users or devices.
**Why:** Every solution is piloted before fleet rollout.
**Verify:** Entra → **Groups**; the pilot group exists.
**Implement:** Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
**Description:** Windows 10 21H2+ or Windows 11 with current updates.
**Why:** Modern Intune features assume a patched, supported OS.
**Verify:** `winver`, or Intune → device → **Hardware**.
**Implement:** Deploy **Update rings** or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
**Description:** Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
**Why:** Enrollment, policy sync, and authentication depend on these endpoints.
**Verify:** From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
**Implement:** Allow Microsoft's published Office 365/Intune URL & IP ranges through proxy/firewall.

---
**The standard deployment model (all solutions):** **Assess → Configure → Pilot → Validate → Expand.**


---


# 3. Implementation Guide — Conditional Access Integration (Government / GCC High)

Follow these steps **in order**. In GCC High, Conditional Access is in **Microsoft Entra**
(**`https://entra.microsoft.us`** → **Protection → Conditional Access**). The **same** CA node also
appears in the Intune admin center (`https://intune.microsoft.us` → **Endpoint security →
Conditional access**) — either portal builds the same policies. **Always start in Report-only.**

> **Government caveat (read first):** every portal below is a **`*.us`** sovereign-cloud URL. If a
> link opens `entra.microsoft.com`, `portal.azure.com`, or `login.microsoftonline.com`, stop — you
> are on the Commercial cloud, and changes there do **not** affect your GCC High tenant.

> **Model:** Break-glass first → policies in Report-only → review → enable → expand.

## Step 1 — Create and exclude break-glass accounts
1. `https://entra.microsoft.us` → **Users → New user → Create new user**. Create two cloud-only
   accounts, e.g. `breakglass1@<yourtenant>.onmicrosoft.us` and
   `breakglass2@<yourtenant>.onmicrosoft.us` (use your real tenant — the domain ends in
   **`.onmicrosoft.us`**, not `.onmicrosoft.com`).
2. Assign both the **Global Administrator** role; set long random passwords and store them offline.
3. You will **exclude these two accounts from every CA policy** in the steps below.

## Step 2 — Create the pilot group
1. `https://entra.microsoft.us` → **Groups → New group** → **Security** → name it
   **`CA-Pilot-Gov`** → add your pilot users. **Create**.

## Step 3 — (If replacing legacy MFA Trusted IPs) create IP-based named locations
> **GCC High caveat:** design location policies on **named locations**, not the legacy per-tenant
> "MFA Trusted IPs" service settings. Named locations are the supported, forward-compatible way to
> express trusted networks, and they are available in GCC High. [Microsoft — CA network
> signals](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-assignment-network)
1. **Protection → Conditional Access → Named locations → + IP ranges location.**
2. **Name:** `Named-Trusted-Office-Egress`. Add your office egress IPv4/IPv6 CIDR ranges. Mark
   **Mark as trusted location** if appropriate. **Create.**
3. You will reference this named location in later policies instead of MFA Trusted IPs.
   *(Skip this step if you are not doing location-based policies.)*

## Step 4 — Policy: require compliant device for Microsoft 365
1. **Protection → Conditional Access → Create new policy.**
2. **Name:** `CA - Require Compliant Device - M365 (Gov)`.
3. **Users:** Include `CA-Pilot-Gov`; **Exclude** the two break-glass accounts.
4. **Target resources:** Cloud apps → **Office 365**.
5. **Grant:** Grant access → **Require device to be marked as compliant** (and/or **Require
   Microsoft Entra hybrid joined device**); **Require all the selected controls**.
6. **Enable policy:** **Report-only**. Click **Create**.

## Step 5 — Policy: require MFA
1. **Create new policy** → **Name:** `CA - Require MFA - All Apps (Gov)`.
2. **Users:** Include `CA-Pilot-Gov`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps.
4. **Grant:** **Require multifactor authentication**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 6 — Policy: block legacy authentication
1. **Create new policy** → **Name:** `CA - Block Legacy Auth (Gov)`.
2. **Users:** Include `CA-Pilot-Gov`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps. **Conditions → Client apps →** set **Configure = Yes**,
   then select **Exchange ActiveSync clients** and **Other clients**.
4. **Grant:** **Block access**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 7 — (Optional) require app protection for mobile
1. **Create new policy** → **Name:** `CA - Require App Protection - Mobile (Gov)`.
2. **Users:** `CA-Pilot-Gov` (exclude break-glass). **Conditions → Device platforms →** iOS,
   Android.
3. **Grant:** **Require app protection policy** (and **Require approved client app**);
   **Require one of the selected controls**. **Report-only → Create**.

## Step 8 — Review Report-only impact
1. Have pilot users sign in normally for a day or two (their sign-ins hit
   `login.microsoftonline.us`).
2. `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs →** open a sign-in →
   **Report-only** tab to see which policies *would* apply and the result.
3. Run **`CAIG-Report.ps1`** (policies + recent sign-in CA results) to summarize impact. Resolve any
   unexpected would-blocks.
   > **GCC High caveat:** the **CA policy PowerPoint export** is Commercial-only today — use the
   > sign-in logs, the **What If** tool, and `CAIG-Report.ps1` for review/evidence instead.

## Step 9 — Enable enforcement
1. For each policy, edit **Enable policy → On**. Start with **Block Legacy Auth** and **Require
   MFA**, then **Require Compliant Device**.
2. Before flipping any policy On, run **`CAIG-Validation.ps1`** to confirm the break-glass accounts
   are still excluded from every policy.
3. Re-verify pilot users can work and break-glass accounts are excluded.

## Step 10 — Expand to production
1. Change each policy's **Users** from `CA-Pilot-Gov` to **All users** (keeping break-glass
   exclusions). Use **`CAIG-Set-ScopeTargeting.ps1`** (defaults to `-WhatIf`) to preview the
   include/exclude change before applying it.
2. Roll out in waves; monitor sign-in logs. Re-validate with **`CAIG-Validation.ps1`**.

> **Do NOT design around Global Secure Access.** GSA / network-based Conditional Access is **not
> available in GCC High** — express network trust with IP-based named locations (Step 3) instead.
> [Microsoft — GSA known
> limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)

---
### Order of operations
`Break-glass → Pilot group → (Named locations) → Compliant-device (RO) → MFA (RO) → Block legacy (RO) → App protection (RO) → Review → Enable → Expand`


---


# 5. Testing Guide — Conditional Access Integration (Government / GCC High)

Run during Report-only (Implementation Step 8) and again after enabling enforcement. All scripts
connect to **US Gov Graph** (`-Environment USGov`); all portal checks use the **`*.us`** endpoints.

## Test 0 — You are on the sovereign cloud
**Do:** Open **`https://entra.microsoft.us`** and confirm the tenant domain ends in
**`.onmicrosoft.us`**. Run **`CAIG-Discovery.ps1`** and confirm it reports the **USGov** Graph
environment (`graph.microsoft.us`).
**Expected:** Portal and Graph both resolve to `*.us`. If Graph shows `graph.microsoft.com`, you
forgot `-Environment USGov`.

## Test 1 — Policies evaluate in Report-only
**Do:** `https://entra.microsoft.us` → **Monitoring & health → Sign-in logs →** open a pilot sign-in
→ **Report-only** tab.
**Expected:** Each policy shows a result (Would apply / satisfied / would block) — proving
evaluation works.

## Test 2 — Compliant device satisfies the control
**Do:** From a compliant pilot device, sign in to `https://outlook.office365.us`. Run
`CAIG-Validation.ps1`.
**Expected:** Access granted; the "require compliant device" policy is satisfied.

## Test 3 — Noncompliant device is challenged/blocked
**Do:** From a noncompliant or unmanaged device, attempt the same sign-in (Report-only shows the
would-be result).
**Expected:** Report-only logs "would block"; after enforcement, access is blocked.

## Test 4 — MFA is required
**Do:** Sign in as a pilot user from a new session (auth goes to `login.microsoftonline.us`).
**Expected:** An MFA challenge appears (after enforcement) / Report-only logs "would require MFA".

## Test 5 — Legacy authentication is blocked
**Do:** Attempt a legacy-auth connection (e.g. an older IMAP client) as a pilot user.
**Expected:** Report-only logs "would block"; after enforcement, the legacy client is denied.

## Test 6 — Break-glass accounts are exempt
**Do:** Run **`CAIG-Validation.ps1`**; sign in with a break-glass account.
**Expected:** Break-glass accounts are excluded from all policies and sign in without CA controls.

## Test 7 — Policy + sign-in report
**Do:** Run **`CAIG-Report.ps1`**.
**Expected:** A clear list of policies/states and a summary of CA results across recent sign-ins,
pulled from `graph.microsoft.us`.

## Test 8 — (If used) named location is honored
**Do:** If you built a location policy in Step 3, sign in from inside and outside the trusted named
location.
**Expected:** The policy applies per the named-location condition (not via legacy MFA Trusted IPs).

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Sovereign check** | Test 0 confirms `*.us` portal + **USGov** Graph before any other test |
| **Pilot pass (Report-only)** | Tests 1–6 behave as expected with **no unexpected** would-blocks for legitimate users |
| **Enforcement pass** | After enabling, pilot users work normally; break-glass verified; no lockouts |


---


# 6. Troubleshooting Guide — Conditional Access Integration (Government / GCC High)

Use **`CAIG-Validation.ps1`** / **`CAIG-Report.ps1`** to see why a sign-in was controlled, and run
**`CAIG-Validation.ps1`** (break-glass exclusion check) before any enforcement change. All scripts
must connect with **`-Environment USGov`**.

## A. Sovereign-cloud / wrong-endpoint mistakes (GCC-High-specific)
| Symptom | Cause | Remediation |
|---|---|---|
| Portal shows a different tenant / no policies | Opened a `*.com` portal (Commercial cloud) | Use the **`*.us`** portals: `entra.microsoft.us`, `intune.microsoft.us`, `portal.office365.us` |
| `CAIG-Report.ps1` returns nothing / auth error | `Connect-MgGraph` ran **without** `-Environment USGov` (hit `graph.microsoft.com`) | Reconnect with `Connect-MgGraph -Environment USGov`; confirm `Get-MgContext` shows the USGov environment. `CAIG-Discovery.ps1` reports the active Graph host |
| Sign-in/auth failures after firewall change | `.us` domains blocked by proxy/filtering | Allow `login.microsoftonline.us`, `graph.microsoft.us`, `*.auth.microsoft.us`, and the GCC High URL/IP ranges |
| A demoed CA feature isn't in the blade | GCC High **lags Commercial 2–6 weeks**, or the feature is Gov-absent | Check `gcc-high-parity-notes.md`; **verify for GCC High** before designing around it |

## B. Lockout risk / admins blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Admin locked out by a policy | Break-glass not excluded, or policy too broad | Sign in with a **break-glass** account (`…@<tenant>.onmicrosoft.us`); fix the exclusion; never enforce without break-glass verified via `CAIG-Validation.ps1` |
| Everyone blocked after enabling | Policy enabled with a misconfigured grant | Use break-glass to set the policy back to **Report-only** (or run `CAIG-Remediation.ps1` to revert it); review the grant controls |

## C. "Require compliant device" blocks legitimate users
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant-looking device blocked | Device not actually Compliant in Intune, or not Entra-registered | Run `CAIG-Validation.ps1`; confirm Intune (`intune.microsoft.us`) shows **Compliant**; fix compliance (Device Compliance GCC High solution) |
| Browser blocked but app works | Device registration/SSO state differs per client | Ensure the device is Entra-registered/joined and the browser uses the work account |

## D. MFA issues
- Users repeatedly prompted → expected on new sessions; confirm "remember MFA" / sign-in frequency
  settings.
- Users with no method → enable authentication methods and have them register before enforcing.
  Confirm each method is available in GCC High before relying on it.

## E. Legacy auth still working
- Block-legacy policy in Report-only → it only logs. Move to **On** to enforce.
- Some "modern-looking" clients still use legacy endpoints → confirm via sign-in logs **Client app**
  column.

## F. Location policy not behaving as expected
- Built on **legacy MFA Trusted IPs** instead of **named locations** → rebuild the condition on an
  IP-based **named location** (Implementation Step 3), which is the supported GCC High approach.
- Expecting **Global Secure Access** network signals → **GSA is not available in GCC High**; express
  network trust with named locations. [Microsoft — GSA
  limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)

## G. Report-only shows nothing
- No sign-ins yet for the targeted users/apps → have pilot users actually sign in (via
  `login.microsoftonline.us`); wait for logs to populate (a few minutes).

## H. Diagnostics quick reference
```powershell
dsregcmd /status        # device join/registration state (affects compliant-device control)
Get-MgContext           # confirm the connection is USGov (graph.microsoft.us), not Commercial
```
`entra.microsoft.us` → **Sign-in logs → (a sign-in) → Conditional Access / Report-only** tabs show
exactly which policies applied and why. The **What If** tool (Conditional Access → What If)
simulates a sign-in and works in GCC High. Note the **PowerPoint export** of policies is
Commercial-only — use `CAIG-Report.ps1` for exportable evidence instead.

## I. When to escalate
If a sign-in is blocked with all controls apparently satisfied (device Compliant, MFA passed) and
the Report-only/CA tabs are inconsistent, capture the sign-in correlation ID and open a Microsoft
support case **against the GCC High / US Government tenant** (specify the sovereign cloud so the case
is routed correctly).


---


# 7. Best Practices — Conditional Access Integration (Government / GCC High)

- **Confirm you are on the sovereign cloud first.** Every session, verify the portal is a `*.us`
  URL and the tenant is `.onmicrosoft.us`. In PowerShell, always
  `Connect-MgGraph -Environment USGov` — a missing `-Environment USGov` targets the Commercial cloud
  and reports the wrong tenant.
- **Create break-glass accounts first.** Two cloud-only `.onmicrosoft.us` Global Admins, excluded
  from every policy, passwords stored offline. This is the single most important safeguard against
  lockout.
- **Always pilot in Report-only.** Never enable a new policy straight to On — review the would-be
  impact in the GCC High sign-in logs first.
- **Exclude break-glass from every policy.** Make it a checklist item on each policy; verify with
  `CAIG-Validation.ps1` before every enforcement change.
- **Block legacy authentication.** It's the channel attackers use to bypass MFA — high value, low
  risk to enable.
- **Layer the controls.** Require MFA + require compliant device + block legacy auth together form a
  strong baseline.
- **Use named locations, not legacy MFA Trusted IPs.** Named locations are the supported,
  forward-compatible way to express trusted networks and are available in GCC High.
- **Do not architect around Global Secure Access.** GSA / network-based CA is **not available in
  GCC High**; plan network trust with IP-based named locations instead. [Microsoft — GSA
  limitations](https://learn.microsoft.com/en-us/entra/global-secure-access/reference-current-known-limitations)
- **Plan for feature lag.** GCC High typically receives new CA/Entra features **2–6 weeks after
  Commercial**. Don't design a rollout around a capability you saw demoed on Commercial until you've
  confirmed it in your GCC High tenant. When in doubt, **verify for GCC High**.
- **Use the What If tool.** Simulate a user/app/condition before enabling to predict the outcome
  (the What If tool works in GCC High; the PowerPoint export does not).
- **Roll out by waves.** Move from `CA-Pilot-Gov` to all users gradually, watching sign-in logs; use
  `CAIG-Set-ScopeTargeting.ps1 -WhatIf` to preview each scope change.
- **Name policies clearly.** `CA - <control> - <scope> (Gov)` so intent is obvious and audits are
  easy.
- **Pair with compliance.** "Require compliant device" is only as strong as your Device Compliance
  (GCC High) policy — deploy that solution alongside.


---


# 8. Deliverables Summary — Conditional Access Integration (Government / GCC High)

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box (Government edition) |
| 1. Solution Overview | What Conditional Access is, how it integrates with Intune, **Commercial vs GCC High — what's different**, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, on the `*.us` sovereign endpoints |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps on the GCC High portals — Report-only first, break-glass safety, parity caveats inline |
| 5. Testing Guide | Validation procedures with pass/fail gates, including a sovereign-cloud check |
| 6. Troubleshooting Guide | Field issues, lockout recovery, and GCC-High-specific gotchas |
| 7. Best Practices | Field-proven recommendations for the sovereign cloud |
| GCC High Parity Notes | Cited reference of Commercial-vs-GCC-High capability gaps |

## PowerShell scripts (all connect to US Gov Graph — `-Environment USGov`)
| Script | What it does |
|---|---|
| `CAIG-Discovery.ps1` | Confirms the US Gov Graph environment, local device Entra join/PRT state, and current CA policy inventory |
| `CAIG-Validation.ps1` | Confirms the device satisfies device-based controls **and** verifies break-glass accounts are excluded from every policy |
| `CAIG-Report.ps1` | Lists CA policies + state and summarizes recent sign-in CA results (read-only, US Gov Graph) |
| `CAIG-Remediation.ps1` | Safe fixes — ensures break-glass exclusions and reverts a runaway policy to Report-only; **defaults to `-WhatIf`** |
| `CAIG-Set-ScopeTargeting.ps1` | Builds pilot→production scope (include/exclude groups) on a policy; **defaults to `-WhatIf`** |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP, all targeting **`graph.microsoft.us`**.
- A repeatable process following the model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero Trust access enforcement deployed **correctly on GCC High** — right portals, right endpoints,
parity gaps handled — with only healthy, authenticated devices and users getting in, proven on a
pilot before scale, with break-glass accounts and Report-only piloting preventing lockouts.
