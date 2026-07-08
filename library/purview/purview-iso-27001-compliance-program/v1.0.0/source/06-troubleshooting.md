# 6. Troubleshooting — Microsoft Purview ISO 27001 Compliance Program

Symptom-first fixes for the failures you actually hit standing up an ISO 27001-aligned Purview program.
Most problems are one of: the ISO template not available, a control that maps but has no evidence, a
technical control not behaving, missing audit/logging evidence, or a script that seems to change nothing.

---

## Compliance Manager / assessment

**The ISO/IEC 27001 assessment template isn't available to create the assessment.**
- **Licensing:** the ISO template is a **premium** template — it requires **E5 / E5 Compliance** or the
  **Compliance Manager Premium Assessment Add-On**, and the **number** of premium assessments depends on
  licensing/seat count. Confirm in the **M365 admin center** and **Compliance Manager → Assessment
  templates** (Req 2.1). Run `ISO27001-Discovery.ps1` for the licensing signal, then **verify in the
  portal** — do not assume.
- **Role:** you need a **Compliance Manager Administrator / Assessor** role to create assessments (Req 2.3).

**I can't set improvement-action status or create assessments from PowerShell.**
- **Expected.** Compliance Manager has **no broad public PowerShell/Graph API** — assessments,
  improvement actions, and evidence upload are **portal-only**. The delivered scripts assess readiness,
  roles, and the **technical evidence** behind actions; they do not replace the portal.

**Automatic testing isn't updating an action's status.**
- Only **eligible** improvement actions auto-test from Microsoft 365 signals; others require manual
  implementation/test and uploaded evidence. Availability is **plan/action-dependent** — verify, and set
  those actions manually.

## Control mapping

**I don't know which Annex A controls to map.**
- The applicable controls come from the **Statement of Applicability** (Req 2.2), produced by the
  ISMS/risk function — **not** from Purview. Do not infer applicability from what Purview does; get the
  SoA first. Applicability is a **determination**, deferred.

**A control maps to Purview but Purview only partly covers it.**
- Mark it **"partial"** in `ISO27001 Control Map – AnnexA-to-Purview` and note what the residual evidence
  source is (an organizational/manual control). Never claim a partially-covered control is fully met — that
  is the auditor's call.

**An organizational / people / physical Annex A control has no Purview capability.**
- Correct — those are **outside Purview** and outside this program. Mark them **out-of-Purview**; that is
  clean scope discipline, not a gap.

## Evidence collection

**`ISO27001-ControlEvidence.ps1` reports a control as `Collected = No`.**
- That is an **evidence gap** to close. Common causes: the underlying object doesn't exist yet (build it
  in Phase 3), the account lacks the **role** to read it (labels/DLP/retention/audit — Req 2.4), or Graph
  isn't connected for the licensing/Conditional-Access signal (`Connect-MgGraph -Scopes
  Organization.Read.All, Policy.Read.All`).

**The evidence register looks stale.**
- It reflects the **live technical state at run time** — re-run it on the **continual-improvement
  cadence** (Best Practices). Attach the fresh export to the matching Compliance Manager improvement
  action and update **test status/date**.

## Technical controls not behaving

**A DLP policy matches nothing / doesn't block.**
- Confirm the policy's **mode** — a **simulation** policy evaluates and logs but does **not** block
  (that's expected during pilot); a **disabled** policy does nothing. Check with `ISO27001-Discovery.ps1`
  (Mode column). To block, enforce it for the pilot ring (Implementation Phase 4).
- Check **instance count/confidence** on the rule and that the test identity/location is **in scope** and
  not excluded. **New/changed DLP policies take time to propagate** (up to ~1 hour, longer for some
  locations) — wait before concluding it's broken.

**Sensitivity labels aren't appearing for users.**
- Confirm the label is **published in a label policy** scoped to those users (`Get-LabelPolicy`), and
  allow for **publish latency**. During pilot the policy is scoped to the ring only — users outside the
  ring correctly see nothing.

**Retention/disposition isn't behaving as specified.**
- Confirm the retention policy is **enabled and scoped** to the test content, and allow for **provisioning
  latency**. Remember the **retention duration/action reflects the records schedule** (a records/legal
  determination) — if the behaviour is "wrong," confirm it against the schedule, not against an assumption.

## Audit / logging evidence

**No logging/monitoring evidence (A.8.15/8.16) is being collected.**
- Confirm **unified audit logging is ON** (`Get-AdminAuditLogConfig | Select
  UnifiedAuditLogIngestionEnabled`, or the Purview Audit page — Req 2.5). Audit data **only accrues from
  when it is enabled** — a late enablement is a permanent gap for the prior period.
- `ISO27001-Report.ps1` returns nothing → widen `-Days` (freshly configured controls need **dwell
  time**), confirm audit logging is on, and confirm your account has the **audit/View-Only** role.

## Scripts / tooling

**A script seems to make no change.**
- **By design.** `ISO27001-Config.ps1` and `ISO27001-Set-Scope.ps1` are **`-WhatIf` by default** — writes
  require `-Commit`. Discovery / ControlEvidence / Report are **read-only**. Re-run with `-Commit` to
  apply an intended write.
- `ISO27001-Config.ps1` **refuses to touch a policy that is already enforcing** and **never sets enforce**
  — moving a control to enforcement is a deliberate portal step after the pilot gate.

**`Connect-IPPSSession` or a cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin. A missing **role** (Compliance/DLP/Records/Audit) surfaces as "cmdlet not
  recognized" or access denied — assign the least-privilege role for that control area (Req 2.4).

---

### Fast triage table

| Symptom | First check |
|---|---|
| ISO template unavailable | Licensing (E5 / E5 Compliance / premium add-on) + Compliance Manager role |
| Can't script assessments | Expected — Compliance Manager is portal-only; scripts do evidence, not assessments |
| Don't know what to map | Get the **SoA** from the ISMS/risk function — applicability is deferred |
| Control partly covered | Mark "partial"; never claim fully met |
| Evidence `Collected = No` | Object missing, role missing, or Graph not connected |
| DLP matches nothing / no block | Mode (sim/disabled), instance count/confidence, scope, propagation time |
| Labels not appearing | Published in a label policy? scoped to those users? publish latency |
| No audit evidence | Unified audit ON? enabled late = gap; dwell time; audit role |
| Script changes nothing | `-WhatIf` default — pass `-Commit`; Config never enforces |
| Cmdlet/connect fails | Module updated, modern auth, correct least-privilege role |
