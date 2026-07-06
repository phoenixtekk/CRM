# macOS BYOD Management — Account-Driven User Enrollment, App Protection & Conditional Access

> **Version 1.0.0** · Category: Intune · Solution code: MACBYOD

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Your people use their **own** Macs to reach company email, files, and apps. You need that data
protected — but you don't own the device, and heavy-handed management will (rightly) be rejected. This
solution builds a **macOS BYOD strategy** in **Microsoft Intune** and **Microsoft Entra ID** that gets
the balance right: **the lightest management footprint that still protects data, and an access gate that
turns away anything unmanaged or unhealthy.**

It is written so a single administrator can follow it end to end:

- **Right-sized enrollment.** We standardize on Apple's **account-driven user enrollment** — the user
  signs in with their Entra ID and macOS creates a **managed Apple Account** and an **isolated managed
  volume**. Corporate apps and data are protected there; the user's personal apps, data, and Apple ID are
  never touched. We also document the two alternatives (full **device enrollment**, and **unmanaged +
  Conditional Access**) so you choose the model deliberately.
- **Access gated on device health.** A named **Conditional Access** policy —
  `CA - Require Compliant Mac - Pilot` — allows Microsoft 365 access only from a **compliant, enrolled**
  Mac, and blocks the rest. Deployed **report-only first**, with break-glass accounts excluded, so no
  one gets locked out.
- **An honest app-protection model.** The most expensive mistake in macOS BYOD is assuming Intune **App
  Protection Policies (MAM)** work like they do on iOS/Android. **They do not** — there is no iOS-style
  per-app container for arbitrary Mac apps. On macOS, corporate-data protection comes from **MDM scope +
  compliance + Conditional Access**. We state this plainly and build the protection the way macOS
  actually supports it.

The package follows the standard repeatable shape — **Assess → Configure → Pilot → Validate → Expand** —
with exact, click-by-click Intune and Entra steps, a requirements guide that tells you how to verify
*and* fix each prerequisite, five ready-to-run PowerShell scripts (Microsoft Graph; discovery/validation/
report are read-only, remediation/scope-targeting default to `-WhatIf`), and testing/troubleshooting
guides with clear pass/fail gates.

**Outcome:** company data protected on personal Macs — the right enrollment model and a Conditional
Access gate, without over-managing the user's device — proven on a pilot before you scale, delivered by
your own team without a consulting engagement.


---


# 1. Solution Overview — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

## What this solution is
Your people want to reach company email, files, and apps from their **own** Macs. You need that
data protected without seizing control of a device you don't own. This solution builds a
**macOS BYOD (Bring-Your-Own-Device) strategy** in **Microsoft Intune** and **Microsoft Entra ID**
that does three things, in the right order:

1. **Enroll personal Macs with the lightest footprint that still gives you control** — Apple's
   **account-driven user enrollment**, which manages a *managed Apple Account* and corporate apps/data
   on the Mac while leaving the user's personal apps, data, and identity untouched.
2. **Gate access on device state** — a named **Conditional Access** policy that only lets a Mac reach
   Microsoft 365 when it is **compliant** (and enrolled), so an unmanaged or unhealthy Mac is turned away.
3. **Tell the honest truth about "app protection" on macOS** — because the biggest mistake buyers make
   here is assuming macOS works like iOS/Android. It does not (see the honest note below).

The result: company data is protected on non-corporate Macs, using the right enrollment model and a
compliance gate — deployed pilot-first and rollback-ready — **without over-managing the user's device**.

## The honest macOS app-protection note (read this first)
On **iOS and Android**, Intune **App Protection Policies (APP / "MAM")** can protect corporate data
*inside* individual apps (Outlook, Teams, Edge) — encryption, copy/paste limits, a PIN, and selective
wipe of company data — **without enrolling the device at all**. It is tempting to assume the same is
available for BYOD Macs. **It is not.**

- **Intune App Protection Policies do NOT cover macOS apps the way they do iOS/Android.** There is no
  equivalent per-app "MAM without enrollment" containerization for arbitrary Mac apps. The APP policy
  types you see for iOS/Android are not the macOS story.
- On **macOS**, corporate-data protection comes from a **different place**: the device being **enrolled
  and in scope for MDM** (so you can push configuration, encryption, and compliance signals) **plus
  Conditional Access** (so only a compliant/enrolled Mac is allowed to reach the data in the first place).
- In practical terms: **the protection boundary on a BYOD Mac is the enrollment + compliance +
  Conditional Access combination, not an iOS-style in-app container.** If you need data protected on a
  Mac, the Mac must be **enrolled** and **compliant**, and access must be **gated**.

Everywhere this guide says "protect company data on a personal Mac," that is what it means. We will not
overclaim macOS MAM, and neither should your internal messaging to users.

## The three BYOD models for Macs (choose deliberately)
There is no single "BYOD" setting — there are three postures, each with a different management
footprint and a different protection story. Pick per your risk appetite; this solution **standardizes
on account-driven user enrollment** as the default, with the other two documented so you choose with
eyes open.

### Model A — Account-driven **user enrollment** (this solution's default)
- **What it is:** The user opens **Settings → (their name area) → Sign in to Work or School account**
  and signs in with their **Entra ID**. macOS creates a **managed Apple Account** and a **separate,
  cryptographically isolated APFS volume** for managed data; corporate apps and data live there,
  personal data stays personal.
