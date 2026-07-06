# macOS Compliance & Conditional Access for Zero-Trust Access

> **Version 1.0.0** · Category: Intune · Solution code: MACCA

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — macOS Compliance & Conditional Access for Zero-Trust Access (Microsoft Intune)

**White-label · Intune Solutions**

A Mac shouldn't reach corporate resources just because someone has the password. Under **Zero Trust**,
access is earned by a device that proves it is healthy — encrypted, patched, firewalled, and free of
active threats. This solution builds the Mac-specific version of that gate: **macOS device compliance
signals in Microsoft Intune** wired to a named **Conditional Access policy in Microsoft Entra**, so
only trusted, compliant Macs get in.

This is a complete, **deploy-it-today** package written for an administrator with no prior macOS
compliance or Conditional Access experience — including the safety practices (Report-only piloting,
break-glass exclusions, grace periods) that let you enforce without locking anyone out.

## What you get
- A plain-language **Solution Overview** of how macOS compliance signals feed Conditional Access under
  Zero Trust.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps in the required order — build the named
  macOS compliance policy, map it to a Report-only CA policy, validate, then expand.
- Five **PowerShell scripts** for Mac/compliance discovery, pre-enforcement validation, an
  access-decision report, safe remediation, and rollout-group targeting.
- **Testing** and **Troubleshooting** guides for a confident, lockout-free rollout.

## What this delivers
A named macOS compliance policy — **FileVault encryption**, **minimum macOS version**, **firewall on**,
and **Microsoft Defender machine-risk** — mapped to a named Conditional Access policy that **requires a
compliant device** for Mac sign-ins, piloted in **Report-only** on a small group before enforcement,
with break-glass accounts excluded.

> Mac-focused by design. For the general Conditional Access baseline (MFA, block legacy auth,
> break-glass) across Windows and mobile, deploy the companion **Conditional Access Integration**
> solution alongside this one.

## The standard deployment model
**Assess → Configure → Pilot → Validate → Expand.**

## Outcome
Only compliant, trusted Macs reach corporate resources — compliance signals wired to Conditional
Access under Zero-Trust — proven on a pilot before you scale.


---


# 1. Solution Overview — macOS Compliance & Conditional Access for Zero-Trust Access

## The problem this solves
A Mac shouldn't reach corporate resources just because someone typed the right password. Under
**Zero Trust**, every access request is verified against **who** the user is *and* **what state
the device is in** — encrypted, patched, firewalled, and free of active threats. This solution
builds the Mac-specific half of that gate: **macOS device compliance signals in Microsoft Intune**
wired to a **named Conditional Access policy in Microsoft Entra**, so only trusted, compliant Macs
get in.

> This solution is **Mac-focused**. If you also run Windows and want the general Conditional Access
> baseline (require MFA, block legacy auth, break-glass accounts), deploy the separate **Conditional
> Access Integration** solution alongside it — this guide references those safety practices but does
> not re-teach them.

## The two halves and how they connect
1. **macOS device compliance (Intune).** A **compliance policy** evaluates each enrolled Mac against
   rules — disk encryption (FileVault), minimum macOS version, firewall on, and Microsoft Defender
   **machine-risk** below a chosen threshold — and marks the Mac **Compliant** or **Not compliant**.
2. **Conditional Access (Entra).** A **CA policy** with the grant control **Require device to be
   marked as compliant** consumes that signal. A compliant Mac is allowed; a non-compliant Mac is
   blocked (or challenged) when it tries to reach the targeted resources.

The Mac's compliance state is the bridge: Intune produces it, Entra enforces on it.

## The macOS compliance signals this delivers
| Signal | What it proves | Intune compliance setting |
|---|---|---|
| **FileVault / disk encryption** | Data at rest is protected if the Mac is lost or stolen | *Require FileVault* / *Encryption of data storage* |
| **Minimum macOS version** | The Mac is patched to a supported, non-vulnerable OS | *Minimum OS version* |
| **Firewall enabled** | The device rejects unsolicited inbound connections | *Firewall* (via macOS settings/compliance) |
| **Microsoft Defender machine risk** | No active/high-severity threat on the device | *Require the device to be at or under machine-risk score* (Defender for Endpoint connector) |

