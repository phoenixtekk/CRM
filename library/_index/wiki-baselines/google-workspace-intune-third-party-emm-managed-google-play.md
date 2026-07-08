# Google Workspace ↔ Intune Third-Party EMM Integration for Managed Google Play

> **Version 1.0.0** · Category: Android · Solution code: ANDROIDGW

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Google Workspace ↔ Intune Third-Party EMM Integration for Managed Google Play

## The situation
Organizations that use **Google Workspace or Cloud Identity** and want Microsoft Intune to manage their
Android devices face a specific, higher-stakes version of the managed Google Play setup. Because they
already own a **managed Google domain**, connecting Intune is **not** the standard managed Google Play
*account enterprise* bind — it is a **third-party EMM integration**, where a Google super-admin delegates
Android management to Intune from the **Google Admin console**. The number-one concern, correctly, is:
**will enabling this re-enrol our existing devices and disrupt users?**

## The problem
- **The re-enrollment risk is real but unclear.** Whether the change forces existing devices to re-enrol
  is **state- and version-dependent** and is **actively evolving** (including Microsoft's ongoing
  **Android Management API / AMAPI** transition). It cannot be safely guessed.
- **Two binding models are easy to confuse**, and using the wrong one on an existing Google domain causes
  domain conflicts and "can't add a Google account" failures.
- **It is a cross-console, high-impact change** touching a Google super-admin and Intune — exactly the
  kind of change that goes wrong when rushed without a baseline, a pilot, or a rollback.

## The approach
This solution delivers the integration as a disciplined, pilot-first project — **Assess → Design →
Configure → Pilot → Validate → Expand** — with the re-enrollment question treated **honestly**:
1. **Baseline** the current managed Google Play binding and the full existing-device inventory *before*
   any change (read-only Graph tooling).
2. **Confirm** the model and the Google-identity ↔ Entra-identity mapping so account add works.
3. **Configure** the Google Admin console third-party EMM (super-admin) and the Intune side, following
   **current** Microsoft/Google guidance for each console.
4. **Assess re-enrollment / end-user impact on a pilot** by diffing device state against the baseline —
   and **verify the result against current guidance**, never asserting it.
5. **Validate** account add + app delivery, then **expand** under change control with a rollback ready.

Five read-only-by-default PowerShell (Microsoft Graph) tools automate the discovery, readiness,
validation, device-impact, and scope work — no credentials in code, and only one reversible, `-Commit`-
gated write.

## The outcome
Managed Google Play delegated to Intune for your Google Workspace organization — **integration active,
accounts adding, apps delivering, and the re-enrollment question answered with evidence before you flip
the switch.** You enable it with confidence instead of fear, and you keep a verified rollback the whole
way.

## Why it matters to the business
- **De-risks an existential-feeling change** to the mobile fleet by measuring and piloting impact rather
  than guessing.
- **Prevents the costly failure modes** (domain conflict, mass re-enrollment, blocked account add) that
  turn a connection into an outage.
- **Self-guided and repeatable** at a fraction of bespoke consulting cost, using only Microsoft and
  Google native surfaces.

> **Honest scope.** Re-enrollment behavior, the AMAPI transition, and web/account-driven enrollment are
> evolving; this solution flags every impact claim as **"verify against current Microsoft/Google
> guidance and your tenant"** and proves it on a pilot. The account-enterprise bind (for tenants without
> Google Workspace) is a separate solution.


---


# 1. Solution Overview — Google Workspace ↔ Intune Third-Party EMM Integration for Managed Google Play

## What this solution is
Microsoft Intune manages Android Enterprise devices and delivers apps through **managed Google Play**.
Before any Android device can enrol, Intune must be connected to managed Google Play — and there are
**two mutually-exclusive ways** to make that connection. Organizations that do **not** use Google
Workspace bind through a **managed Google Play account enterprise** (a separate solution, `ANDROIDENT`).
Organizations that **do** use **Google Workspace or Cloud Identity** already own a **managed Google
domain**, and for them the connection is a **third-party EMM integration**: a Google super-admin
delegates Android management to Intune from the **Google Admin console**, and Intune assumes management
of managed Google Play for that domain.

This solution walks that Google Workspace ↔ Intune third-party EMM integration end to end — the Google
Admin console side, the Intune side, and the identity/account model — and, critically, gives you a
**careful, evidence-based read on whether enabling it will re-enrol existing devices** and what the
end-user experience will be, so you can flip the switch with confidence instead of fear. It uses only
the Intune admin center, the Google Admin console, and Microsoft Graph PowerShell — no third-party
tooling.

> **This is NOT the account-enterprise bind.** If your tenant has no Google Workspace / Cloud Identity
> domain, you want the managed Google Play **account enterprise** connection (`ANDROIDENT`), not this.
> The two models are mutually exclusive — exactly one applies per tenant (see the category Global
> Requirements, requirement 2). This solution is specifically for organizations whose users already
> have **Google Workspace / Cloud Identity** identities.

## Why this matters
- **The re-enrollment fear is the real question.** Teams that already have Android devices under
  management (or under another EMM, or MDM-less) rightly worry that changing the managed Google Play
  binding will force existing devices to **re-enrol**, wiping work profiles and interrupting users.
  Whether a given change triggers re-enrollment depends on your current state, the enrollment models in
  play, and the current Microsoft/Google behavior — so it must be **assessed and piloted, not assumed**.
- **Two binding models are easy to confuse.** Picking the wrong one — or trying to run both — leads to
  "can't add a Google account," duplicate enterprises, and a domain conflict that is painful to unwind.
- **Identity is different here.** With Google Workspace, your users have real Google identities in a
  managed Google domain; the account added to a device and the way managed Google Play resolves the
  user differ from the anonymous account-enterprise model. Getting the account/identity model right up
  front prevents enrollment failures later.
- **It is a high-impact, cross-console change.** The integration touches a super-admin action in the
  **Google Admin console** and a connection in **Intune** — a change-controlled, pilot-first operation
  that can affect the whole Android fleet if rushed.

## The two binding models (and why this solution exists)
| | **Account enterprise** (`ANDROIDENT`) | **Google Workspace / Cloud Identity third-party EMM** (this solution) |
|---|---|---|
| Who it's for | Tenants **without** a Google managed domain | Tenants that **use Google Workspace / Cloud Identity** |
| What you bind | A managed Google Play **account enterprise** Intune creates | Your **existing managed Google domain**, delegated to Intune as the EMM |
| Where the key step happens | Intune admin center (sign in with a Google account) | **Google Admin console** (super-admin enables a third-party Android EMM) **and** Intune |
| Identity model | Anonymous managed Google Play account | Real Google Workspace / Cloud Identity users in a managed domain |
| Mutually exclusive? | Yes — one model per tenant | Yes — one model per tenant |

