# 7. Best Practices — Security Optimization Assessment: Defender for Identity

Field-proven guidance for running this assessment cleanly, keeping it honest, and turning the output into action.

## Keep it strictly read-only
- **Assess with Security Reader + a read-only domain account, never an admin role.** If the identity can install a sensor or change the DSA, the assessment is no longer provably non-disruptive. `SOAMDI-Validate.ps1` fails if a write scope is present — keep it that way.
- **Never install a sensor or change the DSA mid-assessment.** The moment you do, the point-in-time snapshot and the before/after trend are lost. Record it as a finding; fix it pilot-first in the Remediation Playbook.

## The denominator is everything
- **Coverage is only as honest as the DC inventory.** MDI's own sensor list can never reveal a DC with no sensor — always reconcile against the **AD-derived** inventory, across every domain and site, including freshly-promoted DCs.
- **Name the blind DCs, don't just count them.** "92% coverage" is a headline; the value is the *named list* of the 8% an attacker could pivot through.
- **Reconcile with the AD team.** A trust you cannot traverse, or a child domain you cannot read, is itself a finding — surface it rather than silently excluding it.

## Confirm what has no API — don't drop it
- **Some MDI settings (sensor health, DSA, honeytokens) may have no public read API in your tenant.** Where the script cannot read them, it flags them **verify** — confirm those in the portal and record the values. Silently omitting them produces a falsely clean report.

## Interpret each area honestly
- **An un-sensored domain controller is High severity, full stop** — it is the classic identity blind spot.
- **A password-based or over-privileged DSA is a real finding** — best practice is a least-privilege **gMSA**. *Verify current DSA guidance.*
- **No honeytokens is a missed cheap win.** Tagged decoy accounts are high-fidelity tripwires; their absence is a finding, not a nicety.
- **Work the ISPM backlog, don't just admire it.** Unsecure protocols, risky delegations, and exposed credentials are the posture items attackers actually use.
- **Detection tuning cuts both ways** — over-excluding blinds MDI, under-tuning drowns the SOC. Flag both extremes.

## Make the numbers defensible
- **Name the baseline and date in the report.** A percentage without its reference is not defensible.
- **Reconcile the top findings against the portal every run**, including the `verify` items — one wrong "un-sensored DC" claim undermines the whole report.

## Hand off well
- **Lead the review with the un-sensored DCs** — they are the highest-impact, most-urgent fixes.
- **Let the customer own risk-acceptance.** A DC being decommissioned may be a deliberate exception; annotate it so it is not re-flagged each run.
- **Re-run on a cadence**, especially after DC promotions — show coverage climbing to 100%.

## Protect the output
- The report names your identity blind spots — store it in the restricted location (R7), share on a need-to-know basis, never email it broadly.

## Where to go next (adjacent catalog areas)
- **Remediation Playbook (SOAREM)** — the paired, pilot-first solution that *closes* these findings (install sensors, harden the DSA to a gMSA, plant honeytokens, work ISPM), then you re-score.
- **DEFXDR** — unified Defender onboarding if identity is part of a broader coverage gap.
- **THREATHUNT** — proactive hunting over `IdentityDirectoryEvents` / `IdentityLogonEvents` once coverage is solid.
- **SOCXDR** — SOC onboarding and operations for the identity alerts MDI generates. *Response actions and IR determinations belong to the SOC.*
- **Security Optimization Assessment — Defender for Endpoint / Office 365 / Cloud Apps / Cloud / Defender Suite** — the sibling assessments; run the **Defender Suite** assessment for a single cross-workload posture score.
