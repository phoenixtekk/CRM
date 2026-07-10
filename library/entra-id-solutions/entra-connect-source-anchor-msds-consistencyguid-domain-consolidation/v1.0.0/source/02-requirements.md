# 2. Requirements Guide — Migrating the Microsoft Entra Connect Source Anchor to mS-DS-ConsistencyGuid

Verify every requirement before changing the source anchor. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

> The anchor switch is effectively permanent. Confirm the version, the empty-attribute precondition,
> the connector-account permission, and the backup **before** you open the wizard.

## 2.1 A current Microsoft Entra Connect Sync build
Description: Microsoft Entra Connect Sync at a build that supports mS-DS-ConsistencyGuid as the source anchor.
Why: mS-DS-ConsistencyGuid has been the default source anchor since Azure AD Connect 1.1.524; an older build may not offer the Configure Source Anchor operation.
Verify: On the Connect server run `SRCANCHOR-Assess.ps1` (reports the installed version); or check `Add or remove programs` for the Microsoft Azure AD Connect / Microsoft Entra Connect version.
Implement: Upgrade Microsoft Entra Connect Sync to the current release before proceeding, then re-run `SRCANCHOR-Assess.ps1`.

## 2.2 Current source anchor confirmed as objectGUID
Description: Confirmation that the deployment's current source anchor is `objectGUID` (the older method).
Why: This solution is the switch *from* objectGUID; if the anchor is already mS-DS-ConsistencyGuid there is nothing to change.
Verify: Run `SRCANCHOR-Assess.ps1` (reads the source anchor from `Get-ADSyncGlobalSettings`); it reports the current `Microsoft.SourceAnchorAttribute`.
Implement: If already mS-DS-ConsistencyGuid, stop — the migration prerequisite is already met; proceed to the Quest ODM coordination check (2.6).

## 2.3 mS-DS-ConsistencyGuid EMPTY on all in-scope objects (the precondition)
Description: No object in the `Source Anchor – In-Scope OUs` currently has a value in mS-DS-ConsistencyGuid.
Why: The wizard only seeds the attribute where it is empty; if ANY in-scope object already has a value, the wizard refuses by default (a pre-existing value can mean the object is matched by something else, and overwriting it would break the link).
Verify: Run `SRCANCHOR-Test-Preconditions.ps1 -IncludeOU "<OU DN>"` — it lists any in-scope objects whose mS-DS-ConsistencyGuid is already set (count + sample distinguishedNames). Zero = ready.
Implement: Investigate whatever populated the attribute (a prior Connect install, a previous migration, or a manual stamp). Either clear it after confirming it is safe to do so, or exclude those objects from scope, until the count is zero. Do not blindly clear it.

## 2.4 AD DS connector (sync) account WRITE permission to mS-DS-ConsistencyGuid
Description: The AD DS connector (sync) account has Write permission to the mS-DS-ConsistencyGuid attribute across the `Source Anchor – In-Scope OUs`.
Why: To seed the anchor, Connect writes each object's objectGUID value into its mS-DS-ConsistencyGuid attribute (a write-back into AD); without Write permission the seed fails with access-denied.
Verify: Run `SRCANCHOR-Check-Permissions.ps1 -ConnectorAccount "<DOMAIN\account>" -IncludeOU "<OU DN>"` — it reports per-OU PASS/FAIL for Write mS-DS-ConsistencyGuid.
Implement: Delegate Write mS-DS-ConsistencyGuid to the AD DS connector (sync) account on each in-scope OU (see Implementation Step 4 — `dsacls` or the ADUC Delegation of Control wizard).

## 2.5 A full backup / configuration export of Microsoft Entra Connect
Description: An exported Microsoft Entra Connect configuration captured before the change, recorded in the `Source Anchor – Change & Backup Record`.
Why: The switch is effectively permanent; the export is your documented pre-change state and the reference if you need Microsoft support.
Verify: A saved configuration export file exists and its filename, the Connect server name, and the change date are written into the `Source Anchor – Change & Backup Record`.
Implement: In the Microsoft Entra Connect wizard choose `View or export current configuration` and save the export; record it (see Implementation Step 5).

