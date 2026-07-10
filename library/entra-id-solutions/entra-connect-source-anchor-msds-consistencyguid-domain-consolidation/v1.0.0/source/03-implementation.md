# 3. Implementation Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Follow these steps in order. Work happens in three places: PowerShell on the Microsoft Entra Connect
server, `Active Directory Users and Computers` on a domain controller, and the Microsoft Entra Connect
wizard on the Connect server.

> Model: Assess -> Configure -> Pilot -> Validate -> Expand, with an explicit gate between phases.
> The anchor switch is effectively permanent — do not open the wizard until Gate A passes.

Objects and artifacts you will use (name them exactly as written and reuse verbatim):
- AD scope: `Source Anchor – In-Scope OUs` (the OUs Microsoft Entra Connect synchronizes)
- Pilot user set: `PILOT – Source Anchor – Validation Users` (a small set used to prove the hard-match)
- Sync account: `the AD DS connector (sync) account` (the MSOL_/ADSync service account Connect uses)
- Record: `Source Anchor – Change & Backup Record` (the config export + the change date)

---
## Phase 1 — Assess

## Step 1 — Read the current state on the Connect server
1. Sign in to the Microsoft Entra Connect server as an administrator.
2. Open an elevated PowerShell and run `SRCANCHOR-Assess.ps1`.
3. Confirm it reports: the current source anchor is `objectGUID`, the installed Microsoft Entra Connect
   Sync version supports mS-DS-ConsistencyGuid, and the count of in-scope objects that already have
   mS-DS-ConsistencyGuid populated.

## Step 2 — Confirm the empty-attribute precondition
1. Identify the OUs that make up `Source Anchor – In-Scope OUs` (the OUs Connect syncs).
2. Run `SRCANCHOR-Test-Preconditions.ps1 -IncludeOU "<OU distinguishedName>"` for each in-scope OU.
3. Confirm the reported count of objects with mS-DS-ConsistencyGuid already set is **zero**. If it is
   non-zero, **STOP** — investigate what populated the attribute (a prior Connect install, an earlier
   migration, or a manual stamp). Clear it only after confirming it is safe, or exclude those objects
   from scope, until the count is zero. Do not proceed with any value present.

## Step 3 — Confirm the connector-account permission
1. Identify the AD DS connector (sync) account (the MSOL_/ADSync service account Connect uses to read
   and write AD).
2. Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU distinguishedName>"`.
3. Note any OU reporting FAIL for Write mS-DS-ConsistencyGuid — you grant it in Step 4.

## Step 4 — Grant Write mS-DS-ConsistencyGuid where missing
1. On a domain controller, open `Active Directory Users and Computers`, and turn on
   `View -> Advanced Features`.
2. For each OU that failed Step 3, right-click the OU -> `Delegate Control...` -> `Next` ->
   `Add...` the AD DS connector (sync) account -> `Next` -> `Create a custom task to delegate` ->
   `Only the following objects in the folder` -> tick `User objects` -> `Next` -> under `Permissions`
   tick `Property-specific`, then tick `Write mS-DS-ConsistencyGuid` -> `Next` -> `Finish`.
   (Equivalent command line, run as a Domain Admin:
   `dsacls "OU=<in-scope OU>,DC=corp,DC=example,DC=com" /I:S /G "<DOMAIN\account>:WP;mS-DS-ConsistencyGuid;user"`.)
3. Re-run `SRCANCHOR-Check-Permissions.ps1` and confirm every in-scope OU now reports PASS.

## Step 5 — Back up the Connect configuration
1. On the Connect server, launch the Microsoft Entra Connect wizard.
2. On the tasks page choose `View or export current configuration`, then export/save the configuration
   file.
3. Record the export filename, the Connect server name, its ADSync database (SQL/LocalDB) location, and
   the planned change date in the `Source Anchor – Change & Backup Record`.

> ### Gate A — Assess complete
> Proceed only when: source anchor is `objectGUID`; the Connect build supports mS-DS-ConsistencyGuid;
> `SRCANCHOR-Test-Preconditions.ps1` reports **zero** in-scope objects with mS-DS-ConsistencyGuid set;
> `SRCANCHOR-Check-Permissions.ps1` reports **PASS** on every in-scope OU; and the configuration export
> is recorded in the `Source Anchor – Change & Backup Record`. If AD FS is your sign-in method, also
> confirm TCP 80/443/5985 to the primary AD FS server (Requirement 2.7).

---
## Phase 2 — Configure

## Step 6 — Switch the source anchor in the wizard
1. On the Connect server, launch the Microsoft Entra Connect wizard.
2. On the tasks page choose `Configure` -> `Configure Source Anchor`.
3. When prompted, sign in to Microsoft Entra ID with a `Global Administrator` /
   `Hybrid Identity Administrator` (Gov: sign in at `https://login.microsoftonline.us`).