Each signal that a Mac fails flips it **Not compliant**, and the CA policy then denies access — Zero
Trust in action.

## How it works, end to end
1. A Mac is enrolled in Intune and receives the macOS **compliance policy**.
2. Intune evaluates the Mac against the four signals and reports **Compliant** / **Not compliant**.
3. A user on that Mac signs in to a protected resource (e.g. Outlook on the web).
4. Entra evaluates the **Conditional Access policy** — *Require device to be marked as compliant*.
5. **Compliant → allowed. Not compliant → blocked** (Zero Trust: no healthy device, no access).
6. During pilot, the CA policy runs in **Report-only** so you can see *what would happen* before it
   actually blocks anyone.

## Named objects this solution creates (and reuses)
You will build these exact objects and reuse them by name throughout the guide:
- **Compliance policy:** `macOS - Zero-Trust Compliance`
- **Conditional Access policy:** `CA - macOS - Require Compliant Device`
- **Pilot group (Entra security group):** `macOS-ZeroTrust-Pilot`
- **(Optional) exclusion group:** `macOS-ZeroTrust-Exclusions` (for break-glass / service exceptions)

## Benefits
- **Device-state enforcement for Macs** — access is gated on encryption, patch level, firewall, and
  threat state, not just a password.
- **Zero Trust, least privilege** — a Mac earns access only while it stays healthy.
- **Safe rollout** — Report-only mode plus a small pilot group means you validate before you block.
- **Auditable** — named policies and the included reports show exactly which Macs are compliant and
  which sign-ins were allowed or denied.

## Limitations (be honest with buyers)
- Conditional Access requires **Microsoft Entra ID P1**.
- The **Require compliant device** control depends on **this macOS compliance policy** being deployed
  and Macs being **Intune-enrolled and Entra-registered** first.
- The **Defender machine-risk** signal requires **Microsoft Defender for Endpoint on macOS** onboarded
  and the **Intune ↔ Defender connector** turned on (a companion prerequisite, flagged below).
- Available macOS compliance settings evolve; exact setting labels can differ slightly by Intune
  service version. Where a label may vary, this guide flags it — verify against the live console.
- A misconfigured CA policy can block legitimate users. That is why this solution pilots in
  **Report-only** on a small group and keeps break-glass/exclusion accounts out of scope.

## The standard deployment model
> **Assess → Configure → Pilot → Validate → Expand.**
> Build the compliance policy → map it to a Report-only CA policy on the pilot group → confirm
> compliant Macs are allowed and non-compliant Macs are (would-be) blocked → enable enforcement →
> expand to all Macs.


---


# 2. Requirements Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Verify **every** requirement before configuring. Each entry: **Description · Why · Verify ·
Implement-if-missing.** Category-wide prerequisites (Entra tenant, Intune subscription, admin roles,
network access, a pilot group) are in `global-requirements-intune-solutions.md` — confirm those first.

> Note: the category global requirements reference a *Windows* baseline (G6). For this solution that
> requirement is replaced by the **supported macOS baseline** in 2.4 below.

## 2.1 Microsoft Entra ID P1 licensing
**Description:** Microsoft Entra ID P1 (included with Microsoft 365 E3/E5 and Business Premium).
**Why:** Conditional Access is a P1 feature; without it you cannot create the CA policy that enforces
the compliance signal.
**Verify:** Microsoft 365 admin center → **Billing → Licenses** — a plan that includes Entra ID P1 is
assigned to the pilot users.
**Implement:** Assign Microsoft 365 E3/E5 or Business Premium to the targeted users.

