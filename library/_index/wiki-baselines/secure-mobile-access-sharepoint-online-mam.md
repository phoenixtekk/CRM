# Secure Mobile Access to SharePoint Online under MAM (App Protection + Conditional Access)

> **Version 1.0.0** · Category: Intune · Solution code: SPMAM

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Secure Mobile Access to SharePoint Online under MAM (Microsoft Intune)

**White-label · Intune Solutions**

A SharePoint Online intranet that works fine on a laptop can fall apart on a phone the moment
Mobile Application Management (MAM) is in play: employees get blocked or bounced, links open in the
wrong app, and productivity stalls. The cause is almost always a mismatch between three things that
must agree — the App Protection Policies that protect the data, the Conditional Access policy that
gates the sign-in, and the access path the user actually takes (the SharePoint mobile app versus a
protected browser). Sometimes it is an intranet-routing gap on top of that.

This is a complete, deploy-it-today package for delivering secure, reliable mobile access to a
SharePoint Online intranet under MAM with Microsoft Intune, written for an administrator with no
prior App Protection or Conditional Access experience. It doubles as the resolution to a real
support case: "employees can't reliably reach the intranet on mobile."

## What you get
- A plain-language Solution Overview of how mobile access to SharePoint Online works under MAM: App
  Protection Policies, the Conditional Access grant, the supported access paths, and the
  intranet-routing / Microsoft Tunnel-for-MAM decision.
- A Requirements Guide with verify / implement-if-missing for every prerequisite.
- An Implementation Guide of precise, click-by-click steps in the required order — the resolution.
- A root-cause diagnostic tree for "can't reach the intranet on mobile."
- Five PowerShell scripts for readiness discovery, per-user validation, coverage reporting, safe
  remediation, and scope-group targeting.
- Testing and Troubleshooting guides with explicit pass/fail gates.

## What this delivers
App Protection Policies and Conditional Access aligned so mobile users on the supported access path
(the SharePoint mobile app, or a MAM-protected browser) reach the intranet reliably while corporate
data stays protected — with unmanaged browsers steered onto the supported path rather than left to
fail, and the routing decision made deliberately.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Reliable, protected mobile access to a SharePoint Online intranet under MAM, proven on a pilot
before you scale, with a diagnostic tree to root-cause any failure fast.


---


# 1. Solution Overview — Secure Mobile Access to SharePoint Online under MAM

## What this solves
Employees can open a SharePoint Online intranet on a laptop, but on their phones they get blocked,
bounced back to a sign-in loop, or the link opens in an app that refuses to load the page. Under a
Mobile Application Management (MAM) configuration this is almost never a SharePoint problem — it is
a misalignment between the App Protection Policy, the Conditional Access policy, and the access path
the user takes. This solution is the correct, repeatable way to deliver secure, reliable mobile
access to a SharePoint Online intranet under MAM, plus a diagnostic path to root-cause failures.

## The three things that must agree
Reliable mobile access to SharePoint Online under MAM depends on three layers agreeing. When they
disagree, users are blocked.

1. **App Protection Policies (APP / MAM) — data protection.** An App Protection Policy applies
   data-loss-prevention controls (encryption, copy/paste and save-as limits, an app PIN) to the
   Microsoft apps that touch corporate data — here the SharePoint mobile app and a MAM-protected
   browser (Microsoft Edge). MAM protects the data inside approved apps *without* requiring the
   device to be enrolled or company-owned; that is the whole point of MAM (as opposed to MDM).

