# 7. Best Practices — Onboarding Accelerator: Microsoft Defender for Cloud Apps

Field-proven guidance for keeping the Defender for Cloud Apps deployment clean, useful, and low-risk.

## Start every policy in report-only, scoped to a pilot
- Create activity, file, session, and access policies in **monitor / report-only** first, scoped to `MDCA Pilot Users – Pilot Ring – Pilot`. Watch behavior, tune out false positives, then enforce. A CASB that blocks legitimate work on day one loses the room.
- Move to enforce for the pilot, confirm, then broaden the Conditional Access scope in waves — never enforce tenant-wide first.

## Connect Microsoft 365 first, then priority third-party apps
- The Microsoft 365 connector gives the fastest, richest signal. Add high-value third-party apps (`MDCA App Connectors – Priority SaaS – Prod`) next by data sensitivity, not by ease. Connectors are out-of-band API integrations — they add signal without user impact.

## Use the Defender for Endpoint feed for discovery where you can
- If devices are MDE-onboarded, the built-in **Defender for Endpoint → Cloud Apps** integration is the lowest-friction Cloud Discovery source — no log collector to maintain. Fall back to a log collector / SWG feed only where MDE is not the source.

## Treat OAuth app governance as a standing risk surface
- Risky **OAuth app** consents exfiltrate data with no stolen password. Keep `MDCA OAuth App Risk – Tenant – Report` running, review flagged apps (over-privileged scopes, unverified publishers) on a cadence, and keep **revocation approval-gated** — it can break legitimate integrations. Revocation decisions belong to the security team.

## Keep enforcing and revoke actions approval-gated until trusted
- Block, suspend-session, and revoke-app actions are disruptive. Leave them approval-gated during the pilot and early expansion; moving toward automatic enforcement is the security team's decision, made after validation.

## Let discovery and hunting tables warm up
- Discovery data and `CloudAppEvents` populate over time. Use `MCAONB-Hunt.ps1` to confirm streaming before judging coverage, and re-baseline with `MCAONB-Report.ps1 -SaveBaseline` after each expansion.

## Keep licensing and preview facts current
- MDCA, **app governance**, and **Conditional Access App Control** are license-gated and evolve, and App Control supports a changing set of apps. Before relying on a capability, **verify current availability, licensing, and supported apps in your tenant.**

## Defer the data-governance decisions to the owners
- What counts as sensitive data, which apps are sanctioned, and acceptable-use policy are **the customer's compliance/security determinations**. This solution delivers the technical CASB onboarding and controls; the classification and policy decisions stay with the owners.

## Where to go next
Once MDCA is onboarded and validated, natural next steps in the catalog:
- The **Cloud App DLP with Defender for Cloud Apps** solution to layer data-loss-prevention on the connected apps.
- The **Microsoft Defender XDR — Unified Onboarding** accelerator to correlate MDCA with Endpoint, Identity, and Office 365 in one portal.
- The **Onboarding Accelerator — Microsoft Defender for Endpoint** to establish the MDE feed that powers Cloud Discovery.
- **Entra Conditional Access baseline** and identity-governance solutions to strengthen the access layer that App Control depends on.
