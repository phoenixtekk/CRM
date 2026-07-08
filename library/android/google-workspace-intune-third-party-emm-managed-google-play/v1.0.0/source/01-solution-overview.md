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