## 2.6 Quest On Demand Migration configured to stamp mS-DS-ConsistencyGuid on targets
Description: Quest ODM (or Quest Migration Manager) is configured so that each migrated/target object carries the source object's mS-DS-ConsistencyGuid value.
Why: The anchor only survives the move if the migration tool copies mS-DS-ConsistencyGuid onto the target; that carry is what lets Entra Connect hard-match the migrated object to the existing Entra user.
Verify: Confirm in Quest ODM that the matching/attribute mapping carries mS-DS-ConsistencyGuid to the target (per Quest's documentation), then prove it end-to-end with the pilot in Implementation Step 8.
Implement: Configure the mS-DS-ConsistencyGuid carry in Quest ODM per Quest's official documentation. (Quest console internals are documented by Quest; this solution consumes the stamped attribute as its coordination point and does not configure the Quest console.)

## 2.7 AD FS network path — ONLY if AD FS is the sign-in method
Description: If sign-in uses AD FS (federation), direct network connections on TCP 80, 443, and 5985 from the Connect server to the **primary AD FS server**.
Why: Changing the source anchor updates the AD FS issuance/claim rules, which the wizard performs against the primary AD FS server over these ports; without them that step fails.
Verify: Confirm the sign-in method (Entra admin center -> `Identity -> Hybrid management -> Microsoft Entra Connect`); if AD FS, test TCP 80/443/5985 from the Connect server to the primary AD FS server.
Implement: Open TCP 80/443/5985 from the Connect server to the primary AD FS server before running the wizard. If sign-in is PHS, PTA, or cloud authentication, this requirement does **not** apply.

## 2.8 Administrative roles
Description: Enterprise/Domain Admin (or delegated) rights to set the AD permission, plus Global Administrator / Hybrid Identity Administrator for the Entra side.
Why: Delegating Write mS-DS-ConsistencyGuid needs AD rights; the wizard's Entra connection needs the Entra role.
Verify: You can run `dsacls`/Delegation of Control on the in-scope OUs, and sign in to the wizard's Entra connection with the required role.
Implement: Obtain Enterprise/Domain Admin (or a delegated equivalent) for the OU permission and Global Administrator / Hybrid Identity Administrator for the Entra connection.

## 2.9 The Microsoft Entra tenant
Description: The Microsoft Entra ID tenant the Connect server already synchronizes to.
Why: The anchor change is applied by the same Connect deployment against the same tenant.
Verify: Sign in to `https://entra.microsoft.com` (Gov: `https://entra.microsoft.us`) as an administrator; confirm the tenant matches the Connect deployment.
Implement: Use the existing tenant; no new tenant is created by this solution.

> **Government (GCC High) note:** In US Government (GCC High) tenants, use the Microsoft Entra admin
> center at `https://entra.microsoft.us` and sign in at `https://login.microsoftonline.us`. The
> mS-DS-ConsistencyGuid source-anchor mechanics are identical; **verify for GCC High** that your Entra
> Connect build and endpoints are the US-Government variants before you run the wizard.

---
## Checklist
- [ ] Current Microsoft Entra Connect Sync build (supports mS-DS-ConsistencyGuid) — `SRCANCHOR-Assess.ps1`
- [ ] Current source anchor confirmed as `objectGUID` — `SRCANCHOR-Assess.ps1`
- [ ] mS-DS-ConsistencyGuid EMPTY on all in-scope objects — `SRCANCHOR-Test-Preconditions.ps1`
- [ ] AD DS connector (sync) account has Write mS-DS-ConsistencyGuid on each in-scope OU — `SRCANCHOR-Check-Permissions.ps1`
- [ ] Microsoft Entra Connect configuration exported into the `Source Anchor – Change & Backup Record`
- [ ] Quest ODM configured to stamp mS-DS-ConsistencyGuid on targets (per Quest docs)
- [ ] AD FS ports TCP 80/443/5985 to the primary AD FS server (ONLY if AD FS sign-in)
- [ ] Admin roles available (Enterprise/Domain Admin for delegation; Global Admin / Hybrid Identity Admin for Entra)
- [ ] Correct Microsoft Entra tenant confirmed