2. **Conditional Access (CA) — the gate.** A Conditional Access policy decides who is allowed to
   reach SharePoint Online / Office 365 from mobile and under what conditions. Two grant controls
   matter here: `Require approved client app` (the app must be on Microsoft's approved-apps list)
   and `Require app protection policy` (the app must additionally have an App Protection Policy
   applied). The second is the stronger, recommended control; it is what ties CA to the App
   Protection layer.

3. **The access path — how the user actually opens the site.** On mobile there are two *supported*
   paths to SharePoint Online: the SharePoint mobile app, or the site opened in a MAM-protected
   browser (Microsoft Edge signed in with the work account). An *unsupported* path — the intranet
   opened in unmanaged Safari or unmanaged Chrome — is typically blocked by the Conditional Access
   grant, because those browsers cannot satisfy `Require approved client app` /
   `Require app protection policy`. The fix for "it's blocked in Safari" is not to weaken CA; it is
   to steer the user onto the supported path.

## Why the three must be aligned
- If CA requires an app-protection grant but no App Protection Policy is assigned to the user, every
  mobile sign-in is blocked — the grant can never be satisfied.
- If an App Protection Policy exists but CA does not require it, data protection is optional and
  inconsistently applied — a compliance gap, and unmanaged browsers may still load the site.
- If the policies are perfect but the user opens the intranet in unmanaged Safari, CA blocks them —
  and it looks like an outage when it is really a wrong-path problem.

## The routing decision — is Microsoft Tunnel for MAM required here?
"Can't reach the intranet" sometimes means the resource is not reachable from the internet at all —
a truly internal, on-premises web app behind the corporate firewall. Reaching *that* from a
MAM-protected app requires **Microsoft Tunnel for MAM**, which gives approved mobile apps a per-app
VPN into the private network (cross-reference: the Microsoft Tunnel for MAM solution).

But this solution is about SharePoint **Online**. SharePoint Online is a Microsoft 365 cloud service
reachable over the public internet at your `*.sharepoint.com` tenant — it does **not** require
Microsoft Tunnel. The decision is therefore explicit:

> **Decision:** Is the intranet SharePoint **Online** (`*.sharepoint.com`)? → No Tunnel needed;
> the fix is APP + CA + access path. Is the "intranet" actually an on-premises / private web app
> (even if branded as the intranet)? → That resource needs **Microsoft Tunnel for MAM** (separate
> solution). Confirm which one you are dealing with before you start — it changes the fix.

The diagnostic tree below includes a routing branch so you don't burn time on APP/CA when the real
problem is that the resource is private.

## Root-cause diagnostic tree — "can't reach the SharePoint Online intranet on mobile"
Work top-down; stop at the first branch that matches. Each branch names the confirm step and the
section that fixes it.

```
START: user reports the SharePoint Online intranet won't load on mobile
│
├─ Q1. Is the resource SharePoint Online (*.sharepoint.com), or a private/on-prem web app?
│     • Private/on-prem  → ROUTING gap. SharePoint Online needs no Tunnel; a private
│                          resource needs Microsoft Tunnel for MAM (separate solution). STOP.
│     • SharePoint Online → continue.
│
├─ Q2. Which app is the user opening the site in?
│     • Unmanaged Safari / unmanaged Chrome → WRONG ACCESS PATH. CA is blocking an
│         unapproved browser by design. Fix: steer to the SharePoint mobile app or
│         MAM-protected Edge (Overview + Implementation Step 6 / Troubleshooting B). STOP.
│     • SharePoint mobile app or MAM-protected Edge → continue.
│
├─ Q3. Does the block message cite a Conditional Access / organization policy?
│     • "You can't get here from your current device / need an approved app"
│         → CA BLOCK. Confirm in Entra Sign-in logs → the failing CA policy + which
│           grant failed. Go to Q4 to find which control the user can't meet.
│     • No CA message; sign-in loops / token error → go to Q6.
│
├─ Q4. Is an App Protection Policy actually applied to this user for this app?
│     • No APP assigned → MISSING APP GRANT. CA requires app protection but the user has
│         no APP → grant can never pass. Fix: assign the APP to the user's group
│         (Implementation Steps 2–3; run SPMAM-Validation.ps1). STOP.
│     • APP assigned → continue.
│
├─ Q5. Is the CA grant scoped/configured correctly for SharePoint Online / Office 365?
│     • CA not targeting Office 365 / SharePoint Online, or wrong grant/platform
│         → CA MISCONFIG. Fix the target resource, device platforms, and grant
│           (Implementation Step 5; run SPMAM-Discovery.ps1). STOP.
│     • CA correct → continue.
│
└─ Q6. Sign-in / token issue (MFA nag loop, stale token, app not signed into work account)?
      • Yes → TOKEN/SIGN-IN. Fix: sign out and back in with the work account in the
          managed app; complete MFA; clear the app data if needed (Troubleshooting E). STOP.
      • No, and Q1–Q5 all clean → escalate with Sign-in log correlation ID (Troubleshooting G).
```

## The standard deployment model
> **Define the App Protection Policies (SharePoint app + Edge) → build the Conditional Access grant
> for Office 365 → confirm and steer users to the supported access path → validate on a pilot →
> expand.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Secure Mobile Access to SharePoint Online under MAM

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing (Intune + Entra ID P1 + SharePoint Online)
**Description:** Intune (Plan 1) for App Protection Policies, Microsoft Entra ID P1 for Conditional
Access, and a SharePoint Online / Microsoft 365 plan for the intranet.
**Why:** App Protection Policies come from Intune; the CA grant requires Entra ID P1; SharePoint
Online hosts the intranet users are trying to reach.
**Verify:** M365 admin center → **Billing → Licenses**; confirm Intune, Entra ID P1 (or M365
E3/E5 / Business Premium, which include both), and SharePoint Online.
**Implement:** Assign M365 E3/E5 or Business Premium (Intune + Entra ID P1 + SharePoint Online
included) to the target users.

## 2.2 Target users and a pilot group
**Description:** Entra security groups for the users who need mobile intranet access, plus a small
pilot group.
**Why:** App Protection Policies and Conditional Access are assigned to user groups; the pilot group
proves the change before the fleet gets it.
**Verify:** Entra → **Groups**; the target group and a pilot group exist.
**Implement:** Create the groups (Entra → **Groups → New group → Security**), or use
`SPMAM-Set-ScopeTargeting.ps1` to build them.

## 2.3 The Microsoft mobile apps in scope
**Description:** The SharePoint mobile app and Microsoft Edge, from the official app stores, on the
users' iOS/iPadOS and Android devices.
**Why:** These are the two *supported* access paths to SharePoint Online under MAM; the App
Protection Policy applies to them.
**Verify:** On a pilot device, the SharePoint app (publisher **Microsoft Corporation**, bundle ID
`com.microsoft.sharepoint` on iOS / package `com.microsoft.sharepoint` on Android) and Microsoft
Edge (bundle ID `com.microsoft.msedge` on iOS / package `com.microsoft.emmx` on Android) are
installed and can sign in to the work account.
**Implement:** Install the SharePoint app and Microsoft Edge from the App Store / managed Google
Play (optionally deploy them as Intune apps to the target group).

## 2.4 App Protection Policies for SharePoint app + protected browser
**Description:** App Protection Policies (APP / MAM) targeting the SharePoint app and Edge for both
iOS/iPadOS and Android, assigned to the target users.
**Why:** MAM data protection is the control CA will require; without it the app-protection grant can
never be satisfied and mobile sign-ins are blocked.
**Verify:** Intune → **Apps → App protection policies**; run `SPMAM-Discovery.ps1`.
**Implement:** Create them per Implementation Steps 2–3.

## 2.5 Conditional Access policy for Office 365 / SharePoint Online
**Description:** A CA policy scoped to Office 365 (which includes SharePoint Online) with the
`Require app protection policy` grant (and/or `Require approved client app`), targeting iOS and
Android.
**Why:** This is the gate that forces mobile users onto a protected app and blocks unmanaged
browsers.
**Verify:** Entra → **Protection → Conditional Access**; run `SPMAM-Discovery.ps1`.
**Implement:** Create it per Implementation Step 5 (start in **Report-only**).

## 2.6 Break-glass (emergency-access) accounts excluded from CA
**Description:** Two cloud-only emergency-access Global Administrator accounts excluded from every CA
policy.
**Why:** A CA misconfiguration must never lock every administrator out of the tenant.
**Verify:** Entra → **Users**; the two break-glass accounts exist and are excluded from the CA
policy.
**Implement:** Create them and exclude them (Implementation Step 1).

## 2.7 Confirm the resource is SharePoint Online (routing decision)
**Description:** Confirm the intranet is SharePoint Online (`*.sharepoint.com`), not an
on-premises / private web app.
**Why:** SharePoint Online is cloud-reachable and needs no VPN; a private resource needs Microsoft
Tunnel for MAM (a different solution). This decision changes the whole fix.
**Verify:** Open the intranet URL; confirm it resolves to your `*.sharepoint.com` tenant and loads
over the public internet on an off-network connection.
**Implement:** If the resource is actually private/on-prem, stop here and use the Microsoft Tunnel
for MAM solution instead.

---
## Checklist
- [ ] Intune + Entra ID P1 + SharePoint Online licensing assigned
- [ ] Target user group + pilot group created
- [ ] SharePoint app + Microsoft Edge installed on pilot devices
- [ ] App Protection Policies for SharePoint app + Edge (iOS + Android) — `SPMAM-Discovery.ps1`
- [ ] Conditional Access policy for Office 365 with app-protection grant — `SPMAM-Discovery.ps1`
- [ ] Two break-glass accounts excluded from CA
- [ ] Confirmed the intranet is SharePoint Online (no Tunnel needed)


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


# 3. Implementation Guide — Secure Mobile Access to SharePoint Online under MAM

Follow these steps **in order**. App Protection Policies are in the **Microsoft Intune admin
center** (`https://intune.microsoft.com` → **Apps → App protection policies**). Conditional Access
is in **Microsoft Entra** (`https://entra.microsoft.com` → **Protection → Conditional Access**).
**Always start Conditional Access in Report-only.**

> **Model:** Define the App Protection Policies (SharePoint app + Edge) → build the Conditional
> Access grant for Office 365 → confirm and steer users to the supported access path → validate on a
> pilot → expand. This is the resolution: align APP + CA + access path.

> **Naming (reuse these exact names):**
> App Protection Policies: `SPO Mobile – App Protection – iOS` and `SPO Mobile – App Protection – Android`.
> Conditional Access policy: `CA – SPO Mobile – Require APP`.
> Groups: `SPO Mobile – Users – Pilot` and `SPO Mobile – Users – Prod`.

## Step 1 — Create break-glass accounts and the groups
1. Entra → **Users → New user → Create new user**: create two cloud-only emergency-access Global
   Administrators (`breakglass1@…onmicrosoft.com`, `breakglass2@…onmicrosoft.com`) with long random
   passwords stored offline. You will **exclude these two from the CA policy** in Step 5.
2. Entra → **Groups → New group → Security → Name:** `SPO Mobile – Users – Pilot`; add a few
   representative mobile users. **Create.**
3. Create `SPO Mobile – Users – Prod` (the rest of the mobile users). **Create.**

## Step 2 — Create the iOS App Protection Policy (SharePoint app + Edge)
1. Intune → **Apps → App protection policies → Create policy → iOS/iPadOS**.
2. **Name:** `SPO Mobile – App Protection – iOS`. **Next.**
3. **Apps:** **Target policy to → Selected apps → Select public apps →** add **Microsoft SharePoint**
   and **Microsoft Edge**. **Next.**
4. **Data protection:** set **Send org data to other apps → Policy managed apps**;
   **Save copies of org data → Block** (allow **OneDrive/SharePoint** if your policy permits);
   **Receive data from other apps → Policy managed apps**; **Restrict cut, copy, and paste → Policy
   managed apps**. **Next.**
5. **Access requirements:** require an **App PIN**; **Work or school account credentials for access**;
   set the **recheck** timeout to your policy. **Next.**
6. **Conditional launch:** keep the defaults (for example **Max PIN attempts → 5 → Reset PIN**;
   **Offline grace period → 720 min → Block access**). **Next.**
7. **Assignments → Add groups →** `SPO Mobile – Users – Pilot`. **Next → Create.**

## Step 3 — Create the Android App Protection Policy (SharePoint app + Edge)
1. Intune → **Apps → App protection policies → Create policy → Android**.
2. **Name:** `SPO Mobile – App Protection – Android`. **Next.**
3. **Apps → Selected apps → Select public apps →** add **Microsoft SharePoint** and **Microsoft
   Edge**. **Next.**
4. Set **Data protection**, **Access requirements**, and **Conditional launch** to match the iOS
   policy (Step 2.4–2.6). **Next.**
5. **Assignments → Add groups →** `SPO Mobile – Users – Pilot`. **Next → Create.**

## Step 4 — Confirm the routing decision (SharePoint Online = no Tunnel)
1. Confirm the intranet is SharePoint Online: open its URL and verify it resolves to your
   `*.sharepoint.com` tenant over the public internet (test off the corporate network).
2. If it is SharePoint Online, **no Microsoft Tunnel is required** — continue to Step 5.
3. If the "intranet" is actually an on-premises / private web app, **stop**: that resource needs the
   **Microsoft Tunnel for MAM** solution (separate). Do not build a Tunnel for SharePoint Online.

## Step 5 — Create the Conditional Access policy (app-protection grant)
1. Entra → **Protection → Conditional Access → Create new policy.**
2. **Name:** `CA – SPO Mobile – Require APP`.
3. **Users:** **Include →** `SPO Mobile – Users – Pilot`; **Exclude →** the two break-glass accounts.
4. **Target resources → Cloud apps → Include → Select apps → Office 365** (this covers SharePoint
   Online). Do **not** hand-pick only the SharePoint resource; **Office 365** is the supported,
   recommended target.
5. **Conditions → Device platforms → Configure → Yes → Select → iOS and Android.**
6. **Grant → Grant access →** select **Require app protection policy** and **Require approved client
   app**; set **For multiple controls → Require one of the selected controls** (Microsoft recommends
   pairing these two so older approved apps that predate APP are still covered). **Select.**
7. **Enable policy → Report-only.** **Create.**

## Step 6 — Confirm and steer users to the supported access path
1. On a pilot device, open the intranet in the **SharePoint mobile app** (signed in with the work
   account) — it should load. Then open it in **Microsoft Edge** signed in with the work account — it
   should load.
2. Open the same intranet URL in **unmanaged Safari / unmanaged Chrome** — it should be **blocked**
   by CA once enforced (this is expected and correct).
3. Communicate the supported paths to users: "Open the intranet in the SharePoint app, or in
   Microsoft Edge signed in with your work account. Do not use Safari or Chrome." Optionally publish
   a bookmark/link that deep-links into the SharePoint app or Edge.

## Step 7 — Review Report-only impact, then enforce
1. Have pilot users work normally for a day or two using the supported paths.
2. Entra → **Monitoring → Sign-in logs →** open a mobile sign-in → **Report-only** tab to see whether
   `CA – SPO Mobile – Require APP` *would* apply and its result. Run `SPMAM-Discovery.ps1` and
   `SPMAM-Report.ps1` to summarize coverage; resolve any unexpected results.
3. When the pilot is clean, edit the CA policy → **Enable policy → On**. Re-verify pilot users can
   reach the intranet on the supported path and that break-glass accounts are excluded.

## Step 8 — Validate the pilot
1. Run `SPMAM-Validation.ps1` for a pilot user → confirms an App Protection Policy is applied for
   the SharePoint/Edge apps and that the CA app-protection grant is effective for SharePoint Online.
2. Complete the **Testing Guide** (Section 5) and confirm every pass/fail gate.

## Step 9 — Expand to production
1. Add `SPO Mobile – Users – Prod` to the **Include** on all three policies (the two App Protection
   Policies and the CA policy), keeping the break-glass exclusions on CA. Use
   `SPMAM-Set-ScopeTargeting.ps1` to manage the group membership at scale.
2. Roll out in waves; monitor **Sign-in logs** and re-validate with `SPMAM-Validation.ps1` /
   `SPMAM-Report.ps1`.
3. If any assignment is inconsistent, run `SPMAM-Remediation.ps1` (defaults to `-WhatIf`) to preview
   the fix, then re-run with `-WhatIf:$false` to apply.

---
### Order of operations
`Break-glass + groups → iOS App Protection → Android App Protection → routing decision → CA policy (Report-only) → confirm/steer access path → review + enforce → validate → expand`


---


# 5. Testing Guide — Secure Mobile Access to SharePoint Online under MAM

Run after the pilot policies apply (Implementation Steps 6–8) and again before each expansion wave.

## Test 1 — App Protection Policies assigned
**Do:** Intune → **Apps → App protection policies →** open `SPO Mobile – App Protection – iOS` and
`SPO Mobile – App Protection – Android` → **Assignments**; or run `SPMAM-Discovery.ps1`.
**Expected:** Both policies target the SharePoint app and Edge and are assigned to
`SPO Mobile – Users – Pilot`.

## Test 2 — App Protection applied on the device
**Do:** On a pilot device, open the SharePoint app / Edge with the work account; you are prompted for
the App PIN. Run `SPMAM-Validation.ps1` for that user.
**Expected:** The App PIN is enforced and `SPMAM-Validation.ps1` reports the App Protection Policy is
applied for the SharePoint/Edge apps.

## Test 3 — Conditional Access grant effective
**Do:** Entra → **Monitoring → Sign-in logs →** open the pilot user's mobile SharePoint sign-in →
**Conditional Access** (or **Report-only**) tab.
**Expected:** `CA – SPO Mobile – Require APP` applies to the Office 365 / SharePoint Online sign-in
and the app-protection grant is **satisfied** (not failed).

## Test 4 — Supported path loads the intranet
**Do:** On a pilot device, open the SharePoint Online intranet in the **SharePoint mobile app**, then
in **Microsoft Edge** signed in with the work account.
**Expected:** The intranet loads reliably in both.

## Test 5 — Unsupported path is blocked (by design)
**Do:** Open the same intranet URL in **unmanaged Safari / unmanaged Chrome** (CA enforced).
**Expected:** Access is **blocked** with an approved-app / app-protection message — confirming CA is
steering users to the supported path, not that the site is down.

## Test 6 — Routing confirmed (no Tunnel for SharePoint Online)
**Do:** From a pilot device **off** the corporate network, open the intranet on the supported path.
**Expected:** It loads over the public internet — confirming SharePoint Online is cloud-reachable
and no Microsoft Tunnel is required.

## Test 7 — Coverage report
**Do:** Run `SPMAM-Report.ps1`.
**Expected:** A clear report of which target users have the App Protection Policy and are in scope of
the CA policy, with any gaps flagged.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–4 pass; Test 5 shows the expected block; Test 6 confirms cloud reachability |
| **Expand pass** | Tests 1–4 and 7 pass for each production wave before adding the next |


---


# 6. Troubleshooting Guide — Secure Mobile Access to SharePoint Online under MAM

Use `SPMAM-Discovery.ps1` for the policy inventory, `SPMAM-Validation.ps1` for a specific user,
`SPMAM-Report.ps1` for coverage, and `SPMAM-Remediation.ps1` (defaults to `-WhatIf`) for safe fixes.
The **Sign-in logs** in Entra (**Monitoring → Sign-in logs**, open a sign-in → **Conditional Access**
/ **Report-only** tab) are your primary evidence for any block.

## Root-cause diagnostic tree — "can't reach the SharePoint Online intranet on mobile"
Work top-down; stop at the first branch that matches.

```
START: user reports the SharePoint Online intranet won't load on mobile
│
├─ Q1. Is the resource SharePoint Online (*.sharepoint.com), or a private/on-prem web app?
│     • Private/on-prem  → ROUTING gap → see section D. A private resource needs Microsoft
│                          Tunnel for MAM (separate solution). STOP.
│     • SharePoint Online → continue.
│
├─ Q2. Which app is the user opening the site in?
│     • Unmanaged Safari / unmanaged Chrome → WRONG ACCESS PATH → see section B. STOP.
│     • SharePoint mobile app or MAM-protected Edge → continue.
│
├─ Q3. Does the block cite a Conditional Access / organization policy? (Sign-in logs)
│     • Yes (approved app / app protection required) → CA BLOCK → go to Q4.
│     • No; sign-in loops / token error → see section E. STOP.
│
├─ Q4. Is an App Protection Policy actually applied to this user for this app?
│     • No APP assigned → MISSING APP GRANT → see section A. STOP.
│     • APP assigned → continue.
│
├─ Q5. Is the CA grant scoped correctly (Office 365, iOS/Android, app-protection grant)?
│     • Misconfigured → CA MISCONFIG → see section C. STOP.
│     • Correct → continue.
│
└─ Q6. Sign-in / token issue (MFA loop, stale token, app not on the work account)?
      • Yes → TOKEN/SIGN-IN → see section E. STOP.
      • No, and Q1–Q5 clean → escalate with the Sign-in log correlation ID → see section G.
```

## A. Missing app-protection grant (CA requires APP, user has none)
| Symptom | Cause | Remediation |
|---|---|---|
| Every mobile sign-in blocked; log shows the app-protection grant **failed** | No App Protection Policy is assigned to the user for the SharePoint/Edge app | Assign `SPO Mobile – App Protection – iOS/Android` to the user's group (Implementation Steps 2–3); run `SPMAM-Validation.ps1`; if the assignment is inconsistent run `SPMAM-Remediation.ps1` |

## B. Wrong access path (blocked in an unmanaged browser)
- CA blocking unmanaged Safari/Chrome is **expected** — those browsers cannot satisfy the
  approved-app / app-protection grant. Do **not** weaken CA.
- Steer the user to the **SharePoint mobile app** or **Microsoft Edge signed in with the work
  account** (Implementation Step 6). Consider deploying a bookmark/deep link that opens the app or
  Edge, and send the one-line "use the SharePoint app or Edge" message.

## C. Conditional Access misconfigured
| Symptom | Cause | Remediation |
|---|---|---|
| Supported app still blocked | CA not targeting **Office 365** / SharePoint Online, or wrong grant | Set **Target resources → Office 365**; set the grant to `Require app protection policy` + `Require approved client app`; run `SPMAM-Discovery.ps1` |
| Policy doesn't apply on mobile | **Device platforms** condition excludes iOS/Android | Set **Conditions → Device platforms → iOS and Android** |
| Admins locked out during rollout | Break-glass accounts not excluded | Exclude the two break-glass accounts from the CA policy (Implementation Step 1) |

## D. Routing — is this really SharePoint Online?
- SharePoint **Online** (`*.sharepoint.com`) is cloud-reachable and needs **no** Microsoft Tunnel;
  if it won't load on the supported path, the cause is APP/CA/token (sections A/C/E), not routing.
- If the "intranet" is actually an **on-premises / private** web app, it needs **Microsoft Tunnel
  for MAM** (separate solution) — a per-app VPN for approved mobile apps. Confirm reachability off
  the corporate network to tell the two apart.

## E. Sign-in / token issues
- MFA nag loop, stale token, or the app is signed into the wrong (personal) account: sign out and
  back in with the **work account** in the managed app, complete MFA, and if needed clear the app's
  data and re-sign-in. Confirm the account is the work account, not a personal Microsoft account.

## F. Diagnostics quick reference
- Entra → **Monitoring → Sign-in logs** → open the failing mobile sign-in → **Conditional Access** /
  **Report-only** tab: which policy applied and which grant failed.
- Intune → **Apps → Monitor → App protection status**: whether the user's app is protected.
- Run `SPMAM-Discovery.ps1` (policy inventory), `SPMAM-Validation.ps1` (per user), and
  `SPMAM-Report.ps1` (coverage) to correlate.

## G. When to escalate
If the resource is SharePoint Online, the App Protection Policy is applied, the CA policy targets
Office 365 with the correct grant and platforms, the user is on a supported app signed into the work
account with MFA complete, and the intranet still won't load — capture the **correlation ID** from
the Sign-in log entry and open a Microsoft support case.


---


# 7. Best Practices — Secure Mobile Access to SharePoint Online under MAM

- **Align all three layers, always.** App Protection, Conditional Access, and the access path must
  agree. Change one and re-validate the other two — a mismatch is the single most common cause of
  "can't reach the intranet on mobile."
- **Target Office 365, not just the SharePoint resource, in CA.** Scoping the CA policy to
  **Office 365** is the supported, recommended pattern and avoids gaps where a related sign-in
  slips past the grant.
- **Prefer `Require app protection policy`, paired with `Require approved client app`.** The
  app-protection grant is the stronger control; pairing the two (require one of the selected) keeps
  older approved apps covered while enforcing MAM where it exists.
- **Always start CA in Report-only.** Review the impact in Sign-in logs before you enforce, so a
  scoping mistake never blocks real users.
- **Steer, don't weaken.** When users are blocked in Safari/Chrome, move them to the SharePoint app
  or protected Edge — never relax the CA grant to let unmanaged browsers in.
- **Make the routing decision explicitly.** SharePoint Online is cloud-reachable and needs no
  Microsoft Tunnel. Only a truly private/on-prem resource needs Tunnel for MAM — confirm which one
  you have before building anything.
- **Never lock yourself out.** Keep two break-glass Global Administrators excluded from every CA
  policy and test them.
- **Pilot before you expand.** Prove the supported paths and the grant on `SPO Mobile – Users – Pilot`
  before adding `SPO Mobile – Users – Prod`.
- **Reuse the exact object names.** `SPO Mobile – App Protection – iOS/Android`,
  `CA – SPO Mobile – Require APP`, and the group names keep the deployment auditable and repeatable.
- **Communicate the supported path to users.** A one-line message ("use the SharePoint app or Edge
  with your work account") prevents most tickets.
- **Re-validate each wave.** Run `SPMAM-Validation.ps1` and `SPMAM-Report.ps1` before and after each
  expansion so coverage never drifts.


---


# 8. Deliverables Summary — Secure Mobile Access to SharePoint Online under MAM

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case, the problem it resolves, and what's in the box |
| 1. Solution Overview | How mobile access to SharePoint Online works under MAM; APP + CA + access path; the routing decision; the root-cause diagnostic tree |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (App Protection Policies, Conditional Access, access path) — the resolution |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues, remediation, and the root-cause diagnostic tree |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `SPMAM-Discovery.ps1` | Read-only inventory of App Protection Policies + Conditional Access policies and their assignments (Microsoft Graph) |
| `SPMAM-Validation.ps1` | Per-user: confirms an App Protection Policy is applied and the CA app-protection grant is effective for SharePoint Online mobile (Microsoft Graph) |
| `SPMAM-Report.ps1` | Coverage report — which target users have APP and are in scope of the CA policy, with gaps flagged (Microsoft Graph) |
| `SPMAM-Remediation.ps1` | Safe remediation of misconfigured assignments; defaults to `-WhatIf` |
| `SPMAM-Set-ScopeTargeting.ps1` | Builds/maintains the mobile-access scope groups and adds users |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Reliable, protected mobile access to a SharePoint Online intranet under MAM — App Protection and
Conditional Access aligned, users on the supported access path, routing handled — with a diagnostic
tree to root-cause any failure.
