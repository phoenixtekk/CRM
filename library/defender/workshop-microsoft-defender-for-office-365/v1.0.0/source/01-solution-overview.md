# Solution Overview — Workshop: Microsoft Defender for Office 365

## What this is

A complete, self-guided **enablement workshop** that takes an admin or SOC analyst across the whole
**Microsoft Defender for Office 365 (MDO)** surface — **Threat Explorer**, the **anti-phish / Safe
Links / Safe Attachments** protection stack, **Attack Simulation Training**, **Automated
Investigation & Response (AIR)**, and **email advanced hunting** — as concepts, **guided hands-on
labs**, a **runnable email KQL lab pack**, a **take-home runbook**, and a **knowledge-check**.

It is a **skills** product — the outcome is people who can drive MDO. It **cross-references** two
adjacent catalog solutions: the **Defender for Office 365 (Plan 2): Threat Explorer, Attack
Simulation & AIR** implementation solution (which turns the post-delivery features on and
operationalizes them), and the **Microsoft 365 Mail Hygiene** solution (which configures the
prevention policies). This workshop **inspects** those policies read-only and applies the skills; it
does not reconfigure the prevention stack or perform the production rollout.

## How the technology works (the mental model)

- **Two halves: prevention and post-delivery.** MDO both **blocks** mail (anti-spam, anti-malware,
  anti-phishing, Safe Links, Safe Attachments) and lets you **hunt and respond** to what gets through
  (Threat Explorer, AIR, email hunting). The workshop teaches both halves; it **configures** neither.
- **Threat Explorer / Real-time detections.** The interactive hunting surface for email — pivot on
  **sender, recipient, subject, URL, file hash, delivery location, click verdict** and **take action**
  on results. Answers "who else got this, who clicked, is it still in inboxes?" **Real-time
  detections** is the Plan 1 view; **Threat Explorer** (Plan 2) adds depth and retention. *Verify plan
  mapping for your tenant.*
- **The protection stack (inspect, don’t reconfigure).** **Anti-phishing** (impersonation & spoof
  intelligence), **Safe Links** (time-of-click URL rewriting/detonation), and **Safe Attachments**
  (sandbox detonation) produce the verdicts and click data Explorer and hunting surface. In this
  workshop you **read** these policies to understand *why* a message was caught; changing them is the
  **Mail Hygiene** solution.
- **Attack Simulation Training.** A Plan 2 feature that sends **benign, controlled** simulated phishing
  to chosen users, measures who is **compromised**, and **auto-assigns targeted training**. Safe by
  design — no real payload.
- **Automated Investigation & Response (AIR).** When certain email alerts fire, AIR **opens an
  investigation**, correlates evidence, and **recommends** remediation. In an **approval-required**
  posture those actions wait in the **Action center** for a human — nothing auto-deletes.
- **Email advanced hunting.** KQL over the email tables — `EmailEvents`, `EmailAttachmentInfo`,
  `EmailUrlInfo`, `EmailPostDeliveryEvents`, `UrlClickInfo` — for proactive hunting and custom
  detections. Email tables are Plan 2 — *verify availability in your tenant*.

## The standard deployment model

Every solution in this program follows the same five stages; here they structure the workshop:

1. **Assess.** Confirm the MDO features are available and the email tables have data (run
   `WSMDO-Discovery.ps1`).
2. **Configure.** Create the learner cohort `Grp-MDOWorkshop-Cohort` and the lab user group
   `Grp-MDO-LabUsers-Pilot`; load the KQL lab pack `WSMDO-Labs.kql`; agree the **read-only /
   preview-first / approval-required** posture.
3. **Pilot.** Run the **guided labs** (Labs 1–8) with the cohort — console & email-security model,
   Threat Explorer hunting, inspecting the protection stack, a benign simulation, email hunting, AIR
   held for approval, hunt→detection, reporting/user-risk.
4. **Validate.** Run the **capstone** hunt and score the **knowledge-check** `Check-MDOLab-Pilot`
   (`WSMDO-Validate.ps1`); confirm AIR actions are **pending (not auto-applied)** and the detection
   `Detect-MDOLab-Pilot` is **alert-only**.
5. **Expand.** Fold the skills, the saved hunts `Hunt-MDOLab-Pilot`, and the detection into the **live
   email-security practice** — handing the operational rollout to the **Defender for Office 365 (Plan
   2)** implementation solution.

## Scope — what this workshop covers

- **Threat Explorer** — post-delivery email hunting and pivoting (take-action understood, not executed
  in class).
- **The protection stack (read-only)** — inspecting anti-phish / Safe Links / Safe Attachments to
  understand verdicts.
- **Attack Simulation Training** — a benign campaign on the lab group, susceptibility measurement,
  auto-assigned training.
- **AIR** — triggering an investigation the safe way and confirming actions are **held for approval**.
- **Email advanced hunting** — a KQL lab pack over the email tables, ending in an **alert-only**
  custom detection.
- **Reporting / user-risk** and a **take-home runbook + knowledge-check**.

## Out of scope (handled elsewhere)

- **Configuring the prevention policies.** Anti-spam/-malware/-phishing, Safe Links, Safe Attachments,
  connection filtering, and mail-flow hygiene are the **Microsoft 365 Mail Hygiene** solution. This
  workshop **inspects** them read-only.
- **The operational post-delivery rollout.** Turning these features on across the org, tuning AIR
  automation, and running gated production remediation is the **Defender for Office 365 (Plan 2)**
  implementation solution. This workshop builds the **skill**; that product does the **rollout**.
- **Executing production remediation.** Soft/hard-delete and ZAP-style purge against real mail are
  approval-gated incident actions — not workshop labs.
- **The security / HR-legal decisions.** Which users to simulate, acceptable click-rate, the AIR
  automation level, works-council notification, and every production remediation are **the customer’s
  determinations**; this workshop provides the skill, the labs, and the data.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for Threat Explorer, Attack Simulation
  Training, Action center, AIR settings, Advanced hunting, and custom detection rules.
- **PowerShell** with **Microsoft.Graph** (security — advanced hunting via `security/runHuntingQuery`;
  attack-simulation reporting where available — *some endpoints are beta; verify*) and, where used,
  **Exchange Online / Security & Compliance** for MDO reporting cmdlets — used only to **check
  readiness, run lab queries read-only**, score the knowledge-check, and report progress.
- All helpers authenticate **interactively** with an MFA-capable account holding at least read/hunt
  scopes; **no credentials are stored in code**. Government-cloud tenants pass the matching endpoints
  — *verify endpoints for your cloud*.
