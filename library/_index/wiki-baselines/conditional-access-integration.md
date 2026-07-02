# Conditional Access Integration

> **Version 1.0.0** · Category: Intune · Solution code: CAI

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Conditional Access Integration (Microsoft Intune)

**White-label · Intune Solutions**

Device compliance and MFA only protect you if access is actually *gated* on them. **Conditional
Access** is the enforcement engine: it evaluates every sign-in against your rules — is the device
compliant? has the user passed MFA? is this legacy authentication? — and allows, challenges, or
blocks accordingly. Integrated with Microsoft Intune, it turns device compliance into a hard
access requirement.

This is a complete, **deploy-it-today** package for implementing Conditional Access integrated
with Microsoft Intune, written for an administrator with no prior Conditional Access experience —
including the safety practices (break-glass accounts, Report-only mode) that prevent lockouts.

## What you get
- A plain-language **Solution Overview** of how Conditional Access evaluates and enforces sign-ins.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps in the required order — Report-only first.
- Five **PowerShell scripts** for device-state discovery, access validation, policy reporting, sign-in analysis, and break-glass verification.
- **Testing** and **Troubleshooting** guides for confident, lockout-free rollout.

## What this delivers
A baseline Conditional Access posture: **require a compliant (or Entra-joined) device** for
Microsoft 365, **require MFA**, **block legacy authentication**, and (for mobile) **require app
protection** — all piloted in Report-only mode before enforcement, with break-glass accounts excluded.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero Trust access enforcement that only admits healthy, authenticated devices and users —
deployed safely, without locking anyone out.


---


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

## The standard deployment model
> **Create break-glass accounts → build policies in Report-only → review impact → enable →
> expand.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Conditional Access Integration

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites are in `global-requirements-intune-solutions.md`.

## 2.1 Licensing
**Description:** Microsoft Entra ID P1 (or P2 for risk-based policies).
**Why:** Conditional Access is a P1 feature; risk-based conditions need P2.
**Verify:** M365 admin center → **Billing → Licenses** (P1 via M365 E3/E5/Business Premium).
**Implement:** Assign M365 E3/E5 or Business Premium to targeted users.

## 2.2 Break-glass (emergency access) accounts
**Description:** Two cloud-only Global Administrator accounts excluded from all CA policies.
**Why:** They guarantee you can always sign in if a CA policy misfires — the #1 lockout safeguard.
**Verify:** Entra → **Users** — two dedicated emergency accounts exist; run **`CAI-BreakGlassCheck.ps1`**.
**Implement:** Create two cloud-only `.onmicrosoft.com` Global Admins with long random passwords stored offline; exclude them from every CA policy.

## 2.3 Device compliance (for "require compliant device")
**Description:** Intune device compliance policies in place.
**Why:** The "require compliant device" control needs Intune to be marking devices Compliant.
**Verify:** Intune → **Devices → Compliance**; devices report Compliant.
**Implement:** Deploy the **Device Compliance Policies** solution first.

## 2.4 MFA registration
**Description:** Users are able to register MFA methods.
**Why:** "Require MFA" challenges users; they must have a method registered.
**Verify:** Entra → **Authentication methods**; run **`CAI-Discovery.ps1`** for the local user.
**Implement:** Enable authentication methods and (optionally) the registration campaign or SSPR.

## 2.5 Sign-in logs / reporting
**Description:** Access to Entra sign-in logs.
**Why:** Report-only impact is reviewed in the sign-in logs before enforcing.
**Verify:** Entra → **Monitoring → Sign-in logs** loads.
**Implement:** Ensure the operator has Reports Reader / Security Reader.

## 2.6 App protection (optional — mobile)
**Description:** Intune app protection policies for mobile apps.
**Why:** The "require app protection policy" control needs them defined.
**Verify:** Intune → **Apps → App protection policies**.
**Implement:** Create app protection policies for iOS/Android (optional companion work).

---
## Checklist
- [ ] Entra ID P1 licensing assigned
- [ ] **Two break-glass admins created and excluded** — `CAI-BreakGlassCheck.ps1`
- [ ] Device compliance policies in place
- [ ] MFA methods enabled / users can register
- [ ] Sign-in log access for review
- [ ] Pilot Entra group created


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


# 3. Implementation Guide — Conditional Access Integration

Follow these steps **in order**. Conditional Access is in **Microsoft Entra**
(`https://entra.microsoft.com` → **Protection → Conditional Access**). **Always start in Report-only.**

> **Model:** Break-glass first → policies in Report-only → review → enable → expand.

