# 5. Testing & Validation

Nine procedures, each with an explicit **pass/fail**. Run them at the **Pilot** and **Expand** gates.
Event-based retention is **eventually consistent** — allow for service propagation (hours to a few days)
after applying a label, stamping an asset ID, or raising an event before declaring a fail. Raise events only
on **disposable test assets**; never raise a real event that starts a delete clock as a test, and never apply
a regulatory-record label to content you are not prepared to keep permanently.

---

### T1 — Toolchain & scope health
- **Do:** Run `Resolve-EventRetentionScope.ps1`.
- **Pass:** `Connect-IPPSSession` (and Graph where used) succeed; the correct cloud is reported; the
  event-based retention cmdlets are reachable; `Scope – EventRetention-Pilot – Static` resolves.
- **Fail:** any connection fails, the wrong cloud/endpoint is reported, the event cmdlets are absent
  (plan/role), or the scope does not resolve.

### T2 — Baseline inventory captured (read-only)
- **Do:** Run `Get-EventRetentionPosture.ps1`.
- **Pass:** `Event Retention Posture – Tenant – Discovery` lists existing event types, existing event-based
  labels (with their `EventType` and record/regulatory flags), their label policies, and any raised events;
  existing artifacts are identified so none are duplicated.
- **Fail:** the inventory is incomplete, or the script wrote any change (it must be read-only).

### T3 — Event types created as designed
- **Do:** `Get-ComplianceRetentionEventType` for each designed event type.
- **Pass:** each event type exists with the designed name (`Event Type – Employee-Termination`, etc.), and no
  duplicate of an existing event type was created.
- **Fail:** an event type is missing, misnamed, or duplicates one already present.

### T4 — Event-based labels bound to the correct event type
- **Do:** `Get-ComplianceTag` for each designed label; inspect its retention type and event type.
- **Pass:** each label exists with an **event** retention trigger (`RetentionType` is an `Event*` type),
  bound to the **correct** `EventType`, with the designed post-event action and duration, and the correct
  record/regulatory flag — matching the Stage 2 design.
- **Fail:** any label is missing, uses a date-based trigger instead of an event, is bound to the wrong event
  type, or its action/duration/record status differs from design.

### T5 — Label publish / auto-apply reaches the pilot only
- **Do:** As a pilot user, confirm the published event-based labels are selectable (SharePoint/OneDrive);
  create/identify content matching an auto-apply condition and wait for propagation.
- **Pass:** published labels appear for pilot users only; auto-apply applies the designed label to matching
  pilot content; no content outside the pilot scope is affected.
- **Fail:** labels do not appear, apply to the wrong scope, or the wrong label is auto-applied.

### T6 — Labeled content is in the pending ("starts on event") state
- **Do:** On a labeled pilot item, inspect its retention state before any event is raised.
- **Pass:** the item shows retention **pending** — *"retention starts on event"* — with the label and
  duration set but no clock running.
- **Fail:** the clock has already started (mis-configured as date-based), or the item shows no event-based
  retention at all.

### T7 — Asset-ID / keyword matching data is present on content
- **Do:** For asset-ID categories, confirm the **`Compliance Asset Id`** property is stamped on the in-scope
  pilot documents with the correct identifier; for keyword categories, confirm the query matches the in-scope
  content and excludes out-of-scope content.
- **Pass:** the matching data exists on exactly the in-scope content — asset IDs stamped as designed, or the
  keyword query verified to match in-scope and not out-of-scope.
- **Fail:** the `Compliance Asset Id` is missing/blank on in-scope content, or the keyword query matches the
  wrong (or no) content.

### T8 — Raising a test event starts the clock on exactly the matching content
- **Do:** Stamp a disposable test asset (`TEST-ASSET-001`), apply the event-based label, and raise a **test**
  retention event on that asset only (`Set-EventTypesAndLabels.ps1 -RaiseEvent -Commit`, or portal). Wait for
  propagation.
- **Pass:** after propagation, the retention clock starts from the event date on the matching disposable
  asset **and only that asset**; un-matched labeled content stays pending; the event is visible via
  `Get-ComplianceRetentionEvent`.
- **Fail:** the clock never starts, starts on the wrong/too-broad content, or starts at the wrong date.

### T9 — Reporting reflects reality
- **Do:** Run `Test-EventRetentionConfig.ps1` (read-only validation) and `Get-EventRetentionReport.ps1`.
- **Pass:** validation confirms event types exist, labels use the correct event triggers/linkage, and label
  policies are pilot-scoped; the report’s counts of event types, event-based labels, and raised events, and
  its gap flags (labels without an event type, event types with no label, raised-but-unmatched events) are
  consistent with T3–T8.
- **Fail:** validation or the report disagrees with the observed state, or omits configured artifacts.

---

**Overall gate.** The pilot passes only when T1–T9 pass on the pilot scope with the test event starting the
clock on exactly the matching disposable asset and no effect outside the pilot. Expansion passes only when
T3–T9 pass at production scope, the asset-ID / keyword matching data is present on production content, and
the real raise process is tested against the system of record. Any fail on an **irreversible** action
(regulatory record, or a real event that has started/elapsed a delete clock) halts the rollout pending
records/legal review.
