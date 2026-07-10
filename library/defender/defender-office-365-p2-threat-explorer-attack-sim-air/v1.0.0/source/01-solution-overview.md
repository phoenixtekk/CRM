# Solution Overview — Defender for Office 365 (Plan 2): Threat Explorer, Attack Simulation & Automated Investigation

## What this is

A complete, self-guided method for turning on and operationalizing the **post-delivery detection and
response** half of **Defender for Office 365 Plan 2** — Threat Explorer / Real-time detections,
Attack Simulation Training, Automated Investigation & Response (AIR), email Advanced Hunting, and
approval-gated remediation.

It is the **detect / hunt / simulate / respond** layer of email security. It **assumes the
prevention layer already exists** — anti-spam, anti-malware, anti-phishing, Safe Links, Safe
Attachments and mail-flow hygiene are the companion *Microsoft 365 Mail Hygiene: Anti-Spam, EOP &
Defender for Office 365* solution — and builds the hunting, training, and response capability on top
of it. This solution never re-configures the prevention policies; it references them.

## How the technology works (the mental model)

- **Threat Explorer / Real-time detections.** The interactive hunting surface for email. **Real-time
  detections** (available with Plan 1) shows near-live detections; **Threat Explorer** (Plan 2) adds
  a richer, longer-retention view and lets you pivot on **sender, recipient, subject, URL, file
  hash, delivery location, and click verdict**, and **take action** on the results (submit, move,
  delete). It answers "who else got this, who clicked, is it still in inboxes?" — *verify current
  Explorer vs Real-time detections capabilities for your plan and cloud.*
- **Attack Simulation Training.** A Plan 2 feature that sends **benign, controlled** simulated
  phishing (credential harvest, malware attachment, link-in-attachment, drive-by, OAuth consent) to
  chosen users, measures who is **compromised** (clicked / entered credentials / granted consent),
  and **auto-assigns targeted training**. It produces a **user-risk / repeat-offender** picture over
  time. Simulations are safe by design and do not deliver real payloads.
- **Automated Investigation & Response (AIR).** When certain email alerts fire (e.g. a user reported
  a phish, or a URL was found malicious after delivery), AIR **automatically opens an investigation**,
  correlates the evidence (all copies of the message, who clicked, related entities), and produces
  **recommended remediation actions**. In an **approval-required** posture those actions wait in the
  **Action center** for a human to approve — nothing is deleted automatically until you decide to
  trust it. *Automation levels and defaults evolve — verify current behavior in your tenant.*
- **Email Advanced Hunting.** A Defender XDR query surface (KQL) over email tables — `EmailEvents`,
  `EmailAttachmentInfo`, `EmailUrlInfo`, `EmailPostDeliveryEvents`, `UrlClickEvents` — for proactive
  hunting beyond the built-in alerts, and for building **custom detection rules**. Email tables
  require Defender for Office 365 Plan 2 — *verify table availability in your tenant*.
- **Remediation actions (soft/hard delete, ZAP).** The response verbs applied to malicious mail:
  **soft delete** (to Deleted Items, recoverable), **hard delete** (purged), **move to junk**, and
  **Zero-hour Auto Purge (ZAP)**-style retroactive removal of already-delivered mail. Here these run
  as **manual or AIR-recommended actions routed through the Action center with approvals** — the ZAP
  *policy toggle* itself lives in the prevention solution; this solution governs using ZAP-style
  purge as a **deliberate response action**.
- **Action center.** The single approval queue for AIR-recommended and manually-submitted actions —
  the control point where a human approves, rejects, or reviews every remediation, with an audit
  trail.

## The standard deployment model

Every solution in this program follows the same five stages:

1. **Assess.** Confirm Plan 2 is licensed and the features are available; inventory current AIR
   posture, Explorer access, Attack Sim readiness, and email-table freshness (run
   `DEFMDOP2-Discovery.ps1`). Confirm the prevention layer is already in place.
2. **Configure.** Create the pilot group `Grp-MDO-Pilot-Users`; set AIR to an **approval-required**
   posture; save the hunting view `Explorer-PostDelivery-Pilot`; import the KQL hunting library;
   stage the first simulation `Sim-CredHarvest-Pilot` and training `Training-PhishAware-Pilot` — but
   do not launch org-wide.
3. **Pilot.** Run the simulation and hunting **against `Grp-MDO-Pilot-Users` only**; let AIR open
   investigations and **hold their actions in the Action center** for approval; practice a gated
   remediation with `Remediation-PhishBatch-Pilot` in **preview** (`DEFMDOP2-Remediate.ps1 -WhatIf`).
4. **Validate.** Confirm hunting returns results, simulation reporting works, AIR actions are
   **pending approval (not auto-applied)**, and remediation preview is accurate (run
   `DEFMDOP2-Validate.ps1`, `DEFMDOP2-Report.ps1`).
5. **Expand.** Widen the simulation to the organization (`Sim-CredHarvest-Org`), promote the tuned
   custom detection `Detect-PostDeliveryPhish-Pilot`, and decide — **as a documented operations
   decision** — whether to raise AIR automation from approval-required to a higher level.

## Scope — what this solution covers

- **Threat Explorer / Real-time detections** — post-delivery email threat hunting and take-action.
- **Attack Simulation Training** — campaigns, susceptibility measurement, auto-assigned training,
  and user-risk reporting.
- **Automated Investigation & Response (AIR)** — alert-triggered investigations in an
  approval-required posture, with Action center approvals.
- **Email Advanced Hunting** — a reusable KQL query library and custom detections over the email
  tables.
- **Remediation actions** — soft-delete / hard-delete / ZAP-style purge run **through approvals**,
  previewed before execution.

## Out of scope (handled elsewhere)

- **Anti-spam, anti-malware, anti-phishing policy, Safe Links, Safe Attachments, connection
  filtering, and mail-flow hygiene** — the **prevention** layer, delivered by the companion
  *Microsoft 365 Mail Hygiene: Anti-Spam, EOP & Defender for Office 365* solution. This solution
  assumes it is in place and does not re-configure it.
- **Endpoint, identity, and cloud-app detection/response** — Defender for Endpoint, Defender for
  Identity, and Defender for Cloud Apps are separate catalog solutions; this is email-focused.
- **SIEM correlation and SOAR** — exporting these detections to Microsoft Sentinel and building
  playbooks is the Sentinel catalog area.
- **The security-operations decisions** — which users to simulate, acceptable click-rate targets,
  the AIR automation level, and every production remediation approval are **the customer's SOC /
  security-leadership determinations**; this solution provides the technical controls and the data.

## Authentication and connections used

- **Microsoft Defender portal** (`security.microsoft.com`) for Explorer, Attack Simulation Training,
  Action center, Advanced Hunting, and AIR settings.
- **PowerShell** with **Microsoft.Graph** (security endpoints — advanced hunting via
  `Security.runHuntingQuery`, and attack-simulation reporting where available — *some endpoints are
  beta; verify*) and **Exchange Online Management** / **Security & Compliance PowerShell**
  (Connect-ExchangeOnline / Connect-IPPSSession) for MDO reporting cmdlets.
- **KQL** run against the email Advanced Hunting tables for hunting, reporting, and custom detection.
- All tools authenticate **interactively** with an MFA-capable admin; **no credentials are stored in
  code**. Government-cloud tenants pass the matching endpoints — *verify endpoints for your cloud*.