Because the Workspace path starts with a **Google super-admin** action and involves your real Google
identities, it is a genuinely different integration from the account-enterprise bind — and it is the one
that raises the re-enrollment question. That is why it is its own solution.

## How it works
1. **Assess the current binding.** Read the current managed Google Play connection state from Intune /
   Microsoft Graph (`androidManagedStoreAccountEnterpriseSettings` — bind status, owning account, last
   app sync) and inventory the existing Android devices (enrollment type, ownership, management state,
   last check-in). This establishes what you have *before* touching anything.
2. **Confirm the identity/account model.** Verify your Google Workspace / Cloud Identity domain, the
   super-admin who can act in the Google Admin console, and how your users' Google identities map to the
   Entra identities Intune uses — so the account added on devices resolves correctly.
3. **Enable the third-party EMM in the Google Admin console.** A Google super-admin enables a
   **third-party Android EMM provider** (delegating managed Google Play management to Intune) — the
   exact menu path is **verified against current Google Admin console guidance** at run time, because
   Google moves these settings.
4. **Complete the Intune side.** Establish/confirm the Android Enterprise connection in Intune so
   managed Google Play is delegated and app sync succeeds.
5. **Assess re-enrollment / end-user impact — before broad rollout.** Using the existing-device report,
   determine on a **pilot** whether existing managed devices keep working, need re-check-in, or require
   re-enrollment — and **verify that behavior against current Microsoft/Google guidance and your own
   pilot**, never assumed.
6. **Validate account add + app delivery on a pilot**, then **expand** to the fleet under change control,
   with a documented rollback.

## The re-enrollment question — how this solution treats it
Whether enabling the Google Workspace third-party EMM integration (or changing an existing managed
Google Play binding) **re-enrols existing devices** depends on the current state and on Microsoft/Google
behavior that is **actively evolving** (including the ongoing **Android Management API (AMAPI)**
transition and web/account-driven enrollment changes). This solution therefore **does not assert**
re-enrollment behavior. Instead it:
- **Measures** your existing devices and binding so the blast radius is known.
- **Flags** every enrollment-impact claim with **"verify against current Microsoft/Google guidance and
  your tenant."**
- **Pilots** the change on a small device set and **observes** the actual result before any fleet-wide
  action, with a rollback ready.

That discipline is the product: you get a clear, honest read on impact instead of a guess.

## What you can control
- Which model applies (confirming Workspace third-party EMM is correct for your tenant, not the account
  enterprise).
- The pilot device set and pilot user group the change is validated on first.
- The app-assignment and enrollment scope used to contain the pilot.
- The change window and rollback trigger for the production cutover.

## Limitations (be honest with buyers)
- **Re-enrollment behavior is version- and state-dependent** and is **not asserted** here — it is
  assessed and piloted, and flagged to verify against current Microsoft/Google guidance.
- The **Google Admin console** is a Google surface: exact menu paths change, and the super-admin action
  is performed by your Google administrator (patterns are given; the console is deferred to Google's
  current docs).
- Some Graph resources used for the binding state (e.g. `androidManagedStoreAccountEnterpriseSettings`,
  Android enrollment profiles) are on the **Graph beta** endpoint; treat their shape as subject to
  change and verify in your tenant.
- OEM specifics (Samsung Knox, Zebra) and third-party apps are handled at the pattern level; their
  consoles are deferred to the vendor.

## Naming convention (used in every doc and script)
Every artifact this solution creates or reads is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, Intune admin center, and Google Admin console notes. The standard set:

| Artifact | Name |
|---|---|
| Current-binding & posture report | `Binding Posture – Workspace+Intune – Discovery` |
| Integration readiness checklist | `Integration Readiness – Workspace+Intune – Assess` |
| Existing-device impact report | `Device Impact – Android – Assess` |
| Pilot enrollment / assignment group | `MGP Pilot – Android – Stage1` |
| Account-add + app-delivery validation | `Account Add + App Delivery – Pilot – Validation` |
| Broad rollout group | `MGP Broad – Android – Stage2` |
| App-sync / connection health report | `MGP Sync Health – Android – Report` |

## The standard deployment model
> Assess the current binding and devices → design the identity/account model and the target binding →
> configure the Google Admin console third-party EMM + the Intune side → **pilot** on a small set and
> **assess re-enrollment / end-user impact** → validate account add + app delivery → expand under change
> control with rollback.
> Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**


---


# 2. Requirements Guide — Google Workspace ↔ Intune Third-Party EMM Integration

These are the **solution-specific** prerequisites for the Google Workspace ↔ Intune third-party EMM
integration. They build on — and do not repeat — the six **category Global Requirements**
(`global-requirements-android.md`): a Microsoft 365 tenant with Intune and Android Enterprise (GR 1);
the managed Google Play binding decision (GR 2); least-privilege Intune roles (GR 3); the enrollment-
method decision and Graph PowerShell toolchain (GR 4); network reachability to Google & Microsoft
endpoints (GR 5); and a pilot scope with change control (GR 6). Verify the Global Requirements first,
then the solution-specific items below.

Each requirement below is stated as **Description · Why required · How to verify · How to implement if
missing**.

---

## 2.1 Your tenant genuinely uses Google Workspace / Cloud Identity (the correct model)
- **Description:** Your organization has a **Google Workspace or Cloud Identity managed domain** (i.e.
  your users have real Google identities), which is what makes the **third-party EMM** integration the
  right model rather than the managed Google Play **account enterprise** (`ANDROIDENT`).
- **Why required:** The two managed Google Play binding models are **mutually exclusive** (GR 2). Using
  the account-enterprise model on a domain that already exists in Google Workspace causes domain
  conflicts and "can't add account" failures. This solution is only correct if you have a managed Google
  domain.
- **How to verify:** Confirm a Google Workspace / Cloud Identity subscription and that your primary
  domain is verified in the **Google Admin console** (`admin.google.com`). Confirm Intune does **not**
  already have a managed Google Play *account enterprise* bound for a different (non-domain) account.
- **How to implement if missing:** If you have **no** Google managed domain, stop — use the
  account-enterprise solution (`ANDROIDENT`) instead. Do not create a managed Google domain solely to
  use this model.

## 2.2 Google Workspace / Cloud Identity super-admin access
- **Description:** Access to a **Google super-admin** account able to change device-management and
  third-party integration settings in the **Google Admin console**.
- **Why required:** Delegating managed Google Play to a third-party Android EMM (Intune) is a
  **super-admin** action performed in the Google Admin console — it cannot be done from Intune alone.
