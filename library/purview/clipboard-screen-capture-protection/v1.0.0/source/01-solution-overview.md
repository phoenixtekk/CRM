# 1. Solution Overview — Clipboard & Screen-Capture Protection (Microsoft Purview)

## What this solution is
File-level controls — DLP on email, encryption, external-sharing blocks — do nothing about the two most
mundane exfiltration paths on an endpoint: a user **copies sensitive content to the clipboard** and pastes
it into a personal webmail, chat, or note-taking app; or a user **takes a screenshot** of a sensitive
document, dashboard, or record and the pixels walk out as an image. Both bypass every control that watches
the *file*. **Microsoft Purview Endpoint Data Loss Prevention (Endpoint DLP)** closes those two paths by
watching the *activity* on an **onboarded device**: when content that matches your **sensitive information
types** (or carries a sensitive **sensitivity label**) is copied to the clipboard or captured to screen,
the policy can **audit**, **warn with a policy tip and allow-with-justification**, or **block** the action.

This solution is a repeatable, evidence-driven way to configure **clipboard** and **screen-capture**
restrictions for sensitive content on endpoints using only the **Microsoft Purview portal**, **Security &
Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft Graph** — no third-party agent. Its
defining discipline is that **every restriction is built and proven in SIMULATION / audit mode first**
(Microsoft's built-in test mode that records what *would* have been restricted against real device
activity, with zero user impact), tuned for a low false-positive rate, and only then moved to enforcement.

> **Scope boundary.** This solution delivers the **technical method and evidence** for clipboard and
> screen-capture restriction on endpoints. *Which* data is regulated, *which* classifiers or labels legally
> apply, and *what* the enforced action must be for a given data category are **business, compliance,
> privacy, and legal determinations** — deferred to those functions. The solution configures and proves the
> control; it does not make the policy decision.

## Why this matters
- **Copy-paste and screenshots are the file controls' blind spot.** A document can be encrypted, un-shareable,
  and blocked from email, yet a user selects the text, copies it, and pastes it into a browser — or snips the
  screen — and none of the file-level controls ever see it. Endpoint DLP watches the *activity*, not just the
  file.
- **Endpoint DLP is licensing- and onboarding-dependent.** Clipboard and screen-capture restrictions require
  the right plan (typically **Microsoft 365 E5** / the **E5 Compliance** add-on) and devices **onboarded** to
  Purview (shared with Microsoft Defender for Endpoint onboarding). A Devices-location policy is inert until
  onboarding is complete — **verify your licensing/tenant**.
- **Screen-capture restriction and some clipboard behaviours are newer / may be in preview** and are gated on
  minimum OS builds and supported apps/browsers. This solution flags "verify your licensing/tenant" rather
  than asserting availability that may differ in your tenant.
- **Enforced-first is the classic failure.** Blocking clipboard/screenshot straight away breaks legitimate
  work — pasting between two sanctioned business apps, screenshotting a normal page — floods the help desk,
  and gets the policy disabled. Audit/simulation first, tuned, is the difference between a control that
  survives and one that is turned off.

## How it works
1. **Sensitive information types (SITs), classifiers, and sensitivity labels** define *what* content is
   sensitive. Endpoint DLP matches the content involved in a device activity against built-in SITs
   (credit card, national ID, health identifiers, etc.), **custom SITs**, **Exact Data Match (EDM)** SITs,
   **trainable classifiers**, or the presence of a **sensitivity label** on the item.
2. **A DLP policy scoped to the Devices (Endpoint) location** binds those detectors to **endpoint activities**
   under *"Audit or restrict activities on devices"*. The two this solution targets are **copy to clipboard**
   (paste into another app/browser) and **screen capture** (Print Screen / Snipping Tool / third-party
   capture of sensitive content). Each activity is set to **Audit**, **Block with override**, or **Block**.
3. **Simulation / audit mode** runs the policy against live device activity and records what *would* have been
   restricted — with or without policy tips shown — so you see the true volume and false positives **before**
   any enforcement. Every restriction in this solution starts here.
4. **Tuning** reduces false positives using confidence levels, instance thresholds, supporting keywords, EDM,
   label-based conditions, and **allowed-app / browser / network exceptions**, measured against the
   simulation results.
5. **Enforcement** turns the tuned restriction on (tip / allow-with-justification / block) in a limited ring,
   then expands.
6. **Incident/alert handling** — restricted clipboard/screen-capture activities raise **alerts** in the
   Purview portal and flow to **Activity Explorer**; this solution wires the triage, severity, and response
   workflow so matches are actually acted on.