## 2.2 Macs enrolled in Intune and Entra-registered
**Description:** The target Macs are enrolled in Microsoft Intune and appear as devices in Entra.
**Why:** A compliance policy only reaches enrolled Macs, and the **Require compliant device** control
only works if the Mac is registered in Entra so its compliance state can be read at sign-in.
**Verify:** Intune → **Devices → All devices** — the Mac appears with OS **macOS**; run
**`MACCA-Discovery.ps1`** to list enrolled Macs and their current compliance state.
**Implement:** Enroll Macs via **Automated Device Enrollment (ADE)** or the Company Portal /
user enrollment, so they become Intune-managed and Entra-registered.

## 2.3 Microsoft Defender for Endpoint on macOS (for the machine-risk signal)
**Description:** Defender for Endpoint deployed and onboarded on the Macs, with the **Intune ↔
Defender for Endpoint connector** enabled.
**Why:** The **machine-risk** compliance signal reads each Mac's Defender risk score; without the
connector, that signal cannot be evaluated and should be omitted.
**Verify:** Intune → **Endpoint security → Microsoft Defender for Endpoint** — the macOS connection
status is **Enabled** and *Connect macOS devices … to Microsoft Defender for Endpoint* is **On**.
**Implement:** Deploy Defender for Endpoint on macOS (companion **Defender for Endpoint (macOS)
onboarding** solution), then turn on the connector. *Flag: if you are not using Defender on Macs yet,
build the policy with the first three signals and add the machine-risk rule later.*

## 2.4 Supported macOS baseline
**Description:** Macs on a currently supported macOS version (a recent major release with security
updates).
**Why:** The **Minimum OS version** compliance rule assumes the fleet can meet a supported floor; set
the floor to a version your fleet can actually reach so you do not block healthy Macs.
**Verify:** On a Mac,  → **About This Mac**; or Intune → device → **Hardware → Operating system
version**. Run **`MACCA-Discovery.ps1`** to see the OS-version spread across enrolled Macs.
**Implement:** Update Macs to a supported release (e.g. via an Intune macOS **update policy** or the
built-in Software Update) before setting a high minimum-version floor.

## 2.5 FileVault posture (encryption signal)
**Description:** Macs can have FileVault enabled (either already on, or enforced via an Intune
disk-encryption policy).
**Why:** The encryption compliance rule marks a Mac non-compliant if FileVault is off; if you have no
way to turn it on, users will be blocked with no path to remediate.
**Verify:** Intune → **Endpoint security → Disk encryption** — a FileVault policy exists/targets the
Macs; or **`MACCA-Discovery.ps1`** reports encryption state.
**Implement:** Create an Intune **Disk encryption (FileVault)** policy so Macs can become — and stay —
encrypted, then apply the compliance rule.

## 2.6 Pilot Entra security group
**Description:** A Microsoft Entra security group for the pilot Macs/users, named
`macOS-ZeroTrust-Pilot`.
**Why:** Both the compliance policy and the CA policy are targeted at the pilot first, never the whole
fleet.
**Verify:** Entra → **Groups** — `macOS-ZeroTrust-Pilot` exists; or use
**`MACCA-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to preview membership.
**Implement:** Entra → **Groups → New group → Security** → `macOS-ZeroTrust-Pilot` → add pilot
members. **`MACCA-Set-ScopeTargeting.ps1`** can build this membership from your Mac inventory.

## 2.7 Sign-in log / reporting access
**Description:** The operator can read Entra sign-in logs and Conditional Access results.
**Why:** Report-only impact and allow/block decisions are reviewed in the sign-in logs before and
after enforcement.
**Verify:** Entra → **Monitoring → Sign-in logs** loads and shows a **Report-only** / **Conditional
Access** tab on a sign-in.
**Implement:** Grant the operator **Security Reader** or **Reports Reader** in Entra.

## 2.8 Break-glass / exclusion accounts (lockout safety)
**Description:** Emergency-access accounts (and any needed service exceptions) that are **excluded**
from the CA policy.
**Why:** A device-based CA policy *can* block people; break-glass accounts guarantee you can always
get back in.
**Verify:** Entra → **Users** — dedicated emergency accounts exist and are excluded from CA policies.
**Implement:** Follow the **Conditional Access Integration** solution's break-glass guidance (two
cloud-only Global Admins with offline passwords), and exclude them from
`CA - macOS - Require Compliant Device`.

---
## Checklist
- [ ] Entra ID P1 licensing assigned to pilot users
- [ ] Target Macs enrolled in Intune and Entra-registered — `MACCA-Discovery.ps1`
- [ ] Defender for Endpoint (macOS) + connector enabled *(or plan to add the machine-risk rule later)*
- [ ] Supported macOS baseline achievable across the pilot Macs
- [ ] FileVault can be enabled (disk-encryption policy in place)
- [ ] `macOS-ZeroTrust-Pilot` security group created
- [ ] Sign-in log / Report-only access for the operator
- [ ] Break-glass / exclusion accounts identified and excluded from the CA policy


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


# 3. Implementation Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Follow these steps **in order**. You work in two consoles:
- **Intune admin center** — `https://intune.microsoft.com` (the macOS compliance policy).
- **Microsoft Entra admin center** — `https://entra.microsoft.com` → **Protection → Conditional
  Access** (the CA policy).