- **How to verify:** Sign in to `admin.google.com` with the account and confirm access to the mobile
  device-management / third-party integration settings (menu location is **verified against current
  Google guidance** — Google moves these; see Implementation).
- **How to implement if missing:** Have an existing Google super-admin grant the role (or perform the
  step) under change control. Record who will act, as the console step is theirs to run.

## 2.3 Least-privilege Intune role for the connection (Global Admin only where required)
- **Description:** The Intune-side connection is performed with **Intune Administrator**, with **Global
  Administrator** used **only** for the initial managed Google Play / Android Enterprise binding where
  it is genuinely required (per GR 3).
- **Why required:** Establishing or changing the Android Enterprise connection is a tenant-level change;
  day-to-day configuration should not use Global Admin.
- **How to verify:** Confirm the role in the Microsoft 365 admin center / Entra roles; confirm
  `Connect-MgGraph` succeeds with the read scopes the discovery scripts request.
- **How to implement if missing:** Have a Global Admin assign Intune Administrator, and reserve Global
  Admin for the single binding step under change control.

## 2.4 A documented current-state baseline (binding + existing devices)
- **Description:** A captured **before** picture: the current managed Google Play connection state (bind
  status, owning account, last app sync) and an inventory of existing Android devices (enrollment type,
  ownership, management state, last check-in).
- **Why required:** The **re-enrollment / end-user impact** question can only be answered against a known
  starting point. Without the baseline you cannot tell whether a device's state changed after the cutover.
- **How to verify:** Run `ANDROIDGW-Discovery.ps1` (binding posture) and `ANDROIDGW-DeviceImpact.ps1`
  (existing devices) — both read-only — and save `Binding Posture – Workspace+Intune – Discovery` and
  `Device Impact – Android – Assess`.
- **How to implement if missing:** Capture the baseline before making any console change; it is the
  reference the pilot is measured against.

## 2.5 The identity/account model is confirmed (Google identity ↔ Entra identity)
- **Description:** A confirmed mapping of how your **Google Workspace / Cloud Identity** user identities
  relate to the **Entra ID** identities Intune uses — in particular the account that will be added to
  managed devices and how managed Google Play resolves the user in a managed domain.
- **Why required:** In the Workspace model users have real Google identities; a mismatch (e.g. UPN vs
  Google primary email, unmatched domains) is a common root cause of enrollment / account-add failures.
- **How to verify:** Confirm the domains used for Entra UPNs and Google primary emails, and that the
  pilot users exist and are correctly licensed in both. `ANDROIDGW-Readiness.ps1` prints an
  identity/account checklist.
- **How to implement if missing:** Reconcile the identity model (matching domains / provisioning) before
  piloting; document the account users will sign in with on devices.

## 2.6 A named pilot scope for the impact assessment
- **Description:** A small, representative **pilot device set and user group** (`MGP Pilot – Android –
  Stage1`) — ideally spanning each enrollment model you actually use (work profile BYOD, fully managed,
  corporate-owned work profile, dedicated/COSU) — used to observe the real re-enrollment / end-user
  impact before fleet rollout.
- **Why required:** Re-enrollment behavior is **state- and version-dependent** and must be **observed**,
  not assumed (GR 6). A representative pilot is how impact is proven safely.
- **How to verify:** Confirm the pilot group exists and its members/devices are identified;
  `ANDROIDGW-Set-Scope.ps1` can create/populate `MGP Pilot – Android – Stage1`.
- **How to implement if missing:** Build the pilot group and enrol/identify its devices before the
  cutover; agree the observation window and pass/fail gate.

## 2.7 Network reachability for managed Google Play and account sign-in
- **Description:** The pilot devices and enrollment path can reach the required **Google** (managed
  Google Play, Android, Google sign-in) and **Microsoft** (Intune, Entra) endpoints, with no proxy or
  content filter blocking managed Google Play account provisioning or Google account sign-in (extends
  GR 5).
- **Why required:** Adding the managed Google account and syncing managed Google Play both require
  reachability; blocked endpoints are the most common cause of "can't add a Google account" during the
  Workspace integration.
- **How to verify:** Confirm the documented Google/Microsoft endpoints are allowed on the pilot device
  network.
- **How to implement if missing:** Allow the current documented endpoints (verify the current list
  against Microsoft/Google guidance) before piloting.

## 2.8 Change control and a documented rollback
- **Description:** An approved **change window** and a written **rollback** for the binding change —
  because a managed Google Play / third-party EMM binding change is **high-impact** and may affect
  existing devices (GR 6).
- **Why required:** If the pilot shows unacceptable impact (e.g. unexpected re-enrollment), you need a
  defined way to stop and revert before broad rollout.
- **How to verify:** Confirm the change record, the approver, and the rollback steps (including who
  reverts the Google Admin console setting) are documented.
- **How to implement if missing:** Draft the change/rollback plan before touching either console; do not
  proceed to the fleet without it.

---
### Requirements at a glance
`Confirm Workspace is the right model → super-admin + least-priv Intune role → baseline binding +
devices → confirm identity/account model → pilot scope → endpoint reachability → change control +
rollback.`

> **Cross-console reality.** This integration is the one Android solution where a **Google super-admin**
> must act in the **Google Admin console** and a Microsoft admin must act in **Intune**. Line up both
> owners, and both consoles' current guidance, before you start.


---


# Global Requirements — Microsoft Intune Android (Android Enterprise) Solutions

These requirements apply to **every** solution in the **Android** category (Android Enterprise
connection & managed Google Play, Google Workspace ↔ Intune EMM integration, the Android Management API
(AMAPI) migration, dedicated/COSU & work-profile enrollment, app management, and enrollment
troubleshooting). Verify each before starting a solution's implementation steps.

> **Vendor boundary (applies to every Android solution).** The **Microsoft Intune admin center**
> (intune.microsoft.com), **Microsoft Graph**, the **managed Google Play** enrollment surface, and the
> **Google Admin console** (for Google Workspace / Cloud Identity integration) are authored at exact,
> current click-by-click / cmdlet detail from Microsoft's and Google's public documentation. The
> **Android Management API (AMAPI)** transition (Intune's move off the legacy Play EMM API) and
> **web-based / account-driven enrollment** are **actively evolving** — steps, defaults, and whether a
> change triggers **re-enrollment** are **cited or flagged "verify against current Microsoft guidance /
> your tenant"**, never asserted from memory or invented. **OEM specifics** (Samsung Knox, Zebra, and
> other rugged/kiosk vendors) and **third-party apps** are integrated at the pattern level; their
> consoles are deferred to the vendor's docs. Automation is **PowerShell** (Microsoft Graph) — never
> with hardcoded credentials or secrets.

