# 3. Implementation Guide — Insider Risk Readiness Assessment (Microsoft Purview)

This is the exact, ordered procedure to complete an Insider Risk Management (IRM) **readiness assessment** —
the privacy, roles/role-separation, connectors, and scoping groundwork done **before** IRM is deployed
against named users. Everything is done in the **least-exposing mode first**: privacy settings (anonymization
on, minimum indicators) and role separation before any signal is viewed; a tenant **Analytics** scan
(aggregated, anonymized — **no policy**) before any named-user policy; a **disabled/minimal** readiness
policy before any expansion. Portal paths and cmdlets are from Microsoft's public documentation;
**licensing-/plan-dependent features and evolving portal paths are flagged "verify your licensing/tenant"**
and never asserted for your tenant. Do the phases in order. Each phase names its artifacts (from the Overview
naming table), states a **pass/fail gate**, and gives a **rollback**.

> **Automation reality.** IRM has a **limited PowerShell/Graph surface** — it is largely **portal-configured**.
> The five delivered tools report what *is* scriptable (role groups & separation, audit-log state, licensing
> signal, the backing scope group via Microsoft Graph) and **direct you to the Purview portal** for the
> portal-only steps (Analytics scan, connector health, pseudonymization toggle, policy/priority-user
> configuration). Scripts are **read-only or `-WhatIf` by default**; writes require an explicit `-Commit`, and
> **no script ever enables an IRM policy or enforcement**. No credentials are stored in code.

> **Outcomes deferred.** Whether monitoring is lawful in your jurisdiction, any works-council/consultation
> requirement, whether to open a case, what a risk signal means for a person, and any HR/disciplinary/legal
> action are **HR / privacy / legal determinations**. This guide prepares and proves the capability; capture
> those decisions before Phase 5, and note the assessment operates against **no** individual.

---

## Phase 0 — Connect and baseline (Assess)