> **Model:** Build compliance → create the CA policy in **Report-only** on the pilot → review →
> enable → expand. **Never** point a new device-based CA policy straight at all users.

Objects you will create and reuse by name:
`macOS - Zero-Trust Compliance` (compliance policy) · `CA - macOS - Require Compliant Device`
(CA policy) · `macOS-ZeroTrust-Pilot` (pilot group) · `macOS-ZeroTrust-Exclusions` (optional).

---

## Step 1 — Confirm the pilot group exists
1. Entra → **Groups**. Confirm **`macOS-ZeroTrust-Pilot`** exists (from Requirements 2.6). If not,
   **New group → Security →** name it `macOS-ZeroTrust-Pilot` → add the pilot Macs/users → **Create**.
2. *(Optional)* Create **`macOS-ZeroTrust-Exclusions`** the same way for any service/exception accounts
   you will exclude from the CA policy alongside your break-glass accounts.

## Step 2 — (Optional) Confirm the Defender connector for the machine-risk signal
1. Intune → **Endpoint security → Microsoft Defender for Endpoint**.
2. Confirm **Connection status: Enabled** and **Connect macOS devices … to Microsoft Defender for
   Endpoint** is **On**.
3. If Defender on macOS is not in place yet, **skip the machine-risk rule** in Step 3.6 and add it
   later — the other three signals still deliver a strong Zero-Trust gate.

## Step 3 — Create the macOS compliance policy `macOS - Zero-Trust Compliance`
1. Intune → **Devices → Compliance** (Compliance policies) → **+ Create policy**.
2. **Platform:** **macOS**. Click **Create**.
3. **Name:** `macOS - Zero-Trust Compliance`. **Description:** *Zero-Trust device health for Macs —
   encryption, OS, firewall, Defender risk.* → **Next**.
4. **Compliance settings → Device Health / System Security:**
   - **Firewall** → **Require** (or **Enable** — the label may read *Firewall* under System Security).
     *Flag: exact grouping of the firewall setting can vary by Intune version; if you don't see it
     under Device Health, look under **System Security**.*
5. **Encryption:**
   - **Require encryption of data storage on device** → **Require** (this is FileVault on macOS).
6. **System Security → Operating system version:**
   - **Minimum OS version** → set a floor your fleet can meet (e.g. a current supported major
     release). *Flag: choose a version verified reachable via `MACCA-Discovery.ps1` — too high a
     floor blocks healthy Macs.*
7. **Microsoft Defender for Endpoint (machine risk)** — *only if Step 2 connector is On:*
   - **Require the device to be at or under the machine-risk score** → choose **Medium** (blocks
     High risk) to start; you can tighten to **Low** later.
8. **Actions for noncompliance** → keep the default **Mark device noncompliant** but set it to a
   **grace period** (e.g. *Immediately* for pilot, then a few days for production — see Best
   Practices) so users get a warning window before being blocked. Optionally add **Send email to end
   user**. → **Next**.