## The two activities this solution controls (and what each stops)
- **Copy to clipboard →** copying sensitive content and pasting it into another application or a browser
  (personal webmail, chat, notes). Endpoint DLP can audit, warn-and-justify, or block the paste of classified
  content. Configure the **allowed apps / browsers** so sanctioned tools aren't caught alongside exfiltration.
- **Screen capture →** taking a screenshot (Print Screen, Windows Snipping Tool, or a supported third-party
  capture app) of sensitive content on screen. Endpoint DLP can audit or block the capture. **Availability
  and supported capture apps/OS builds vary — verify your licensing/tenant (this capability is newer / may be
  in preview).**

## A complementary lever: sensitivity-label protection (RMS usage rights)
Where content carries a **sensitivity label with encryption**, the label's **usage rights** independently
govern copy: removing the **EXTRACT ("Copy")** usage right from a permission set prevents copying content out
of protected Office files regardless of endpoint. This solution's primary path is **Endpoint DLP** (which
covers any content, labelled or not, and adds screen capture), but the label-usage-right lever is documented
here as a complementary control where labels are already in use — verify your labeling design with the
information-protection owner.

## The simulate→enforce journey (the core discipline)
> Confirm SITs/labels → build the Endpoint DLP policy with **clipboard + screen-capture** activities in
> **SIMULATION / audit** (no user impact) → measure volume and false positives in **Activity Explorer / DLP
> alerts** → **tune** (confidence, instance count, keywords, EDM, label condition, allowed-app/browser
> exceptions) → re-simulate until false positives are acceptable → enable with **policy tips +
> allow-override/justification** in a **pilot ring** → validate → expand to **enforce (block)** across the
> intended scope → operate (triage alerts, review overrides, re-tune).

## What you can control
- Which **SITs/classifiers/labels** trigger the restriction, and at what **confidence** and **instance count**.
- Which **endpoint activities** are covered — **clipboard**, **screen capture**, or both — and the **action**
  per activity (audit → tip → justify → block).
- Which **users / devices / groups** are **included or excluded**, and the **pilot ring** enforced first.
- The **allowed apps / browsers / network locations** so sanctioned workflows aren't caught.
- Whether users get **policy tips**, can **override** with justification, and what the override says.

## Limitations (be honest with buyers)
- **Endpoint DLP requires onboarded devices and the appropriate licensing** (verify your plan — endpoint DLP
  is gated behind E5 / the E5 Compliance add-on). A Devices-location policy is inert until onboarding is
  complete.
- **Screen-capture restriction and some clipboard behaviours are newer / may be in preview**, are limited to
  **supported apps/browsers and minimum OS builds**, and evolve — this solution flags "verify your
  licensing/tenant" rather than asserting availability.
- Endpoint DLP restricts content it can **classify** (SIT / label match). Content below the confidence/instance
  threshold, or that the device agent cannot classify at the moment of the activity, will not match. DLP is
  one control among several, not a guarantee — a determined user can still photograph a screen with a phone.
- The **enforced action for a data category is a compliance/legal decision**, not a technical default — this
  solution configures and proves the control; the determination is deferred.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses `<Purpose> – <Scope> – <Stage>`, reused verbatim across the docs,
scripts, and the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Endpoint DLP policy (simulation) | `DLP – Endpoint Clipboard+Screen – Simulation` |
| Content rule on that policy | `DLP – Endpoint Clipboard+Screen – Rule` |
| Enforced pilot policy | `DLP – Endpoint Clipboard+Screen – Enforce Pilot` |
| Pilot user/device ring | `DLP Pilot Ring – Stage1` |
| Policy-tip / override text | `DLP Notice – Clipboard/Screen – Standard` |
| Incident/alert workflow | `DLP Alerts – Clipboard/Screen – Operations` |
| (Optional) label restricting copy | `Confidential – No-Copy – Endpoint` |

## The standard deployment model
> **Assess** current endpoint exposure and classification intent → **Design** the SIT/label detectors and the
> clipboard/screen-capture restriction → **Configure** the Endpoint DLP policy **in simulation/audit** →
> **Pilot** (simulate → tune → enforce to a ring) → **Validate** against pass/fail gates (clipboard/screenshot
> of sensitive content restricted, false-positive rate low, incidents handled) → **Expand** to the full scope
> and ongoing operations. Every high-impact change is piloted in simulation first, with a documented rollback.
