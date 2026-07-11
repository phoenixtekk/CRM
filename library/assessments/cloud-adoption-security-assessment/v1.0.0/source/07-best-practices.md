# 7. Best Practices — Cloud Adoption Security Assessment

Field-proven guidance for running a whole-estate security assessment that people trust and act on — plus
where to go next to close the gaps.

## Keep it read-only, keep it least-privilege
- **Never** run the assessment with a write or admin role "to be safe." An assessment that could change the
  tenant is no longer an assessment. Use **Security/Global Reader** + **Azure Reader** and let
  `CLDSEC-Validate.ps1` prove it.
- Consent only the **read** Graph scopes. If a script ever needs a write scope, treat it as a bug, not a
  requirement.

## Score against a named, current baseline — and record it
- Always name the **reference baseline** in the report (Microsoft security baselines + Secure Score; CIS /
  Zero Trust if your org uses them). *Baselines evolve — verify against current Microsoft guidance each run.*
- Record the **scope and run date** in the report header so the score is comparable and defensible. A score
  with no baseline and no date is an opinion, not evidence.

## Pilot before you present
- Run the **pilot scope** first and **validate High/Critical findings against the live portal** before the
  full run. False positives destroy credibility faster than missing findings.
- When you confirm a false positive, **record why** (a compensating control the script can't see) — don't
  quietly delete it.

## Rank by risk, sequence by effort
- Present findings **risk-ranked** (impact × exposure), then sequence the roadmap by effort: **quick wins →
  foundational → strategic**. A budget owner funds the roadmap that shows the cheapest risk reduction first.
- Weight **identity and endpoints** highest by default — they are the most common breach entry points — but
  record any deviation your organization intentionally makes.

## Treat the report as sensitive
- The findings report is a **map of your weaknesses**. Store it in the restricted
  **`CloudSecAssessment – Estate – Findings`** location and share on a need-to-know basis. Never email it
  broadly or drop it in an open channel.

## Trend, don't snapshot-and-forget
- The value compounds when you **re-run** with the same scope and baseline after each remediation wave, and
  chart the maturity score over time. A rising score is the single best evidence that security spend is working.

## Leave the decisions with the owners
- The assessment states each gap and its risk and recommends a sequence. **Whether to accept a risk, how to
  prioritize against business need, and any regulatory / records / legal mapping are the customer's
  decisions** — made by security, compliance, and leadership, not by this guide or its scripts.

## Where to go next (adjacent catalog areas)
This assessment is the **map**; these solutions do the **roadworks** (each pilot-first and change-controlled):
- **Identity & Conditional Access hardening / Zero-Trust identity** — to build the MFA, legacy-auth-block,
  device-compliance, and PIM controls the identity pillar flagged.
- **Defender XDR unified onboarding** — to turn on and connect the Defender products where the assessment
  found coverage gaps.
- **Defender for Cloud (CSPM) posture management** — to raise the infrastructure Secure Score and close the
  Azure resource findings.
- **Defender for Office 365 hardening** and **Cloud App / DLP** — for the email, app-consent, shadow-IT, and
  data-loss findings.
- **SOC & XDR operations** and **Threat Hunting** — to operationalize detection and hunt against the residual
  risk once the roadmap is under way.
- **AI Workload Security Assessment** (sibling assessment) — if your estate now includes Azure AI workloads,
  assess that new attack surface with the paired AI-specific assessment.

Close the top-ranked findings, then **re-run this assessment** to prove the score moved.