- **Footprint:** **Light.** No supervision, no device serial required, no wipe of the whole Mac —
  only the **managed** data can be removed. Users keep their personal Apple ID and privacy.
- **What you get:** MDM management of the *corporate* scope, a compliance signal, and Entra device
  registration — enough to drive **Conditional Access**.
- **Best for:** Personal Macs where you want data protected and access gated, but must respect that
  the device is the user's own.

### Model B — **Device enrollment** (BYOD, but fuller management)
- **What it is:** The user enrolls the whole Mac via the **Company Portal** app (Intune's standard
  macOS device enrollment). The **entire device** comes under MDM.
- **Footprint:** **Heavier.** You manage the whole Mac (not just a corporate volume). It is *not*
  supervised (that requires company ownership / ADE), but you can push broader configuration and, if
  needed, wipe the device.
- **Best for:** Personal Macs where the user accepts fuller management in exchange for full access —
  or where user enrollment's constraints don't fit. More footprint than most BYOD users will accept.

### Model C — **Unmanaged + Conditional Access only** (no enrollment)
- **What it is:** The Mac is **not enrolled** at all. You lean on **Conditional Access** (e.g. require
  MFA, or restrict to browser-only sessions with app-enforced restrictions) to limit what an unmanaged
  Mac can do.
- **Footprint:** **None on the device** — but also **no device-health signal**, so you cannot require
  *compliance* (there's nothing reporting it). Protection is limited to identity-layer controls.
- **Best for:** Low-risk access, contractors, or a stopgap. **Cannot** satisfy a "require compliant
  device" policy, because an unmanaged Mac has no compliance state.

> **This solution builds Model A** (account-driven user enrollment) and gates it with Conditional
> Access requiring **compliant** (and enrolled) Macs. Model C is covered so you understand what you
> give up by *not* enrolling; Model B is the fallback when user enrollment doesn't fit.

## How account-driven user enrollment works (Model A, step by step)
1. **Tenant readiness.** macOS enrollment is allowed, and account-driven **user** enrollment is enabled
   as the platform's enrollment type (Implementation §Phase 1). You do **not** need Apple Business
   Manager for this model — it is identity-driven, not device-serial-driven.
2. **User initiates from the Mac.** In **System Settings**, the user adds their **Work or School
   account** (their Entra ID). This is user-initiated by design — you are not seizing the device.
3. **Managed Apple Account + isolated volume.** macOS provisions a **managed Apple Account** and a
   **separate managed APFS volume**. Corporate apps/data are placed there; personal data is not touched.
4. **MDM applies the corporate scope.** Intune pushes the configuration and compliance policy scoped to
   BYOD, and the Mac reports a **compliance state**. The Mac registers with **Entra ID** as a device.
5. **Conditional Access gates access.** Your named CA policy checks: is this Mac **compliant** (and
   enrolled)? If yes, access to Microsoft 365 is allowed; if no, it is blocked or challenged.
6. **Un-enrollment = selective removal.** When the user removes the work account (or you retire it),
   only the **managed** volume/data is removed — the personal Mac stays intact.

## Benefits
- **Least footprint that still protects data** — manage the corporate scope, not the user's whole Mac.
- **Access gated on device health** — Conditional Access allows only compliant, enrolled Macs.
- **Privacy-respecting** — personal apps, data, and Apple ID stay the user's; only managed data is
  ever removed.
- **No Apple Business Manager required** for the user-enrollment model — identity-driven onboarding.
- **Honest, defensible model** — you protect data the way macOS actually supports it, not with an
  iOS-style promise you can't keep.
- **Pilot-first and rollback-ready** — every step is scoped to a pilot group and reversible.

## Limitations (be honest with buyers)
- **No iOS-style app protection on macOS.** As above — protection is enrollment + compliance +
  Conditional Access, **not** per-app MAM containers for arbitrary Mac apps.
- **Account-driven user enrollment requires a recent macOS.** Account-driven **user** enrollment is a
  modern macOS capability; older Macs may only support device enrollment (Model B). Confirm your OS
  floor in Requirements (R-OS) and flag anything below it rather than assuming.
- **User-initiated by design.** You cannot silently push user enrollment onto a personal Mac — the
  user adds the work account. Your rollout must include user communication.
- **Unmanaged Macs can't be "compliant."** If you choose Model C, a require-compliance CA policy will
  block those Macs — that is expected, not a bug.
- **Conditional Access can lock people out if misconfigured.** Always deploy CA in **report-only**
  first, with break-glass accounts excluded (Best Practices).

## The standard deployment model
This solution uses **one** primary model so the process is repeatable across our catalog:

> **Personal (BYOD) Macs onboarded with account-driven user enrollment into Microsoft Intune, scoped
> to a BYOD compliance policy, and gated by a named Conditional Access policy that requires a compliant
> (enrolled) Mac — piloted, validated, then expanded.**

Every step follows the repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to macOS BYOD
account-driven user enrollment and the Conditional Access gate.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and
Microsoft Entra at `https://entra.microsoft.com` unless noted.

## R1. Microsoft Intune with macOS enrollment allowed
**Description:** An Intune-licensed tenant where the **macOS** platform is permitted to enroll.
**Why:** An enrollment restriction that blocks macOS will silently stop BYOD Macs from onboarding.
**Verify:** Intune → **Devices → Enrollment → Enrollment device platform restrictions → macOS** shows
**Personally owned devices = Allow**.
**Implement:** Edit the default (or a pilot-targeted) restriction to **Allow** macOS personally owned
devices for the pilot group.

## R2. Account-driven user enrollment supported OS floor
**Description:** Target Macs run a macOS version that supports **account-driven user enrollment**.
**Why:** Account-driven **user** enrollment is a modern macOS capability; older Macs may only support
device enrollment (Model B). Do not assume — confirm and flag anything below the floor.
**Verify:** On the Mac, **Apple menu → About This Mac**; or after onboarding, Intune → device →
**Hardware**. *Uncertain about the exact minimum for your fleet? Flag it and confirm against Microsoft's
current macOS enrollment documentation rather than guessing — the floor has moved across macOS releases.*
**Implement:** Update the Mac via **System Settings → General → Software Update**, or set a
minimum-OS **compliance policy** so Macs below the floor are flagged. Where a Mac cannot meet the floor,
fall back to **device enrollment** (Overview, Model B).

## R3. Managed Apple Account capability (Apple identity for user enrollment)
**Description:** The tenant/domain can issue or federate a **managed Apple Account** used by
account-driven user enrollment for the corporate scope.
**Why:** Account-driven user enrollment provisions a **managed Apple Account** and an isolated managed
volume; the user's **personal** Apple ID is left alone. Without a managed Apple Account path, the
corporate scope cannot be established.
**Verify:** Confirm your organization's managed Apple Account approach (federated with Entra, or issued)
is in place for the pilot users. *If you are unsure whether managed Apple Accounts are configured for
your org, flag it and confirm before piloting — do not invent a state that isn't there.*
**Implement:** Establish managed Apple Accounts per Apple's current guidance (federation with Microsoft
Entra ID is the common path). Coordinate with whoever owns your Apple identity relationship.