## Step 1 — Create and exclude break-glass accounts
1. Entra → **Users → New user** → create two cloud-only `breakglass1@…onmicrosoft.com` and `breakglass2@…onmicrosoft.com` Global Administrators with long random passwords (store offline).
2. You will **exclude these two accounts from every CA policy** in the steps below.

## Step 2 — Create the pilot group
1. Entra → **Groups → New group** → Security → `CA-Pilot` → add pilot users. **Create**.

## Step 3 — Policy: require compliant device for Microsoft 365
1. **Protection → Conditional Access → Create new policy.**
2. **Name:** `CA - Require Compliant Device - M365`.
3. **Users:** Include `CA-Pilot`; **Exclude** the two break-glass accounts.
4. **Target resources:** Cloud apps → **Office 365**.
5. **Grant:** Grant access → **Require device to be marked as compliant** (and/or **Require Microsoft Entra hybrid joined device**); **Require all the selected controls**.
6. **Enable policy:** **Report-only**. Click **Create**.

## Step 4 — Policy: require MFA
1. **Create new policy** → **Name:** `CA - Require MFA - All Apps`.
2. **Users:** Include `CA-Pilot`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps.
4. **Grant:** **Require multifactor authentication**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 5 — Policy: block legacy authentication
1. **Create new policy** → **Name:** `CA - Block Legacy Auth`.
2. **Users:** Include `CA-Pilot`; **Exclude** break-glass accounts.
3. **Target resources:** All cloud apps. **Conditions → Client apps →** select **Exchange ActiveSync clients** and **Other clients**.
4. **Grant:** **Block access**.
5. **Enable policy:** **Report-only**. **Create**.

## Step 6 — (Optional) require app protection for mobile
1. **Create new policy** → **Name:** `CA - Require App Protection - Mobile`.
2. **Users:** `CA-Pilot` (exclude break-glass). **Conditions → Device platforms →** iOS, Android.
3. **Grant:** **Require app protection policy** (and **Require approved client app**). **Report-only → Create**.

## Step 7 — Review Report-only impact
1. Have pilot users sign in normally for a day or two.
2. Entra → **Monitoring → Sign-in logs →** open a sign-in → **Report-only** tab to see which policies *would* apply and the result.
3. Run **`CAI-PolicyReport.ps1`** and **`CAI-SignInReport.ps1`** to summarize impact. Resolve any unexpected blocks.

## Step 8 — Enable enforcement
1. For each policy, edit **Enable policy → On**. Start with **Block Legacy Auth** and **Require MFA**, then **Require Compliant Device**.
2. Re-verify pilot users can work and break-glass accounts are excluded.

## Step 9 — Expand to production
1. Change each policy's **Users** from `CA-Pilot` to **All users** (keeping break-glass exclusions).
2. Roll out in waves; monitor sign-in logs. Re-validate with **`CAI-Validation.ps1`**.

---
### Order of operations
`Break-glass → Pilot group → Compliant-device (RO) → MFA (RO) → Block legacy (RO) → App protection (RO) → Review → Enable → Expand`


---


# 5. Testing Guide — Conditional Access Integration

Run during Report-only (Implementation Step 7) and again after enabling enforcement.

## Test 1 — Policies evaluate in Report-only
**Do:** Entra → **Monitoring → Sign-in logs →** open a pilot sign-in → **Report-only** tab.
**Expected:** Each policy shows a result (Would apply / satisfied / would block) — proving evaluation works.

## Test 2 — Compliant device satisfies the control
**Do:** From a compliant pilot device, sign in to `https://outlook.office.com`. Run `CAI-Validation.ps1`.
**Expected:** Access granted; the "require compliant device" policy is satisfied.

## Test 3 — Noncompliant device is challenged/blocked
**Do:** From a noncompliant or unmanaged device, attempt the same sign-in (Report-only shows the would-be result).
**Expected:** Report-only logs "would block"; after enforcement, access is blocked.

## Test 4 — MFA is required
**Do:** Sign in as a pilot user from a new session.
**Expected:** An MFA challenge appears (after enforcement) / Report-only logs "would require MFA".

## Test 5 — Legacy authentication is blocked
**Do:** Attempt a legacy-auth connection (e.g. older IMAP client) as a pilot user.
**Expected:** Report-only logs "would block"; after enforcement, the legacy client is denied.

## Test 6 — Break-glass accounts are exempt
**Do:** Run **`CAI-BreakGlassCheck.ps1`**; sign in with a break-glass account.
**Expected:** Break-glass accounts are excluded from all policies and sign in without CA controls.

