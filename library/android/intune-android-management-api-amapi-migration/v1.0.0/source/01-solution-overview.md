# Solution Overview

## What this solution does

Microsoft is moving Intune's Android Enterprise management from the **legacy Google Play EMM
API** to the **Android Management API (AMAPI)**. This solution is the migration playbook for that
transition: you **assess** the organization's current Android estate and enrollment models,
**plan** a migration wave, **execute** the move (including the newer **web / account-driven
enrollment** path where it applies), **validate** that devices manage under AMAPI, that Google
accounts add, and that apps still deliver — and you handle the common post-migration failures.

The single question every team asks — *"do our devices re-enroll, and what does the end user
see?"* — is treated as a **first-class risk**, not a footnote. Because the AMAPI transition,
web/account-driven enrollment, and re-enrollment behavior are **actively evolving**, this playbook
**flags every version-specific behavior for verification against current Microsoft guidance and
your own tenant** rather than asserting a fixed timeline or outcome from memory.

> **Verify-first discipline (state this to stakeholders).** The AMAPI rollout is staged and
> changing. Timelines, which enrollment methods move when, the exact portal labels, and — most
> importantly — **whether any given device re-enrolls** are things you must confirm against
> Microsoft's current Android Management API / "What's new" documentation and by testing in your
> pilot. Where this document says **"verify against current Microsoft guidance,"** treat it as a
> hard gate, not advice.

## What AMAPI is, and how it differs from the legacy Play EMM API

**Android Enterprise** is Google's framework for managing Android in the enterprise (managed
Google Play, work profiles, fully managed and dedicated devices). An EMM such as Intune talks to
Google through an API to provision the managed Google Play enterprise, push apps, and drive
enrollment and policy.

- **Legacy Play EMM API** — the original Google Play EMM API that Intune has historically used to
  broker Android Enterprise management.
- **Android Management API (AMAPI)** — Google's **newer, consolidated** management API. Microsoft
  is transitioning Intune's Android Enterprise capabilities onto AMAPI. Much of the change is a
  **backend / service-side** move: the management *plane* changes, while the day-to-day admin
  concepts (work profile, fully managed, dedicated/COSU, managed Google Play apps) remain.

What this means in practice, at the level you can rely on:

- The **enrollment models are conceptually the same** — personally-owned **work profile (BYOD)**,
  **fully managed**, **corporate-owned work profile**, and **dedicated / COSU (kiosk)** — but the
  **enrollment mechanics and available options can shift** as methods move to AMAPI. **Verify the
  current enrollment options for each model in your tenant.**
- A newer **web-based / account-driven enrollment** experience is part of the modern Android
  enrollment direction. **Its availability, the exact user flow, and which device types it
  applies to are evolving — verify against current Microsoft guidance before you design around
  it.**
- **Whether a device re-enrolls is the key unknown and is version-dependent.** Do **not** promise
  end users "no re-enrollment" (or "you must re-enroll") until you have confirmed the behavior for
  your specific enrollment model, device type, and the current state of the AMAPI rollout. **Test
  it in the pilot and read it off Microsoft's current guidance.**

## The enrollment methods affected

| Enrollment model | What it is | Migration sensitivity |
|------------------|-----------|-----------------------|
| **Work profile (BYOD)** | Personally-owned device with a managed work profile | High-visibility to end users; re-enrollment / re-consent behavior **must be verified** |
| **Fully managed** | Corporate-owned, fully managed device | Corporate-owned; coordinate any re-enrollment as a change |
| **Corporate-owned work profile** | Corporate device with a separate work profile | As above; verify user-facing impact |
| **Dedicated / COSU (kiosk)** | Single-purpose / shared kiosk devices, no user affinity | Often no interactive user, but a re-provision can wipe/reset a kiosk — **verify and stage carefully** |

For each model, the **user-facing impact** (re-enrollment, re-consent, a wipe of the work
profile, or nothing at all) is **exactly what you validate in the pilot before you expand** — and
exactly what you communicate to users **only after** you have confirmed it.

