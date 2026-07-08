# 2. Requirements Guide — Purview AI Hub Governance (DSPM for AI), Microsoft Purview

Verify **every** requirement below before starting the Implementation Guide. These are the
**solution-specific** prerequisites for governing AI interactions from the DSPM-for-AI experience; they
build on the shared **Global Requirements — Microsoft Purview Solutions** (licensing, least-privilege
roles, Security & Compliance PowerShell + Graph toolchain, in-scope workloads, compliance/records/legal
stakeholders, and a pilot scope with change control). Read the Global Requirements first; this guide does
not repeat them.

> **Determination note.** What AI usage is *acceptable*, which content must be *withheld* from AI, which
> risky patterns warrant review, and any regulatory applicability are **governance, compliance, privacy,
> and legal determinations** owned by those functions — not technical defaults. Insider-risk and
> communication-compliance **outcomes are deferred to HR/legal**. This solution provides the
> **configuration method and evidence**; confirm the intent and case-handling with the accountable owner.

---

## 2.1 Licensing for DSPM for AI and the underlying controls
- **Description:** DSPM for AI has **free/included** visibility capabilities and **premium** capabilities
  that require **Microsoft 365 E5** or the **E5 Compliance** add-on (advanced DLP, insider risk,
  communication compliance, Audit Premium). Microsoft 365 **Copilot** governance assumes Copilot is
  licensed. Some DSPM-for-AI capabilities are **in preview**. **Verify your licensing/tenant** — Microsoft's
  licensing tables and the preview notes are the authority; do not assume a capability is included.
- **Why required:** The recommended AI policies (DLP, insider risk, communication compliance) are plan-gated.
- **How to verify:** M365 admin center → subscriptions/add-ons; confirm the DSPM-for-AI experience and the
  specific policy pages are available in the Purview portal (`IPRMS`/`AIHUB-Readiness.ps1` licensing signal).
- **How to implement if missing:** Assign/purchase the required plan for the pilot users before configuring.

## 2.2 Least-privilege roles for the AI-governance controls
- **Description:** The controls span several role groups: **Compliance Administrator / DLP** (the DLP
  policy), **Insider Risk Management** roles (risky-AI-usage policy — with strict role separation),
  **Communication Compliance** roles (prompt/response detection), **Information Protection** (labels the
  Copilot honors), and **Audit** roles (visibility). Assign the **least-privilege** role for each control
  to the person who owns it; reserve Global Administrator for where it is genuinely required.
- **Why required:** Each policy type is gated by its own role; insider-risk/communication-compliance
  additionally require **role separation** for privacy.
- **How to verify:** Purview → **Roles & scopes / Permissions** confirms the memberships per control.
- **How to implement if missing:** Assign the least-privilege roles under change control; keep insider-risk/
  communication-compliance roles separated from general admin.

## 2.3 Security & Compliance PowerShell + Graph toolchain
- **Description:** A workstation with **ExchangeOnlineManagement** (`Connect-IPPSSession` for the DLP and
  audit cmdlets) and **Microsoft Graph PowerShell** (licensing/service signals), with a modern-auth /
  MFA-capable admin.
- **Why required:** The scriptable parts (audit enablement, the test-mode DLP policy, discovery, validation,
  reporting) run through these.
- **How to verify:** `Connect-IPPSSession` then `Get-DlpCompliancePolicy` succeeds; `Connect-MgGraph`
  succeeds for the SKU read.
- **How to implement if missing:** Install the modules; confirm modern-auth sign-in. See the Global Requirements.

## 2.4 Unified audit enabled (AI visibility depends on it)
- **Description:** **Unified audit logging** must be **enabled** so AI interactions (Copilot and more) are
  captured and visible in DSPM-for-AI reports and available to eDiscovery.
- **Why required:** Without audit, there is no visibility into AI interactions — the foundation of the
  whole solution.
- **How to verify:** `Get-AdminAuditLogConfig` shows `UnifiedAuditLogIngestionEnabled = True` (the provided
  `AIHUB-Discovery.ps1` / `AIHUB-Readiness.ps1` report it); AI activities appear in the audit search.
- **How to implement if missing:** Enable it (`Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled
  $true` — the config helper does this gated behind `-Commit`); allow ingestion latency before expecting data.

## 2.5 A sensitivity-label taxonomy that Copilot can honor
- **Description:** For label-based AI protection to mean anything, a **sensitivity-label taxonomy** (and,
  for the withhold-from-AI control, a specific label such as `Highly Confidential`) must exist and be
  published. Copilot honors labels and their encryption — content the user isn't entitled to won't surface
  in AI answers, and labeled output stays labeled.
- **Why required:** The DLP "protect labeled content from AI" rule and the Copilot label-honoring behaviour
  key off existing labels.
- **How to verify:** `Get-Label` returns the taxonomy including the label the DLP rule targets; labels are
  published in a label policy.
- **How to implement if missing:** Build/publish the taxonomy first (the labels solution); return here once
  the target label exists.

## 2.6 A pilot ring and the pilot-in-simulation commitment
- **Description:** A named **pilot ring** (`grp-ai-pilot@contoso.com`) to receive the DLP-for-AI policy and
  detections **first**, and an explicit commitment that the DLP policy runs in **test/simulation** and the
  detections are validated before broad enforcement. DLP over AI is **high-impact** — simulation-first is
  mandatory.
- **Why required:** A DLP policy that withholds content from AI changes what Copilot can answer over;
  simulation surfaces false positives before they block real work.
- **How to verify:** Confirm the pilot group, a change window, and an approver.
- **How to implement if missing:** Create the pilot group and agree change control before configuring anything.

## 2.7 Endpoint / browser onboarding for consumer-AI signals (if in scope)
- **Description:** To surface sensitive data going into **consumer AI sites** (e.g. ChatGPT via the browser),
  target devices must be **onboarded** to endpoint DLP and the **Purview browser extension** installed on
  supported browsers. This is optional scope — include it if consumer-AI egress is a concern.
- **Why required:** Consumer-AI egress signals come from endpoint/browser telemetry, which requires onboarding.
- **How to verify:** Purview → **Settings → Device onboarding** shows onboarded devices; confirm the browser
  extension deployment; **verify current browser/extension support for your tenant**.
- **How to implement if missing:** Onboard devices and deploy the extension before expecting consumer-AI
  signals; this can follow the Copilot-governance pilot.

## 2.8 A privacy-by-design and case-handling decision (insider risk / communication compliance)
- **Description:** A decision, from your **HR, privacy, and legal** stakeholders, on how the risky-AI-usage
  insider-risk policy and the prompt/response communication-compliance policy are run — **pseudonymization**
  where applicable, **role separation**, who reviews, and how outcomes are handled. These are HR/privacy-
  sensitive controls.
- **Why required:** Insider-risk and communication-compliance data is sensitive; the configuration must be
  privacy-by-design and the **outcomes are HR/legal determinations**, not technical ones.
- **How to verify:** Confirm the review workflow, pseudonymization setting, role separation, and named
  reviewers with HR/privacy/legal.
- **How to implement if missing:** Get the privacy-by-design model and case-handling signed off before
  enabling the detections.