1. **Connect the toolchain** (GR-#3). On the admin workstation:
   ```powershell
   Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force   # provides Connect-IPPSSession
   Connect-IPPSSession -UserPrincipalName admin@contoso.com            # Security & Compliance PowerShell (role groups, audit)
   Connect-MgGraph -Scopes 'Organization.Read.All','Group.Read.All' -NoWelcome   # licensing signal, scope group (read)
   ```
2. **Run the readiness posture assessment** (delivered script #1, read-only):
   ```powershell
   .\IRMASSESS-Discovery.ps1 -CsvPath .\IRMASSESS-Posture.csv
   ```
   It reports the **IRM role groups and their membership + separation conflicts**, the **unified-audit-log**
   state, a **licensing signal** (subscribed-SKU service plans matching an insider-risk plan), and prints a
   **portal checklist** for the parts that are portal-only (analytics, connectors, pseudonymization,
   policies).
3. **Confirm licensing** (Req 2.1) in the M365 admin center / Purview portal — **verify your licensing/tenant**;
   do not scaffold against a plan you do not hold.
4. **Confirm the portal-only baseline** in **Purview portal → Insider Risk Management**: is IRM openable, is
   **Analytics** available, what (if anything) is already configured under **Settings** and **Policies**?

**Pass/fail gate:** you have a written baseline — IRM role-group membership (with any separation conflicts
flagged), audit-log state, a licensing signal, and a portal note of what already exists.
**Rollback:** none (read-only).

---

## Phase 1 — Establish the privacy-by-design posture (Design → Configure, least-exposing)

Do privacy **before** anyone views signal. These are **portal settings** (IRM exposes no cmdlet to toggle
them) — the guide directs the exact path; the scripts flag them in the scorecard.

5. **Turn anonymization ON** (`Anonymization – On – Readiness`). **Purview portal → Insider Risk Management →
   Settings → Privacy** → select **"Show anonymized versions of usernames."** Analysts will now triage
   **pseudonymized** identities; only an authorized **Investigator** can de-anonymize within a case.
6. **Enable the MINIMUM indicators** for the intended template. **Settings → Policy indicators** → enable only
   the indicators the chosen template needs (e.g. for departing-user data theft: the relevant data-exfiltration
   indicators) — **not** every indicator. Data minimization is a privacy control.
7. **Record the privacy decision** with the privacy stakeholder (Req 2.7): anonymization on, the indicator set,
   the retention/region settings, and any works-council/consultation note.

**Pass/fail gate:** anonymization is **on**, only the minimum required indicators are enabled, and the privacy
decision is documented and signed off by the privacy stakeholder — **before** any analyst has access.
**Rollback:** privacy settings are non-destructive toggles; revert the indicator set / anonymization in the
same portal page. (Anonymization should never be turned *off* without a documented privacy/legal decision.)

---

## Phase 2 — Separate the IRM roles (Configure — the central control)

8. **Confirm/assign the four separated roles.** **Purview portal → Settings → Roles & scopes → Permissions**
   → assign each IRM role group to a **different** named owner:
   - **Insider Risk Management Admins** — configuration only.
   - **Insider Risk Management Analysts** — triage on **pseudonymized** data.
   - **Insider Risk Management Investigators** — case content / forensic evidence / de-anonymization.
   - **Insider Risk Management Auditors** — review the IRM audit trail.
9. **Minimize the super-group.** Remove anyone from the all-powerful **Insider Risk Management** role group who
   does not genuinely require full control.
10. **Keep IRM separate from HR/Legal.** Ensure HR and Legal are **escalation/review** recipients, **not**
    default holders of the Investigator (de-anonymizing) role (Req 2.2/2.7).
11. **Verify separation with the scripts:**
    ```powershell
    .\IRMASSESS-Discovery.ps1        # lists IRM role groups + members and flags separation conflicts
    .\IRMASSESS-Validate.ps1         # per-gate pass/fail incl. role-separation gate
    ```
    A **conflict** = the same identity in two conflicting roles (e.g. Analyst *and* Investigator), or
    unnecessary super-group membership.

**Pass/fail gate:** each of Admin / Analyst / Investigator / Auditor is held by a **different** owner; the
super-group is minimal; no separation conflict is flagged; HR/Legal are not default Investigators.
**Rollback:** role-group membership changes are non-destructive; remove/re-add members
(`Remove-RoleGroupMember` / `Add-RoleGroupMember`) to restore separation.

---

## Phase 3 — Prepare and health-check the connectors (Configure)

Templates are inert without their signal. Prepare only the connectors the intended policy needs. Connector
setup and health are **portal-configured** — the guide names the steps; the scripts flag connector health as a
portal check in the scorecard.

12. **Confirm audit logging is on** (Req 2.5) — the correlation substrate:
    ```powershell
    .\IRMASSESS-Validate.ps1 -Gate Audit   # reads UnifiedAuditLogIngestionEnabled → PASS/FAIL
    ```
    If FAIL, enable unified audit logging per Microsoft docs and allow ingestion before proceeding.
13. **Stand up the HR data connector** (`HR Connector – Readiness`) if the template needs it (departing/
    disgruntled-user templates). **Purview portal → Data Connectors → HR (CSV/API)** → configure the import of
    resignation dates, role changes, and performance/PIP events → run and confirm a **successful import**.
14. **Enable the built-in signals** the template requires: **Entra account deletion** (departing-user), **DLP**
    policy signal, and **Microsoft Defender for Endpoint** integration for security-violation indicators
    (**Settings** → the relevant integration toggles). Optional **healthcare** / **physical-badging**
    connectors for those domains.
15. **Verify connector health** in **Purview portal → Data Connectors** (last import time / status) — **verify
    in the Purview portal**; connector state is not reliably scriptable.

**Pass/fail gate:** audit logging is on (script PASS); every connector the intended template needs is
configured and shows a healthy/recent import in the portal.
**Rollback:** a connector can be paused/removed in the portal with no effect on other Purview features;
removing an unneeded connector reduces signal collection (a privacy-positive rollback).

---

## Phase 4 — Pilot in the least-exposing mode: Analytics, then a disabled/minimal policy (Pilot)

16. **Run Insider Risk Analytics first** (`IRM Analytics – Insights – Tenant`). **Purview portal → Insider Risk
    Management → Analytics → Run scan / Get started.** Analytics returns **aggregated, anonymized** insight
    into potential risk **without a policy and without naming anyone** — the least-exposing way to confirm IRM
    has signal to work with. Review the insights with the privacy stakeholder. *(Analytics is portal-only —
    there is no cmdlet; verify in the portal.)*
17. **Create the backing scope group** (`IRM Priority Users – Readiness – Scope`) — an Entra security group you
    control, created **empty** as the readiness scope:
    ```powershell
    .\IRMASSESS-Config.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -WhatIf   # preview
    .\IRMASSESS-Config.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -Commit    # create (empty)
    ```
    The script creates only the **backing group** (empty, least-exposing). Binding it as a **priority user
    group** and creating the **policy** are portal steps (IRM exposes no policy cmdlet).
18. **Bind the priority user group and create the readiness policy DISABLED/MINIMAL.** **Purview portal →
    Insider Risk Management → Settings → Priority user groups** → create the group backed by the security group
    from step 17. Then **→ Policies → Create policy** → choose the template (e.g. *Data theft by departing
    users* → `IRM – Data Theft Departing Users – Readiness Pilot`) → scope it to the **priority user group
    only** → keep it **minimal / do not broadly enable**. *(Template availability and exact wording are
    version-dependent — verify in your tenant.)*
19. **Adjust the readiness scope narrowly** if needed:
    ```powershell
    .\IRMASSESS-Set-Scope.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' -WhatIf      # report members
    .\IRMASSESS-Set-Scope.ps1 -ScopeGroupName 'IRM Priority Users - Readiness - Scope' `
        -AddMember 'pilotuser@contoso.com' -Commit                                                  # narrow, deliberate
    ```
    Keep the scope minimal — this is a readiness pilot, not a rollout.

**Pass/fail gate:** the Analytics scan has run and been reviewed (aggregated/anonymized); the backing scope
group exists and is minimal; the readiness policy exists **disabled/minimal**, scoped to the priority-user
group only. **No broad enforcement.**
**Rollback:** the Analytics scan changes nothing about individuals; the readiness policy can be **deleted or
kept disabled** in the portal; the backing group can be emptied/deleted
(`IRMASSESS-Set-Scope.ps1 -RemoveMember ... -Commit`) with no residual effect.

---

## Phase 5 — Validate and hand off (Validate → Expand is HR/privacy/legal's call)

20. **Validate every readiness gate:**
    ```powershell
    .\IRMASSESS-Validate.ps1 -CsvPath .\IRMASSESS-Validation.csv
    ```
    Confirms licensing signal, audit-log state, role separation, the backing scope group, and prints the
    portal-verified gates (privacy/anonymization, connectors, analytics, policy) as **PASS / FAIL / VERIFY-IN-
    PORTAL**.
21. **Produce the pseudonymized readiness scorecard** for stakeholder review — **no personal data**:
    ```powershell
    .\IRMASSESS-Report.ps1 -CsvPath .\IRMASSESS-Scorecard.csv
    ```
    It emits **counts and gate status only** (role-group member *counts*, not names; gate pass/fail;
    portal-check reminders) — safe to share with HR/privacy/legal.
22. **Hand the scorecard to HR / privacy / legal** (Req 2.7). **Expansion to operational IRM — enabling the
    policy against named users, broadening scope, opening cases — is their decision**, made against employment/
    privacy law and any works-council consultation. This assessment stops at *readiness proven*.
23. **Record the evidence** (baseline, validation, scorecard, the privacy sign-off, the role-separation
    confirmation) as the deliverable record.

**Pass/fail gate:** every readiness gate is PASS or an explicit documented VERIFY-IN-PORTAL; the pseudonymized
scorecard is produced and handed to HR/privacy/legal with the expansion decision explicitly theirs.
**Rollback:** the entire readiness scaffold is non-operational — the policy stays disabled, the scope group
can be emptied/deleted, privacy settings persist; nothing has run against an individual, so there is nothing
to undo operationally.

---

## Order-of-operations summary

| Phase | Do | Artifact(s) | Gate | Rollback |
|---|---|---|---|---|
| 0 Assess | Connect, baseline roles/audit/licensing, portal recon | Posture CSV | Baseline captured | n/a (read-only) |
| 1 Privacy | Anonymization **ON**, minimum indicators | `Anonymization – On – Readiness` | Privacy posture set + signed off | Revert toggles (portal) |
| 2 Roles | Separate Admin/Analyst/Investigator/Auditor; minimize super-group | Role-separation model | 4 owners distinct, no conflict | Re-set membership |
| 3 Connectors | Audit on; prepare HR/Entra/DLP/Defender; health-check | `HR Connector – Readiness` | Signal present & healthy | Pause/remove connector |
| 4 Pilot | **Analytics** (no policy) → backing group → **disabled/minimal** policy | Analytics insights, scope group, readiness policy | Analytics reviewed; policy disabled/minimal | Delete/disable policy, empty group |
| 5 Validate | Validate gates; pseudonymized scorecard; hand off | Validation CSV, scorecard | All gates PASS/VERIFY; handed to HR/privacy/legal | Non-operational; nothing to undo |

> **The assessment never operates IRM against an individual.** It proves the capability is licensed, private,
> role-separated, connected, and scoped — then defers the decision to deploy, and every case/outcome, to HR,
> privacy, and legal.