## R4. macOS BYOD compliance policy (scoped to the pilot)
**Description:** An Intune **compliance policy** for macOS defining what "healthy enough for access"
means for BYOD (e.g. minimum OS, disk encryption where applicable, no jailbreak/gatekeeper issues).
**Why:** Conditional Access can only require a **compliant** Mac if a compliance policy exists and is
**assigned** to the Mac. No policy → no compliance signal → the CA gate cannot use it.
**Verify:** Intune → **Devices → Compliance policies**; a macOS policy named **`macOS BYOD Compliance -
Pilot`** exists and is assigned to your pilot group.
**Implement:** Create it during deployment (Implementation §Phase 2), or start from the settings there
and assign it to **`BYOD-Mac-Pilot`**.

## R5. Conditional Access capability (Entra ID P1 or higher)
**Description:** A licensing plan that includes **Conditional Access** (Entra ID P1, included in
Microsoft 365 E3/E5 and Business Premium).
**Why:** The access gate — "require a compliant/enrolled Mac" — is a Conditional Access policy.
**Verify:** Entra → **Protection → Conditional Access** loads and lets you create policies; **Entra →
Overview → Licenses** shows a P1 (or higher) plan.
**Implement:** Assign an Entra ID P1-bearing license (E3/E5/Business Premium) to the admins and the
pilot users in scope.

## R6. Break-glass (emergency access) accounts
**Description:** Two cloud-only **emergency access** accounts excluded from Conditional Access.
**Why:** A misconfigured CA policy can lock **everyone** out. Break-glass accounts are your way back in.
**Verify:** Entra → **Users**; two dedicated emergency accounts exist and are **excluded** from all
CA policies (Entra → Protection → Conditional Access → each policy → Users → Exclude).
**Implement:** Create two cloud-only accounts (long random passwords, stored securely, MFA per Microsoft
guidance), and **exclude** them from every CA policy before you enable any policy.

## R7. Pilot user identities and their personal Macs
**Description:** A small set of **pilot users** who will onboard their **own** Macs, and a Microsoft
Entra security group named **`BYOD-Mac-Pilot`** containing them.
**Why:** Account-driven user enrollment is **user-initiated**; you need willing pilot users who will add
their work account on a real personal Mac to validate the end-to-end experience.
**Verify:** Entra → **Groups → `BYOD-Mac-Pilot`** exists with the pilot users as members.
**Implement:** Entra → **Groups → New group → Security**, name it **`BYOD-Mac-Pilot`**, add the pilot
users. (This is the category Global Requirement G5, named for this solution.)

## R8. User communication / consent for BYOD
**Description:** A short user-facing message explaining what account-driven user enrollment does and
does **not** do to a personal Mac.
**Why:** BYOD only works if users trust it. They must understand the corporate scope is isolated and
only managed data is ever removed — and that you cannot see or wipe their personal data.
**Verify:** A one-page BYOD explainer exists for pilot users (privacy scope, what's managed, how to
remove the work account).
**Implement:** Draft it from the Overview's "How it works" and "privacy" points; the Best Practices
guide lists exactly what to tell users.

## R9. Network access to Microsoft and Apple endpoints
**Description:** Outbound HTTPS from the pilot Macs to Microsoft Entra/Intune and to Apple's identity
and enrollment endpoints.
**Why:** Sign-in, enrollment, managed Apple Account provisioning, policy sync, and Conditional Access
evaluation all depend on these endpoints.
**Verify:** From the Mac's network, reach `https://login.microsoftonline.com`,
`https://enrollment.manage.microsoft.com`, and Apple's identity/enrollment endpoints (e.g.
`https://gdmf.apple.com`, `https://identity.apple.com`).
**Implement:** Allow Microsoft's published Microsoft 365/Intune/Entra URL & IP ranges and Apple's
published enrollment/identity ranges through proxy/firewall. Do **not** TLS-inspect Apple enrollment
and push traffic.

