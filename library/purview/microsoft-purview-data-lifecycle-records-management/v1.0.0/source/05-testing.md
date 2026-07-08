# 5. Testing & Validation

Ten procedures, each with an explicit **pass/fail**. Run them at the **Pilot** and **Expand** gates. Most
retention/records behavior is **eventually consistent** — allow for service propagation (hours to a few
days) before declaring a fail. Use the provided scripts where noted; never approve a real disposition or
apply a regulatory-record label to production content as a test.

---

### T1 — Toolchain & scope health
- **Do:** Run `Resolve-RetentionScope.ps1`.
- **Pass:** `Connect-IPPSSession` (and Graph where used) succeed; the correct cloud is reported; Data
  lifecycle management and Records management are reachable; the pilot scope resolves.
- **Fail:** any connection fails, the wrong cloud/endpoint is reported, or the scope does not resolve.

### T2 — Baseline inventory captured (read-only)
- **Do:** Run `Assess-RetentionRecordsPosture.ps1`.
- **Pass:** `Retention Posture – Tenant – Discovery` lists existing labels (with record/regulatory flags),
  policies + rules with locations/enabled state, event types, and file-plan descriptors; overlaps with any
  existing retention are identified.
- **Fail:** the inventory is incomplete, or the script wrote any change (it must be read-only).

### T3 — Retention labels created as designed
- **Do:** `Get-ComplianceTag` for each designed label.
- **Pass:** each label exists with the correct action, duration, retention type/trigger, record/regulatory
  flag, file-plan descriptors, and (where reviewed) reviewer emails — matching the Stage 2 design.
- **Fail:** any label is missing or its action/duration/trigger/record status differs from the design.

### T4 — Retention policy staged and pilot-scoped
- **Do:** `Get-RetentionCompliancePolicy` and `Get-RetentionComplianceRule` for `Retention Policy –
  Tenant-Baseline – Pilot`.
- **Pass:** the policy exists, its rule has the designed action/duration, and it is scoped to the **pilot
  locations** (or a pilot adaptive scope) — and was **disabled** until the pilot gate.
- **Fail:** the policy is enabled tenant-wide before validation, mis-scoped, or the rule differs from design.

### T5 — Label publish / auto-apply reaches the pilot
- **Do:** As a pilot user, confirm published labels are selectable (Outlook/SharePoint/OneDrive); create
  content matching an auto-apply condition and wait for propagation.
- **Pass:** published labels appear for pilot users only; auto-apply applies the designed label to matching
  pilot content; no content outside the pilot scope is affected.
- **Fail:** labels do not appear, apply to the wrong scope, or the wrong label is auto-applied.

### T6 — Records declaration locks content
- **Do:** Apply a record label to a disposable pilot test item; attempt to edit/delete/move it.
- **Pass:** the item is declared an in-place record and is locked against edit/delete/move per its rules,
  with a declare entry in the audit trail.
- **Fail:** the item remains editable/deletable, or no record was declared. *(Do not test regulatory
  records on any item you are not prepared to keep permanently.)*

### T7 — Event-based retention triggers
- **Do:** For an event-based label, raise a **test** retention event on a disposable asset
  (`New-ComplianceRetentionEvent … -AssetId TEST-ASSET-001`).
- **Pass:** the retention clock starts on the matching content when the event is raised (visible after
  propagation); before the event the item shows "retention starts on event".
- **Fail:** the clock never starts, or starts on the wrong content / at the wrong time.

### T8 — Disposition routes to review
- **Do:** For a category configured with reviewers, confirm the reviewer accounts are in **Disposition
  Management** and can see the Purview **Disposition** area; drive a short-duration disposable test label
  to expiry (or inspect the configuration).
- **Pass:** at end of retention, the item enters the Disposition queue and a named reviewer can approve
  deletion / extend / relabel; the decision is evidenced. Reviewers see only what their role allows.
- **Fail:** the item auto-deletes when a review was required, reviewers cannot see the queue, or no
  disposition record is kept.

### T9 — Retention precedence produces the intended effective outcome
- **Do:** On a pilot item touched by more than one policy/label, reason through Microsoft's precedence
  (retention > deletion; longest retention wins; explicit > implicit; shortest deletion wins) and confirm
  the observed outcome.
- **Pass:** the effective retention/deletion matches the intended design after precedence is applied.
- **Fail:** the effective outcome differs from intent (redesign the overlapping artifacts — do not force it).

### T10 — Compliance report reflects reality
- **Do:** Run `Get-RetentionDispositionReport.ps1` to produce `Lifecycle Compliance – Tenant – Report`.
- **Pass:** the report shows label coverage, policy locations/enabled state, records-configured counts, and
  pending-disposition pointers consistent with what was configured and observed in T3–T8.
- **Fail:** the report disagrees with observed state, or omits configured artifacts.

---

**Overall gate.** The pilot passes only when T1–T10 pass on the pilot scope with no effect outside it.
Expansion passes only when T3–T10 pass at production scope with expected coverage and no unexpected
retention conflicts. Any fail on an **irreversible** artifact (regulatory record, disposition) halts the
rollout pending records/legal review.