9. **Scope tags** → default → **Next**.
10. **Assignments → Included groups → Add groups →** select **`macOS-ZeroTrust-Pilot`**. → **Next**.
11. **Review + create** → **Create**. The policy `macOS - Zero-Trust Compliance` now evaluates the
    pilot Macs.

## Step 4 — Let compliance evaluate, then confirm signals
1. Give the pilot Macs time to sync (Company Portal → **check status**, or wait for the sync cycle).
2. Intune → **Devices → Compliance → `macOS - Zero-Trust Compliance` → Device status** — confirm pilot
   Macs report **Compliant** (or see exactly which signal fails).
3. Run **`MACCA-Validation.ps1`** to confirm the pilot Macs are **Compliant** and Entra-registered —
   the two facts the CA policy depends on.

## Step 5 — Create the Conditional Access policy in Report-only
1. Entra → **Protection → Conditional Access → + Create new policy**.
2. **Name:** `CA - macOS - Require Compliant Device`.
3. **Users:** **Include → Select users and groups →** `macOS-ZeroTrust-Pilot`.
   **Exclude →** your **break-glass** accounts (and `macOS-ZeroTrust-Exclusions` if used). *Never omit
   the break-glass exclusion.*
4. **Target resources:** **Cloud apps →** select **Office 365** (start here; broaden later).
5. **Conditions → Device platforms → Configure = Yes → Include → Select device platforms → macOS.**
   This scopes the policy to Macs so it never affects Windows/mobile sign-ins.
6. **Grant:** **Grant access → Require device to be marked as compliant.** Leave **Require all the
   selected controls** selected. **Select**.
7. **Enable policy:** **Report-only**. Click **Create**.

## Step 6 — Review Report-only impact
1. Have pilot users sign in normally from their Macs for a day or two.
2. Entra → **Monitoring → Sign-in logs →** open a pilot sign-in → **Report-only** tab — confirm
   `CA - macOS - Require Compliant Device` shows a result (*would apply / satisfied / would block*).
3. Run **`MACCA-Report.ps1`** to summarize, per Mac, the **compliance state** and the **would-be
   access decision**. Resolve any unexpected would-blocks (usually a failing signal — see
   Troubleshooting).

## Step 7 — Prove a non-compliant Mac would be blocked
1. On a **pilot test Mac**, deliberately fail one signal (e.g. turn FileVault off on a spare test
   device, or let it drop below the OS floor). Wait for Intune to mark it **Not compliant**.
2. Sign in from that Mac and check the **Report-only** tab — the policy should read **would block**.
3. Confirm with **`MACCA-Report.ps1`** that the non-compliant Mac maps to a **deny** decision.
   *(Re-enable the signal afterward so the test Mac returns to Compliant.)*

## Step 8 — Enable enforcement
1. Re-run **`MACCA-Validation.ps1`** and confirm **break-glass accounts are excluded** from
   `CA - macOS - Require Compliant Device`.
2. Edit the CA policy → **Enable policy → On** → **Save**.
3. Verify pilot users on compliant Macs still work, and that the earlier non-compliant test Mac is now
   actually **blocked** (not just "would block").

## Step 9 — Expand to all Macs
1. Broaden the **compliance policy** assignment (Step 3.10) from `macOS-ZeroTrust-Pilot` to your
   all-Macs group, in waves. Use **`MACCA-Set-ScopeTargeting.ps1`** (default `-WhatIf`) to preview the
   membership change before applying it.
2. Broaden the **CA policy** **Users** (Step 5.3) to the all-Macs group, keeping break-glass/exclusion
   accounts excluded. Optionally widen **Target resources** from Office 365 to **All cloud apps**.
3. Monitor each wave with **`MACCA-Report.ps1`**; keep the grace period generous until the fleet
   settles (Best Practices).

---
### Order of operations
`Pilot group → (Defender connector) → Compliance policy → evaluate → CA policy (Report-only) →
review → prove non-compliant blocked → enable On → expand in waves`


---


# 5. Testing Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Run these during Report-only (Implementation Step 6) and again after enabling enforcement (Step 8).
Core proof: **compliant Mac → allowed; non-compliant Mac → denied.**

