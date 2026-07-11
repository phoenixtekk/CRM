# 7. Best Practices — Security Optimization Assessment: Defender for Endpoint

Field-proven guidance for running this assessment cleanly, keeping it honest, and turning the output into action.

## Keep it strictly read-only
- **Assess with Security Reader, never an admin role.** If the identity can write, the assessment is no longer provably non-disruptive. `SOAMDE-Validate.ps1` deliberately fails if a write scope is present — keep it that way.
- **Never "just fix it" mid-assessment.** The moment you enable a rule you saw was off, the run is no longer a clean point-in-time snapshot and the before/after trend is lost. Record it as a finding; fix it in the Remediation Playbook, pilot-first.

## Make the numbers defensible
- **Always supply an expected device count.** Onboarding coverage against "devices MDE already knows about" flatters the result; against the *authoritative* count (Intune/AD/CMDB) it tells the truth.
- **Name the baseline in the report.** "72%" means nothing without "against the Microsoft security baseline + Secure Score endpoint recommendations, on <date>". Baselines evolve — *re-confirm the current guidance each run.*
- **Score unlicensed features as N-A, not Fail** — but list them as coverage findings. An E3 tenant missing an E5-only control is a licensing decision, not a misconfiguration.
- **Reconcile before you deliver.** Spot-check the top findings against the portal every time. One wrong finding undermines the whole report's credibility with the security owner.

## Interpret coverage, not just the headline score
- **Audit-mode ASR rules are the classic false-comfort.** A tenant can look "configured" while every rule is in Audit and blocking nothing. Always separate **Block** from **Audit** in the coverage view.
- **Watch sensor health, not just onboarding.** "Onboarded" but Inactive/ImpairedCommunication is a blind spot that headline onboarding numbers hide.
- **Tamper protection off anywhere is high severity** — it undermines every other endpoint control on that device.

## Hand off well
- **Deliver an ordered backlog, not a data dump.** The value is the *ranking*: High → Low, with evidence and a remediation pointer, so the owner can work top-down.
- **Let the customer own risk-acceptance.** Some findings will be knowingly accepted (a legacy app that breaks a specific ASR rule). Annotate those as accepted exceptions rather than re-reporting them every run.
- **Re-run on a cadence.** A single score is a snapshot; a trend proves the program is working. Same scope file, new dated run folder.

## Protect the output
- The findings report is a **map of your weaknesses** — store it in the restricted location (R7), share on a need-to-know basis, and don't email it broadly.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook (SOAREM)** — the paired, pilot-first (`-WhatIf`-gated) solution that *closes* the findings this assessment raises, then you re-score.
- **DEFXDR** — unified onboarding across Defender workloads, if the assessment shows onboarding/coverage gaps at the deployment level.
- **THREATHUNT** — proactive KQL threat hunting once posture is solid.
- **SOCXDR** — SOC onboarding and operations for the alerts MDE generates. *Live-threat and IR determinations belong to the SOC.*
- **Security Optimization Assessment — Defender for Office 365 / Identity / Cloud Apps / Cloud / Defender Suite** — the sibling assessments; run the **Defender Suite** assessment for a single cross-workload posture score.