4. Let the wizard analyze mS-DS-ConsistencyGuid across the in-scope objects. When it offers
   `mS-DS-ConsistencyGuid` as the source anchor, select it and continue.
5. Complete the wizard. For each in-scope object whose mS-DS-ConsistencyGuid is empty, Connect writes
   that object's objectGUID value into its mS-DS-ConsistencyGuid attribute (the seed). Because the
   seeded value equals the existing objectGUID, the immutableId does not change and no re-sync occurs.

> If the wizard reports that mS-DS-ConsistencyGuid is **not empty** and refuses, do not force it —
> return to Step 2, clear or exclude the flagged objects, then retry. If it reports **access denied**
> writing the attribute, return to Step 4 and re-grant the connector-account permission.

## Step 7 — Confirm the seed landed
1. On the Connect server run `SRCANCHOR-Validate.ps1`.
2. Confirm it reports the current source anchor is now `mS-DS-ConsistencyGuid`, sampled in-scope objects
   have mS-DS-ConsistencyGuid populated, and each sampled object's mS-DS-ConsistencyGuid (Base64) equals
   its prior immutableId (the objectGUID Base64) — i.e. the anchor value did not change.

> ### Gate B — Configure complete
> Proceed only when the source anchor reads `mS-DS-ConsistencyGuid`, in-scope objects are seeded, and
> the seeded value equals the previous immutableId (no anchor change, no duplicates).

---
## Phase 3 — Pilot

## Step 8 — Migrate one pilot user through Quest ODM and prove the hard-match
1. Assemble a small `PILOT – Source Anchor – Validation Users` set (a handful of representative users
   whose migration you can safely rehearse).
2. Confirm the mS-DS-ConsistencyGuid values are populated for the pilot users (`SRCANCHOR-Validate.ps1`
   or a spot check).
3. Using Quest ODM, perform a test migration of one `PILOT – Source Anchor – Validation Users` object
   into the target domain **with mS-DS-ConsistencyGuid stamped onto the target object** (per Quest's
   documentation and Requirement 2.6).
4. Let a Connect delta sync run (`Start-ADSyncSyncCycle -PolicyType Delta` on the Connect server).
5. In `https://entra.microsoft.com -> Identity -> Users` (Gov: `https://entra.microsoft.us`), confirm
   the migrated pilot user is the **same** Entra object updated in place — **not** a new/duplicate
   account — and it retains its mailbox, licenses, and sign-in.

> ### Gate C — Pilot passes
> Proceed only when a pilot object migrated through Quest ODM (with mS-DS-ConsistencyGuid stamped)
> hard-matches the existing Entra user: one object, updated in place, no duplicate, licenses/mailbox
> intact.

---
## Phase 4 — Validate

## Step 9 — Full validation and report
1. On the Connect server run `SRCANCHOR-Validate.ps1` and `SRCANCHOR-Report.ps1`.
2. Confirm: the anchor is `mS-DS-ConsistencyGuid`; the seeded/populated count matches the in-scope
   object count; there are no unresolved ADSync run errors; the duplicate-risk check is clean; and (if
   Microsoft Graph is available) the matched Entra users' `onPremisesImmutableId` values are unchanged.
3. Complete the Testing Guide. Do not begin production waves until the validate gate passes.

> ### Gate D — Validate passes
> Proceed only when validation shows the anchor migrated, no duplicate/orphaned Entra objects, sign-in
> working, and immutableId unchanged for existing users.

---
## Phase 5 — Expand

## Step 10 — Run the production migration waves
1. Proceed with the full Quest ODM migration waves against the target domain, keeping the
   mS-DS-ConsistencyGuid stamp configured for every wave.
2. After each wave, run `SRCANCHOR-Report.ps1` and confirm no duplicates/orphans and no new ADSync
   errors before starting the next wave.
3. Keep the `Source Anchor – Change & Backup Record` up to date with each wave's date and result.

> ### Gate E — Expand complete
> All migration waves finished; `SRCANCHOR-Report.ps1` clean across the migrated population; every
> migrated user hard-matched with identity, mailbox, and licenses intact.

> **Rollback note:** the anchor switch is effectively permanent. Do **not** attempt to revert to
> objectGUID mid-migration — doing so would re-break the link for already-migrated users. Your safety
> is the pre-change backup (`Source Anchor – Change & Backup Record`) and the empty-attribute
> precondition proven at Gate A, not a mid-flight rollback.

---
### Order of operations
`Assess (version, anchor, empty precondition, permission, backup) -> Gate A -> Configure Source Anchor
(wizard, seed) -> Gate B -> Pilot one Quest ODM migration + hard-match -> Gate C -> Validate (no
duplicates, immutableId unchanged) -> Gate D -> Expand (production waves, monitor) -> Gate E`