## Test 1 — Compliance policy evaluates each signal
**Do:** Intune → **Devices → Compliance → `macOS - Zero-Trust Compliance` → Device status**. Run
**`MACCA-Validation.ps1`**.
**Expected:** Pilot Macs show **Compliant**, or the exact failing signal (encryption / OS / firewall /
machine-risk) is named.

## Test 2 — CA policy evaluates in Report-only
**Do:** Entra → **Monitoring → Sign-in logs →** open a pilot Mac sign-in → **Report-only** tab.
**Expected:** `CA - macOS - Require Compliant Device` shows a result — proving the policy evaluates
macOS sign-ins.

## Test 3 — Compliant Mac is allowed
**Do:** From a **Compliant** pilot Mac, sign in to `https://outlook.office.com`. Run
**`MACCA-Report.ps1`**.
**Expected:** Access granted; the report maps this Mac to **Compliant → allow**.

## Test 4 — Non-compliant Mac is denied
**Do:** On a test Mac, fail one signal (FileVault off, below the OS floor, firewall off, or elevated
Defender risk). After Intune marks it **Not compliant**, attempt the same sign-in.
**Expected:** Report-only logs **would block**; after enforcement the sign-in is **blocked**.
`MACCA-Report.ps1` maps this Mac to **Not compliant → deny**.

## Test 5 — Each signal independently trips compliance
**Do:** One at a time on a test Mac: disable FileVault; drop below the OS floor; disable the firewall;
(if Defender in use) raise machine risk.
**Expected:** Each single failure flips the Mac **Not compliant** on its own — confirming all four
signals are wired in, not just one.

## Test 6 — Policy scoping is macOS-only
**Do:** From a Windows or mobile device (same pilot user), sign in to the same resource.
**Expected:** `CA - macOS - Require Compliant Device` does **not** apply (Device platforms = macOS) —
proving this policy touches only Macs.

## Test 7 — Break-glass / exclusions are exempt
**Do:** Sign in with a break-glass account (or an account in `macOS-ZeroTrust-Exclusions`).
**Expected:** The macOS compliant-device policy does **not** apply — the account is excluded and is
never locked out.

## Test 8 — Grace period behaves as configured
**Do:** With a grace period set, make a Compliant Mac non-compliant and watch the status over the
grace window.
**Expected:** The Mac shows **In grace period** (still allowed) until the window expires, then flips to
**Not compliant** and is blocked — confirming users get a warning window, not an instant lockout.

## Test 9 — Access-decision report
**Do:** Run **`MACCA-Report.ps1`** across the pilot.
**Expected:** A clear per-Mac list of compliance state and allow/deny decision, with counts — the
artifact you use to sign off each rollout wave.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass (Report-only)** | Tests 1–7 behave as expected; compliant Macs would be allowed, non-compliant would be blocked, **no unexpected** would-blocks for healthy Macs |
| **Enforcement pass** | After enabling On: compliant Macs work, a non-compliant Mac is actually blocked, break-glass verified, grace period behaves (Test 8), no unintended lockouts |


---


# 6. Troubleshooting Guide — macOS Compliance & Conditional Access for Zero-Trust Access

Use **`MACCA-Report.ps1`** to see, per Mac, the compliance state and access decision;
**`MACCA-Validation.ps1`** before any enforcement change; and Entra → **Sign-in logs → (a sign-in) →
Report-only / Conditional Access** tabs to see exactly which policy applied and why.

## A. Lockout risk / users blocked unexpectedly
| Symptom | Cause | Remediation |
|---|---|---|
| Legitimate Mac user blocked | The Mac is **Not compliant** (a signal failed) | Run `MACCA-Report.ps1`; fix the failing signal (below); confirm Intune shows **Compliant** |
| Admin/service account blocked | Break-glass / exception not excluded from the CA policy | Sign in with a **break-glass** account; add the exclusion to `CA - macOS - Require Compliant Device`; re-verify with `MACCA-Validation.ps1` |
| Whole pilot blocked after enabling On | Policy enabled before Report-only was clean | Use break-glass to set `CA - macOS - Require Compliant Device` back to **Report-only**; resolve would-blocks, then re-enable |

