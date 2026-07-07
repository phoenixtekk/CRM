# Testing & Validation

Run these after the Configure and Pilot stages, and again to refresh evidence before the assessment
window. Each test states the **procedure** and the **expected pass/fail**. A test **passing** means the
control is *configured and evidenced as designed* — it does **not** assert the control "satisfies" a
NIST 800-171 requirement as an assessment matter; that determination is your assessor's.

Run validations against the **`CUI – Pilot – Org`** group first (Gate 3), then across the full
**`CUI – Boundary – Org`** OU (Gate 4).

---

## T1 — Boundary membership is correct

- **Procedure:** `python cui-boundary-check.py --ou "/CUI – Boundary – Org" --out boundary-exposure.csv`
  then review membership against the CUI inventory.
- **Pass:** Every user/group/Shared Drive in the CUI inventory is inside the boundary OU, and no
  unexpected members are present.
- **Fail:** Missing in-scope members, or out-of-scope members present → correct OU membership and
  re-run before evidencing.

## T2 — External sharing is restricted (AC)

- **Procedure:** As a boundary-OU user, attempt to share a CUI Drive file externally; also run the
  boundary checker's sharing scan.
- **Pass:** External sharing is blocked or limited to the allow-list per **`Sharing – CUI Boundary –
  Restricted`**; the checker reports no unexpected external exposure.
- **Fail:** External share succeeds outside policy → re-apply the sharing policy; re-pilot.

## T3 — Context-aware access enforces (AC)

- **Procedure:** Access a CUI app from a context that violates **`CAA – CUI Boundary – Enforce`** (e.g.
  disallowed location/device state per your access level).
- **Pass:** Access is denied from the non-conforming context and allowed from a conforming one.
- **Fail:** Access allowed from a non-conforming context → verify access-level assignment to the OU's
  apps.

## T4 — 2-Step Verification / keys enforced (IA)

- **Procedure:** Confirm a boundary-OU account cannot complete sign-in without the enforced second
  factor; review the 2SV enrollment report.
- **Pass:** 2SV (security keys where required) is enforced for 100% of boundary-OU accounts; no
  exempted accounts remain.
- **Fail:** Any boundary account without enforced 2SV → remediate before evidencing.

## T5 — DLP detects and acts on CUI (SI/MP)

- **Procedure:** Send/share test content matching the CUI detector; in pilot the rule is
  **`DLP – CUI – Monitor`**, in enforcement **`DLP – CUI – Enforce`**.
- **Pass:** Monitor logs the event; Enforce blocks/warns as designed; no false-block of legitimate
  non-CUI content in the pilot sample.
- **Fail:** CUI content passes undetected, or heavy false positives → tune the detector; re-pilot. **Do
  not promote monitor→enforce fleet-wide on a failed pilot.**

## T6 — Audit logging and export work (AU)

- **Procedure:** Perform a set of known admin and user actions in the boundary; confirm they appear in
  the audit logs and in the **`AuditExport – CUI – Org`** sink.
- **Pass:** All test actions are recorded and present in the exported/retained sink within the expected
  latency; retention rule **`Retention – CUI – Org`** is active.
- **Fail:** Missing events or export not populating → verify export configuration and retention rule.

## T7 — Data region / encryption posture (SC/MP)

- **Procedure:** Confirm the boundary OU's data-region policy and (where licensed) encryption state via
  the Admin console and `assess-nist-controls.py`.
- **Pass:** Data region and encryption match the documented regulated-workload design. **Verify Assured
  Controls / encryption availability in your tenant** — if a capability is unavailable by edition, this
  test **defers to a POA&M item** rather than failing the readiness gate.
- **Fail (actionable):** Configuration drifts from the documented design → re-apply; **capability
  unavailable by edition** → record on POA&M, not a hard fail.

## T8 — App / API access controlled (CM)

- **Procedure:** From a boundary-OU account, attempt to authorize a non-allow-listed Marketplace/OAuth
  app.
- **Pass:** Authorization is blocked per the allow-list.
- **Fail:** Non-allow-listed app authorizes → re-apply app-access restriction.

## T9 — Evidence package is complete and indexed

- **Procedure:** `python collect-evidence.py --ou "/CUI – Boundary – Org" --package "Evidence – CUI
  Boundary – <date>"` then review the package index against the control map.
- **Pass:** Every `configured` control has a matching config export and/or audit-log extract in the
  package, indexed to its control ID.
- **Fail:** A configured control has no evidence → collect the missing artifact.

## T10 — SSP and POA&M are complete (CA)

- **Procedure:** `python generate-ssp-poam.py …`, then the compliance owner reviews.
- **Pass:** **`SSP – CUI Boundary – Org`** has an implementation statement for every in-scope
  requirement; **`POA&M – CUI Boundary – Org`** has a row (owner + milestone) for every
  partial/not-configured/verify-edition requirement; the compliance owner has reviewed and accepted the
  drafts.
- **Fail:** Any in-scope requirement missing an SSP statement or an unmet requirement missing from the
  POA&M → complete before declaring assessment-ready.

---

**Overall readiness gate (Gate 4):** T1–T10 pass (with T7 edition-gaps parked on the POA&M), and the
compliance owner has accepted the SSP + POA&M. At this point the environment is **assessment-ready**.
The C3PAO assessment and its outcome remain out of scope.
