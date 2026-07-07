# Implementation

Follow the house model — **Assess → Design → Configure → Pilot → Validate → Expand**. Turning off open
group creation and enabling expiration are **tenant-wide, high-impact** changes, so every Configure step
is done **pilot-first**, with a **`-WhatIf` dry-run** before any commit and a **rollback** noted inline.
Reuse the exact artifact names from the reference design.

> **Naming convention (mandatory).** Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused
> verbatim in testing, troubleshooting, and the scripts — e.g. `Group Creators – Governed – Pilot`,
> `Expiration Policy – M365 Groups – Prod`.

---

## Stage 0 — Connect

```powershell
Connect-MgGraph -Scopes "Directory.ReadWrite.All","Group.ReadWrite.All","GroupMember.ReadWrite.All"
Connect-MicrosoftTeams
Connect-IPPSSession        # Security & Compliance PowerShell (retention, labels)
```
Use a modern-auth/MFA admin sign-in. **No stored credentials.** For Government clouds pass the
environment switches your tenant requires (e.g. `Connect-MgGraph -Environment USGov`) — verify the exact
value in your tenant.

---

## Stage 1 — Assess (read-only)

1. **Inventory every team/M365 Group.** Run `Get-TeamsGovernanceInventory.ps1` (Script 1). It enumerates
   all M365 Groups/teams and flags **ownerless**, **stale** (no recent activity), potential **duplicates**
   (near-identical display names), and **unclassified** teams. Nothing is changed.
2. **Capture the baseline.** Save the inventory CSV as the pre-change baseline; it is your rollback
   reference and the "before" side of the governance report.
3. **Confirm current creation posture.** Note whether `EnableGroupCreation` is currently unset/`true`
   (open creation) — the inventory report surfaces this.

**Gate 1 (Assess):** You have a complete inventory and a written list of ownerless/stale/duplicate teams.

---

## Stage 2 — Design

1. **Creators model.** Confirm the security group `Group Creators – Governed – Pilot` (and later
   `… – Prod`) and its membership.
2. **Naming standard.** Decide the prefix/suffix and blocked words for `Naming Policy – M365 Groups – Prod`
   — e.g. prefix `GRP-[Department]-` , suffix `-[GroupName]`, blocked words like `CEO,Payroll,HR`.
3. **Classification.** Confirm the published container labels `Sensitivity Label – Public/Internal/
   Confidential – Prod` and which data maps to which (compliance owner decides).
4. **Lifecycle.** Decide the expiration lifetime (e.g. 180 or 365 days) for `Expiration Policy – M365
   Groups – Prod`, the retention posture for `Retention Policy – Teams – Prod` (**duration set by
   compliance**), and archival criteria (e.g. stale > 180 days AND owner confirms keep-read-only).
5. **Ownership.** Set the minimum-owners rule (e.g. ≥ 2 owners) and the ownerless remediation approach.

**Gate 2 (Design):** A one-page standard is signed off by governance/security/compliance.

---

## Stage 3 — Configure (pilot scope, `-WhatIf` first)

### 3a. Creation control + naming policy

1. **Dry-run.** `.\Set-TeamsCreationNamingPolicy.ps1 -CreatorsGroupName "Group Creators – Governed – Pilot"
   -Prefix "GRP-" -BlockedWords "CEO,Payroll,HR" -WhatIf` — shows the exact `Group.Unified` settings that
   would change (`EnableGroupCreation`, `GroupCreationAllowedGroupId`, `PrefixSuffixNamingRequirement`,
   `CustomBlockedWordsList`) without writing.
2. **Commit (pilot).** Re-run with `-Commit`. This sets `EnableGroupCreation = false` and points
   `GroupCreationAllowedGroupId` at `Group Creators – Governed – Pilot`, and applies the naming policy.
   > **Note:** creation control is **tenant-wide** — there is no per-scope creation setting. Pilot the
   > *naming policy string* and the *creators membership* by keeping the creators group small first; only
   > expand membership at Stage 6. Announce the change to users before committing.
3. **Rollback:** re-run with `-Commit -Rollback` to set `EnableGroupCreation = true` and clear the naming
   requirement, restoring open creation.

### 3b. Classification (container labels)

1. Ensure `Sensitivity Label – … – Prod` labels are **published** (Requirement 6).
2. Enable label support: the same config script sets `EnableMIPLabels = true` when `-EnableLabels` is
   passed (dry-run first). After enabling, run the Graph label sync as documented
   (`Execute-AzureAdLabelSync` equivalent via Graph) — **verify the current sync cmdlet in your tenant**,
   as this step is version-dependent.
3. Apply a label to a pilot team to confirm the label appears on the team/site.