## Test 7 — Policy + sign-in report
**Do:** Run **`CAI-PolicyReport.ps1`** and **`CAI-SignInReport.ps1`**.
**Expected:** A clear list of policies/states and a summary of CA results across recent sign-ins.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (Report-only)** | Tests 1–6 behave as expected with **no unexpected** would-blocks for legitimate users |
| **Enforcement pass** | After enabling, pilot users work normally; break-glass verified; no lockouts |


---


# 6. Troubleshooting Guide — Conditional Access Integration

Use **`CAI-Validation.ps1`** / **`CAI-SignInReport.ps1`** to see why a sign-in was controlled, and
**`CAI-BreakGlassCheck.ps1`** before any enforcement change.

## A. Lockout risk / admins blocked
| Symptom | Cause | Remediation |
|---|---|---|
| Admin locked out by a policy | Break-glass not excluded, or policy too broad | Sign in with a **break-glass** account; fix the exclusion; never enforce without break-glass verified |
| Everyone blocked after enabling | Policy enabled with a misconfigured grant | Use break-glass to set the policy back to **Report-only**; review the grant controls |

## B. "Require compliant device" blocks legitimate users
| Symptom | Cause | Remediation |
|---|---|---|
| Compliant-looking device blocked | Device not actually Compliant in Intune, or not Entra-registered | Run `CAI-Validation.ps1`; confirm Intune shows **Compliant**; fix compliance (DCP solution) |
| Browser blocked but app works | Device registration/SSO state differs per client | Ensure the device is Entra-registered/joined and the browser uses the work account |

## C. MFA issues
- Users repeatedly prompted → expected on new sessions; confirm "remember MFA"/sign-in frequency settings.
- Users with no method → enable authentication methods and have them register before enforcing.

## D. Legacy auth still working
- Block-legacy policy in Report-only → it only logs. Move to **On** to enforce.
- Some "modern-looking" clients still use legacy endpoints → confirm via sign-in logs **Client app** column.

## E. Report-only shows nothing
- No sign-ins yet for the targeted users/apps → have pilot users actually sign in; wait for logs to populate (a few minutes).

## F. Diagnostics quick reference
```powershell
dsregcmd /status        # device join/registration state (affects compliant-device control)
```
Entra → **Sign-in logs → (a sign-in) → Conditional Access / Report-only** tabs show exactly which
policies applied and why. The **What If** tool (Conditional Access → What If) simulates a sign-in.

## G. When to escalate
If a sign-in is blocked with all controls apparently satisfied (device Compliant, MFA passed) and
the Report-only/CA tabs are inconsistent, capture the sign-in correlation ID and open a Microsoft support case.


---


# 7. Best Practices — Conditional Access Integration

- **Create break-glass accounts first.** Two cloud-only Global Admins, excluded from every policy, passwords stored offline. This is the single most important safeguard against lockout.
- **Always pilot in Report-only.** Never enable a new policy straight to On — review the would-be impact in sign-in logs first.
- **Exclude break-glass from every policy.** Make it a checklist item on each policy you create.
- **Block legacy authentication.** It's the channel attackers use to bypass MFA — high value, low risk to enable.
- **Layer the controls.** Require MFA + require compliant device + block legacy auth together form a strong baseline.
- **Use the What If tool.** Simulate a user/app/condition before enabling to predict the outcome.
- **Roll out by waves.** Move from pilot group to all users gradually, watching sign-in logs.
- **Name policies clearly.** `CA - <control> - <scope>` so intent is obvious and audits are easy.
- **Monitor continuously.** Review sign-in logs and `CAI-SignInReport.ps1` for unexpected blocks after each change.
- **Pair with compliance.** "Require compliant device" is only as strong as your Device Compliance policy — deploy that solution alongside.


---


# 8. Deliverables Summary — Conditional Access Integration

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Conditional Access is, how it integrates with Intune, benefits, limitations |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — Report-only first, break-glass safety |
| 5. Testing Guide | Validation procedures with pass/fail gates |
| 6. Troubleshooting Guide | Field issues and lockout recovery |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `CAI-Discovery.ps1` | Local device/identity state: Entra join, registration, MFA-relevant facts |
| `CAI-Validation.ps1` | Confirms the device satisfies "require compliant/joined device" controls |
| `CAI-PolicyReport.ps1` | Lists Conditional Access policies and their state (Microsoft Graph) |
| `CAI-SignInReport.ps1` | Summarizes recent sign-ins and their CA results (Microsoft Graph) |
| `CAI-BreakGlassCheck.ps1` | Verifies break-glass accounts are excluded from all CA policies |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the repeatable model: **Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Zero Trust access enforcement — only healthy, authenticated devices and users get in — deployed
safely with break-glass accounts and Report-only piloting.
