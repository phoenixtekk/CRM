# Solution Overview — Microsoft Defender for Office 365

## What this is

A complete, self-guided solution for **operating, enabling, and proving** **Microsoft Defender for
Office 365 (MDO)**. It joins two tracks into one lifecycle:

- **Track A — Enable the team:** guided hands-on labs across the whole MDO surface — **Threat
  Explorer**, the **anti-phish / Safe Links / Safe Attachments** protection stack, **Attack Simulation
  Training**, **Automated Investigation & Response (AIR)**, and **email advanced hunting** — with a
  runnable email KQL pack and a knowledge-check.
- **Track B — Prove value:** a scoped, safe, reversible **proof of concept (PoC)** that fires benign
  test signal at a pilot group, demonstrates the headline detections, and captures the evidence.

It is the **operate/enable/prove layer** over two adjacent solutions. It **cross-references** — and
does not repeat — the **Microsoft 365 Mail Hygiene & Anti-Spam — EOP / Defender for Office 365**
solution (which *configures* the prevention policies) and the **Defender for Office 365 (Plan 2) —
Threat Explorer, Attack Simulation & AIR** solution (which *turns the post-delivery features on and
operationalises them org-wide*). This solution **inspects** the prevention policies read-only, builds
the **skill** to drive the post-delivery half, and **proves** the product on real-but-safe signal.

## How the technology works (the mental model)

- **Two halves: prevention and post-delivery.** MDO both **blocks** mail (anti-spam, anti-malware,
  anti-phishing, Safe Links, Safe Attachments) and lets you **hunt and respond** to what gets through
  (Threat Explorer, AIR, email hunting). This solution operates and proves both halves; it
  **configures** neither.
- **Threat Explorer / Real-time detections.** The interactive hunting surface for email — pivot on
  **sender, recipient, subject, URL, file hash, delivery location, click verdict** and **take action**
  on results. Answers "who else got this, who clicked, is it still in inboxes?" **Real-time
  detections** is the Plan 1 view; **Threat Explorer** (Plan 2) adds depth and retention. *Verify plan
  mapping for your tenant.*
- **The protection stack (inspect, don't reconfigure).** **Anti-phishing** (impersonation & spoof
  intelligence), **Safe Links** (time-of-click URL rewriting/detonation), and **Safe Attachments**
  (sandbox detonation) produce the verdicts and click data Explorer and hunting surface. Here you
  **read** these policies to understand *why* a message was caught; changing them is the **Mail
  Hygiene** solution.
- **Attack Simulation Training.** A Plan 2 feature that sends **benign, controlled** simulated phishing
  to chosen users, measures who is **compromised**, and **auto-assigns targeted training**. Safe by
  design — no real payload. It is also the sanctioned way to generate benign phishing signal for the
  PoC.
- **Automated Investigation & Response (AIR).** When certain email alerts fire, AIR **opens an
  investigation**, correlates evidence, and **recommends** remediation. In an **approval-required**
  posture those actions wait in the **Action center** for a human — nothing auto-deletes.
- **Email advanced hunting.** KQL over the email tables — `EmailEvents`, `EmailAttachmentInfo`,
  `EmailUrlInfo`, `EmailPostDeliveryEvents`, `UrlClickInfo` — for proactive hunting and custom
  detections. Email tables are Plan 2 — *verify availability in your tenant.*
- **Benign PoC signal.** The **GTUBE** anti-spam test string, the **EICAR** anti-malware test file, and
  a benign **Safe Links** test URL are industry-standard, harmless triggers that exercise the
  detection pipeline without any real threat. Combined with an Attack Simulation campaign, they let you
  *watch MDO catch the simulation* instead of trusting a slide deck.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the enable-and-prove
lifecycle:

1. **Assess.** Confirm the MDO features are available and the email tables have data
   (`MDOFULL-Discovery.ps1`); confirm the prevention baseline exists to inspect (from the **Mail
   Hygiene** solution); create the learner cohort and the consented pilot group.