## B. A specific compliance signal is failing
| Signal | Typical cause | Remediation |
|---|---|---|
| **Encryption / FileVault** | FileVault off, or key escrow not complete | Ensure the Intune **Disk encryption (FileVault)** policy targets the Mac; have the user enable FileVault; wait for re-evaluation |
| **Minimum OS version** | Mac below the floor you set | Lower the floor to what the fleet can reach *or* update the Mac (Software Update / update policy); confirm with `MACCA-Discovery.ps1` |
| **Firewall** | macOS firewall disabled | Enable the firewall (or deploy a settings policy that does); re-sync |
| **Machine risk (Defender)** | Active/high-severity detection, or connector off | Resolve the Defender alert on the device; confirm the **Intune ↔ Defender** connector is **Enabled**; if Defender isn't deployed, remove the machine-risk rule until it is |

## C. Compliance state not updating
- The Mac hasn't synced → Company Portal → **check status**, or wait for the next sync cycle; then
  re-run `MACCA-Report.ps1`.
- Policy not assigned → confirm `macOS - Zero-Trust Compliance` targets a group the Mac is in
  (`MACCA-Set-ScopeTargeting.ps1 -WhatIf` previews membership).

## D. CA policy isn't applying to Macs
- **Device platforms** not set to macOS, or set to something else → confirm **Conditions → Device
  platforms → macOS** on `CA - macOS - Require Compliant Device`.
- Wrong target resource → the user's app isn't in the policy's **Target resources** (you scoped to
  Office 365) → widen resources or test against Office 365.
- Policy still in **Report-only** → it only logs; move **Enable policy → On** to enforce.

## E. "Require compliant device" blocks a device that looks compliant
- Intune shows **Compliant** but Entra still blocks → the Mac may not be **Entra-registered**, so
  Entra can't read its state → run `MACCA-Validation.ps1`; re-register/re-enroll the Mac.
- Compliance changed very recently → allow time to propagate to Entra; re-test.

## F. Report-only shows nothing
- No pilot sign-ins yet for the targeted resource → have pilot users actually sign in from their Macs;
  wait a few minutes for logs to populate.

## G. Diagnostics quick reference
- **Intune → Devices → Compliance → `macOS - Zero-Trust Compliance` → Device status** — per-Mac,
  per-signal pass/fail.
- **Entra → Conditional Access → What If** — simulate a macOS sign-in to predict the outcome before
  enforcing.
- **`MACCA-Report.ps1`** — the single artifact tying compliance state to the access decision.

## H. When to escalate
If a Mac is Intune-**Compliant** and Entra-registered but sign-in is still blocked with the
Report-only / Conditional Access tabs inconsistent, capture the sign-in **correlation ID** and open a
Microsoft support case.


---


# 7. Best Practices — macOS Compliance & Conditional Access for Zero-Trust Access

## Grace & rollout safety
- **Use a compliance grace period.** Set **Actions for noncompliance → Mark device noncompliant** to
  fire after a **grace window** (e.g. a few days) rather than immediately, so a Mac that briefly fails
  a signal gets a warning before access is cut. Start tighter in pilot, more generous during fleet
  expansion, then tighten once stable.
- **Send the noncompliance email.** Add **Send email to end user** so people know *why* they're about
  to be blocked and how to fix it — this dramatically reduces help-desk load at cutover.
- **Always pilot the CA policy in Report-only.** Never enable `CA - macOS - Require Compliant Device`
  straight to On — review the would-be impact in sign-in logs first.
- **Prove the block before you enforce.** Deliberately make one test Mac non-compliant and confirm the
  Report-only "would block" *before* flipping enforcement On.

## Zero-Trust rollout
- **Start narrow, expand in waves.** Pilot group → wave 1 → wave 2 → all Macs. Validate each wave with
  `MACCA-Report.ps1` before widening.
