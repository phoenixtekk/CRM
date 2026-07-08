# 6. Troubleshooting — Microsoft Purview HIPAA Compliance Program

Common failure modes and how to resolve them. Ordered roughly by where they surface in the model
**Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand.** Portal paths, template
availability, and cmdlets are **plan-dependent and the portal evolves — verify against your tenant.**

## The HIPAA/HITECH (or HITRUST CSF) template is not available to create
- **Cause:** Premium templates require **Microsoft 365 E5 / E5 Compliance** or the **Compliance Manager
  Premium Assessment Add-On**, and the **number** of premium assessments is entitlement-bound. GCC/GCC
  High and sovereign clouds may differ.
- **Fix:** Confirm entitlement in the M365 admin center → `Billing → Licenses`; in the portal →
  **Compliance Manager → Assessment templates**, check the template shows as available. `CMPHIPAA-Discovery.ps1`
  reports the compliance-capable SKUs it can read, but SKU strings vary — **confirm with Microsoft
  licensing, don't assume**. Assign/purchase the required plan before relying on the template.

## `Connect-IPPSSession` or `Connect-MgGraph` fails
- **Cause:** Missing module, no modern-auth/MFA, or insufficient role.
- **Fix:** `Install-Module ExchangeOnlineManagement` and `Install-Module Microsoft.Graph`
  (`-Scope CurrentUser`). Sign in with a modern-auth / MFA-capable admin holding a Compliance Manager role
  (or Compliance Administrator). For Graph sections, consent to the read scopes the script requests
  (`Organization.Read.All`, `Directory.Read.All` for licensing; `Policy.Read.All` for Conditional Access).
  Use `-SkipGraphLicensing` / `-SkipGraphCA` to run the non-Graph sections if Graph is unavailable.

## A role group "could not be read" or a name looks wrong
- **Cause:** Purview role-group naming evolves; the exact Compliance Manager role-group names in your
  tenant may differ from the defaults, or your admin lacks rights to read membership.
- **Fix:** In the portal → `Settings → Roles & scopes → Permissions`, confirm the actual role-group names,
  then re-run with those names. `Get-RoleGroup` (via `Connect-IPPSSession`) lists what exists. Ensure the
  running admin can read role-group membership.

## Separation-of-duties flag: someone is Administrator AND Contributor
- **Cause:** A person holds both the config-owning **Administrators** role and the action-owning
  **Contributors** role — the evidence you produce is less defensible if access to it was not separated.
- **Fix:** Decide with the HIPAA owners whether the overlap is accepted; if not, remove the surplus
  membership with `CMPHIPAA-Set-Scope.ps1 -Action Remove ... -Commit`. Keep the Security/Privacy Officer
  and auditors as **Readers**.

## The score didn't change after I "implemented" a safeguard
- **Cause:** Compliance Manager **measures; it does not enforce.** Marking an action implemented in the
  portal does not change the tenant — and if automatic testing is on, the action's **test status** reflects
  the *actual* technical signal, which may still be absent.
- **Fix:** Run `CMPHIPAA-Validation.ps1` to confirm the underlying control (audit ingestion, DLP for ePHI,
  label, retention, Conditional Access) is actually present. If it is absent, the safeguard is genuinely
  not implemented — deploy that control in **its own solution**, piloted in simulation/test first, then
  re-validate. Do not mark a safeguard implemented without proof (no false passes).

## A safeguard shows implemented but `CMPHIPAA-Validation.ps1` says the control is ABSENT
- **Cause:** A manual "Implemented" status was set without the technical control being in place — a false
  pass that inflates the HIPAA score (worse than a low score in an OCR investigation).
- **Fix:** Reset the action to **Not implemented / Not assessed** until the control exists and is evidenced.
  Attach real evidence (audit-config export, policy screenshot/export, CA report) and set the test
  status/date. Prefer **automatic testing** for the technical safeguards it can read.

## Automatic testing isn't updating an action
- **Cause:** Not every improvement action is **eligible** for automatic testing; eligibility is
  plan/action-dependent, and the underlying Microsoft 365 signal must exist.
- **Fix:** Confirm automatic testing is enabled (`HIPAA Automatic Testing – Setting`) in **Compliance
  Manager → Settings**. For ineligible actions (most Administrative/Physical safeguards — training, BAAs,
  facility controls, policy documents), attach **manual** evidence with an owner and date; record the
  source in `HIPAA Evidence – Register`.

## `CMPHIPAA-Configuration.ps1` reports rows as FAIL
- **Cause:** A row is missing a mandatory field (Action, Safeguard, Owner, TargetDate,
  ImplementationStatus, EvidenceSource, TestMode) or the TargetDate doesn't parse.
- **Fix:** Complete the owner-provided CSV — every action needs an owner, a valid target date, a mapped
  safeguard, and a named evidence source. Re-run the dry-run until all rows are OK, then `-Commit`.

## I expected the scripts to create the assessment / set action status — they didn't
- **Cause:** Compliance Manager does **not** expose a broad public PowerShell/Graph write API to create
  assessments or set action/evidence status. The scripts assess readiness/roles and the **technical
  evidence** and structure the local plan/evidence artifacts.
- **Fix:** Create the assessment, assign actions, and upload evidence in the **Purview portal**, driven by
  the `HIPAA Action Plan – Pilot` / `HIPAA Evidence – Register` / `HIPAA Control Map – Safeguards`
  artifacts the Configuration script writes.

## Shared controls didn't credit across HITECH and HITRUST/NIST
- **Cause:** The action is not a shared/Microsoft-managed control, or its status wasn't set on the source
  assessment.
- **Fix:** Confirm the control is a **shared** control and its implementation/test status is set; shared
  controls credit automatically across assessments that map the same control. Track only the **gap**
  between frameworks, not the overlap.

## A high-impact technical remediation caused disruption
- **Cause:** A mapped action's technical control (a new DLP, label with encryption, retention, or
  Conditional Access policy) was enforced without piloting.
- **Fix:** Always deploy high-impact controls in **simulation/test/disabled** mode first, under their own
  change control, in their own solution — then evidence them here. Roll the control back in its own
  feature; **removing the Compliance Manager assessment does not undo a tenant change** (the assessment
  only measures).

## Rollback
- **Assessments/measurement:** any assessment can be removed in the portal without touching tenant
  configuration; scope can be narrowed at any time (non-destructive).
- **Roles:** revert membership with `CMPHIPAA-Set-Scope.ps1 -Action Remove ... -Commit`.
- **Technical controls:** roll back in the owning feature's solution — not here; this program only measures
  and evidences.

---
*Whether the resulting score/evidence satisfies the HIPAA obligation — and which safeguards apply, how each
addressable specification is met, and the risk-analysis outcome — are **compliance/privacy/legal
determinations**, not technical fixes in this guide.*
