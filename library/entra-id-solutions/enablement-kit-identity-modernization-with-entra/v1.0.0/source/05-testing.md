# 5. Testing, Knowledge-Check & Take-Home Runbook — Enablement Kit: Identity Modernization with Entra

Because this is an enablement kit, "testing" means two things: **validating the labs worked** and
**confirming the team learned** (a knowledge-check). This guide also assembles the **take-home
runbook** the team keeps after the kit. Reference the scripts by name throughout.

## Part A — Lab validation procedures

### V1. Lab environment (Lab 0)
- Run `EKIDMOD-Validate.ps1`. **Pass:** pilot group `Identity Modernization – Pilot – Lab` present,
  sample users present and in the group, Graph module OK, licensing detected.
- Run `EKIDMOD-Discovery.ps1`. **Pass:** a baseline is printed (legacy auth, MFA state, methods,
  federated domains) with no script errors.

### V2. Conditional Access report-only (Labs 1–2)
- Entra → **Protection → Conditional Access → Policies**; confirm `CA – Pilot – Require MFA
  (Report-only)`, `CA – Pilot – Block Legacy Auth (Report-only)`, and `CA – Pilot – Sign-in Risk MFA
  (Report-only)` all show state **Report-only** and are scoped to the pilot group with break-glass
  excluded. **Pass:** all three present and report-only.
- Use the **What-If** tool: Entra → **Conditional Access → Policies → What If** → select a pilot lab
  user → evaluate. **Pass:** the report-only policies show as "would apply".
- Sign in as a pilot lab user, then review **Conditional Access → Insights and reporting (report-only
  workbook)**. **Pass:** the sign-in appears with the report-only result — proving impact is visible
  *before* enforcement.

### V3. Passwordless (Lab 3)
- Entra → **Authentication methods → Policies**; confirm FIDO2/passkey enabled and targeted at the
  pilot group. Have a lab user complete registration at `https://aka.ms/mysecurityinfo`. **Pass:** the
  method is registered for at least one lab user (visible under the user's **Authentication methods**).

### V4. Governance (Lab 4)
- Confirm `Access Review – Pilot – Lab` exists and is in progress, and `Access Package – Pilot Apps –
  Lab` exists with a request policy. **Pass:** both present; a lab user can request the access package.

### V5. Scorecard (Lab 7)
- Run `EKIDMOD-Report.ps1 -OutputPath .\EKIDMOD-Scorecard`. **Pass:** CSV + HTML produced and open
  cleanly, showing per-building-block scores.
- (Optional) Run two or three queries from `EKIDMOD-Signals.kql` in Log Analytics. **Pass:** queries
  return rows (or a clean empty result) without syntax errors.

## Part B — Knowledge-check (the team should be able to answer)
1. Name the seven building blocks of the Entra target-state architecture and which license each needs.
2. Why is every Conditional Access policy introduced in **report-only** first? Where do you read the
   impact before enforcing?
3. What is the difference between **sign-in risk** and **user risk** in Identity Protection, and how
   does each map to a Conditional Access grant?
4. Order the safe steps to migrate a **federated** domain to **cloud authentication**. What is the
   rollback point, and what role does **staged rollout** play?
5. In governance, explain **eligible vs active** role assignments in PIM, and when you would use an
   **access package** instead of direct group membership.
6. Where does **Global Secure Access** fit in the modernization sequence, and why after CA + Identity
   Protection?
7. Why must **break-glass** accounts be excluded from the policies you build, and how are they
   monitored?

*(Suggested pass mark: the team answers 6 of 7 without notes.)*

## Part C — Take-home runbook (fill in during the kit)
Assemble a one-page-per-section runbook the team keeps. Capture, for your tenant:

- **Baseline** — the `EKIDMOD-Discovery.ps1` output and `EKIDMOD-Report.ps1` scorecard (dated).
- **Break-glass** — the two accounts, where credentials are stored, and who monitors sign-ins.
- **CA rollout plan** — the report-only policies built, and the ring plan to enforce them
  (pilot → dept → all), with each exclusion.
- **Identity Protection** — the risk policies to enforce and thresholds chosen.
- **Passwordless plan** — methods to enable and the registration campaign approach.
- **Governance plan** — which roles go into PIM, which access is packaged, review cadence.
- **GSA plan** — when and where GSA is introduced.
- **Coexistence / legacy retirement** — the federation-to-cloud sequence and AD FS decommission
  criteria.
- **Hand-offs** — which implementation solution executes each production step (ENTZTCA, ENTPASSKEY,
  ENTPIM/ENTIGA, HYBID/EKHYBID, GSA, app-governance).

A completed runbook + a passed knowledge-check = the kit's success criteria.
