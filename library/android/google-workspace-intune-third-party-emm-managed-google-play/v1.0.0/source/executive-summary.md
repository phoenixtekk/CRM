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