## R10. Administrative roles for enrollment, compliance, and Conditional Access
**Description:** The operator holds the roles needed to configure enrollment/compliance (**Intune
Administrator**) and Conditional Access (**Conditional Access Administrator** or **Security
Administrator**).
**Why:** Creating the enrollment type, the compliance policy, and the CA policy requires elevated rights
across both Intune and Entra.
**Verify:** Entra → **Roles and administrators**; confirm **Intune Administrator** and a CA-capable
role are assigned to the operator.
**Implement:** Assign **Intune Administrator** plus **Conditional Access Administrator** (or **Security
Administrator**); reserve Global Administrator for tenant-wide changes.


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


# 3. Implementation — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Follow these steps **in order**. The *why* for each capability lives in the Solution Overview; the
steps below are deliberately short and exact so you can **click to implement**. Throughout, the
repeatable pattern applies: **Assess → Configure → Pilot → Validate → Expand.** Do everything against
the pilot group **`BYOD-Mac-Pilot`** first.

All admin-center steps use the Microsoft Intune admin center at `https://intune.microsoft.com` and
Microsoft Entra at `https://entra.microsoft.com` unless noted. Named objects you will create:

| Object | Name | Where |
|---|---|---|
| Pilot security group | **`BYOD-Mac-Pilot`** | Entra → Groups |
| Enrollment type | **account-driven user enrollment** (macOS) | Intune → Enrollment |
| Compliance policy | **`macOS BYOD Compliance - Pilot`** | Intune → Compliance policies |
| Conditional Access policy | **`CA - Require Compliant Mac - Pilot`** | Entra → Conditional Access |

---

## Phase 0 — Assess (confirm readiness)

### Step 1. Run the discovery script
1. On an admin workstation with the **Microsoft Graph PowerShell SDK**, run
   **`MACBYOD-Discovery.ps1`** (read-only).
2. Confirm: macOS enrollment **allowed**, an account-driven user-enrollment configuration present (or
   flagged as not yet enabled), a macOS **compliance policy**, and whether a **Conditional Access**
   policy already gates macOS. Resolve any FAIL before continuing.

### Step 2. Confirm the pilot group exists
1. Entra → **Groups**; confirm **`BYOD-Mac-Pilot`** exists with your pilot users (Requirements R7).
2. If missing: **Groups → New group → Security**, name it **`BYOD-Mac-Pilot`**, add pilot users.

---

## Phase 1 — Configure account-driven user enrollment

### Step 3. Allow macOS personally owned enrollment
1. Intune → **Devices → Enrollment → Enrollment device platform restrictions**.
2. Open the default (or a pilot-targeted) restriction → **macOS**.
3. Set **Personally owned devices = Allow**. Save.

### Step 4. Enable account-driven user enrollment for macOS
1. Intune → **Devices → Enrollment → Apple** → open the **macOS** enrollment area.
2. Select the **account-driven user enrollment** enrollment type (the identity-driven, lighter-footprint
   BYOD option — **not** device enrollment and **not** Automated Device Enrollment).
3. Configure it to target **`BYOD-Mac-Pilot`** so only pilot users get this experience first.
4. Save.

> **If your console does not surface account-driven *user* enrollment for macOS**, confirm your OS floor
> (Requirements R2) and your managed Apple Account path (R3) — both are prerequisites. **Flag it and
> confirm against Microsoft's current macOS enrollment documentation rather than forcing a different
> enrollment type.** Do not silently substitute device enrollment; that changes the footprint the buyer
> asked for.

### Step 5. Confirm the managed Apple Account path
1. Verify pilot users can obtain a **managed Apple Account** for the corporate scope (Requirements R3) —
   the user's **personal** Apple ID stays untouched.
2. If unclear, coordinate with whoever owns your Apple identity relationship **before** piloting.

---

## Phase 2 — Scope BYOD compliance

### Step 6. Create the BYOD compliance policy
1. Intune → **Devices → Compliance policies → Create policy**.
2. **Platform = macOS**; **Create**.
3. **Name:** **`macOS BYOD Compliance - Pilot`**.
4. **Compliance settings** — keep BYOD-appropriate and minimal (do not over-manage a personal Mac):
   - **Minimum OS version** = your confirmed account-driven-enrollment floor (Requirements R2).
   - **System Integrity Protection** required (where supported).
   - Disk-encryption / firewall settings **only** where they make sense for BYOD and match your policy.
5. **Actions for noncompliance** — start gentle: **Mark noncompliant** immediately; optionally email
   the user. (Avoid retire/wipe actions on personal Macs.)
6. **Assignments** → include **`BYOD-Mac-Pilot`**.
7. **Review + Create.**

> Prefer automation for scoping? Run **`MACBYOD-Set-ScopeTargeting.ps1`** to assign the compliance
> policy (and, later, the CA policy) to a target group. It **defaults to `-WhatIf`** and only writes
> when you pass `-Apply`.

---

## Phase 3 — Build the Conditional Access gate

### Step 7. Confirm break-glass exclusions exist
1. Entra → **Users**; confirm your two **break-glass** emergency accounts exist (Requirements R6).
2. You will exclude them from the CA policy in the next step. **Never skip this.**