## 1. Microsoft 365 tenant with Intune and Android Enterprise
- **Description:** A Microsoft 365 tenant with **Microsoft Intune** and Android Enterprise available,
  and the licensing the capability requires.
- **Why required:** All Android policy, enrollment, and app configuration is performed in Intune.
- **How to verify:** Sign in to the Intune admin center; confirm Android platform availability.
- **How to implement if missing:** Provision/assign Intune licensing before starting.

## 2. The managed Google Play binding (account enterprise OR Google Workspace)
- **Description:** Intune connected to **managed Google Play** — either the **managed Google Play
  account enterprise** (for tenants WITHOUT Google Workspace) or the **Google Workspace / Cloud Identity
  ↔ Intune third-party EMM** integration (for tenants that use Google Workspace). One and only one model
  applies per tenant.
- **Why required:** Android Enterprise enrollment and app delivery depend on the managed Google Play
  connection; the two binding models are mutually exclusive and must be chosen deliberately.
- **How to verify:** Intune admin center → **Devices > Android > Android enterprise (or Enrollment)** —
  confirm the connection status and which model is in place.
- **How to implement if missing:** Establish the correct binding (this is often the first solution in the
  line) before enrolling devices.

## 3. Administrative access (least-privilege Intune roles)
- **Description:** Access with the least-privilege role the solution names — typically **Intune
  Administrator**, with **Global Administrator** only where genuinely required (e.g. the initial managed
  Google Play / Google Workspace binding).
- **Why required:** Enrollment, connector, and app changes require the corresponding role.
- **How to verify:** Confirm the role in the M365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 4. Enrollment method decision and Graph/PowerShell toolchain
- **Description:** A decided **enrollment method** — personally-owned **work profile** (BYOD), **fully
  managed**, **corporate-owned work profile**, or **dedicated / COSU (kiosk)** — plus a workstation with
  **Microsoft Graph PowerShell** for automation.
- **Why required:** Profiles, restrictions, and app assignment differ by enrollment method; the provided
  scripts run through Graph.
- **How to verify:** Confirm the target enrollment method(s) with the device owners; `Connect-MgGraph`
  succeeds.
- **How to implement if missing:** Choose the enrollment method and install Graph PowerShell before starting.

## 5. Network reachability to Google & Microsoft endpoints
- **Description:** Devices and the enrollment path can reach the required **Google (managed Google Play,
  Android)** and **Microsoft (Intune, Entra)** service endpoints (no proxy/filter blocks the enrollment
  or account sign-in).
- **Why required:** Enrollment, managed Google Play account provisioning, and adding a Google account all
  require reachability; blocked endpoints are a common cause of "can't add a Google account" failures.
- **How to verify:** Confirm the required endpoints are allowed on the device network.
- **How to implement if missing:** Allow the documented Google/Microsoft endpoints before enrolling.

## 6. A pilot scope and change control
- **Description:** A **pilot group / small device set** to validate on before fleet-wide rollout, and a
  **change-control** process for production changes (enrollment-model, connector, and AMAPI-migration
  changes are high-impact and may affect existing devices).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and protects the production fleet.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Create a pilot scope and agree change control before production changes.

*The deployment model across every Android solution is the same: **Assess → Design → Configure → Pilot →
Validate → Expand**, with explicit pass/fail gates and a documented rollback for production changes.
Automation is delivered as **PowerShell** (Microsoft Graph) — never with hardcoded credentials or
secrets. Where the AMAPI transition or enrollment behavior is version-dependent, verify against current
Microsoft guidance rather than assuming.*


---


# 3. Implementation Guide — Google Workspace ↔ Intune Third-Party EMM Integration

Follow these steps **in order**. Work happens in three places: the **Intune admin center**
(`https://intune.microsoft.com`), the **Google Admin console** (`https://admin.google.com`), and
**Microsoft Graph PowerShell**. Every script defaults to **read-only or `-WhatIf`** — nothing changes
until you deliberately re-run the one scope helper with `-Commit`. Artifact names follow the
`<Purpose> – <Scope> – <Stage>` convention from the Overview and are reused verbatim.

> **Model:** Assess the current binding and devices, design the identity/account model, configure the
> Google Admin console third-party EMM and the Intune side, **pilot** and **assess re-enrollment /
> end-user impact**, validate account add + app delivery, then expand under change control with a
> rollback ready. Pattern: **Assess → Design → Configure → Pilot → Validate → Expand.**

> **Re-enrollment is not asserted anywhere in this guide.** Where a step touches enrollment impact, it
> tells you to **observe** the result on the pilot and **verify it against current Microsoft/Google
> guidance and your tenant** — never to assume a device will or will not re-enrol.

---

## Step 1 — Confirm this is the right model (Assess)
1. Confirm your organization has a **Google Workspace / Cloud Identity** managed domain (Requirement
   2.1). If you have **no** Google managed domain, stop and use the account-enterprise solution
   (`ANDROIDENT`) instead — the two models are mutually exclusive (GR 2).
2. In Intune, open **Devices → Android → Android enterprise (Enrollment)** and note the current managed
   Google Play connection status and the account it is bound to.
3. Identify the **Google super-admin** who will act in the Google Admin console (Requirement 2.2) and the
   **Intune Administrator / Global Administrator** who will act in Intune (Requirement 2.3).

## Step 2 — Capture the current-state baseline (Assess)
1. Run `ANDROIDGW-Discovery.ps1` (read-only) to record the managed Google Play connection state —
   bind status, owning account/organization, last app sync — into `Binding Posture – Workspace+Intune –
   Discovery`. The script flags whether the current binding looks like an **account enterprise** or a
   **managed-domain / Workspace** binding so you know your starting point.
2. Run `ANDROIDGW-DeviceImpact.ps1` (read-only) to inventory every existing Android device — enrollment
   type, ownership, management state, last check-in — into `Device Impact – Android – Assess`. This is
   the **blast-radius baseline** the pilot is measured against.
3. Keep both exports. They are the reference for answering the re-enrollment question later.

## Step 3 — Confirm the identity/account model (Design)
1. Run `ANDROIDGW-Readiness.ps1` (read-only) to print the integration readiness + identity checklist
   into `Integration Readiness – Workspace+Intune – Assess`: Intune-side prerequisites, the pilot
   users' presence/licensing, and the **Google identity ↔ Entra identity** mapping to confirm
   (Requirement 2.5).
2. Confirm the domains used for Entra UPNs and Google primary emails line up for the pilot users, and
   document the account each user will sign in with on their device.
