# 6. Troubleshooting

Common failure modes when implementing data lifecycle and records management org-wide in Microsoft
Purview, and how to resolve them. Most retention/records behavior is **eventually consistent** — before
treating something as broken, confirm it is not simply **propagation latency** (see the last item).
Portal paths and feature availability are **cloud-dependent** — verify in your tenant/cloud.

---

### Cannot connect / cmdlets missing
- **Symptom:** `Connect-IPPSSession` fails, or `Get-ComplianceTag` / `New-RetentionCompliancePolicy` /
  `New-FilePlanProperty*` / `New-ComplianceRetentionEventType` are "not recognized."
- **Likely cause:** Not connected to Security & Compliance PowerShell; the **ExchangeOnlineManagement**
  module is missing/old; or the session lacks the **Records management** scope/plan.
- **Resolve:** Install/update `ExchangeOnlineManagement`; run `Connect-IPPSSession` (with `-ConnectionUri`
  for GCC/GCC High/DoD). Run `Resolve-RetentionScope.ps1` to confirm connectivity, cloud, and reachable
  solutions. If records/file-plan/event cmdlets are absent, confirm the **E5/E5 Compliance-class**
  licensing and the **Records Management / Compliance Administrator** role.

### "Insufficient permissions" creating labels, policies, or the file plan
- **Symptom:** Access-denied on `New-ComplianceTag`, `New-RetentionCompliancePolicy`, or
  `New-FilePlanProperty*`.
- **Likely cause:** The admin is not in the required Purview role group.
- **Resolve:** Add the account to **Records Management** or **Compliance Administrator** /
  **Compliance Data Administrator** (Purview portal → Roles & scopes → Permissions). Reviewers need
  **Disposition Management**. Re-check with `Get-RoleGroupMember` / the portal after assignment
  (propagation can take time).

### A published retention label doesn't appear for users
- **Symptom:** Pilot users don't see the label in Outlook/SharePoint/OneDrive.
- **Likely cause:** Label-publish **propagation delay** (can take a day or more); the label policy's
  locations don't include the user; or the client hasn't refreshed.
- **Resolve:** Confirm the label policy (`Label Policy – User-Publish – Pilot`) targets the pilot
  user/site; allow up to a few days; have the user sign out/in. Verify with `Get-RetentionComplianceRule`
  that `PublishComplianceTag` names the correct label.

### Auto-apply isn't labeling matching content
- **Symptom:** Content that should match an auto-apply condition stays unlabeled.
- **Likely cause:** Auto-apply runs on a service timer and can take **7+ days** for existing content; the
  `ContentMatchQuery` / sensitive-info-type condition doesn't actually match; or the location isn't in
  scope; or the plan doesn't include auto-apply.
- **Resolve:** Confirm the condition against real content (test the KQL query), confirm the location is in
  the policy, confirm licensing, and **wait for the timer** before judging. Auto-apply of a records label
  is still subject to the same latency.

### A record label isn't locking content
- **Symptom:** After applying a record label, the item can still be edited/deleted.
- **Likely cause:** The label was created without `-IsRecordLabel $true`; propagation hasn't completed; or
  the label applied is a plain retention label, not the record label.
- **Resolve:** Verify with `Get-ComplianceTag` that `IsRecordLabel` is true; confirm the correct label was
  applied; allow for propagation. Remember a **regulatory** record is a stronger, one-way lock — don't
  confuse the two.

### Event-based retention clock never starts
- **Symptom:** Items with an event-based label stay in "retention starts on event" and never begin
  counting.
- **Likely cause:** No **retention event** was raised, the event's **asset ID / keyword** doesn't match
  the content, or the label's `EventType` differs from the event's type.
- **Resolve:** Raise the event with `New-ComplianceRetentionEvent` using the exact asset ID/keyword that
  matches the content and the same event type the label uses. Confirm the label's `RetentionType` is an
  `Event*` type and its `EventType` name matches. Allow for propagation after the event is raised.

### Disposition items never reach reviewers
- **Symptom:** Content expires but nothing appears in the Disposition queue, or reviewers can't see it.
- **Likely cause:** The label has no `ReviewerEmail`; reviewers aren't in **Disposition Management**; or
  retention hasn't actually elapsed yet.
- **Resolve:** Confirm the label's reviewers (`Get-ComplianceTag`), add the reviewer accounts to
  **Disposition Management**, and confirm the retention period has genuinely expired. Disposition is
  actioned in **Records management → Disposition** in the portal — the report script points there rather
  than approving disposals itself.

### Content is retained (or deleted) differently than expected — retention conflict
- **Symptom:** The effective retention/deletion on an item doesn't match a single policy or label you set.
- **Likely cause:** **Retention precedence** across overlapping policies/labels: retention wins over
  deletion; the **longest** retention wins; **explicit** (label) beats **implicit** (policy); the
  **shortest** deletion wins.
- **Resolve:** Enumerate every policy/label touching the content (`Assess-RetentionRecordsPosture.ps1`),
  reason through precedence, and **redesign** the overlapping artifacts to produce the intended effective
  outcome — do not try to force a result against the precedence rules.

### Government-cloud portal path or feature differs / is missing
- **Symptom:** A portal path from the guide 404s, an endpoint fails, or a feature isn't present in
  GCC/GCC High/DoD.
- **Likely cause:** Sovereign-cloud differences — different URLs (`*.office365.us`), different
  `Connect-IPPSSession -ConnectionUri`, and some features lag or are unavailable.
- **Resolve:** Use the correct sovereign endpoint and portal URL for your cloud, and **verify feature
  availability in your tenant** before relying on it. Treat any Commercial-vs-Government difference as a
  tenant-verify item, not an error.

### It "isn't working" — but it's actually propagation latency
- **Symptom:** A just-made change (policy enable, label publish, auto-apply, event, disposition) hasn't
  taken effect.
- **Likely cause:** Normal **eventual consistency** — application, label propagation, auto-apply, event
  processing, and disposition run on service timers (hours to several days; some policy application up to
  7 days).
- **Resolve:** Wait the expected window before re-testing; don't stack "fixes" on top of a change that
  simply hasn't propagated. Re-run `Get-RetentionDispositionReport.ps1` after the window to confirm state.
