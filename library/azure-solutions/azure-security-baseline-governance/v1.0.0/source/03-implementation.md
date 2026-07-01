# 3. Implementation Guide — Azure Security Baseline & Governance

Follow these steps **in order**, in the **Azure portal** (`https://portal.azure.com`). Objects are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in every later step, script, and test.

> **Model:** Assign guardrails in **audit** first, understand the picture, then move the **same** assignment to **deny** on a controlled gate. Tighten RBAC and apply the baseline on a **pilot scope**, validate, then expand. Keep a rollback for every deny/RBAC change.

## Naming (set once, reuse verbatim)
- Guardrail initiative assignment (audit stage): `Security Baseline Guardrails – Pilot MG – Audit`
- Guardrail initiative assignment (deny stage): `Security Baseline Guardrails – Pilot MG – Deny`
- Custom least-privilege role: `Resource Operator LeastPriv – Pilot Sub – Prod`
- Scope group (management group node): `Governance Scope – Pilot MG – Prod`

## Step 1 — Define and confirm the scope
1. `portal.azure.com` → **Management groups**. Confirm (or create) the node that will hold the pilot subscriptions; treat it as `Governance Scope – Pilot MG – Prod`.
2. Place the pilot subscription(s) under that node.
3. Run `AZSEC-Set-ScopeTargeting.ps1` to resolve the management-group/subscription scope string used by every later step, and `AZSEC-Discovery.ps1` for the current policy/RBAC/Defender baseline.

## Step 2 — Assign the guardrail initiative in audit
1. `portal.azure.com` → **Policy** → **Definitions** and pick the initiative to assign (start with the built-in Microsoft cloud security benchmark plus the named guardrails: require encryption, restrict public storage/network access, allowed locations, allowed SKUs).
2. **Assign**. **Scope:** the management-group node from Step 1 (`Governance Scope – Pilot MG – Prod`).
3. **Assignment name:** `Security Baseline Guardrails – Pilot MG – Audit`.
4. **Parameters:** set every guardrail **effect** to **Audit** (or **AuditIfNotExists**). Set allowed **locations** and allowed **SKUs** to your standards.
5. **Review + create.** No resource is blocked at this stage.

## Step 3 — Review the audit picture and exempt false positives
1. **Policy** → **Compliance** → open `Security Baseline Guardrails – Pilot MG – Audit`.
2. Review non-compliant resources. For any legitimate exception, create a scoped **Exemption** (Policy → Exemptions) with a justification and expiry — do not weaken the policy.
3. Run `AZSEC-Report.ps1` to capture the audit-stage posture as the pre-change baseline.

## Step 4 — Tighten RBAC to least privilege
1. `portal.azure.com` → the pilot subscription → **Access control (IAM)** → **Role assignments**. Identify **standing Owner** assignments that are broader than needed.
2. **Access control (IAM)** → **Add** → **Add custom role** → create `Resource Operator LeastPriv – Pilot Sub – Prod` granting only the actions operators actually need (deny sensitive `Microsoft.Authorization/*` write, etc.).
3. Reassign affected principals from **Owner** to the custom role (or to a scoped built-in role) at the narrowest scope. Prefer **PIM eligible** activation over standing access where available.
4. Run `AZSEC-Validation.ps1` to confirm the least-privilege state and that no unexpected standing Owner remains.

## Step 5 — Apply the secure-configuration baseline
1. Confirm the baseline policies are part of the assigned initiative: require storage encryption, **deny/audit public blob access**, require **secure transfer (HTTPS)**, restrict **public network access**, allowed **locations** and **SKUs**, and diagnostic-logging policies.
2. Where a baseline control is not yet covered, add the built-in policy to the initiative (or assign it alongside) at the same scope, **in audit** for now.
3. Run `AZSEC-Report.ps1` to confirm the baseline controls appear in the posture report.

## Step 6 — Enable Defender for Cloud and remediate top findings
1. `portal.azure.com` → **Microsoft Defender for Cloud** → **Environment settings** → the pilot subscription → enable **foundational CSPM** (and any enhanced plans agreed in requirements).
2. **Microsoft Defender for Cloud** → **Secure score** — record the starting score.
3. **Recommendations** — work the highest-impact items first; use **Fix** where offered.
4. **Regulatory compliance** — map to the standard(s) you must meet and note the gaps.
5. Run `AZSEC-Report.ps1` to capture secure score, top recommendations, and drift versus the baseline.

## Step 7 — Validate on the pilot
1. Run `AZSEC-Validation.ps1` → confirms the audit-stage assignment is present, RBAC is least-privilege, and the provider is registered.
2. Run `AZSEC-Report.ps1` → confirms posture, secure score, and drift.
3. Attempt to create a resource that violates a guardrail (e.g. a storage account with public access) — in audit it is **allowed but flagged**. Complete the **Testing Guide** before proceeding.

## Step 8 — Move guardrails from audit to deny (the gate)
1. **Gate:** only proceed when the audit picture is clean (exemptions in place, no surprise blocks expected) and the change is approved.
2. **Policy** → **Assignments** → duplicate the assignment as `Security Baseline Guardrails – Pilot MG – Deny`, or edit the existing one, setting each guardrail **effect** to **Deny**.
3. Re-run `AZSEC-Validation.ps1` and re-attempt the violating-resource creation — it must now be **blocked**.
4. **Rollback:** if deny blocks legitimate work, set the effect back to **Audit** (or remove the deny assignment) — resources already created are unaffected.

## Step 9 — Expand to production
1. Reassign the validated initiative (in the effect stage you've proven) to the broader management-group node covering the remaining subscriptions.
2. Roll the custom role and RBAC tightening out to those subscriptions.
3. Enable Defender for Cloud on the expanded scope and re-baseline the secure score.
4. Re-validate each cycle with `AZSEC-Validation.ps1` and track drift with `AZSEC-Report.ps1`.

---
### Order of operations
`Define scope → assign initiative (audit) → review/exempt → tighten RBAC → apply baseline → enable Defender + remediate → validate → move to deny (gate) → expand`
