# 1. Solution Overview — Cloud-App DLP (Defender for Cloud Apps)

## What this solution is
Sensitive data does not only live in Microsoft 365. It lives in the third-party SaaS apps your business
runs on — file-sharing (Box, Dropbox, Google Drive), CRM (Salesforce), ITSM (ServiceNow), HR, and dozens
more. Native Microsoft Purview DLP covers Exchange, SharePoint, OneDrive, Teams, and endpoints; it does
**not**, on its own, reach into those non-Microsoft clouds. That gap is where regulated data quietly
accumulates and leaves.

**Microsoft Defender for Cloud Apps (MDCA)** — Microsoft's Cloud Access Security Broker (CASB) — closes
that gap with two complementary controls:

- **File policies** inspect files **at rest** inside connected SaaS apps (via each app's **API connector**),
  match their *content* against **sensitive information types (SITs)** and **sensitivity labels**, and apply
  **governance actions** — send an alert, notify the owner, remove external/public sharing, apply a
  sensitivity label, quarantine, or trash.
- **Session policies** apply controls in **real time** as users interact with cloud apps — through
  **Conditional Access App Control** (a reverse proxy Microsoft Entra routes sessions to) — to **monitor**,
  **block download/upload/copy/paste/print**, or **protect on download** (apply a label/encryption).

This solution is a repeatable, evidence-driven way to extend DLP to third-party cloud apps using only the
**Microsoft Defender portal** (security.microsoft.com → **Cloud apps**), **Microsoft Entra Conditional
Access**, **Security & Compliance PowerShell**, and **Microsoft Graph** — no third-party CASB tooling. Its
defining discipline mirrors the rest of the Purview estate: **every control is piloted in a safe TEST mode
first** — Conditional Access in **report-only**, session policies set to **Monitor only**, and file policies
to **alert-only** — proven on a **pilot ring**, tuned for low false positives, and only then moved to
enforcement (block / protect / quarantine).

> **Scope boundary.** This solution delivers the **technical method and evidence** for cloud-app DLP.
> *Which* SaaS apps and data are in scope, *which* classifiers legally apply, and *what* governance/session
> action a given data category warrants are **business, compliance, privacy, and legal determinations** —
> deferred to those functions. The solution configures and proves the control; it does not make the policy
> decision.

## Why this matters
- **Third-party SaaS is the DLP blind spot.** A customer list synced to a personal Dropbox, a contract
  shared "anyone with the link" from Box, or a bulk export downloaded from Salesforce onto an unmanaged
  laptop never touches a Microsoft workload — so native Purview DLP never sees it. MDCA is the control that
  does.
- **Two problems, two mechanisms.** *Data already sitting* in a SaaS app is a **file-policy** (at-rest,
  API-connector) problem; *data moving in a live session* (download to an unmanaged device, upload, copy)
  is a **session-policy** (real-time, reverse-proxy) problem. Using the wrong one leaves a gap. This
  solution deploys both, deliberately.
- **Enforcing without a test phase breaks the business.** A session policy set straight to *block download*,
  or a file policy set straight to *quarantine*, will stop legitimate work and get switched off. The safe
  path — report-only Conditional Access, Monitor-only sessions, alert-only file governance, on a pilot ring
  — is what makes the control survive.
- **It reuses your existing classification investment.** MDCA content inspection uses the same Purview
  **SITs** and **sensitivity labels** that drive your Microsoft-365 DLP, so cloud-app DLP is an *extension*
  of the classification layer you already have, not a parallel one.

## How it works
1. **Connect the apps you want to govern at rest.** In **Cloud apps → App connectors**, connect each SaaS
   app via its **API connector** (OAuth). The connector lets MDCA scan files, see sharing state, and take
   governance actions inside that app. *File policies require a connected app.*
2. **Onboard apps for real-time session control.** In **Microsoft Entra → Conditional Access**, create a
   policy with **Session → Use Conditional Access App Control** that routes the target users/apps through
   the MDCA reverse proxy. Onboarded apps appear under **Cloud apps → Conditional Access App Control apps**.
   *Session and access policies require this routing.*
3. **Define detection with SITs and labels.** MDCA inspects content using Purview **sensitive information
   types** (built-in / custom / EDM) via the Microsoft Data Classification Service, and can match on
   **sensitivity labels**. This is the same classification layer as native DLP.
4. **Build file policies (data at rest).** A **file policy** filters connected-app files by content (SIT),
   label, sharing state, owner, or app, and applies **governance actions** — alert, notify, remove sharing,
   apply label, quarantine, trash — **alert-only first**.
5. **Build session policies (real time).** A **session policy** on a Conditional-Access-App-Control app
   controls live activities — download, upload, copy, paste, print, send — with actions **Monitor only**,
   **Block**, or **Protect** (apply label/encryption on download) — **Monitor only first**.
6. **Pilot in test mode, tune, then enforce.** Run Conditional Access in **report-only**, session policies
   in **Monitor only**, and file policies in **alert-only** on a **pilot ring**; measure matches and false
   positives; then move to enforcement (block / protect / quarantine) and expand.

## The two control planes (and what each covers)
| Plane | Mechanism | Covers | Requires | Example action |
|---|---|---|---|---|
| **File policy** | API connector (at rest) | Files already stored in a connected SaaS app; sharing state | An **app connector** for that app | Remove external sharing; apply label; quarantine |
| **Session policy** | Conditional Access App Control (real-time reverse proxy) | Live user activity in a cloud-app session | An **Entra CA policy** routing sessions to MDCA | Block download to unmanaged device; protect on download |
| **Access policy** | Conditional Access App Control (real-time) | Whether a session is allowed at all | An **Entra CA policy** routing sessions to MDCA | Block access from unmanaged/non-compliant device |

## The pilot→enforce journey (the core discipline)
> Connect apps (API) + onboard apps (CA App Control) → define detection with SITs/labels → build **file
> policies (alert-only)** and **session policies (Monitor only)** with the CA policy in **report-only**, on a
> **pilot ring** → measure matches and false positives → **tune** (SIT confidence/instance count, label
> filters, app/folder scope, exclusions) → enforce on the ring (governance actions on; CA policy on; session
> action Block/Protect) → validate → **expand** to the full scope → operate (triage alerts, review, re-tune).

## What you can control
- Which **SaaS apps** are connected (file policy) and which are onboarded to **CA App Control** (session).
- Which **SITs / sensitivity labels** each policy matches, at what confidence and instance count.
- Which **users/groups/apps** each session/access policy applies to (via the Conditional Access assignment).
- The **governance action** per file policy (alert → notify → remove sharing → apply label → quarantine →
  trash) and the **session action** (Monitor → Block → Protect) — set per compliance's determination.
- The **pilot ring** enforced first and how long you dwell in test mode before enforcing.

## Limitations (be honest with buyers)
- **MDCA is licensing-dependent.** Defender for Cloud Apps requires the appropriate plan (available with
  **Microsoft 365 E5 / E5 Security / E5 Compliance** or standalone) — **verify your licensing/tenant.**
  Content inspection with Purview SITs/labels and Conditional Access App Control likewise depend on your
  plan.
- **File policies require a connected app; session/access policies require Conditional Access App Control
  routing.** Neither works "out of the box" — a file policy is inert until the app's **API connector** is
  connected; a session policy is inert until an **Entra CA policy** routes sessions to the proxy.
- **Session control (reverse proxy) has coverage and app-compatibility limits.** Some apps, native/desktop
  clients, and activities are not fully proxy-controllable — Microsoft maintains the list of featured/
  supported apps; **verify the target app is supported** for session control.
- **The portal is evolving.** MDCA now lives inside the **Microsoft Defender portal**
  (security.microsoft.com → **Cloud apps**); the legacy standalone portal is being retired. Paths are cited
  from Microsoft's public docs and flagged "verify your tenant."
- **The governance/session action per data category is a compliance/legal decision**, not a technical
  default — this solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses a consistent `<Mechanism> – <Scope> – <Type>` form, reused
verbatim across the docs, scripts, the Defender portal, and Entra. The standard set:

| Artifact | Name |
|---|---|
| App connector (API, data at rest) | `Box – App Connector – API` *(example SaaS app)* |
| Conditional Access App Control policy (Entra) | `MDCA – CA App Control – Session Routing` |
| File policy (data at rest) | `MDCA – SaaS Files PII – File Policy` |
| Session policy (real-time) | `MDCA – Download Protect PII – Session Policy` |
| Access policy (optional, real-time) | `MDCA – Unmanaged Device – Access Policy` |
| Sensitivity label applied by policy | `Confidential – Applied by MDCA` *(reuse an existing Purview label)* |
| Pilot ring (users/group) | `MDCA Pilot Ring – Stage1` |
| Alert/incident workflow | `MDCA Alerts – Triage – Operations` |

## The standard deployment model
> **Assess** current cloud-app exposure (connected apps, Shadow IT, existing policies) → **Design** which
> apps, SITs/labels, file policies, and session policies you need → **Configure** connectors + CA App
> Control routing, then build file policies **alert-only** and session policies **Monitor only** with CA in
> **report-only** → **Pilot** on a ring (measure → tune) → **Validate** against pass/fail gates → **Expand**
> to enforcement (governance actions on, CA on, Block/Protect) tenant-wide and operate. Every high-impact
> change is piloted in test mode first, with a documented rollback.