3. Confirm managed Google Play / Google sign-in endpoints are reachable on the pilot network
   (Requirement 2.7).

## Step 4 — Build and scope the pilot (Design)
1. Run `ANDROIDGW-Set-Scope.ps1` in its default **`-WhatIf`** mode to preview creating/populating the
   pilot group `MGP Pilot – Android – Stage1`. Review the preview — no change is made.
2. Re-run `ANDROIDGW-Set-Scope.ps1 -Commit` to create/populate the pilot group. Include a
   **representative** device for each enrollment model you actually use (work profile BYOD, fully
   managed, corporate-owned work profile, dedicated/COSU) so the impact assessment covers them all.
3. Scope the pilot's app assignments and any enrollment restrictions to `MGP Pilot – Android – Stage1`
   so the change is contained.

## Step 5 — Enable the third-party Android EMM in the Google Admin console (Configure — Google side)
1. The **Google super-admin** signs in to `https://admin.google.com`.
2. Navigate to the **mobile device management → third-party integrations / Android EMM** area and
   **enable a third-party Android EMM provider**, delegating managed Google Play management to Intune.
   > ⚠️ **Verify the current menu path against Google's live guidance.** Google relocates these settings
   > (they have lived under *Devices → Mobile & endpoints → Settings → Third-party integrations* and
   > under an *Android EMM* setting). Do **not** rely on a remembered path — follow Google's current
   > documentation for *managed Google Play with a third-party EMM* / *bind a managed Google domain to
   > an EMM*, and capture any token/identifier the console generates for the Intune side.
3. Record exactly what was enabled, when, and by whom, in the change record (Requirement 2.8) — this is
   the action you will reverse if you roll back.

## Step 6 — Complete the connection on the Intune side (Configure — Microsoft side)
1. In Intune, complete/confirm the **Android Enterprise** connection so managed Google Play is delegated
   to Intune for your domain, following Intune's current in-portal flow for connecting to managed Google
   Play.
   > ⚠️ **Verify the current Intune flow against Microsoft's live guidance.** The connection UX and the
   > interplay with the Google Admin console step evolve (including the **AMAPI** transition). Follow
   > Microsoft's current documentation for connecting Intune to managed Google Play for Google Workspace
   > / Cloud Identity organizations.
2. Re-run `ANDROIDGW-Discovery.ps1` and confirm the binding posture now shows a **bound** state and a
   recent **successful app sync**. If app sync has not completed, trigger/allow a sync and re-check.

## Step 7 — Assess re-enrollment / end-user impact on the pilot (Pilot — the critical gate)
1. On the pilot devices only, **observe** what actually happens after the binding is in place:
   - Do already-managed devices keep checking in and stay compliant, or do they prompt to re-add an
     account / re-enrol?
   - What does the end user see (any account prompt, work-profile change, app re-provisioning)?
2. Re-run `ANDROIDGW-DeviceImpact.ps1` and **diff it against the Step 2 baseline** (`Device Impact –
   Android – Assess`): compare enrollment type, management state, and enrolled/last-check-in dates per
   device to detect any device that re-enrolled or fell out of management.
   > ⚠️ **Do not assume — verify.** Whether any change is expected is **state- and version-dependent**.
   > Confirm the observed behavior against **current Microsoft/Google guidance and your tenant** before
   > drawing a conclusion, and record it in the pilot notes.
3. **Pass/fail gate:** proceed **only** if the pilot devices behave as your verified expectation
   requires (e.g. no unexpected re-enrollment, users retain access, apps still deliver). If not, invoke
   rollback (Step 10) and reassess.

## Step 8 — Validate account add + app delivery on the pilot (Validate)
1. On a fresh/representative pilot device, confirm a pilot user can **add the managed Google account**
   and complete enrollment for the target enrollment model.
2. Assign a known managed Google Play app to `MGP Pilot – Android – Stage1` and confirm it **installs**
   on the pilot devices.
3. Run `ANDROIDGW-Validation.ps1` (read-only) to produce `Account Add + App Delivery – Pilot –
   Validation`: it reports app-sync health, the pilot's assigned managed Google Play apps, and the pilot
   devices' install/compliance state. Complete the **Testing Guide (05)** before expanding.

## Step 9 — Expand to the fleet (Expand)
1. Only after the pilot passes both gates (Step 7 impact, Step 8 validation), broaden scope to
   `MGP Broad – Android – Stage2` in stages (e.g. by enrollment model or business unit), re-observing
   device state at each stage.
2. Re-run `ANDROIDGW-Validation.ps1` to refresh `MGP Sync Health – Android – Report` and confirm the
   connection stays healthy and apps deliver as scope widens.
3. Keep the change record and rollback current until the full fleet is confirmed stable.

## Step 10 — Rollback (if a gate fails)
1. If the pilot shows unacceptable impact, **stop expanding** and follow the documented rollback
   (Requirement 2.8): the Google super-admin reverses the third-party EMM enablement in the Google Admin
   console and the Intune side is reverted per Microsoft's current guidance.
   > ⚠️ Rollback of a managed Google Play / third-party EMM binding is itself **high-impact** and may
   > affect devices. **Verify the current, supported rollback procedure against Microsoft/Google
   > guidance** before executing, and treat it as its own change-controlled action.
2. Re-run `ANDROIDGW-DeviceImpact.ps1` and confirm devices return to the baseline state; reassess the
   plan before attempting the cutover again.

---
### Order of operations
`Confirm model → baseline binding + devices → confirm identity model → build pilot scope → Google Admin
console third-party EMM → Intune side → assess re-enrollment impact (gate) → validate account add + app
delivery (gate) → expand in stages → rollback ready throughout.`

### Pass/fail gates
- **Gate A (impact):** pilot devices behave as your *verified* expectation requires — no unexpected
  re-enrollment or loss of management; users retain access.
- **Gate B (validation):** pilot users can add the managed Google account and assigned managed Google
  Play apps install; connection/app sync is healthy.
- **Rollback trigger:** either gate fails → stop, revert the Google Admin console + Intune change per
  current guidance, return to baseline, reassess.


---


# 5. Testing & Validation Guide — Google Workspace ↔ Intune Third-Party EMM Integration

Testing proves two things: (A) the integration is **active and healthy**, and (B) enabling it did **not**
cause **unexpected** re-enrollment or loss of management on existing devices. Run these checks on the
**pilot** first and pass every gate before expanding. All test scripts are **read-only**.

> **The re-enrollment result is observed, not assumed.** Every impact check below compares the pilot's
> real state to the Step 2 baseline and asks you to **verify the interpretation against current
> Microsoft/Google guidance and your tenant** — the tests measure; they do not predict.

---

