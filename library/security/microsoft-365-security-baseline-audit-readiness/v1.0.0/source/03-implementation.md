# 3. Implementation Guide — Microsoft 365 Security Baseline & Audit Readiness

Follow these steps in order, across the Microsoft 365 admin centers. The steps produce three named
objects you will reuse verbatim throughout: the baseline register (`M365 Security Baseline Register
– Tenant Services – Baseline`), the Compliance Manager assessment (`Compliance Assessment – Target
Framework – Mapping`), and the evidence pack (`Control Evidence Pack – Tenant Baseline – Audit`).

> **Model:** Assess current posture, configure the services to the baseline, pilot against a scope
> group, validate, then expand — mapping controls and capturing evidence as you go. Assess to
> Configure to Pilot to Validate to Expand.

## Step 1 — Create the scope groups
1. Run `M365SEC-Set-ScopeTargeting.ps1 -Apply` to create the baseline scope groups
   (`M365 Baseline Scope – Pilot – Users` and `M365 Baseline Scope – Broad – Users`), or create them
   in Entra to Groups to New group to Security.
2. Add a small, representative pilot population to `M365 Baseline Scope – Pilot – Users`.

## Step 2 — Assess the current posture (Secure Score + config)
1. Go to `https://security.microsoft.com` to Secure Score and record the current score and the top
   recommended actions.
2. Run `M365SEC-Discovery.ps1` to capture the current Secure Score, the secure-score control
   profiles, and the key service configuration read via Microsoft Graph.
3. Record every target setting, its current value, and its desired value in the baseline register
   (`M365 Security Baseline Register – Tenant Services – Baseline`).

## Step 3 — Configure identity to the baseline
1. Entra admin center (`https://entra.microsoft.com`): block legacy authentication and confirm the
   Conditional Access / security-defaults posture in the baseline register.
2. Apply the admin-role baseline (least privilege; reserve Global Administrator).
3. For scoped Conditional Access, target `M365 Baseline Scope – Pilot – Users` first.
4. Capture the resulting settings into the evidence pack (`Control Evidence Pack – Tenant Baseline –
   Audit`).

## Step 4 — Configure email protection (Exchange Online Protection)
1. `https://security.microsoft.com` to Email & collaboration to Policies & rules to Threat policies.
2. Apply the preset security policies (anti-malware, anti-phish, anti-spam, Safe Attachments, Safe
   Links) to the baseline, scoping the pilot to `M365 Baseline Scope – Pilot – Users` where the
   policy supports scoping.
3. Capture the policy settings into the evidence pack.

## Step 5 — Configure collaboration (sharing and guest access)
1. SharePoint admin center: set the external-sharing posture per the baseline register.
2. Teams admin center: set guest-access and external-access posture per the baseline register.
3. Capture the sharing/guest settings into the evidence pack.

## Step 6 — Configure device and data posture
1. Intune (`https://intune.microsoft.com`): confirm the compliance-policy baseline signals used by
   the baseline register.
2. Purview (`https://purview.microsoft.com`): set the data-protection / DLP posture per the baseline
   register, scoping DLP pilots to `M365 Baseline Scope – Pilot – Users` where supported.
3. Capture the device/data settings into the evidence pack.

## Step 7 — Map controls in Compliance Manager
1. `https://purview.microsoft.com` to Compliance Manager to Assessments to Add assessment.
2. Select the assessment template for your target framework and name the assessment `Compliance
   Assessment – Target Framework – Mapping`.
3. Work the improvement actions: mark each Microsoft-managed and customer-managed action against the
   baseline settings you configured in Steps 3 to 6, and set implementation and test status.

## Step 8 — Capture control evidence
1. Run `M365SEC-Report.ps1` to produce the Secure Score summary and the control-evidence report.
2. File the report, exported settings, and screenshots into the evidence pack (`Control Evidence
   Pack – Tenant Baseline – Audit`), dated and tied to each control / improvement action.

## Step 9 — Validate the pilot
1. Run `M365SEC-Validation.ps1` to confirm the tenant matches the baseline register (baseline
   compliance).
2. Confirm sign-in, mail flow, and sharing still work for the pilot population; complete the Testing
   Guide.
3. Remediate any baseline gaps with `M365SEC-Remediation.ps1` (defaults to `-WhatIf`; re-run with
   `-Apply` after review).

## Step 10 — Expand and set the review cadence
1. Once the pilot validates, expand scoped changes from `M365 Baseline Scope – Pilot – Users` to
   `M365 Baseline Scope – Broad – Users` (and tenant-wide where the setting is tenant-scoped).
2. Set a review cadence (e.g. monthly Secure Score review, quarterly baseline re-validation) and
   re-run `M365SEC-Validation.ps1` and `M365SEC-Report.ps1` each cycle to keep posture and evidence
   current.

---
### Order of operations
`Scope groups → Assess (Secure Score + Discovery) → Identity → Email (EOP) → Collaboration → Device/Data → Map in Compliance Manager → Capture evidence → Validate pilot → Expand + review cadence`