## The web / account-driven enrollment path

Modern Android enrollment is trending toward a **web-based / account-driven** experience (the user
signs in and the enrollment is driven from an account/web flow rather than a QR/token-first
setup). This solution includes a **readiness check** for that path — managed Google Play binding
present, enrollment profiles configured, network endpoints reachable — but treats the **exact
availability and flow as evolving**. **Confirm whether web/account-driven enrollment is available
for your enrollment model and tenant against current Microsoft guidance before committing to it in
the wave plan.**

## The managed Google Play binding still underpins everything

AMAPI does not remove the **managed Google Play** connection — Android Enterprise still depends on
it. Per the category **Global Requirements**, exactly one binding model applies to the tenant:

- **Managed Google Play account enterprise** (tenants **without** Google Workspace), or
- **Google Workspace / Cloud Identity ↔ Intune third-party EMM** (tenants that **use** Google
  Workspace).

The migration assumes this binding is healthy. If it is not, fix the binding first (see the
category Global Requirements and the connection solution) before migrating.

## Benefits

- **Migrate with eyes open** — the estate is assessed, the wave is planned, and the end-user /
  re-enrollment impact is **verified**, not assumed.
- **Low disruption** — pilot-first, with explicit pass/fail gates and a documented rollback before
  any production wave.
- **Evidence-backed** — five Microsoft Graph PowerShell tools inventory the estate, plan waves,
  check web-enrollment readiness, and produce a post-migration validation report.
- **Current, not stale** — every version-specific behavior is flagged for verification against
  Microsoft's live guidance, so the plan does not rot as AMAPI evolves.

## Limitations and boundaries

- **Not a source of AMAPI timelines.** This solution does **not** publish a Microsoft rollout
  timeline or assert re-enrollment behavior — those are read from Microsoft's current guidance and
  proven in your pilot.
- **No invented cmdlets or portal paths.** Where Microsoft's exact blade label or a Graph property
  is version-dependent, it is flagged **"verify in your tenant."** The scripts use only documented,
  read-only Graph reads (plus optional `-WhatIf`-gated group creation for wave planning).
- **OEM and third-party apps at the pattern level.** Samsung Knox, Zebra, and other rugged/kiosk
  specifics defer to the vendor's documentation; managed Google Play and Graph are authored
  exactly.
- **Assumes the category prerequisites are met** — a healthy managed Google Play binding, Intune
  as MDM authority, admin roles, and network reachability (see the Global Requirements).
- **Post-migration deep troubleshooting** cross-references the dedicated **Android enrollment
  troubleshooting (Google account / AMAPI)** solution for symptom-level "can't add a Google
  account" / enrollment-failure diagnosis.

## Deployment model

This solution follows the standard house model — **Assess → Design → Configure → Pilot → Validate
→ Expand** — with explicit pass/fail gates and a documented rollback at each production step:

1. **Assess** — inventory the Android estate and current enrollment models
   (`AMAPIMIG-Assess-AndroidEstate.ps1`) and confirm the managed Google Play binding health
   (`AMAPIMIG-Config.ps1`).
2. **Design** — plan the migration wave and define pilot/production cohorts
   (`AMAPIMIG-New-MigrationWavePlan.ps1`); decide the enrollment path per model, **after**
   verifying web/account-driven availability (`AMAPIMIG-Test-WebEnrollmentReadiness.ps1`).
3. **Configure** — prepare enrollment profiles, app assignments, and wave groups (safe/`-WhatIf`
   helpers).
4. **Pilot** — migrate a small cohort; **observe the actual end-user / re-enrollment behavior**.
5. **Validate** — devices manage under AMAPI, accounts add, apps deliver
   (`AMAPIMIG-Get-PostMigrationValidation.ps1`).
6. **Expand** — promote wave by wave; keep the validation and diagnostic tools on hand.
