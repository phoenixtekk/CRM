# Testing & Validation

Each test states the **procedure** and the **expected pass/fail** signal. Run them after the pilot
configure stage (Stage 3) and again after production expansion (Stage 6). Most map directly to a check in
`Test-TeamsGovernanceReadiness.ps1` (Script 5).

---

## Test 1 — Creation control blocks non-creators

- **Procedure:** As a user who is **not** a member of `Group Creators – Governed – Pilot`, attempt to
  create a team (Teams client → *Join or create a team*) and an M365 Group (e.g. a new Planner/SharePoint
  group). Also run `Get-MgBetaDirectorySetting` and inspect the `Group.Unified` values.
- **Pass:** Creation is blocked/hidden for the non-creator; `EnableGroupCreation = false` and
  `GroupCreationAllowedGroupId` equals the creators group's GUID.
- **Fail:** The non-creator can still create a team, or the settings are unset.

## Test 2 — Creation allowed for approved creators

- **Procedure:** As a member of `Group Creators – Governed – Pilot`, create a team.
- **Pass:** The team is created successfully.
- **Fail:** An approved creator is blocked (check group membership propagation — allow time for replication).

## Test 3 — Naming policy enforced

- **Procedure:** As an approved creator, create a group named to violate the standard — include a blocked
  word (e.g. `Payroll`) and omit the required prefix.
- **Pass:** The blocked word is rejected, and the configured prefix/suffix
  (`PrefixSuffixNamingRequirement`) is auto-applied to a valid name.
- **Fail:** The blocked word is accepted or no prefix/suffix is applied.

## Test 4 — Classification label applies to a team

- **Procedure:** Ensure `EnableMIPLabels = true`. Create/label `Pilot Team – Governance-A – Pilot` with
  `Sensitivity Label – Confidential – Prod`. Check the team/site shows the label.
- **Pass:** The container label is visible on the team and its SharePoint site; label-driven settings
  (guest access/privacy) apply per the label.
- **Fail:** No label option appears, or the label does not stick (confirm the label is published and scoped
  to Groups & sites, and the label sync has run — version-dependent, verify in your tenant).

## Test 5 — Expiration policy active and scoped

- **Procedure:** Run `Get-MgGroupLifecyclePolicy`. For the pilot, confirm `managedGroupTypes = Selected`
  and the pilot group is included; check `groupLifetimeInDays` matches the design.
- **Pass:** A single lifecycle policy exists with the intended lifetime and scope; renewal notifications go
  to `alternateNotificationEmails`.
- **Fail:** No policy, wrong lifetime, or `All` when a scoped pilot was intended.

## Test 6 — Renewal / soft-delete behavior

- **Procedure:** In a controlled test, let a selected group reach expiration (or use a short test lifetime).
  Observe owner renewal notifications; do not renew; confirm soft-delete, then restore.
- **Pass:** Owners are notified; an unrenewed group is soft-deleted and is **restorable** within the
  deleted-groups window (default ~30 days — verify); a renewed group persists.
- **Fail:** No notification, or the group is hard-deleted / not restorable.

## Test 7 — Retention coverage (mechanism only)

- **Procedure:** Run `Get-RetentionCompliancePolicy` / `Get-RetentionComplianceRule`; confirm
  `Retention Policy – Teams – Prod` targets the Teams channel/chat locations and the associated files, with
  the **duration supplied by compliance**.
- **Pass:** The policy exists, is enabled, and covers the intended Teams locations. (The **correctness of
  the duration** is the compliance owner's determination, not this test.)
- **Fail:** No policy, disabled, or missing the Teams locations.

## Test 8 — Ownership standard

- **Procedure:** Run `Get-TeamsGovernanceInventory.ps1` and filter to teams below the minimum-owners rule.
  Confirm the ownerless groups policy `Ownerless Policy – Teams – Prod` is configured in Org settings.
- **Pass:** Pilot teams meet the minimum-owners threshold; the ownerless policy is enabled and prompts
  members.
- **Fail:** Ownerless/under-owned pilot teams remain, or the policy is not configured.

## Test 9 — Archival read-only

- **Procedure:** Archive a stale pilot team via the lifecycle script (`-Commit`). Confirm with
  `Get-Team | Where-Object Archived` and try to post in a channel as a member.
- **Pass:** The team shows `Archived = true`; members cannot post (SharePoint site read-only when
  `-SetSpoSiteReadOnlyForMembers` was used). Un-archive restores write access.
- **Fail:** The team is not archived or members can still post.

## Test 10 — Governance report accuracy

- **Procedure:** Run `Get-TeamsGovernanceReport.ps1`. Cross-check a sample of its counts (creation status,
  naming, classification coverage, ownerless/stale/duplicate, expiration posture) against the admin
  center / raw cmdlet output.
- **Pass:** Report figures reconcile with the source data; the report renders (CSV/HTML) without error.
- **Fail:** Counts diverge from source, or the report errors (check connection scopes and permissions).

---

### Overall pass/fail gate

The solution is validated when **Tests 1–6, 8, and 9 PASS on the pilot**, **Test 7** confirms the
retention **mechanism** is in place (duration owned by compliance), and **Test 10** reconciles. Only then
proceed to Stage 6 (Expand). Re-run Tests 1, 3, 5, and 10 after production expansion.