2. **Configure.** Load the KQL lab pack `MDOFULL-Labs.kql`; confirm **AIR is approval-required**; agree
   the **read-only / preview-first / `-WhatIf`** posture. (Production policy configuration itself is the
   cross-referenced solutions' job — not this one.)
3. **Pilot.** Run **Track A** (guided Labs 1–8) with the cohort, and **Track B** (the guided PoC:
   benign signal → demonstrate Safe Links / Safe Attachments / ZAP / Threat Explorer) against the
   pilot group.
4. **Validate.** Run the **capstone** hunt, score the **knowledge-check**, and run the PoC capability
   validation and **evidence capture** (`MDOFULL-Validate.ps1`, `MDOFULL-Report.ps1`); confirm AIR
   actions are **pending (not auto-applied)** and the detection `Detect-MDOFULL-Pilot` is
   **alert-only**.
5. **Expand.** Fold the skills, saved hunts, and evidence into the **live email-security practice** —
   handing the operational rollout to the **Defender for Office 365 (Plan 2)** solution and any
   prevention tightening to the **Mail Hygiene** solution — and **tear down** the benign PoC signal.

## Scope — what this solution covers

- **Threat Explorer** — post-delivery email hunting and pivoting (take-action understood, not executed
  against production).
- **The protection stack (read-only)** — inspecting anti-phish / Safe Links / Safe Attachments to
  understand verdicts.
- **Attack Simulation Training** — a benign campaign on the pilot group; susceptibility measurement and
  auto-assigned training.
- **AIR** — triggering an investigation the safe way and confirming actions are **held for approval**.
- **Email advanced hunting** — a KQL lab pack over the email tables, ending in an **alert-only** custom
  detection.
- **A scoped, safe PoC** — benign signal (Attack Simulation / GTUBE / EICAR / Safe Links), a demo of
  the headline detections, capability validation, an **evidence scorecard**, and clean teardown.
- **Reporting / user-risk** and a **take-home runbook + knowledge-check**.

## Out of scope (handled by the cross-referenced solutions)

- **Configuring the prevention policies.** Anti-spam/-malware/-phishing, Safe Links, Safe Attachments,
  connection filtering, and mail-flow hygiene are the **Microsoft 365 Mail Hygiene & Anti-Spam — EOP /
  Defender for Office 365** solution. This solution **inspects** them read-only.
- **The operational post-delivery rollout.** Turning these features on across the org, tuning AIR
  automation, and running gated production remediation is the **Defender for Office 365 (Plan 2) —
  Threat Explorer, Attack Simulation & AIR** solution. This solution builds the **skill** and the
  **proof**; that solution does the **rollout**.
- **Executing production remediation.** Soft/hard-delete and ZAP-style purge against real mail are
  approval-gated incident actions — not labs, and not part of the PoC.
- **The security / HR-legal decisions.** Which users to simulate, acceptable click-rate, the AIR
  automation level, works-council notification, what counts as a PoC "pass," and every production
  remediation are **the customer's determinations**; this solution provides the skill, the labs, the
  data, and the proof.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for Threat Explorer, Attack Simulation
  Training, Action center, AIR settings, Advanced hunting, custom detection rules, and quarantine.
- **PowerShell** with **Microsoft.Graph** (security — advanced hunting via `security/runHuntingQuery`;
  `Mail.Send` for the benign PoC test messages; attack-simulation reporting where available — *some
  endpoints are beta; verify*) and, where used, **Exchange Online / Security & Compliance** for MDO
  reporting and quarantine cmdlets — used only to **check readiness, run lab queries read-only**,
  generate benign signal, validate detections, and capture evidence.
- All helpers authenticate **interactively** with an MFA-capable account holding at least read/hunt
  scopes; **no credentials are stored in code**. Government-cloud tenants pass the matching endpoints
  — *verify endpoints for your cloud.*