### Step 8. Create the named Conditional Access policy (report-only first)
1. Entra → **Protection → Conditional Access → Create new policy**.
2. **Name:** **`CA - Require Compliant Mac - Pilot`**.
3. **Users:**
   - **Include** → **`BYOD-Mac-Pilot`**.
   - **Exclude** → your two **break-glass** accounts.
4. **Target resources:** **Cloud apps → Include → Office 365** (or the specific apps you are gating).
5. **Conditions → Device platforms:** **Include → macOS** (so this policy targets Macs only).
6. **Grant:** **Grant access → Require device to be marked as compliant** (this is the compliance gate).
   Optionally also require **Microsoft Entra hybrid joined / device to be enrolled** per your model; for
   BYOD user enrollment, **require compliant** is the primary control.
7. **Enable policy = Report-only.**
8. **Create.**

> Automating the CA build? **`MACBYOD-Remediation.ps1`** can create/repair this policy and **always
> re-asserts break-glass exclusions**; it **defaults to `-WhatIf`** and only writes with `-Apply`.

---

## Phase 4 — Pilot

### Step 9. Onboard a pilot Mac (user-initiated)
1. As a **pilot user on their own Mac**, open **System Settings**.
2. Add the **Work or School account** (the account-driven user-enrollment sign-in), authenticating with
   the user's **Entra ID**.
3. macOS provisions the **managed Apple Account** and the **separate managed volume**; the corporate
   scope is applied. Personal apps, data, and Apple ID are untouched.
4. Wait for Intune policy to sync; the Mac appears in **Intune → Devices → macOS** as a
   **personally owned**, user-enrolled device.

### Step 10. Confirm the compliance signal
1. Intune → **Devices → macOS → (the pilot device) → Compliance**; confirm it evaluates against
   **`macOS BYOD Compliance - Pilot`** and reports **Compliant**.
2. Or run **`MACBYOD-Validation.ps1 -Serial the-device-serial`** for a per-device PASS/FAIL.

---

## Phase 5 — Validate

### Step 11. Validate the end-to-end posture
1. Run **`MACBYOD-Validation.ps1`** against the pilot Mac: enrolled (**account-driven user
   enrollment**), **personally owned**, **compliant**, and Entra-registered.
2. Review **`CA - Require Compliant Mac - Pilot`** in **report-only**: Entra → **Sign-in logs** → filter
   to the pilot user/macOS → confirm the policy would have **allowed** the compliant Mac and **blocked**
   a non-compliant/unenrolled one (test from an unmanaged Mac to see the block *predicted*).
3. Run **`MACBYOD-Report.ps1`** for the BYOD access-posture snapshot (enrolled vs unmanaged, compliant
   vs not, which Macs the CA policy would gate).

### Step 12. Turn the gate on for the pilot
1. Once report-only shows the intended outcome with **no surprise blocks** for legitimate users, edit
   **`CA - Require Compliant Mac - Pilot`** → **Enable policy = On**.
2. Re-test with a pilot user: a **compliant** enrolled Mac gets in; a **non-compliant/unenrolled** Mac
   is **blocked**. Break-glass accounts remain excluded.

---

## Phase 6 — Expand

### Step 13. Widen scope in waves
1. Create a production group (e.g. **`BYOD-Mac-Users`**) and add the next wave of users.
2. Use **`MACBYOD-Set-ScopeTargeting.ps1`** (preview with `-WhatIf`, then `-Apply`) to assign the
   **compliance policy** and the **CA policy** to the production group — or clone the pilot CA policy to
   a production-named policy (e.g. **`CA - Require Compliant Mac - Production`**) and expand its scope.
3. Keep break-glass exclusions on **every** CA policy.
4. Validate each wave with **`MACBYOD-Validation.ps1`** / **`MACBYOD-Report.ps1`** before widening
   further. Roll out in waves, never all at once.


---


# 5. Testing & Validation — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Validate against a **pilot Mac** and the **`BYOD-Mac-Pilot`** group before expanding. Each test has an
explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device steps for the user experience. Keep the Conditional Access policy in
**report-only** until Tests 1–6 pass.

## Test 1 — Tenant readiness
**Procedure:** Run `MACBYOD-Discovery.ps1`.
**Pass:** macOS enrollment **allowed**; account-driven user enrollment present/enabled (or clearly
flagged as not yet enabled); a macOS **compliance policy** (`macOS BYOD Compliance - Pilot`) exists; and
the CA policy state is reported. No blocking FAIL.
**Fail:** Any prerequisite missing → resolve using the Requirements guide before onboarding devices.

## Test 2 — Personal Mac enrolls (account-driven user enrollment)
**Procedure:** As a pilot user on their **own** Mac, add the **Work or School account** in **System
Settings** and complete sign-in.
**Pass:** The Mac appears in **Intune → Devices → macOS** as **personally owned**, enrollment type
**account-driven user enrollment**; a **managed Apple Account** and separate managed volume were
provisioned; the user's personal Apple ID/data are untouched.
**Fail:** No enrollment → confirm macOS is **Allowed** (R1), the OS floor is met (R2), and the managed
Apple Account path exists (R3). Do **not** substitute device enrollment to "make it work" — flag it.

## Test 3 — Managed scope is isolated (privacy)
**Procedure:** On the enrolled Mac, confirm corporate apps/data live in the managed scope while personal
apps/data remain separate.
**Pass:** Managed (corporate) data is present in the managed volume; personal data/apps are unaffected;
removing the work account would remove **only** managed data.
**Fail:** Personal data appears managed, or the whole device is under management → you likely used
**device enrollment** (Model B), not **account-driven user enrollment** (Model A). Re-check Step 4 of
Implementation.

