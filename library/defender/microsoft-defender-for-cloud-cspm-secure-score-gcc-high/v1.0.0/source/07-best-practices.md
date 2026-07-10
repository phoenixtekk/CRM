# 7. Best Practices — Microsoft Defender for Cloud: CSPM & Secure Score Remediation

Field-proven guidance for running a posture-management program that measurably raises Secure Score without surprises.

## Enable on a pilot subscription, then inherit at management-group scope
- Turn on Defender CSPM and agentless scanning on `CSPM Scope – Pilot Sub – Pilot` first, validate the cost and the recommendation picture, then enable at a **management-group** scope so new subscriptions inherit posture automatically.
- Preview every plan change with `DEFCSPMG-Enable-CSPM.ps1` (`-WhatIf` default) before applying.

## Remediate by risk, not by count
- Work **attack paths** and highest-impact recommendations first — a single choke point on an internet-exposure → identity → sensitive-data path removes more real risk than clearing dozens of low-severity items.
- Use the built-in **Fix** action where offered, but do manual remediation of production resources in a controlled window with a rollback.

## Treat Secure Score as a trend
- Capture a **baseline** (`DEFCSPMG-Report.ps1 -SaveBaseline`) and track the delta each cycle. A rising trend is the signal the program is working; a single snapshot is not.
- Re-baseline after each expansion wave so the trend reflects real scope growth, not just the pilot.

## Make exemptions honest and time-bound
- Every exception is a scoped **exemption** with a **justification and expiry** (`CSPM Exemption – <recommendation> – Prod`) — never a silent suppression. Review exemptions on a cadence so they don't become permanent blind spots.
- Whether an exemption is *acceptable* is the security/compliance team's decision; the tooling records and expires it.

## Assign ownership with governance rules
- Use `Secure Score Remediation – Pilot Sub – Prod` to assign **owners and due dates** to recommendations. Posture only improves when someone owns each finding; governance rules make that explicit and trackable.

## Export continuously and report the trend
- Stream recommendations and Secure Score to Log Analytics (`CSPM Continuous Export – Pilot Sub – Prod`) and trend them in the `Secure Score Trend – Pilot Sub – Prod` workbook. This turns posture from a portal glance into a reportable metric for leadership.

## Keep licensing and preview facts current (GCC High/DoD parity)
- **Defender CSPM, agentless scanning, and several plans are paid** and version-dependent. Before enabling, **verify current pricing and availability in your tenant** — never assume a feature is free or included.
- **In GCC High/DoD, feature and plan parity can lag commercial.** Agentless/data-aware posture, attack-path analysis, certain data connectors, AWS/GCP multicloud connectors, and preview capabilities **may be delayed or unavailable** in the sovereign cloud. Confirm each **against current Microsoft Government documentation** for your specific cloud (GCC High vs DoD/IL5) — see `gcc-high-parity-notes.md`. Do not assert parity or invent availability.

## Defer the compliance and risk decisions to the owners
- Which **regulatory standards** apply, which **records/legal** obligations must be met, and whether a given **exemption or residual risk** is acceptable are the **compliance, legal, and security teams'** determinations. This solution delivers the controls, the scoring, and the evidence — not the decision.

## Where to go next
Once CSPM is running and Secure Score is trending up, natural next steps in the catalog:
- **Azure Security Baseline & Governance** to enforce secure configuration with Azure Policy guardrails (audit → deny).
- **Microsoft Defender XDR Deployment & Unified Onboarding** to correlate endpoint/identity/email/cloud threat detection alongside posture.
- The **Sentinel** solutions to stream Defender for Cloud alerts into a SIEM for hunting and SOAR.
- **AWS/GCP** landing-zone and security-hub solutions to deepen multicloud coverage beyond high-level posture.