### 3c. Ownership standards

1. Configure the **ownerless groups policy** `Ownerless Policy – Teams – Prod` in the Microsoft 365 admin
   center → **Settings → Org settings → Microsoft 365 Groups → Ownerless groups**, selecting members to be
   prompted to become owners. (This is an admin-center feature; confirm availability in your cloud.)
2. For the pilot, use `Get-TeamsGovernanceInventory.ps1` output to identify pilot teams lacking the
   minimum owners and assign owners with `Add-MgGroupOwnerByRef` (or via the admin center).

### 3d. Expiration + retention + archival

1. **Expiration dry-run.** `.\Set-TeamsLifecyclePolicy.ps1 -ExpirationDays 180 -ManagedGroupTypes Selected
   -PilotGroupId <pilotGroupGuid> -NotificationEmails "governance@contoso.com" -WhatIf`. Using
   `-ManagedGroupTypes Selected` scopes expiration to the pilot groups only — **this is how you pilot
   expiration safely**.
2. **Commit (pilot).** Re-run with `-Commit` to create `Expiration Policy – M365 Groups – Prod` covering
   only the selected pilot groups. Owners receive renewal notifications; unrenewed groups are soft-deleted
   (restorable for 30 days by default — verify).
3. **Retention.** With the compliance owner, create `Retention Policy – Teams – Prod` for Teams channel
   messages/chats and the associated files. The lifecycle script will **report** the current retention
   coverage and, when `-ConfigureRetention -Commit` is passed with an explicit `-RetentionDays` supplied
   **by compliance**, create the Purview policy via `New-RetentionCompliancePolicy` /
   `New-RetentionComplianceRule`. **Never** set a retention duration without the compliance determination.
4. **Archival.** For teams that should be kept read-only rather than deleted, the lifecycle script archives
   them with `Set-TeamArchivedState -GroupId <id> -Archived $true -SetSpoSiteReadOnlyForMembers $true`
   (dry-run first; `-Commit` to apply). Rollback: `Set-TeamArchivedState … -Archived $false`.

**Gate 3 (Configure):** Every control applied to the pilot with a successful dry-run first; rollback
tested for creation control and archival.

---

## Stage 4 — Pilot

1. Have a pilot user **not** in `Group Creators – Governed – Pilot` attempt to create a team — it must be
   blocked.
2. Have a creator create a team with a non-compliant name — the naming policy must block/prefix it.
3. Apply/observe a classification label on `Pilot Team – Governance-A – Pilot`.
4. Let a selected pilot group approach expiration (or force a short lifetime in a test) and confirm the
   renewal notification and soft-delete/renew behavior.
5. Archive one stale pilot team and confirm read-only.

---

## Stage 5 — Validate (pass/fail gates)

Run `Test-TeamsGovernanceReadiness.ps1` (Script 5) and confirm each gate:

- **Creation controlled** — `EnableGroupCreation = false`, `GroupCreationAllowedGroupId` set. **PASS/FAIL**
- **Naming enforced** — `PrefixSuffixNamingRequirement` present; a bad name is rejected. **PASS/FAIL**
- **Classification on** — `EnableMIPLabels = true`; pilot team shows a label. **PASS/FAIL**
- **Expiration active** — a lifecycle policy exists with the intended lifetime. **PASS/FAIL**
- **Ownership** — pilot teams meet the minimum-owners rule; ownerless policy configured. **PASS/FAIL**
- **Stale handled** — stale pilot teams are archived or slated for expiration. **PASS/FAIL**

**Gate 5 (Validate):** All gates PASS on the pilot before expanding.

---

## Stage 6 — Expand (production, change control)

1. Repoint creation control from the pilot creators group to `Group Creators – Governed – Prod` (re-run
   Script 2 with the prod group; dry-run first).
2. Change expiration from `-ManagedGroupTypes Selected` to `All` (re-run Script 3 with `-ManagedGroupTypes
   All`) so **every** group is covered — announce first; this soft-deletes unrenewed groups tenant-wide.
3. Publish the naming/classification standard to all users; expand creators-group membership per the model.
4. Schedule `Get-TeamsGovernanceReport.ps1` (Script 4) to run on a cadence (e.g. monthly) for ongoing
   posture and to catch drift.

**Documented rollback (any stage):** re-enable open creation (`Set-TeamsCreationNamingPolicy.ps1 -Commit
-Rollback`), remove/relax expiration (`Set-TeamsLifecyclePolicy.ps1 -RemoveExpiration -Commit`), and
un-archive teams (`Set-TeamArchivedState … -Archived $false`). Keep the Stage-1 baseline inventory as the
reference for what "before" looked like.