- **Start with Office 365, then broaden resources.** Scope the CA policy to **Office 365** first;
  expand to **All cloud apps** only after the compliant-device gate is proven stable.
- **Keep the policy macOS-scoped.** Leave **Conditions → Device platforms = macOS** so this policy
  never surprises Windows or mobile sign-ins — pair it with the general Conditional Access solution
  for those.
- **Layer signals, don't rush them.** If Defender on macOS isn't ready, ship the encryption + OS +
  firewall gate now and add the **machine-risk** rule when the connector is on. Tighten the risk
  threshold (Medium → Low) only after the fleet is clean.
- **Set a reachable OS floor.** Base **Minimum OS version** on what `MACCA-Discovery.ps1` shows your
  fleet can actually run; raise it as you patch, not before.

## Safety & hygiene
- **Break-glass first, excluded always.** Keep emergency-access accounts (from the Conditional Access
  Integration solution) excluded from this policy; re-verify the exclusion before every enforcement
  change with `MACCA-Validation.ps1`.
- **Name objects clearly.** `macOS - Zero-Trust Compliance`, `CA - macOS - Require Compliant Device`,
  `macOS-ZeroTrust-Pilot` — consistent names make audits and handovers trivial.
- **Ensure a remediation path exists.** Before requiring a signal, make sure users *can* satisfy it —
  a FileVault disk-encryption policy, an OS-update policy, firewall configuration — so "non-compliant"
  is always fixable, never a dead end.
- **Monitor continuously.** Review sign-in logs and `MACCA-Report.ps1` after every change; watch for
  unexpected denies for legitimate Macs.
- **Use `-WhatIf` first.** Run `MACCA-Remediation.ps1` and `MACCA-Set-ScopeTargeting.ps1` in their
  default `-WhatIf` mode and read the preview before committing any change.


---


# 8. Deliverables Summary — macOS Compliance & Conditional Access for Zero-Trust Access

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | macOS compliance signals → Conditional Access; the Zero-Trust model for Macs |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing |
| Global Requirements (Intune Solutions) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps — build compliance, map to a Report-only CA policy, validate, expand |
| 5. Testing Guide | Validation procedures with pass/fail gates (compliant → allowed; non-compliant → denied) |
| 6. Troubleshooting Guide | Field issues, failing signals, and lockout recovery |
| 7. Best Practices | Grace periods and safe Zero-Trust rollout |

## PowerShell scripts
| Script | What it does |
|---|---|
| `MACCA-Discovery.ps1` | Inventories enrolled Macs and their macOS compliance policies + CA policies (Microsoft Graph, read-only) |
| `MACCA-Validation.ps1` | Confirms pilot Macs are Compliant + Entra-registered and break-glass accounts are excluded — the pre-enforcement check |
| `MACCA-Report.ps1` | Per-Mac compliance state mapped to the would-be / actual access decision (allow/deny) |
| `MACCA-Remediation.ps1` | Safe, `-WhatIf`-by-default fixes for common compliance gaps (e.g. re-sync, re-target a Mac) |
| `MACCA-Set-ScopeTargeting.ps1` | Builds/updates the pilot & rollout group membership from the Mac inventory (`-WhatIf` by default) |

## What the buyer receives
- This implementation guide as a branded **Word** document and **PDF**.
- All five **PowerShell scripts** in a single ZIP.
- A repeatable process following the standard model: **Assess → Configure → Pilot → Validate → Expand.**

## Named objects this solution creates
- Compliance policy: **`macOS - Zero-Trust Compliance`**
- Conditional Access policy: **`CA - macOS - Require Compliant Device`**
- Pilot group: **`macOS-ZeroTrust-Pilot`** (optional exclusions group `macOS-ZeroTrust-Exclusions`)

## Outcome
Only compliant, trusted Macs reach corporate resources — Mac-specific compliance signals (encryption,
OS version, firewall, Defender risk) wired to a named Conditional Access policy under Zero-Trust —
proven on a pilot in Report-only before you scale.