## Test 1 — Binding is active and app sync is healthy
- **How:** Run `ANDROIDGW-Discovery.ps1` (read-only) after Step 6.
- **Pass:** The managed Google Play connection shows a **bound** state, an owning account/organization
  consistent with your Google Workspace domain, and a **recent successful** last app sync.
- **Fail:** Not bound, bound to an unexpected account, or a failed/stale app sync → re-check the Google
  Admin console third-party EMM enablement and the Intune connection (Implementation Steps 5–6).

## Test 2 — Existing-device baseline captured (pre-change)
- **How:** Confirm `Device Impact – Android – Assess` was captured **before** the Google Admin console
  change (Implementation Step 2) with `ANDROIDGW-DeviceImpact.ps1`.
- **Pass:** A saved baseline lists every existing Android device with enrollment type, ownership,
  management state, and last check-in.
- **Fail:** No pre-change baseline → you cannot answer the re-enrollment question objectively. Do **not**
  proceed to broad rollout; recapture on any devices still in the prior state if possible.

## Test 3 — Re-enrollment / impact assessment on the pilot (the critical gate)
- **How:** After the binding is in place, re-run `ANDROIDGW-DeviceImpact.ps1` and **diff** it against the
  Test 2 baseline for the pilot devices — compare enrollment type, management state, and
  enrolled/last-check-in dates per device.
- **Pass:** Pilot devices behave as your **verified expectation** requires (e.g. they keep checking in,
  stay compliant, and did not silently re-enrol or drop out of management), and users report no loss of
  access.
- **Fail:** Any device shows an **unexpected** change (new enrolled date, changed enrollment type,
  fell out of management) that your verification does **not** account for → invoke rollback
  (Implementation Step 10) and reassess.
- **⚠️ Verify:** Confirm whether an observed change is expected against **current Microsoft/Google
  guidance and your tenant** before calling this pass or fail — do not assume.

## Test 4 — End-user experience on the pilot
- **How:** Have pilot users use their devices normally for the agreed observation window; collect what
  they saw (any account prompt, work-profile change, app re-provisioning).
- **Pass:** No unexpected prompts or interruptions beyond what your verified expectation allows; users
  retain access to work apps and data.
- **Fail:** Users hit account-add prompts, lost work profiles, or missing apps not explained by your
  verified expectation → rollback and reassess.

## Test 5 — Account add on a fresh enrollment
- **How:** On a representative pilot device for each enrollment model in scope, have a pilot user add the
  managed Google account and complete enrollment.
- **Pass:** The account adds cleanly and the device enrols in the intended model.
- **Fail:** "Can't add a Google account" / account resolution errors → check identity/account mapping
  (Requirement 2.5) and endpoint reachability (Requirement 2.7); see Troubleshooting.

## Test 6 — App delivery to the pilot
- **How:** Assign a known managed Google Play app to `MGP Pilot – Android – Stage1`; run
  `ANDROIDGW-Validation.ps1` and confirm on-device install.
- **Pass:** The app appears in managed Google Play and installs on pilot devices; `Account Add + App
  Delivery – Pilot – Validation` shows the expected assigned apps and install/compliance state.
- **Fail:** App not synced or not installing → re-check app sync (Test 1) and assignment scope.

## Test 7 — Connection health holds as scope expands
- **How:** During Expand (Implementation Step 9), re-run `ANDROIDGW-Validation.ps1` at each stage to
  refresh `MGP Sync Health – Android – Report`.
- **Pass:** Bind state stays bound, app sync stays successful, and newly-scoped devices deliver apps and
  stay compliant.
- **Fail:** Any regression → pause expansion, investigate, and keep rollback ready.

## Test 8 — Rollback is exercised and understood
- **How:** Confirm the documented rollback (Requirement 2.8 / Implementation Step 10) is written and the
  Google super-admin knows the reversal step; dry-run the decision path.
- **Pass:** A verified rollback procedure exists and returns pilot devices to baseline in a table-top
  check.
- **Fail:** No verified rollback → do not proceed to broad rollout.

---
### Exit criteria (all must hold before Expand)
1. Binding **bound** with a healthy, recent app sync (Test 1).
2. A pre-change device baseline exists (Test 2).
3. Pilot re-enrollment/impact matches your **verified** expectation — no unexpected changes (Test 3).
4. Pilot end-user experience acceptable (Test 4).
5. Account add + app delivery succeed on the pilot (Tests 5–6).
6. A verified rollback is ready (Test 8).

> If any exit criterion fails, **do not expand.** Roll back per current Microsoft/Google guidance, return
> to baseline, and reassess. The value of this solution is a clear, evidence-based impact read — honor it.


---


# 6. Troubleshooting — Google Workspace ↔ Intune Third-Party EMM Integration

A symptom → likely root cause → fix playbook for the Google Workspace / Cloud Identity ↔ Intune
third-party EMM integration. Work top-down; each item names the script or console area to check.

