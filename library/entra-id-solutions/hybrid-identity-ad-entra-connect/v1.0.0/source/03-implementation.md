# 3. Implementation Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Follow these steps in order. Work happens in two places: the Microsoft Entra Connect wizard on the
host server, and the cloud portal at `https://entra.microsoft.com` (Identity -> Hybrid management).

> Model: rehearse in staging mode, validate on a pilot scope, then expand to the whole directory.
> The identity plane is high risk — keep your break-glass accounts to hand before every change.

Objects you will create (name them exactly as written and reuse verbatim):
- AD organizational unit: `Hybrid Pilot Sync Scope - Pilot - Pilot`
- AD organizational unit: `Hybrid Production Sync Scope - All-Domains - Expand`
- Entra security group: `Hybrid Join Devices - Pilot - Pilot`
- Hybrid join service connection point config: `Hybrid Entra Join - Domain - Configure`

## Step 1 — Prepare AD and the pilot scope
1. On a domain controller, open `Active Directory Users and Computers`.
2. Create an OU named `Hybrid Pilot Sync Scope - Pilot - Pilot` and move a handful of representative
   pilot users (and test devices) into it.
3. Create an OU (or confirm the existing structure) named
   `Hybrid Production Sync Scope - All-Domains - Expand` to represent the full production scope for
   later expansion.
4. Run `HYBID-Discovery.ps1` and resolve every flagged item (`.local` UPNs, duplicate UPNs/proxyAddresses, AD health).

## Step 2 — Verify the public domain in Entra
1. In `https://entra.microsoft.com`, go to `Identity -> Settings -> Domain names`.
2. Confirm your public domain shows Verified (add and verify it with the displayed DNS TXT record if not).
3. Ensure AD user UPN suffixes match that public domain (fix in `Active Directory Domains and Trusts` if needed).

## Step 3 — Install Microsoft Entra Connect on the host
1. On the Connect host server, download Microsoft Entra Connect and launch the installer.
2. Accept the license, then choose `Customize` (so you can scope the sync and pick the auth method).
3. On `Install required components`, leave the defaults and click `Install`.

## Step 4 — Choose the authentication method (in the wizard)
1. On the `User sign-in` page, select the primary method:
   - `Password Hash Synchronization` (recommended default), or
   - `Pass-through authentication`, or
   - `Federation with AD FS` (only for a stated requirement).
2. Tick `Enable single sign-on` (Seamless SSO) for domain-joined corporate-network users.
3. Click `Next`.

## Step 5 — Connect to Entra ID and AD
1. On `Connect to Microsoft Entra ID`, sign in with a `Global Administrator` (the one-time first-sync consent).
2. On `Connect your directories`, add your AD forest with an enterprise-admin (or delegated sync) credential. Click `Next`.
3. On `Microsoft Entra sign-in configuration`, confirm the UPN suffix is the verified public domain (resolve any warning here before continuing).

## Step 6 — Scope the synchronization
1. On `Domain and OU filtering`, choose `Sync selected domains and OUs`.
2. Select only `Hybrid Pilot Sync Scope - Pilot - Pilot` for the pilot. Click `Next`.
3. On `Uniquely identifying your users`, accept the default (`Users are represented once`) unless you have a multi-forest match attribute.
4. On `Filter users and devices`, keep `Synchronize all users and devices`. Click `Next`.

## Step 7 — Optional features, then stage the first sync
1. On `Optional features`, enable what you need — for example `Password writeback` and (if PTA/federation primary) keep `Password hash synchronization` ticked as a backup. Click `Next`.
2. On `Ready to configure`, tick `Enable staging mode` so the first run imports and rehearses without exporting to the cloud. Click `Install`.
3. When it finishes, run `HYBID-Validation.ps1` and `HYBID-Report.ps1` on the host to review what would export, the connector-space object counts, and any sync errors — fix errors before going live.

## Step 8 — Take the server out of staging mode (go live for the pilot)
1. Re-run the Microsoft Entra Connect wizard, choose `Configure staging mode`, and clear the
   `Enable staging mode` checkbox. Finish the wizard.
2. Force a sync cycle: on the host run `Start-ADSyncSyncCycle -PolicyType Delta`.
3. In `https://entra.microsoft.com -> Identity -> Hybrid management -> Microsoft Entra Connect ->
   Connect Sync`, confirm sync status is healthy and the pilot users now appear under
   `Identity -> Users`.

## Step 9 — Enable Seamless SSO and confirm the auth method
1. In `Identity -> Hybrid management -> Microsoft Entra Connect`, confirm the chosen sign-in method
   shows Enabled and (for PTA) at least two healthy authentication agents.
2. For Seamless SSO, ensure the `AZUREADSSO` computer object exists in AD and roll out the two browser
   settings via Group Policy to pilot devices (Microsoft documents the exact registry/policy values).

## Step 10 — Enable hybrid Entra join (devices)
1. Create an Entra security group named `Hybrid Join Devices - Pilot - Pilot` for pilot devices.
2. Re-run the Microsoft Entra Connect wizard -> `Configure device options` -> `Configure Hybrid Azure AD join`; this writes the service connection point named `Hybrid Entra Join - Domain - Configure`. Select your device OS/platform and finish.
3. On a pilot device, run `dsregcmd /status` and confirm `AzureAdJoined : YES` and `DomainJoined : YES` (allow a policy cycle and a sign-in).

## Step 11 — Validate the pilot
1. Run `HYBID-Validation.ps1` -> confirms sync ran, pilot objects exported, and a test sign-in works.
2. Run `HYBID-Report.ps1` -> confirms sync health, object coverage, and zero unresolved sync errors.
3. Complete the Testing Guide. Do not expand until the pilot gate passes.

## Step 12 — Expand to production
1. Re-run the wizard -> `Customize synchronization options` -> `Domain and OU filtering` and add
   `Hybrid Production Sync Scope - All-Domains - Expand` to the sync scope. Finish.
2. Run `Start-ADSyncSyncCycle -PolicyType Initial` for a full sync of the new scope.
3. Re-run `HYBID-Report.ps1` to confirm coverage and health across the full directory; add
   `Hybrid Join Devices - Pilot - Pilot` members (or a production device group) as you expand hybrid join.

---
### Order of operations
`Prepare AD + pilot scope -> verify domain -> install Connect -> choose auth method -> connect directories -> scope sync -> stage first sync -> exit staging (pilot live) -> Seamless SSO -> hybrid join -> validate -> expand`
