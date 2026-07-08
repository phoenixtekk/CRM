# 5. Testing & Validation — Microsoft 365 Copilot Data-Protection Readiness (Microsoft Purview)

Testing proves the remediation actually reduces Copilot exposure **without breaking legitimate
collaboration** — before anything is enforced tenant-wide, and before the go/no-go is signed. Every gate
below is validated on the **pilot ring** first, with policies in **simulation/test/disabled**, and each
has an explicit **pass/fail** and a **rollback**. Run `AICOPILOT-Validation.ps1` (read-only) to collect
the machine-checkable evidence; confirm the human-judgement gates with stakeholders.

> **Determination boundary.** These gates confirm the controls are *configured and behaving as
> designed*. Whether the residual exposure is *acceptable* is a compliance/privacy/legal determination
> (Requirement 2.8) — testing supplies the evidence, stakeholders make the call.

## Gate 1 — Scope, licensing, roles, and connections (Step 0)
- **Test:** Run `AICOPILOT-ReadinessScope.ps1`. Confirm sign-in, auditing on, and the available
  levers (labels, label policies, DLP, auto-labeling) enumerated; confirm the pilot ring and change
  window are agreed.
- **Pass:** All connect; auditing on; levers listed; pilot ring recorded.
- **Fail / rollback:** Missing licensing or role → resolve per Requirements 2.1–2.2 before proceeding
  (read-only; nothing to undo).

## Gate 2 — Oversharing baseline captured (Steps 1–2)
- **Test:** `Oversharing – Estate – Discovery` and `Unlabeled Sensitive – Estate – Assess` are written
  and list in-scope sites with their oversharing signal and label-coverage picture; where SAM is
  licensed, the SharePoint DAG reports reconcile with the export.
- **Pass:** Both exports present; top "broad + sensitive" targets can be named as the before-state.
- **Fail / rollback:** Empty/partial export → check Graph permissions and in-scope site list, re-run
  (read-only).

## Gate 3 — Labeling piloted safely (Step 4)
- **Test:** The pilot label policy `Default Labeling – Users – Pilot` is published to the ring only; the
  auto-labeling policy `Auto-Label Sensitive – Pilot – Simulation` exists in **simulation** and has
  labeled **nothing**. Review the simulation results for false positives (content that would be
  mislabeled).
- **Pass:** Default labeling applies for the pilot ring; simulation shows a sensible would-label set with
  an acceptable false-positive rate; no auto-label has been applied.
- **Fail / rollback:** High false positives → tighten the auto-labeling conditions and re-simulate;
  unpublish the label policy / delete the simulation policy to revert (no content changed).

## Gate 4 — DLP for Copilot behaves as designed (Step 5)
- **Test:** The DLP policy `DLP for Copilot – Pilot – Test` exists in **test/disabled** on the
  **Microsoft 365 Copilot** location, conditioned on the agreed labels. Review the **test** matches:
  content that *would* be kept out of Copilot. Confirm appropriate content is **not** over-matched.
  *(If the Copilot DLP location is absent in your tenant — verify — this gate is met instead by
  confirming label encryption/usage rights keep the content out of Copilot, plus Gate 5 access
  reduction.)*
- **Pass:** Test policy present on the Copilot location; matches align with the "keep out of Copilot"
  intent; no excessive over-match on appropriate content.
- **Fail / rollback:** Over/under-matching → adjust the label conditions and re-test; delete the test
  policy to revert (nothing was blocked).

## Gate 5 — SharePoint access reduced on pilot targets (Step 6)
- **Test:** `Site Access Reduction – Sites – Pilot` was produced; the pilot targets have had broad
  **EEEU**/org-wide grants and over-broad sharing links removed (and/or RAC applied), and any interim
  **RCD/RSS** containment is in place and recorded. Re-run the discovery on the pilot sites.
- **Pass:** The pilot sites' oversharing signal is measurably lower; interim containment (if used) is
  recorded as temporary; **no legitimate access was broken** (confirm with site owners/users).
- **Fail / rollback:** Legitimate access broken → restore the prior sharing on that site; disable RSS
  (`Set-SPOTenantRestrictedSearchMode -Mode Disabled`) / remove RCD to revert containment.

## Gate 6 — Copilot honors the controls (behavioral spot-check, where Copilot is licensed)
- **Test:** With a pilot user, confirm Copilot behavior against protected content: content under a
  "keep out of Copilot" label / DLP should **not** be summarized or cited; a cited response should carry
  the highest-priority sensitivity label of its sources; content on a site now access-restricted should
  no longer be reachable by that user's Copilot. *(Behavioral timing depends on service processing —
  allow for propagation.)*
- **Pass:** Copilot does not surface the protected/restricted content for a user without rights; label
  inheritance on citations is observed.
- **Fail / rollback:** Copilot still surfaces protected content → recheck the label encryption/usage
  rights, DLP location scope, and site access; do not proceed to broad enforce until this holds.

## Gate 7 — Readiness go/no-go evidence complete (Step 8)
- **Test:** `AICOPILOT-ReadinessReport.ps1` compiles `Copilot Readiness – Tenant – GoNoGo` with the
  before/after oversharing, controls applied and their state, and residual risk. Stakeholders (2.8)
  review it.
- **Pass:** The record is complete and internally consistent; named approvers sign the go/no-go against
  the agreed criteria.
- **Fail / rollback:** Missing evidence or unmet criteria → return the relevant policy to
  simulation/test, remediate the gap, and re-report before broad rollout.

## Regression / recurring validation
- Schedule the read-only chain `ReadinessScope → OversharingDiscovery → Validation → ReadinessReport`
  on the `Copilot Readiness Review – Tenant – Recurring` cadence (e.g. monthly). New sites, new broad
  shares, and drift in label coverage are caught before they become Copilot exposure. A rising
  oversharing signal or falling label coverage between runs is the trigger to re-remediate.
