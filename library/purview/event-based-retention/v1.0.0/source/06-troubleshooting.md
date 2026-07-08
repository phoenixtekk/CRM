# 6. Troubleshooting

Common failure modes when implementing event-based retention in Microsoft Purview, and how to resolve them.
Most retention behavior is **eventually consistent** — before treating something as broken, confirm it is
not simply **propagation latency** (see the last item). Portal paths, the `Compliance Asset Id` property,
and cmdlet parameters are **plan- and cloud-dependent** — verify in your tenant/cloud.

---

### Cannot connect / event or label cmdlets missing
- **Symptom:** `Connect-IPPSSession` fails, or `Get-ComplianceRetentionEventType` / `New-ComplianceTag` /
  `New-ComplianceRetentionEvent` are "not recognized."
- **Likely cause:** Not connected to Security & Compliance PowerShell; the **ExchangeOnlineManagement**
  module is missing/old; or the session lacks the licensing/scope for event-based retention.
- **Resolve:** Install/update `ExchangeOnlineManagement`; run `Connect-IPPSSession` (with `-ConnectionUri`
  for GCC/GCC High/DoD). Run `Resolve-EventRetentionScope.ps1` to confirm connectivity, cloud, and reachable
  cmdlets. If the event cmdlets are absent, confirm the **E5 / E5 Compliance-class** licensing and the
  **Records Management / Compliance Administrator** role.

### "Insufficient permissions" creating event types, labels, or raising events
- **Symptom:** Access-denied on `New-ComplianceRetentionEventType`, `New-ComplianceTag`, or
  `New-ComplianceRetentionEvent`.
- **Likely cause:** The admin is not in the required Purview role group, or is not among the designated
  event-raising operators.
- **Resolve:** Add the account to **Records Management** or **Compliance Administrator** /
  **Compliance Data Administrator** (Purview portal → Roles & scopes → Permissions). Confirm the account is
  one of the authorized event-raisers (2.5). Re-check after assignment (role propagation can take time).

### "Start retention based on an event" option / event-based label type is missing
- **Symptom:** When creating a label you cannot choose an event-based trigger, or `New-ComplianceTag` rejects
  the event retention type.
- **Likely cause:** The tenant is not licensed for event-based retention, or the exact `-RetentionType`
  value / parameter differs in your module version.
- **Resolve:** Confirm the **E5 / E5 Compliance-class** entitlement. Verify the correct event retention type
  value for your tenant/module version (the design uses an `Event*` type) before scripting, and check the
  option in the portal first.

### An event-based label doesn't appear for users (publish)
- **Symptom:** Pilot users don't see the label in SharePoint/OneDrive.
- **Likely cause:** Label-publish **propagation delay** (can take a day or more); the label policy's
  locations don't include the user/site; or the client hasn't refreshed.
- **Resolve:** Confirm the label policy (`Label Policy – EventBased-Publish – Pilot`) targets the pilot
  site/user; allow up to a few days; refresh the client. Verify with `Get-RetentionComplianceRule` that
  `PublishComplianceTag` names the correct label.

### Auto-apply isn't labeling matching content
- **Symptom:** Content that should match an auto-apply condition stays unlabeled.
- **Likely cause:** Auto-apply runs on a service timer and can take **7+ days** for existing content; the
  `ContentMatchQuery` / condition doesn't actually match; the location isn't in scope; or the plan doesn't
  include auto-apply.
- **Resolve:** Test the query against real content, confirm the location is in the policy, confirm licensing,
  and **wait for the timer** before judging.

### Labeled content shows "pending" and the clock never starts
- **Symptom:** Items with an event-based label stay in *"retention starts on event"* forever and never begin
  counting.
- **Likely cause (most common):** **No retention event has been raised** for that event type — the label is
  working exactly as designed, but the trigger is missing. Or an event was raised but its **asset ID /
  keyword didn't match**, or the label's `EventType` differs from the event's type.
- **Resolve:** Raise the event with `Set-EventTypesAndLabels.ps1 -RaiseEvent` (or `New-ComplianceRetentionEvent`)
  using the **exact** asset ID / keyword that matches the content and the **same event type** the label uses.
  Confirm the label's `RetentionType` is an `Event*` type and its `EventType` name matches the event. Then
  allow for propagation. **If no one is raising events at all, fix the raise process (2.3) — that is the real
  defect.**

### A raised event matched nothing (or the wrong content)
- **Symptom:** After raising an event, no clocks start, or clocks start on unexpected items.
- **Likely cause:** The **`Compliance Asset Id`** was never stamped on the target documents (asset-ID
  matching had nothing to match); the asset ID supplied at raise time doesn't equal the one stamped; or a
  **keyword** query is too broad/narrow.
- **Resolve:** Confirm the `Compliance Asset Id` is present and correct on the in-scope content (T7), and
  that the raise supplies the identical value. For keyword categories, validate the query matches in-scope
  and excludes out-of-scope content before re-raising. Remember matching data must exist **before** the event.

### The clock started from the wrong date
- **Symptom:** Retention is counting from a date that isn't when the event actually occurred.
- **Likely cause:** The retention event was raised with the **raise date** rather than the true **event
  date** (`-EventDateTime`).
- **Resolve:** Set `-EventDateTime` to when the event actually happened (e.g. the real termination date),
  especially when raising after the fact. If already raised incorrectly, correct it per records/legal
  direction before the clock elapses.

### An event-based label also declares a record and content is locked unexpectedly
- **Symptom:** After an event-based **record** label applies, owners lose edit/delete.
- **Likely cause:** The label was created with the record setting (by design) — a record locks content;
  a **regulatory** record is a stronger, one-way lock.
- **Resolve:** Confirm with `Get-ComplianceTag` whether `IsRecordLabel` / `Regulatory` is set; communicate
  the lock before applying record labels to live content. Records declaration/un-declaration mechanics are
  owned by the data lifecycle & records product — defer to it.

### Retention differs from expectation — a retention conflict
- **Symptom:** The effective retention/deletion on an item doesn't match the event-based label you set.
- **Likely cause:** **Retention precedence** across overlapping policies/labels: retention wins over
  deletion; the **longest** retention wins; **explicit** (label) beats **implicit** (policy); the **shortest**
  deletion wins.
- **Resolve:** Enumerate every policy/label touching the content (`Get-EventRetentionPosture.ps1` plus the
  broader program's assessment), reason through precedence, and **redesign** the overlap to produce the
  intended effective outcome — do not force a result against the precedence rules.

### Government-cloud portal path, property, or parameter differs / is missing
- **Symptom:** A portal path 404s, the `Compliance Asset Id` behaves differently, an endpoint fails, or a
  feature isn't present in GCC/GCC High/DoD.
- **Likely cause:** Sovereign-cloud differences — different URLs (`*.office365.us`), different
  `Connect-IPPSSession -ConnectionUri`, and some features/parameters lag or differ.
- **Resolve:** Use the correct sovereign endpoint and portal URL for your cloud, and **verify feature and
  property availability in your tenant** before relying on it. Treat any Commercial-vs-Government difference
  as a tenant-verify item, not an error.

### It "isn't working" — but it's actually propagation latency
- **Symptom:** A just-made change (label publish, asset-ID stamp, a raised event) hasn't taken effect.
- **Likely cause:** Normal **eventual consistency** — label propagation, asset-ID indexing, and event
  processing run on service timers (hours to several days).
- **Resolve:** Wait the expected window before re-testing; don't stack "fixes" on top of a change that
  simply hasn't propagated. Re-run `Get-EventRetentionReport.ps1` after the window to confirm state.