## Test 4 — Compliance signal reports
**Procedure:** Intune → **Devices → macOS → (device) → Compliance**, or run
`MACBYOD-Validation.ps1 -Serial the-device-serial`.
**Pass:** The Mac evaluates against **`macOS BYOD Compliance - Pilot`** and reports **Compliant**.
**Fail:** No compliance state → the policy isn't assigned to `BYOD-Mac-Pilot` (R4); **Noncompliant** →
address the failing setting (usually OS version) and re-sync.

## Test 5 — Conditional Access (report-only) predicts the right outcome
**Procedure:** With `CA - Require Compliant Mac - Pilot` in **report-only**, have the pilot user sign in
to a gated app (e.g. `https://outlook.office.com`) from the enrolled Mac; then attempt from an
**unmanaged** Mac. Review Entra → **Sign-in logs** (or run `MACBYOD-Report.ps1`).
**Pass:** The log shows the policy **would allow** the **compliant, enrolled** Mac and **would block**
the **unmanaged/non-compliant** Mac. Break-glass accounts are excluded.
**Fail:** Would block a legitimate compliant Mac → check the grant control and platform condition
(Implementation Step 8); would allow an unmanaged Mac → confirm the grant is **Require compliant** and
the macOS platform condition is set.

## Test 6 — Enforce the gate for the pilot
**Procedure:** Set `CA - Require Compliant Mac - Pilot` to **On**. Re-test from a compliant enrolled Mac
and from an unmanaged Mac.
**Pass:** Compliant enrolled Mac → **access granted**; unmanaged/non-compliant Mac → **access blocked**;
break-glass account (excluded) → still able to sign in.
**Fail:** Legitimate user locked out → revert to report-only, correct scope/exclusions, and re-test.
Use a **break-glass** account if you lose admin access.

## Test 7 — App-protection expectation is correct (honesty check)
**Procedure:** Confirm your internal messaging and controls match how macOS actually protects data.
**Pass:** Protection for BYOD Macs is delivered by **enrollment + compliance + Conditional Access** — not
by an iOS-style App Protection Policy. No one is relying on macOS "MAM" that doesn't exist.
**Fail:** Someone expects per-app containerization/selective in-app wipe on arbitrary Mac apps → correct
the expectation (Solution Overview, honest note). Gate access via CA instead.

## Test 8 — Selective removal on off-boarding
**Procedure:** Have a pilot user remove the **Work or School account** (or retire the device in Intune).
**Pass:** Only the **managed** volume/data is removed; the personal Mac remains intact and usable; the
device drops out of the compliant set and the CA gate would block corporate access.
**Fail:** Whole device wiped or personal data affected → the wrong enrollment model was used; re-check
that this is **account-driven user enrollment** (Model A).

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 pass on at least one pilot Mac, the CA policy enforces the
intended allow/block outcome with break-glass excluded, and a real pilot user confirms the privacy
boundary (personal data untouched, only managed data removable).


---


# 6. Troubleshooting — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Work top-down: confirm the **enrollment** (personal Mac onboards), then the **compliance signal**, then
the **Conditional Access gate**, and only then the **user experience**. Most failures are macOS blocked
by an enrollment restriction, an OS below the account-driven-enrollment floor, a compliance policy not
assigned, or a CA policy scoped/graded incorrectly. When in doubt, re-run `MACBYOD-Discovery.ps1` and
`MACBYOD-Validation.ps1` after each change.

## The "Sign in to Work or School account" option doesn't enrol / no managed scope appears
- **macOS not allowed.** Intune → **Devices → Enrollment → Enrollment device platform restrictions →
  macOS**; set **Personally owned devices = Allow** (R1).
- **OS below the floor.** Account-driven **user** enrollment needs a modern macOS; update the Mac (R2).
  If unsure of the exact minimum, **flag it and confirm** against Microsoft's current documentation —
  don't guess.
- **Account-driven user enrollment not enabled.** Confirm the enrollment type is configured for macOS and
  targets `BYOD-Mac-Pilot` (Implementation Step 4).
- **Managed Apple Account path missing.** The corporate scope needs a **managed Apple Account** (R3);
  coordinate with your Apple identity owner. Do **not** silently switch to device enrollment to force it.

## The whole Mac got managed / personal data looks managed
- **Wrong model.** This is the symptom of **device enrollment (Model B)**, not **account-driven user
  enrollment (Model A)**. Account-driven user enrollment manages only a **separate managed volume**.
  Remove the enrollment, correct **Implementation Step 4** to the account-driven **user** enrollment
  type, and re-onboard.

## Device enrolled but **no compliance state** / shows Not evaluated
- **Compliance policy not assigned.** Confirm `macOS BYOD Compliance - Pilot` is assigned to
  `BYOD-Mac-Pilot` (R4). Without assignment there is no signal, and Conditional Access can't require it.
- **Sync pending.** Give Intune time to evaluate, or force a sync; re-run
  `MACBYOD-Validation.ps1 -Serial the-device-serial`.

## Device shows **Noncompliant**
- **OS below the compliance floor** — update macOS (R2), or lower the floor if BYOD-appropriate.
- **A health setting is failing** (e.g. SIP/encryption) — review the failing setting in
  Intune → device → **Compliance** and address it; keep BYOD compliance **minimal** so you're not failing
  personal Macs on corporate-only controls.