> **Golden rule for every enrollment-impact symptom:** measure it (baseline vs current with
> `ANDROIDGW-DeviceImpact.ps1`) and **verify the interpretation against current Microsoft/Google
> guidance and your tenant**. Do **not** conclude "the integration re-enrolled the fleet" (or "it
> won't") from memory — confirm it.

---

## A. Model / binding problems

### A1 — "This account is already a managed Google Play enterprise" / domain conflict
- **Likely cause:** An **account-enterprise** binding (`ANDROIDENT`) already exists, or the same Google
  domain is bound both ways — the two models are mutually exclusive (GR 2).
- **Fix:** Run `ANDROIDGW-Discovery.ps1` and read the `ModelHint` + owner. Confirm in the Intune admin
  center which binding is present. If an account enterprise is bound but you need the Workspace
  third-party EMM model, resolve the binding deliberately under change control (verify the current,
  supported procedure with Microsoft) before enabling the Google-side integration.

### A2 — You have no Google managed domain but followed this solution
- **Likely cause:** Wrong solution — this is only for tenants with Google Workspace / Cloud Identity.
- **Fix:** Use the account-enterprise solution (`ANDROIDENT`) instead (Requirement 2.1).

### A3 — Binding shows "not bound" after completing both consoles
- **Likely cause:** The Google Admin console third-party EMM enablement or the Intune connection did not
  fully complete, or app sync has not run.
- **Fix:** Re-run `ANDROIDGW-Discovery.ps1`; if `bindStatus` is not bound, re-check the Google Admin
  console setting (super-admin) and the Intune connection flow against **current** guidance
  (Implementation Steps 5–6). Allow/trigger an app sync and re-check.

## B. Google Admin console side

### B1 — Can't find the third-party Android EMM / managed Google Play setting
- **Likely cause:** Google relocated the setting (it has lived under *Devices → Mobile & endpoints →
  Settings → Third-party integrations* and under an *Android EMM* setting).
- **Fix:** Do **not** rely on a remembered path — follow Google's **current** documentation for using
  managed Google Play with a third-party EMM / binding a managed Google domain to an EMM. Confirm the
  acting account is a **super-admin** (Requirement 2.2).

### B2 — The console generated a token/identifier but the Intune side won't accept it
- **Likely cause:** Token not captured/entered correctly, or the Intune flow expects a different step in
  the current version.
- **Fix:** Re-capture exactly what the Google console produced; follow Microsoft's current Intune
  connection flow. If the flow has changed (AMAPI transition), verify the current end-to-end procedure
  before retrying, and record the steps in the change record.

## C. Identity / account-add problems

### C1 — "Can't add a Google account" during enrollment
- **Likely cause (most common):** Endpoint reachability — managed Google Play / Google sign-in blocked
  on the device network (Requirement 2.7); or an identity mismatch (Entra UPN vs Google primary email).
- **Fix:** Confirm the required Google/Microsoft endpoints are allowed (verify the current list). Run
  `ANDROIDGW-Readiness.ps1` and resolve any identity/domain mismatch (Requirement 2.5). Retry on a known-
  good network.

### C2 — Account adds but the user resolves to the wrong identity / no apps
- **Likely cause:** Google identity ↔ Entra identity mapping is off, or the user isn't licensed/in scope.
- **Fix:** Run `ANDROIDGW-Readiness.ps1` for the user (presence + licensing) and confirm domains align.
  Confirm the user is in the pilot scope and app assignments target `MGP Pilot – Android – Stage1`.

## D. App delivery / sync

### D1 — Assigned managed Google Play apps don't install
- **Likely cause:** Failed/stale app sync, or the app isn't assigned to the device's group.
- **Fix:** Run `ANDROIDGW-Validation.ps1`: check `lastAppSyncStatus` (should be success) and that the
  app shows the expected assignment. Trigger/allow a sync; re-scope the assignment if needed.

### D2 — App sync status is failed
- **Likely cause:** Connection health degraded (binding, token, or service issue).
- **Fix:** Re-run `ANDROIDGW-Discovery.ps1` for bind state; re-verify the connection on both consoles.
  Refresh `MGP Sync Health – Android – Report` and monitor.

## E. Re-enrollment / device-impact scenarios (handle with care)

### E1 — After the cutover, some devices show a new enrolled-date
- **Likely cause:** Possible re-enrollment — **or** a benign state change. A changed enrolled-date does
  **not** by itself prove the integration re-enrolled the device.
- **Fix:** Run `ANDROIDGW-DeviceImpact.ps1 -BaselineCsv <baseline>` and review the diff. Correlate with
  the change window. **Verify against current Microsoft/Google guidance** whether the observed change is
  expected for your enrollment models. If it is unexpected and disruptive, invoke rollback
  (Implementation Step 10). Never assert cause from the diff alone.

### E2 — Devices dropped out of management after the change
- **Likely cause:** Enrollment/connection state changed in a way the devices didn't follow, or an
  identity/scope problem.
- **Fix:** Use the impact diff to list dropped devices; check their user/identity and scope. If the pilot
  shows this, **stop expanding**, roll back per current guidance, and reassess before retrying.

### E3 — Users report unexpected prompts or lost work profiles on the pilot
- **Likely cause:** The change affected existing profiles in a way your expectation didn't account for.
- **Fix:** Treat as a **Gate A failure** (Testing 05, Test 3–4): roll back, capture what users saw,
  verify expected behavior against current guidance, and only retry once the expected experience is
  confirmed.

### E4 — Dedicated/COSU or rugged (Samsung Knox/Zebra) devices behave differently from phones
- **Likely cause:** OEM/kiosk enrollment paths are the most sensitive to binding changes and are
  vendor-specific (pattern level here).
- **Fix:** Test these device classes **explicitly** in the pilot; defer OEM-console specifics to the
  vendor's current docs. Do not infer their behavior from a personal phone.

## F. Rollback

### F1 — Need to revert the integration
- **Likely cause:** A gate failed and you must return to baseline.
- **Fix:** The Google super-admin reverses the third-party EMM enablement in the Google Admin console and
  the Intune side is reverted — **verify the current, supported rollback procedure against
  Microsoft/Google guidance first**, as rollback is itself high-impact. Re-run `ANDROIDGW-DeviceImpact.ps1`
  and confirm devices return to the baseline state (Implementation Step 10).

---
### Escalation checklist before opening a vendor case
1. `ANDROIDGW-Discovery.ps1` output (bind status, owner, app-sync status) — for Microsoft.
2. `ANDROIDGW-DeviceImpact.ps1` baseline **and** post-change diff — the objective evidence of what
   changed.
3. The Google Admin console change record (what was enabled, when, by which super-admin).
4. The specific enrollment model(s) affected and whether behavior was confirmed against current guidance.
5. Whether the issue reproduces on the pilot scope only or fleet-wide.


---


# 7. Best Practices — Google Workspace ↔ Intune Third-Party EMM Integration

Field-tested principles for integrating Google Workspace / Cloud Identity with Intune as a third-party
EMM for managed Google Play — with the re-enrollment question treated honestly throughout.

## Model & identity
- **Confirm the model before anything else.** Verify you have a Google Workspace / Cloud Identity managed
  domain and therefore need the **third-party EMM** integration, not the account-enterprise bind
  (`ANDROIDENT`). Never run both — one model per tenant (GR 2).
- **Reconcile identities up front.** Line up Entra UPNs and Google primary emails for the pilot users
  before you touch either console; unmatched domains/identities are the top cause of "can't add
  account" in the Workspace model.
- **Document the sign-in account.** Record exactly which account users add on devices, so support can
  reproduce and triage.

## Re-enrollment discipline (the heart of this solution)
- **Never assert re-enrollment behavior — observe it.** Whether a binding change re-enrols existing
  devices is state- and version-dependent and **actively evolving** (including the AMAPI transition).
  Measure it on a pilot; verify against current Microsoft/Google guidance; then decide.
- **Baseline before you touch anything.** Capture the binding posture and full device inventory
  *before* the Google Admin console change — it is the only way to prove what changed.
- **Pilot every enrollment model you actually run.** Work profile BYOD, fully managed, corporate-owned
  work profile, and dedicated/COSU can behave differently; include a representative of each in
  `MGP Pilot – Android – Stage1`.
- **Diff, don't eyeball.** Compare the post-change device report to the baseline per device (enrollment
  type, management state, enrolled/last-check-in dates) rather than trusting a glance at the console.

