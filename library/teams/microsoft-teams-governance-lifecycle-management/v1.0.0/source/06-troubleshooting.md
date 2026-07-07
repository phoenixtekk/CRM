# Troubleshooting

Common failure modes and resolutions. Symptoms map to the controls in the implementation and the five
scripts. For plan/cloud-dependent behavior, **verify in your tenant** rather than assuming.

---

## Creation control

**Users can still create teams after applying creation control.**
- **Directory changes have not propagated.** `Group.Unified` changes can take time to reach all users;
  wait and re-test. Confirm the write with `Get-MgBetaDirectorySetting`.
- **`EnableGroupCreation` still `true`.** Re-run `Set-TeamsCreationNamingPolicy.ps1` with `-Commit` and
  confirm the re-read shows `false`. A dry-run (missing `-Commit`) never writes.
- **Wrong or empty `GroupCreationAllowedGroupId`.** Confirm it holds the creators group **GUID**, not the
  name. Run `Test-TeamsGovernanceReadiness.ps1 -CreatorsGroupName "…"` to check the binding.

**Approved creators are blocked.**
- **Membership not yet replicated** in the creators security group — allow time and re-test.
- **Nested groups aren't honored** — `GroupCreationAllowedGroupId` uses direct membership of one security
  group; add users directly (or the intended nested group's members).

**`Get-MgBetaDirectorySetting` errors or returns nothing.**
- **Beta module missing** — `Install-Module Microsoft.Graph.Beta`.
- **Insufficient scope** — reconnect with `Connect-MgGraph -Scopes "Directory.ReadWrite.All"`.
- **Setting not yet created** — the tenant may have no `Group.Unified` instance; the config script creates
  it from the template on first `-Commit`.

## Naming policy

**Blocked words / prefix not enforced.**
- **Entra ID P1 not licensed** for the creating user — the naming policy is P1-gated; assign P1 (verify).
- **Policy not written** — confirm `PrefixSuffixNamingRequirement` / `CustomBlockedWordsList` are set via
  `Get-MgBetaDirectorySetting`.
- **Admin bypass** — global/groups admins can bypass naming policy by design; test with a standard creator.

**Names get an unexpected prefix/suffix.**
- That is the policy working. Review the `PrefixSuffixNamingRequirement` string (e.g. `GRP-[GroupName]`)
  and adjust with the config script if the pattern is wrong.

## Classification (container labels)

**No label option when creating a team, or labels don't stick.**
- **`EnableMIPLabels` not `true`** — enable it (config script `-EnableLabels -Commit`).
- **Labels not published or wrong scope** — the container labels must exist, be scoped to **Groups &
  sites**, and be **published** to the creator (Requirement 6); confirm with `Get-Label`.
- **Label sync not run** — after enabling label support a directory label sync is required; the exact
  cmdlet is **version-dependent — verify the current sync step in your tenant**.
- **P1 not licensed** — container labels for groups require Entra ID P1.

## Expiration

**No renewal notifications / groups not expiring.**
- **P1 not licensed** for members — expiration requires Entra ID P1 for all group members (verify).
- **Scope is `Selected` but group not enrolled** — enroll the group (`Add-MgGroupToLifecyclePolicy`) or
  switch to `All` for tenant-wide coverage.
- **Notification target wrong** — for groups without an owner, notifications go to
  `alternateNotificationEmails`; ensure it points at a monitored governance mailbox.
- **Auto-renew on activity** — active groups auto-renew and will not expire; this is expected.

**A group was deleted by expiration and users want it back.**
- **Restore from soft-delete** — an expired group is soft-deleted and restorable within the deleted-groups
  window (default ~30 days — **verify**). Restore it, then investigate why it wasn't renewed.

**`New-MgGroupLifecyclePolicy` fails "policy already exists".**
- **Only one lifecycle policy per tenant is allowed.** Update the existing one (`Update-MgGroupLifecyclePolicy`)
  — the config script does this automatically when a policy is present.

## Retention

**No retention policy created despite `-ConfigureRetention -Commit`.**
- **By design:** the script refuses to create retention without an explicit `-RetentionDays` **supplied by
  compliance**. Obtain the duration from the compliance/records owner and pass it.
- **Not connected to Security & Compliance** — run `Connect-IPPSSession` first.
- **Plan/portal differences** — Purview retention coverage and portal URLs differ between Commercial and
  Government clouds (`*.office365.us`); verify the plan covers the Teams locations.

**Expired group's content unexpectedly retained.**
- Expiration and retention are independent — content under `Retention Policy – Teams – Prod` is preserved
  for the compliance duration even after the group is expired. This is correct behavior.

## Ownership

**Ownerless teams keep appearing.**
- **Ownerless groups policy not configured** — set `Ownerless Policy – Teams – Prod` in Org settings so
  members are prompted to become owners.
- **Owners leaving** — schedule `Get-TeamsGovernanceInventory.ps1` monthly to resurface under-owned teams;
  enforce the ≥ 2 owners rule.

## Archival

**`Set-TeamArchivedState` fails or members can still post.**
- **Not connected** — run `Connect-MicrosoftTeams`.
- **Site not read-only** — pass `-SetSpoSiteReadOnlyForMembers $true` when archiving; the lifecycle script
  does this by default.
- **Wrong identifier** — use the team's **GroupId** (GUID), not display name.

## Reporting & validation

**Report counts don't match the admin center.**
- **Timing / caching** — Graph activity and admin-center reports can lag; re-run and compare like-for-like.
- **Scope gaps** — ensure the connection has `Group.Read.All`, `Directory.Read.All`, and
  `GroupMember.Read.All`.

**`Test-TeamsGovernanceReadiness.ps1` exits non-zero.**
- That is the gate working — read the FAIL lines. Resolve each failed control (creation, naming,
  classification, expiration, ownership, stale) before running Stage 6 (Expand).
