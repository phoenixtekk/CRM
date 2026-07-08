# 6. Troubleshooting

Common failure modes when delivering regulatory & immutable records and a mapped file plan in Microsoft
Purview, and how to resolve them. Most records behavior is **eventually consistent** — before treating
something as broken, confirm it is not simply **propagation latency** (see the last item). Portal paths
and feature availability are **cloud-dependent** — verify in your tenant/cloud.

---

### Cannot connect / records or file-plan cmdlets missing
- **Symptom:** `Connect-IPPSSession` fails, or `Get-ComplianceTag` / `New-ComplianceTag` /
  `New-FilePlanPropertyAuthority` / the other `New-FilePlanProperty*` cmdlets are "not recognized."
- **Likely cause:** Not connected to Security & Compliance PowerShell; the **ExchangeOnlineManagement**
  module is missing/old; or the session lacks the **Records management** plan/role.
- **Resolve:** Install/update `ExchangeOnlineManagement`; run `Connect-IPPSSession` (with `-ConnectionUri`
  for GCC/GCC High/DoD). Run `Resolve-RecordsScope.ps1` to confirm connectivity, cloud, and reachable
  cmdlets. If the records/file-plan cmdlets are absent, confirm the **E5 / E5 Compliance-class** licensing
  (2.1) and the **Records Management / Compliance Administrator** role (2.3).

### "Insufficient permissions" creating labels or the file plan
- **Symptom:** Access-denied on `New-ComplianceTag` or `New-FilePlanProperty*`.
- **Likely cause:** The admin is not in the required Purview role group.
- **Resolve:** Add the account to **Records Management** or **Compliance Administrator** /
  **Compliance Data Administrator** (Purview portal → Roles & scopes → Permissions). Reviewers need
  **Disposition Management**. Re-check with `Get-RoleGroupMember` / the portal after assignment
  (role propagation can take time).

### `Set-ImmutableRecordLabels.ps1` REFUSES a label as "UNMAPPED"
- **Symptom:** The config script refuses to create a record label, reporting it is unmapped.
- **Likely cause:** The label's `filePlan` block in the design has no **authority** and/or **citation** —
  by policy this solution will not create an immutable record with no documented reason for the lock.
- **Resolve:** Add the file-plan descriptors (authority, citation, and category/department/reference ID as
  designed) to the label in the design JSON, run `Set-FilePlanDescriptors.ps1 -Commit` to create any
  missing descriptors, then re-run the label script. This is a guardrail, not a bug.

### A record label isn't locking content
- **Symptom:** After applying a record label, the item can still be edited/deleted.
- **Likely cause:** The label was created without `-IsRecordLabel $true` (so it is a plain retention
  label); declaration propagation hasn't completed; or a plain retention label was applied instead of the
  record label.
- **Resolve:** Verify with `Get-ComplianceTag` that `IsRecordLabel` is true on the applied label; confirm
  the **correct** label was applied; allow for propagation. Remember a **regulatory** record is a stronger,
  one-way lock — don't confuse the two rungs.

### Regulatory vs record confusion — a label is more (or less) locked than intended
- **Symptom:** A label can't be un-declared when you expected it to be reversible, or vice versa.
- **Likely cause:** `-Regulatory $true` (one-way, irreversible) was used where a plain `-IsRecordLabel`
  (reversible, un-declarable) was intended, or the reverse.
- **Resolve:** Check `IsRegulatory` / `IsRecordLabel` with `Get-ComplianceTag`. A **regulatory** label
  **cannot be changed or removed** — if one was created in error it cannot be un-declared; retire it from
  publication and create the correct label. This is exactly why the config script gates `-Regulatory`
  behind `-AllowRegulatory -SignOffRef` and why regulatory labels are only ever tested on a disposable
  item.

### A published record label doesn't appear for users
- **Symptom:** Pilot users don't see the record label in Outlook/SharePoint/OneDrive to declare a record.
- **Likely cause:** Label-publish **propagation delay** (can take a day or more); the label policy's
  locations don't include the user; or the client hasn't refreshed.
- **Resolve:** Confirm the label policy (`Label Policy – Records-Publish – Pilot`) targets the pilot
  user/site; allow up to a few days; have the user sign out/in. Verify with `Get-RetentionComplianceRule`
  that `PublishComplianceTag` names the correct label.

### Auto-apply isn't declaring matching content
- **Symptom:** Content that should match an auto-apply condition stays undeclared/unlabeled.
- **Likely cause:** Auto-apply runs on a service timer and can take **7+ days** for existing content; the
  `ContentMatchQuery` / sensitive-info-type condition doesn't actually match; the location isn't in scope;
  or the plan doesn't include auto-apply.
- **Resolve:** Confirm the condition against real content (test the KQL query), confirm the location is in
  the policy, confirm licensing, and **wait for the timer** before judging. Auto-apply of a record label
  is subject to the same latency.

### The report shows an UNMAPPED record label
- **Symptom:** `Get-RecordsFilePlanReport.ps1` flags a record/regulatory label as UNMAPPED (no
  authority/citation).
- **Likely cause:** The label was created (perhaps in the portal, or by bulk import) without file-plan
  descriptors attached — a record locked without a documented reason.
- **Resolve:** Attach the file-plan descriptors: in the portal edit the label's file-plan descriptors, or
  for a **non-regulatory** label re-create it mapped and re-publish. A **regulatory** label cannot be
  edited — if it is unmapped, record the authority/citation out-of-band and factor it into the next
  version, and treat it as a lesson to always map before creating.

### Disposition items never reach reviewers
- **Symptom:** Content expires but nothing appears in the Disposition queue, or reviewers can't see it.
- **Likely cause:** The label has no `ReviewerEmail`; reviewers aren't in **Disposition Management**; or
  retention hasn't actually elapsed yet. (The disposition *operation* is owned by the broader records
  product; this solution wires the role and reports coverage.)
- **Resolve:** Confirm the label's reviewers (`Get-ComplianceTag`), add the reviewer accounts to
  **Disposition Management**, and confirm the retention period has genuinely expired. Disposition is
  actioned in **Records management → Disposition** in the portal — the report points there rather than
  approving disposals itself.

### Government-cloud portal path or feature differs / is missing
- **Symptom:** A portal path from the guide 404s, an endpoint fails, or a records/file-plan feature isn't
  present in GCC/GCC High/DoD.
- **Likely cause:** Sovereign-cloud differences — different URLs (`*.office365.us`), different
  `Connect-IPPSSession -ConnectionUri`, and some features lag or are unavailable.
- **Resolve:** Use the correct sovereign endpoint and portal URL for your cloud, and **verify feature
  availability in your tenant** before relying on it. Treat any Commercial-vs-Government difference as a
  tenant-verify item, not an error.

### It "isn't working" — but it's actually propagation latency
- **Symptom:** A just-made change (label publish, auto-apply, record declaration) hasn't taken effect.
- **Likely cause:** Normal **eventual consistency** — publish, auto-apply, and declaration run on service
  timers (hours to several days; some auto-apply of existing content up to 7 days).
- **Resolve:** Wait the expected window before re-testing; don't stack "fixes" on top of a change that
  simply hasn't propagated. Re-run `Get-RecordsFilePlanReport.ps1` after the window to confirm state.