## Cross-console change control
- **Two owners, one change window.** The Google super-admin and the Intune admin act in a coordinated,
  change-controlled window — not ad hoc, and not by two people independently.
- **Write the rollback first.** Know exactly how the Google super-admin reverses the third-party EMM
  enablement and how the Intune side reverts, and verify that procedure against current guidance —
  before you enable anything.
- **Record the token/identifiers.** Capture anything the Google Admin console generates during
  enablement so the Intune side and any rollback are reproducible.

## Verify-against-current-guidance habit
- **Treat every console path as perishable.** Google relocates the third-party integration setting and
  Microsoft evolves the Intune connection flow; follow **live** documentation for both, not remembered
  paths.
- **Flag beta surfaces.** Some binding-state Graph resources (e.g.
  `androidManagedStoreAccountEnterpriseSettings`, Android enrollment profiles) are on the Graph **beta**
  endpoint — verify their shape in your tenant and expect change.

## Scope, safety, and automation
- **Contain the pilot with scope.** Assign apps and enrollment restrictions to the pilot group so the
  change is bounded; expand only in stages.
- **Keep automation read-only by default.** Discovery, readiness, validation, and device-impact scripts
  are read-only; only the scope helper writes, and only with `-Commit`. Request least Graph scopes; keep
  no credentials in code.
- **Re-run health as you expand.** Refresh `MGP Sync Health – Android – Report` at each expansion stage;
  a regression is a signal to pause.

## Operations
- **Communicate to users before the cutover.** Even if your verified expectation is "no impact," tell
  pilot users what to expect and how to report anything odd — it turns surprises into fast signal.
- **Watch app sync continuously.** A stale or failed managed Google Play sync silently breaks app
  delivery; alert on it.
- **Re-baseline after big changes.** After the fleet is stable, capture a fresh binding + device
  baseline so future changes (including AMAPI-driven ones) have a current reference.

## OEM & third-party (pattern level)
- **Defer OEM consoles to the vendor.** Samsung Knox, Zebra, and other rugged/kiosk specifics are
  integrated at the pattern level; follow the vendor's current docs for their console.
- **Test OEM/kiosk devices explicitly in the pilot.** Dedicated/COSU and rugged devices are the most
  sensitive to enrollment changes — do not infer their behavior from a phone.


---


# 8. Deliverables Summary — Google Workspace ↔ Intune Third-Party EMM Integration

Everything included in this solution, and what each piece is for. The through-line: integrate Google
Workspace / Cloud Identity with Intune as a third-party EMM for managed Google Play — and get an honest,
evidence-based read on **re-enrollment / end-user impact** — following **Assess → Design → Configure →
Pilot → Validate → Expand**.

## Documentation
| Document | What it gives you |
|---|---|
| **01 — Solution Overview** | The Google Workspace ↔ Intune third-party EMM model vs the account-enterprise bind, how managed Google Play is delegated, the identity/account implications, and how the re-enrollment question is treated (measured + piloted, never asserted). |
| **02 — Requirements Guide** | Solution-specific prerequisites (right model, Google super-admin, least-priv Intune role, current-state baseline, identity/account model, pilot scope, reachability, change control) each with verify/implement, on top of the six category Global Requirements. |
| **03 — Implementation Guide** | Exact ordered steps across the Google Admin console, Intune, and Graph — baseline, identity model, configure both sides, pilot the impact assessment, validate account add + app delivery, expand, with pass/fail gates and a rollback. |
| **05 — Testing & Validation** | Eight tests with explicit exit criteria: binding active, pre-change baseline, re-enrollment/impact diff (the critical gate), end-user experience, account add, app delivery, health-holds-on-expand, rollback ready. |
| **06 — Troubleshooting** | A symptom → root-cause → fix playbook for wrong-model/domain conflicts, "can't add a Google account," app sync failures, and the re-enrollment/impact scenarios. |
| **07 — Best Practices** | Model & identity discipline, the re-enrollment discipline, cross-console change control, the verify-against-current-guidance habit, scope/safety/automation, and operations. |
| **Executive Summary** | A one-page business framing for approvers: the risk, the approach, and the outcome. |

## PowerShell tools (Microsoft Graph) — read-only or -WhatIf by default, no credentials in code
| Script | Role | Safety |
|---|---|---|
| **ANDROIDGW-Discovery.ps1** | Current managed Google Play binding + Workspace-integration posture assessment; flags the likely binding model and app-sync health; device baseline. | Read-only |
| **ANDROIDGW-Readiness.ps1** | Integration-readiness + identity checker: Intune prereqs, pilot-user presence/licensing, Google-identity↔Entra mapping, and the manual Google-side items. | Read-only |
| **ANDROIDGW-Validation.ps1** | Account-add + app-delivery validation report: connection health, assigned managed Google Play apps, pilot device compliance/check-in. | Read-only |
| **ANDROIDGW-DeviceImpact.ps1** | Existing-device impact / enrollment-state report; baseline before, diff after — measures (never asserts) re-enrollment impact. | Read-only |
| **ANDROIDGW-Set-Scope.ps1** | Scope/config helper: creates & populates the pilot group so the change is contained; read-reports the current enrollment target. | **-WhatIf by default**; writes only the reversible pilot group with **-Commit** |

## Named artifacts (the `<Purpose> – <Scope> – <Stage>` set)
`Binding Posture – Workspace+Intune – Discovery` · `Integration Readiness – Workspace+Intune – Assess` ·
`Device Impact – Android – Assess` · `MGP Pilot – Android – Stage1` · `Account Add + App Delivery –
Pilot – Validation` · `MGP Broad – Android – Stage2` · `MGP Sync Health – Android – Report`.

## What "done" looks like
- The correct model confirmed (Workspace third-party EMM, not account-enterprise), with a captured
  current-state baseline of binding and devices.
- The Google Admin console third-party EMM enabled by a super-admin and the Intune side completed, with
  a **bound** connection and healthy app sync.
- The **re-enrollment / end-user impact assessed on a pilot** and **verified against current
  Microsoft/Google guidance** — no unexpected re-enrollment, users retain access.
- Account add + app delivery validated on the pilot, then expanded under change control with a verified
  rollback ready throughout.

> **Scope boundaries.** Re-enrollment behavior, the AMAPI transition, and web/account-driven enrollment
> are actively evolving — this solution measures and pilots them and flags "verify against current
> guidance," never asserting from memory. The Google Admin console is deferred to Google's current docs;
> OEM (Samsung Knox/Zebra) and third-party apps are covered at the pattern level. The account-enterprise
> bind is a separate solution (`ANDROIDENT`).
