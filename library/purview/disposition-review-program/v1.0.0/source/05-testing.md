# 5. Testing & Validation

Ten procedures, each with an explicit **pass/fail**. Run them at the **Pilot** and **Expand** gates.
Disposition behaviour is **eventually consistent** — allow for service propagation (hours to days) before
declaring a fail, and use **short-duration disposable test labels** so a full cycle completes in the pilot
window. **Never approve a real production disposition as a test** — exercise the delete path only on
disposable test content you are prepared to lose.

---

### T1 — Toolchain, cloud & permission health
- **Do:** Run `Resolve-DispositionScope.ps1`.
- **Pass:** `Connect-IPPSSession` (and Graph where used) succeed; the correct cloud is reported;
  `Get-ComplianceTag` and `Get-RoleGroupMember -Identity "Disposition Management"` return; the pilot scope
  resolves.
- **Fail:** any connection fails, the wrong cloud/endpoint is reported, the Disposition Management role
  group is unreachable, or the scope does not resolve.

### T2 — Baseline posture captured (read-only)
- **Do:** Run `Assess-DispositionPosture.ps1`.
- **Pass:** `Disposition Posture – Tenant – Discovery` lists retention labels with action, and for
  retain-then-delete labels whether review is enabled (single/multi-stage), the stages and reviewers, and
  Disposition Management membership; **auto-delete-with-no-review** labels are flagged; the script made no
  change (read-only).
- **Fail:** the inventory is incomplete, the auto-delete gap is not surfaced, or the script wrote anything.

### T3 — Disposition labels configured as designed
- **Do:** `Get-ComplianceTag` for each designed disposition label.
- **Pass:** each label exists with `RetentionAction = KeepAndDelete`, the correct duration/trigger, and the
  designed **review configuration** — single-stage `ReviewerEmail`, or multi-stage stages in the **correct
  order** with the correct reviewers — matching the Stage 2 design.
- **Fail:** any label is missing, auto-deletes when review was designed, or its stage count/order/reviewers
  differ from the design.

### T4 — Reviewers can actually act (Disposition Management)
- **Do:** `Get-RoleGroupMember -Identity "Disposition Management"`; cross-check against every stage's
  reviewer group; as a reviewer, open Microsoft Purview → **Records management → Disposition**.
- **Pass:** every stage reviewer is in **Disposition Management** and can see the Disposition area; reviewers
  see **only** the labels for which they are a reviewer; no non-reviewer is over-granted.
- **Fail:** a reviewer is missing from Disposition Management (cannot see the queue), a reviewer sees items
  outside their scope, or accounts are over-granted.

### T5 — Label publish / auto-apply reaches the pilot only
- **Do:** As a pilot user, confirm the disposition label is selectable (Outlook/SharePoint/OneDrive), or
  create content matching an auto-apply condition and wait for propagation.
- **Pass:** the disposition label appears for / applies to pilot content only; no content outside
  `Scope – Disposition-Pilot – Static` is affected.
- **Fail:** the label does not appear, applies to the wrong scope, or the wrong label is applied.

### T6 — Expiring content routes to review (does NOT auto-delete)
- **Do:** Let a short-duration disposable test item reach expiry; observe the **Disposition** queue.
- **Pass:** at end of retention the item **enters the Disposition queue** for review and is **not** deleted;
  reviewers receive notification email.
- **Fail:** the item auto-deletes when a review was required, never appears in the queue, or no notification
  is sent.

### T7 — Single-stage disposition completes and disposes
- **Do:** For a single-stage test label, have the reviewer **approve permanent deletion** in the portal.
- **Pass:** the item is permanently disposed after the single approval; a disposition record / proof of
  disposal is produced.
- **Fail:** approval does not dispose the item, or no proof is recorded.

### T8 — Multi-stage advances in order and disposes only after the final stage
- **Do:** For a multi-stage test label, approve **Stage 1** and observe advancement; on separate test items,
  exercise **extend retention** and **relabel/apply different label**.
- **Pass:** approval advances the item to the **next** stage; disposal occurs **only after the final stage
  approves**; **extend** and **relabel** stop disposal and behave as designed; a non-final approval never
  deletes.
- **Fail:** the item disposes before the final stage, stages advance out of order, or extend/relabel do not
  stop disposal. *(If your tenant does not offer multi-stage, record it as plan-limited and validate
  single-stage only.)*

### T9 — Proof of disposal & audit evidence exist (defensibility)
- **Do:** After a (test) disposition completes, capture the **disposition record / proof of disposal** in
  the portal Disposition export and the corresponding **audit** events (`Search-UnifiedAuditLog`).
- **Pass:** an exportable proof-of-disposal exists for the disposed item (what, who approved each stage,
  when) and matching audit events are present — the defensible-disposal evidence trail.
- **Fail:** no proof of disposal is retained, the reviewer/stage attribution is missing, or audit events are
  absent.

### T10 — Evidence/compliance report reflects reality
- **Do:** Run `Get-DispositionEvidenceReport.ps1` to produce `Disposition Evidence – Tenant – Report`.
- **Pass:** the report shows, per label, the review configuration (single/multi-stage, stages, reviewers),
  Disposition Management coverage, and flags gaps (auto-delete-no-review labels, reviewers-not-in-DM,
  empty stages), and points to the portal Disposition export + audit log for the item-level proof —
  consistent with T3–T9.
- **Fail:** the report disagrees with observed state, omits configured labels, or fails to flag a known gap.

---

**Overall gate.** The pilot passes only when T1–T10 pass on the pilot scope with no effect outside it —
including a **full review cycle** (T6–T9) proven on disposable test content with its evidence trail.
Expansion passes only when T3–T10 pass at production scope with expected coverage and **no review category
silently auto-deleting**. Any fail on the **irreversible** path (a completed disposition without the
designed stages/approvals, or missing proof of disposal) halts the rollout pending records/legal review.
