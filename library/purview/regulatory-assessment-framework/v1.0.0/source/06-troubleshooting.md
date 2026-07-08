# 6. Troubleshooting — Regulatory Assessment Framework (Microsoft Purview)

Common issues, grouped by stage. Each has a **symptom**, the **likely cause**, and a **resolution**.
None of the tools change tenant configuration: `CMPFRAME-Configuration.ps1` and `CMPFRAME-Report.ps1`
only read/write **local** artifact files, `CMPFRAME-Set-Scope.ps1` is `-WhatIf` by default and touches
only role-group membership with `-Commit`, and `CMPFRAME-Discovery.ps1` / `CMPFRAME-Validation.ps1` are
read-only. Compliance Manager **measures**, it does not enforce — so most issues are licensing, role, or
crosswalk-input problems.

## Licensing & template availability

**Symptom:** a regulation's template does not appear under **Compliance Manager → Assessment templates**.
**Likely cause:** the template is a premium template not covered by the tenant's entitlement, or licensing
isn't assigned (Requirement 2.1). Template availability is plan-dependent and evolves.
**Resolution:** verify entitlement with Microsoft licensing (do not assume), assign it, and re-check. If it
is genuinely unavailable, record the regulation as **not-yet-licensed** in `RAF Scope – Record` rather than
proceeding — that is a legitimate scoping result, not a tool failure.

**Symptom:** `CMPFRAME-Discovery.ps1` can't read licensing SKUs.
**Likely cause:** `Microsoft.Graph` not installed or `Organization.Read.All` not consented.
**Resolution:** `Install-Module Microsoft.Graph -Scope CurrentUser`, re-run and consent, or confirm
licensing in the Microsoft 365 admin center.

## Crosswalk input (CMPFRAME-Configuration.ps1)

**Symptom:** "Input CSV missing required column(s)".
**Likely cause:** the input file lacks one of `Control, Regulations, Owner, TargetDate, EvidenceSource`
(optional `AutoTest`).
**Resolution:** add the headers exactly; `Regulations` is a **semicolon-separated** list
(e.g. `NIST 800-53;ISO 27001;HIPAA`).

**Symptom:** validation reports `[orphan]`, `[owner]`, `[date]`, or `[evid]` issues.
**Likely cause:** a control maps to no regulation, or has no owner / target date / evidence source.
**Resolution:** these are real gaps — resolve them with the control owners before `-Commit`. A control you
cannot evidence does not belong in the canonical set.

**Symptom:** `-Commit` wrote nothing / files missing.
**Likely cause:** `-Commit` was omitted (default is dry-run), or `-OutDir` isn't writable.
**Resolution:** re-run with `-Commit` and a writable `-OutDir`; the three files
(`RAF-Crosswalk-Register.csv`, `RAF-Action-Plan-Shared.csv`, `RAF-Evidence-Register.csv`) are written there.

## Roles & separation (CMPFRAME-Set-Scope.ps1)

**Symptom:** "Role group '… ' not found or not readable".
**Likely cause:** the Compliance Manager role-group names differ in your tenant, or the signed-in admin
can't manage role groups.
**Resolution:** confirm the names under **Settings → Roles & scopes → Permissions**, and sign in with an
account allowed to manage role groups. Verify names against your tenant — Purview evolves.

**Symptom:** you want to add someone but the tool says they are "already a member".
**Likely cause:** membership matches by display name or the UPN local-part; the person is already in the group.
**Resolution:** no action needed. To move someone to a lower-privilege role, `Remove` them from the higher
group and `Add` to the correct one, keeping administrators separated from contributors.

## Reporting (CMPFRAME-Report.ps1)

**Symptom:** "Crosswalk file not found".
**Likely cause:** you ran the report before `CMPFRAME-Configuration.ps1 -Commit` produced the register.
**Resolution:** commit the configuration first, then point `-CrosswalkPath` at the generated
`RAF-Crosswalk-Register.csv`.

**Symptom:** every regulation shows "awaiting evidence".
**Likely cause:** no `-EvidencePath` was supplied, or the evidence register's `TestStatus` is still
`Not assessed`.
**Resolution:** attach evidence and update status in the Purview portal, refresh
`RAF-Evidence-Register.csv`, and pass `-EvidencePath`. Remember coverage counts controls **mapped and
evidenced** — not regulatory adequacy.

## Automatic testing & signals (CMPFRAME-Validation.ps1)

**Symptom:** a shared control shows **ABSENT** even though you think the control exists.
**Likely cause:** wrong endpoint/role, or the underlying technical control (audit, DLP, retention, labels,
Conditional Access) genuinely isn't in place yet.
**Resolution:** confirm connectivity/role and re-read; if the control really is absent, implement it as a
**separate, simulation/test-piloted change** owned by that feature's solution — not switched on blind here.

**Symptom:** automatic testing in Compliance Manager doesn't update an action's status.
**Likely cause:** automatic testing isn't enabled, the action isn't eligible for automatic testing, or the
signal hasn't propagated.
**Resolution:** enable automatic testing (Requirement 2.7) per the governance owners' decision, confirm the
action is auto-testable, and allow time to propagate; otherwise attach **manual** evidence.

## What these gates do NOT decide
Whether a **regulation applies**, and whether the **evidence satisfies it**, are
**compliance / records / privacy / legal determinations** (Requirement 2.5) — the framework builds the
shared-control set, the crosswalk, the assessments, and the coverage matrix; adequacy and sign-off belong
to those functions. The **high-impact technical changes** a shared control requires (enabling audit, DLP,
retention, labels, Conditional Access) are separate, simulation-piloted changes owned by their own solution.