## Conditional Access blocks a legitimate compliant Mac
- **Grant control mismatch.** The policy must grant on **Require device to be marked as compliant**
  (Implementation Step 8). If it also requires hybrid-join, a BYOD user-enrolled Mac will fail — hybrid
  join is not the BYOD control.
- **Platform condition too broad/narrow.** Ensure the **Device platforms** condition includes **macOS**
  and isn't accidentally excluding it.
- **Not actually compliant yet.** Confirm the Mac reports **Compliant** first (see above); the CA gate is
  only as good as the compliance signal beneath it.

## Conditional Access lets an **unmanaged** Mac through
- **Grant not enforcing compliance.** Confirm the grant is **Require compliant** and the policy is **On**
  (not report-only). Remember: an **unmanaged** Mac has **no compliance state**, so a require-compliance
  policy should block it — if it's getting through, the policy isn't applying (check user/app/platform
  scope).

## Locked out after enabling the CA policy
- **Use a break-glass account.** Sign in with one of your two excluded **emergency access** accounts
  (R6), set the policy back to **report-only**, fix the scope/exclusions, and re-test. This is exactly
  why break-glass accounts and report-only-first are mandatory.

## "But I expected App Protection Policies to cover the Mac apps"
- **They don't — this is expected, not a bug.** Intune **App Protection Policies (MAM)** cover iOS/Android
  apps, **not** arbitrary macOS apps. On macOS the protection boundary is **enrollment + compliance +
  Conditional Access**. Re-set the expectation (Solution Overview, honest note) and gate access with CA
  rather than looking for a macOS MAM container that doesn't exist.

## Off-boarding wiped the whole Mac / affected personal data
- **Wrong action or wrong model.** For account-driven user enrollment, removing the work account (or
  retiring the device) removes **only** the managed data. If a full wipe happened, a device-level
  retire/wipe action was used or the device was **device-enrolled** — avoid wipe actions on BYOD and
  confirm the enrollment model.

## Useful checkpoints
- **Intune:** Devices → macOS → (device) → **Hardware / Compliance / Configuration**; Enrollment →
  platform restrictions; Compliance policies → assignment.
- **Entra:** Protection → **Conditional Access** → policy state (report-only vs on) and user/exclusion
  scope; **Sign-in logs** → filter to the pilot user/macOS to see which policies applied and the result.
- **On the Mac:** **System Settings → General → Device Management / Profiles** (managed scope present);
  the user's **Work or School account** entry.
- **Scripts:** re-run `MACBYOD-Validation.ps1` after each change to confirm the gate; `MACBYOD-Report.ps1`
  for the fleet-wide posture.


---


# 7. Best Practices — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Field-proven guidance to keep the deployment reliable, private, and low-footprint — the two things that
make macOS BYOD succeed or fail are **respecting the user's device** and **being honest about what
protection macOS actually provides**.

## Choose the least footprint that still protects data
- **Default to account-driven user enrollment (Model A).** It manages only the corporate scope, leaves
  personal data alone, and still yields a compliance signal for Conditional Access. Use the heavier
  **device enrollment (Model B)** only when user enrollment genuinely doesn't fit.
- **Don't over-manage a personal Mac.** Keep the BYOD compliance policy **minimal** — the OS floor and a
  few sensible health checks. Every additional control on someone's own Mac erodes trust and adoption.
- **Never use retire/wipe-the-device actions on BYOD.** For account-driven user enrollment, off-boarding
  removes only the **managed** data by design — lean on that, not a full wipe.

## Be honest about macOS app protection (the #1 misconception)
- **Do not promise iOS-style App Protection Policies (MAM) on macOS — they don't exist for arbitrary Mac
  apps.** Corporate-data protection on a Mac comes from **enrollment + compliance + Conditional Access**,
  not per-app containers or selective in-app wipe.
- **Message this to stakeholders up front.** If a security requirement assumes macOS MAM, correct it
  before you build — otherwise you'll ship a control that can't do what someone expects.
- **Gate with Conditional Access instead.** The reliable macOS control is "only a compliant, enrolled Mac
  reaches the data." That *is* the protection boundary.

## Privacy: earn and keep user trust
- **Publish a one-page BYOD explainer** (Requirements R8): what's managed (corporate scope only), what
  IT can and **cannot** see or do (no personal data, no personal Apple ID, no whole-device wipe), and how
  the user removes the work account.
- **Make removal easy and honest.** Tell users exactly how to remove the work account and what happens
  (only managed data goes). Ease of exit increases willingness to enrol.
- **Keep the managed Apple Account path clean.** The corporate scope uses a **managed Apple Account**;
  never ask users to hand over their personal Apple ID.

## Conditional Access discipline (don't lock people out)
- **Always start in report-only.** Deploy `CA - Require Compliant Mac - Pilot` in **report-only**, read
  the sign-in logs, and only enforce once the predicted allow/block matches intent.
- **Exclude two break-glass accounts from every CA policy — always.** Verify the exclusion before you
  enable any policy; a misconfigured require-compliance policy can lock out the whole tenant.
- **Scope by platform.** Set the **macOS** device-platform condition so this policy affects Macs only and
  doesn't collide with your Windows/iOS gates.
- **Expand in waves.** Move from `BYOD-Mac-Pilot` to a production group deliberately; re-validate each
  wave with the scripts before widening.

