# 5. Testing & Validation

Ten procedures, each with an explicit **pass/fail**. Run them at the **Pilot** and **Expand** gates. Most
records behavior is **eventually consistent** — allow for service propagation (hours to a few days; up to
7 days for auto-apply of existing content) before declaring a fail. Use the provided scripts where noted;
**never** apply a regulatory-record label to any item you are not prepared to keep for its full period,
and never approve a real disposition as a test.

---

### T1 — Toolchain & scope health
- **Do:** Run `Resolve-RecordsScope.ps1`.
- **Pass:** `Connect-IPPSSession` (and Graph where used) succeed; the correct cloud is reported; Records
  management (file-plan + records cmdlets) is reachable; the pilot scope resolves.
- **Fail:** any connection fails, the wrong cloud/endpoint is reported, records/file-plan cmdlets are
  absent (plan/role), or the scope does not resolve.

### T2 — Baseline inventory captured (read-only)
- **Do:** Run `Assess-RecordsFilePlanPosture.ps1`.
- **Pass:** `Records Posture – Tenant – Discovery` lists existing labels with record/regulatory flags,
  action/duration, and the existing file-plan descriptors; labels are correctly flagged as mapped vs
  unmapped; reusable descriptors are identified.
- **Fail:** the inventory is incomplete, mis-flags record/regulatory status, or the script wrote any
  change (it must be read-only).

### T3 — File-plan descriptors created as designed
- **Do:** Run the `Get-FilePlanPropertyAuthority` / `-Category` / `-SubCategory` / `-Citation` /
  `-Department` / `-ReferenceId` cmdlets (or `Get-RecordsFilePlanReport.ps1`) for each designed descriptor.
- **Pass:** every designed descriptor exists with the correct name (and, for citations, URL/jurisdiction),
  and reused descriptors were not duplicated.
- **Fail:** a designed descriptor is missing, misnamed, or duplicated.

### T4 — Record labels created and mapped to the file plan
- **Do:** `Get-ComplianceTag` for each designed record label.
- **Pass:** each record label exists with `IsRecordLabel` true, the correct action/duration/trigger, and
  its **file-plan descriptors attached** (authority/category/department/citation/reference ID as
  designed) — matching the Stage 2 design.
- **Fail:** any record label is missing, is not flagged as a record, has the wrong action/duration, or is
  **unmapped** (no file-plan descriptors).

### T5 — Regulatory-record labels exist only where signed off
- **Do:** `Get-ComplianceTag` and filter for `IsRegulatory`/`Regulatory` true.
- **Pass:** a regulatory-record label exists **only** for categories records/legal signed off, each is
  mapped to the file plan, and each has a recorded sign-off reference; no regulatory label exists for a
  non-designated category.
- **Fail:** a regulatory label exists without sign-off, a designated regulatory category is a plain record
  label instead, or a regulatory label is unmapped.

### T6 — Record declaration locks content
- **Do:** As a pilot user, apply a **record** label to a disposable pilot test item; attempt to
  edit/delete/move it.
- **Pass:** the item is declared an in-place record and is **locked** against edit/delete/move per its
  rules, with a declare entry in the audit trail. Un-declaration by a records manager restores edit/delete
  (non-regulatory).
- **Fail:** the item remains editable/deletable, or no record was declared.

### T7 — Regulatory lock is irreversible (disposable test item only)
- **Do:** *Only if a regulatory category is in pilot scope and signed off:* apply the regulatory label to
  a **single disposable test item you will keep for its full period**; attempt to remove/change the label
  and un-declare it.
- **Pass:** the regulatory label cannot be removed, changed, un-declared, or shortened by any role — the
  lock is confirmed one-way.
- **Fail:** the regulatory label can be removed/changed/un-declared. *(Never run this on content you are
  not prepared to keep permanently.)*

### T8 — Publish / auto-apply reaches the pilot only
- **Do:** As a pilot user, confirm published record labels are selectable (Outlook/SharePoint/OneDrive);
  create content matching an auto-apply condition and wait for propagation.
- **Pass:** published record labels appear for **pilot users only**; auto-apply applies and **locks** the
  designed record label on matching pilot content; no content outside the pilot scope is affected.
- **Fail:** labels do not appear, apply to the wrong scope, or the wrong label is auto-applied.

### T9 — Every declared record maps to an authority/citation (defensibility)
- **Do:** Run `Get-RecordsFilePlanReport.ps1` and inspect the file-plan mapping columns.
- **Pass:** every in-scope record/regulatory label reports a **retention authority** and **citation** (and
  category/department/reference ID as designed) — the inventory is fully mapped and traceable to the
  mandate.
- **Fail:** any in-scope record label is unmapped (no authority/citation), i.e. locked without a
  documented reason.

### T10 — Records & file-plan report reflects reality
- **Do:** Run `Get-RecordsFilePlanReport.ps1` to produce `Records & File Plan – Tenant – Report`.
- **Pass:** the report shows record/regulatory label counts, file-plan mapping completeness, label-policy
  locations/enabled state, and disposition-reviewer pointers consistent with what was configured and
  observed in T3–T8.
- **Fail:** the report disagrees with observed state, or omits configured labels/descriptors.

---

**Overall gate.** The pilot passes only when T1–T10 pass on the pilot scope with no effect outside it.
Expansion passes only when T3–T10 pass at production scope with every record label mapped to the file
plan and no unexpected retention conflicts. Any fail on an **irreversible** artifact (a regulatory record,
a completed disposition) halts the rollout pending records/legal review.
