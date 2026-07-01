# 1. Solution Overview — Microsoft 365 Security Baseline & Audit Readiness

## What this solution is
This is a Microsoft 365 tenant and service secure-configuration baseline, plus the audit-evidence
program that goes with it. It hardens the settings that govern identity, email (Exchange Online
Protection), collaboration (Teams / SharePoint / OneDrive), device, and data services to a single
documented baseline; it measures and improves that posture with Microsoft Secure Score; and it maps
the resulting controls to a recognized framework in Microsoft Purview Compliance Manager, capturing
the control evidence an auditor asks for.

This is the tenant/service layer, and is deliberately distinct from CIS/STIG endpoint hardening
(which secures the operating system on each device). Here the object being hardened is the Microsoft
365 tenant and its cloud services.

## Why this matters (the why lives here, and only here)
A tenant that "works" is not a tenant that is secure. Defaults leave gaps — legacy authentication
enabled, weak external sharing, no baseline for admin roles — and those gaps are exactly what a
framework assessment or a breach investigation surfaces. Worse, even a well-configured tenant fails
an audit if nobody can produce evidence that the control is in place and stays in place. This
solution fixes both problems at once: it raises the actual security posture (measurable as Secure
Score) and it produces the durable, mapped, dated evidence that turns an audit from a fire drill
into a report.

## How it works
1. A baseline register — the object named `M365 Security Baseline Register – Tenant Services –
   Baseline` — records every target setting across identity, email, collaboration, device, and data
   services, with its desired value and rationale.
2. Microsoft Secure Score (`security.microsoft.com` to Secure Score) measures current posture
   against Microsoft's recommended actions; each improvement action raises the score and maps to one
   or more baseline settings.
3. The tenant and services are configured to the baseline in the admin centers (Entra, Exchange,
   Teams/SharePoint, Intune, Purview), then piloted against a scope group before expansion.
4. Microsoft Purview Compliance Manager (`purview.microsoft.com` to Compliance Manager) holds an
   assessment — the object named `Compliance Assessment – Target Framework – Mapping` — that maps
   improvement actions to the controls of a recognized framework and tracks implementation and test
   status.
5. Control evidence (screenshots, exported settings, script output) is captured into the object
   named `Control Evidence Pack – Tenant Baseline – Audit`, dated and tied to each control.
6. The baseline is re-validated on a review cadence so posture and evidence stay current.

## What you can control
- Identity: legacy-auth block, security defaults / Conditional Access posture, admin-role baseline.
- Email (Exchange Online Protection): anti-malware, anti-phish, anti-spam, and Safe Attachments /
  Safe Links preset security policies.
- Collaboration: external sharing posture for SharePoint / OneDrive and Teams guest access.
- Device and data: compliance-policy baseline signals and data-protection / DLP posture.
- Measurement and mapping: Secure Score targets and the Compliance Manager framework assessment.
- Evidence: what is captured, when, and against which control.

## Limitations (be honest with buyers)
- This baselines the M365 tenant and services; it does not harden the endpoint OS (that is the
  CIS/STIG endpoint baseline, a separate solution).
- Compliance Manager assessment templates and some improvement actions depend on your
  security/compliance licensing (E5 / compliance add-ons unlock more).
- Secure Score reflects Microsoft-defined recommended actions; it is a strong measure, not a
  certification, and should be paired with the framework assessment.
- Framework mapping supports the audit; the auditor of record still issues the finding.

## The standard Phoenixtekk deployment model
> Record the baseline register to assess Secure Score and current config, configure services to the
> baseline, pilot against a scope group, validate, then expand — mapping controls in Compliance
> Manager and capturing evidence throughout. Phoenixtekk pattern: Assess to Configure to Pilot to
> Validate to Expand, on a review cadence.