## Operating system & compliance
- **Confirm and pin your OS floor.** Account-driven user enrollment needs a modern macOS; set a
  minimum-OS compliance setting so Macs below the floor are flagged rather than silently failing to
  enrol. If you're unsure of the exact minimum, **flag it and confirm** — don't guess.
- **Keep compliance BYOD-appropriate.** Require what protects data (OS floor, SIP, encryption where it
  makes sense) — not a full corporate lockdown of a personal machine.

## Operations & documentation
- **Keep a runbook** of the named objects (`BYOD-Mac-Pilot`, `macOS BYOD Compliance - Pilot`,
  `CA - Require Compliant Mac - Pilot`), the managed Apple Account owner, the OS floor, and the
  break-glass account locations.
- **Report monthly** with `MACBYOD-Report.ps1`: enrolled BYOD Macs vs unmanaged, compliant vs not, and
  which Macs the CA policy gates. A rising "unmanaged but accessing" count is a signal to act.
- **Use `-WhatIf` first on every change.** `MACBYOD-Remediation.ps1` and `MACBYOD-Set-ScopeTargeting.ps1`
  default to preview mode; review the intended change, then re-run with `-Apply`.

## Security posture
- **Combine BYOD with identity hardening** (MFA, sign-in risk policies) so the CA gate is one layer of
  several, not the only one.
- **Treat unmanaged Macs honestly.** If you allow Model C (unmanaged + CA), remember those Macs **cannot
  be compliant** — a require-compliance policy will block them. Decide that intentionally.


---


# 8. Deliverables Summary — macOS BYOD Management: Account-Driven User Enrollment, App Protection & Conditional Access

Everything included in this solution package, and what each piece is for.

## Documentation (this guide)
- **Executive Summary** — the business case and outcome in one page.
- **Solution Overview** — the three BYOD models for Macs (account-driven **user enrollment** vs
  **device enrollment** vs **unmanaged + Conditional Access**), the management footprint each carries,
  how account-driven user enrollment works step by step, and the **honest note** that Intune App
  Protection Policies do **not** cover macOS apps the way they do iOS/Android — protection comes via MDM
  scope + Conditional Access.
- **Requirements Guide** — every prerequisite (Intune with macOS enrollment allowed, the OS floor, the
  managed Apple Account path, a BYOD compliance policy, Conditional Access licensing, break-glass
  accounts, pilot users/group, user communication, network, admin roles) with how to **verify** and how
  to **implement if missing**, plus the category-level Global Requirements.
- **Implementation Guide** — exact, ordered, click-by-click steps across six phases: assess, enable
  account-driven user enrollment, scope BYOD compliance, build the named Conditional Access policy
  (require compliant/enrolled Mac), pilot, validate, and expand.
- **Testing & Validation** — eight tests with explicit pass/fail gates (personal Mac enrolls, managed
  scope isolated, compliance reports, CA predicts then enforces the right allow/block, the honesty
  check, and selective removal) and an acceptance gate.
- **Troubleshooting** — top-down diagnosis for enrollment, compliance, and Conditional Access failures.
- **Best Practices** — least footprint, privacy/user trust, the macOS app-protection honesty rule, and
  Conditional Access discipline.

## PowerShell scripts (Microsoft Graph) — `MACBYOD-Scripts.zip`
All scripts are tenant-side (run from an admin workstation with the Microsoft Graph PowerShell SDK);
each has a header explaining **Purpose · How to run · Expected results**. Discovery, Validation, and
Report are **read-only**; Remediation and Set-ScopeTargeting **default to `-WhatIf`** and only change
anything when you pass `-Apply`.

1. **`MACBYOD-Discovery.ps1`** — BYOD-readiness discovery: is macOS enrollment allowed, is account-driven
   user enrollment present, does a macOS BYOD compliance policy exist, and does a Conditional Access
   policy gate macOS. Read-only.
2. **`MACBYOD-Validation.ps1`** — per-device validation for one BYOD Mac: enrolled via **account-driven
   user enrollment**, **personally owned**, **compliant**, and Entra-registered — with a clear PASS/FAIL
   verdict. Read-only.
3. **`MACBYOD-Report.ps1`** — a BYOD access-posture report: macOS devices by enrollment type (user
   enrollment vs device vs unmanaged), compliance state, and which Macs the require-compliance CA policy
   would gate. Read-only; optional CSV.
4. **`MACBYOD-Remediation.ps1`** — safe remediation: create/repair the require-compliant-Mac Conditional
   Access policy (always re-asserting break-glass exclusions) and assign the BYOD compliance policy.
   **Defaults to `-WhatIf`**; changes require `-Apply`.
5. **`MACBYOD-Set-ScopeTargeting.ps1`** — target-group builder/assigner: move the compliance and CA
   policies from the pilot group to a production group. **Defaults to `-WhatIf`**; changes require
   `-Apply`.

## Named objects this solution creates
- Pilot security group **`BYOD-Mac-Pilot`** (Entra)
- Enrollment type **account-driven user enrollment** for macOS (Intune)
- Compliance policy **`macOS BYOD Compliance - Pilot`** (Intune)
- Conditional Access policy **`CA - Require Compliant Mac - Pilot`** (Entra)

## Hero image
- **`MACBYOD-hero.png`** — the product image (1200×1200) used on the marketplace listing.

## How it's delivered
A **Word** document and **PDF** (cover, table of contents, page numbers, and a scripts appendix), plus
all five PowerShell scripts in a single **ZIP** — yours to keep and reuse across **unlimited devices**.
