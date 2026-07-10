# Diagnostic Workflow

This is the core deliverable: the ordered workflow for a **cloud sync "users skipped / JoinNotFound /
not provisioned"** incident. It adapts the category-standard **Assess → Configure → Pilot → Validate →
Expand** model to a diagnostic shape:

**Collect → Analyze → Remediate → Verify.**

During an incident, start here. Work it in order — **Collect once** on the agent host, then **Analyze**
the area the symptom points to with the focused tools, **Remediate** in the owning plane (portal /
AADCloudSyncTools / AD), and **Verify** by re-running provision on demand and reading the provisioning
log until the object provisions with **action = Create**.

> Names used verbatim (from `01-solution-overview.md` / `02-requirements.md`):
> **`Cloud Sync – AD to Entra – Configuration`**, **`Cloud Sync – In-Scope Users – OU`**,
> **`Cloud Sync – Pilot Scope – Pilot`**, **`Cloud Sync – Provisioning Agent Host`**, and Microsoft's
> **"Microsoft Entra Provisioning Agent"**, **"Microsoft Entra Connect Agent Updater"**, and
> **"Microsoft Entra AD Synchronization Service"**.

---

## Phase 1 — Collect (always start here)

Run the collector **once** on `Cloud Sync – Provisioning Agent Host` to snapshot the agent state and
gather the logs into one bundle — so you spend the incident reasoning, not gathering.

```
powershell -ExecutionPolicy Bypass -File .\CLDSYNCDX-Collect-Diagnostics.ps1 -OutFolder .\CloudSyncDiag
```

Run it **elevated** (R2) so it can read the agent services, the Trace folder, and export the logs. The
collector captures:

- the **"Microsoft Entra Provisioning Agent"** and **"Microsoft Entra Connect Agent Updater"** service
  states (should be **Running**);
- the PowerShell **execution policy** (an over-restrictive or `Unrestricted` policy is noteworthy);
- the **proxy** configuration presence (WinHTTP / agent config), which affects outbound reachability;
- the agent **Trace** folder (`C:\ProgramData\Microsoft\Azure AD Connect Provisioning Agent\Trace`);
- and, **if the AADCloudSyncTools module is present**, a full `Export-AADCloudSyncToolsLogs` bundle.

Everything is zipped to a timestamped **`Cloud Sync – Diagnostics – <timestamp>`** folder. The
collector makes **no changes**.

**Gate (Collect):** the bundle wrote successfully and the two agent services are named with their
state. If the host can't run PowerShell elevated, resolve R1/R2 first.

---

## Phase 2 — Analyze (run the focused check for the flagged area)

Pick the branch by **symptom**. Each focused tool prints a **PASS/FAIL** verdict (or the authoritative
provisioning-log reason) and the exact remedy.

### Symptom → tool map

| Symptom | Where the truth is | Run this tool | What it isolates |
|---|---|---|---|
| Provision on demand shows **Evaluate → "User was skipped", JoinNotFound** | Provisioning logs | `CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid <guid>` | The **authoritative** per-object action / status / skipReason + step detail |
| **Nothing is being created** fleet-wide; job may be stuck | Sync job / SP / org | `CLDSYNCDX-Check-Provisioning.ps1` | Job **Active/Enabled/Quarantined**, SP present, `onPremisesSyncEnabled`, deletion-threshold |
| The **agent shows unhealthy** / recently stopped syncing | Agent host | `CLDSYNCDX-Check-Agent.ps1` | Services Running · execution policy · outbound 443 · proxy/config |
| A **specific user** never provisions (skipped / not created) | Active Directory | `CLDSYNCDX-Test-Object.ps1 -Identity <user> -InScopeOU <dn[]>` | Critical-object · out-of-scope OU · non-routable UPN · possible duplicate |
| You **just changed scope/config** and still nothing | Sync job + AD object | `CLDSYNCDX-Check-Provisioning.ps1` **then** `CLDSYNCDX-Test-Object.ps1` | Whether a **restart** is needed to clear watermarks, and whether the OU is now in scope |

### Branch A — read the authoritative reason (start here for JoinNotFound)

```
powershell -File .\CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid 11111111-2222-3333-4444-555555555555
```

or by UPN:

```
powershell -File .\CLDSYNCDX-Get-ProvisioningLog.ps1 -UserPrincipalName user@contoso.com
```

It queries the **provisioning logs** (Microsoft Graph `auditLogs/provisioning`) for that object and
prints the latest entries with the **provisioningAction** (create/update/delete/other), the **status**
(success / skipped / failure), the **skipReason** (e.g. `JoinNotFound`), and the per-step detail
(Import / Scope / Match / Evaluate). This is the authoritative statement of *what the service decided
and why* — everything else in Analyze is about explaining that reason.

### Branch B — job / service-principal / org health

```
powershell -File .\CLDSYNCDX-Check-Provisioning.ps1
```

It finds the cloud sync **synchronization job**, reports whether it is **Active / Enabled /
Quarantined** (with the quarantine reason and escrow count if any), whether the **"Microsoft Entra AD
Synchronization Service"** service principal exists, and the org's `onPremisesSyncEnabled`. It flags
**`AzureDirectoryServiceAuthorizationFailed`** (missing SP) and object-deletion-threshold symptoms.
Read-only — it never restarts the job.

### Branch C — agent health on the host

```
powershell -ExecutionPolicy Bypass -File .\CLDSYNCDX-Check-Agent.ps1
```

It checks, with PASS/FAIL and a remedy per FAIL: the two agent **services are Running**, the
**execution policy** is workable (not `Unrestricted`, ideally `RemoteSigned`/`Undefined`), a **sample
outbound 443** endpoint is reachable, and the **agent config / proxy** file is present. The first FAIL
is usually why the agent went unhealthy.

### Branch D — is this specific object even a candidate?

```
powershell -File .\CLDSYNCDX-Test-Object.ps1 -Identity jsmith `
    -InScopeOU 'OU=Cloud Sync – In-Scope Users – OU,DC=contoso,DC=com','OU=Cloud Sync – Pilot Scope – Pilot,DC=contoso,DC=com'
```

It reports, for the user: **`IsCriticalSystemObject`** (excluded by design if true), whether its OU is
**under one of the supplied in-scope OU DNs** (out-of-scope if not), whether its **UPN suffix** is a
routable/verified domain, and an **advisory** on a possible same-UPN/`proxyAddresses` object that would
already exist in the tenant. Read-only against AD.

**Gate (Analyze):** you can name the condition — either the provisioning log states the reason
(`JoinNotFound` + the failing step), or a focused tool reports a specific FAIL with a named remedy. Do
not guess past it; fix it and re-check.

---

## Phase 3 — Remediate (in the owning plane)

The toolkit is **read-only** — it never changes the object, tenant, configuration, or agent. Apply the
indicated fix in the plane that owns it. Typical remedies by finding:

| Finding | Where to fix | Typical remedy |
|---|---|---|
| Target already exists (prior sync method / cloud-only same UPN) | Entra ID | Reconcile the duplicate: remove/rename the stale cloud object, or let the soft-match join it; align `userPrincipalName` / `proxyAddresses` so exactly one target matches |
| Configuration not **Enabled** | Portal (Cloud sync) | Enable `Cloud Sync – AD to Entra – Configuration` |
| User's OU **not in scoping filters** | Portal (Cloud sync) | Add the user's OU to the configuration's scoping filters (or move the user into `Cloud Sync – In-Scope Users – OU`) |
| Scope/config changed but objects not re-discovered | Portal / AADCloudSyncTools | **Restart provisioning** on the configuration to clear watermarks so objects are re-evaluated |
| Object is **`IsCriticalSystemObject`** / replication victim | (by design) | Test with a normal user; built-in accounts are filtered out intentionally |
| Job **quarantined** (e.g. bad admin creds) | Portal / AADCloudSyncTools | **Clear quarantine** / **Restart** the job after fixing the underlying auth failure; `Repair-AADCloudSyncToolsAccount` for the agent account |
| **Object-deletion threshold** blocking (Connect + cloud sync coexistence) | AADCloudSyncTools | `Disable-AADCloudSyncToolsDirSyncAccidentalDeletionPrevention -tenantId <tid>` (then re-enable the safeguard after the run) |
| **`AzureDirectoryServiceAuthorizationFailed`** — SP missing | Microsoft Graph | Re-enable sync to recreate the **"Microsoft Entra AD Synchronization Service"** SP: `PATCH /organization/<tid> { "onPremisesSyncEnabled": true }` |
| Agent service stopped / unhealthy / no outbound 443 | Agent host / network | Start the **"Microsoft Entra Provisioning Agent"** + **"Microsoft Entra Connect Agent Updater"** services; open outbound **80/443** to the documented endpoints; restart the agent |

Several of these touch tenant-wide or outward-facing state (the org sync flag, quarantine, the deletion
safeguard). Remediate under **change control** — see `07-best-practices.md`. Exact cmdlet syntax and
portal navigation for the cloud sync service are **deferred to Microsoft's official documentation**.

---

## Phase 4 — Verify (re-run until the object provisions)

After a fix, re-run the focused tool for the branch you worked, then run the decisive test: **provision
on demand** the user again and read the provisioning log.

```
powershell -File .\CLDSYNCDX-Check-Provisioning.ps1                 # job Active/Enabled, not quarantined
powershell -File .\CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid <guid>   # action now = Create / Update, not skipped
```

Then prove it **in the tenant**: run **provision on demand** for the user in **Entra Connect → Cloud
sync →** the configuration, confirm the **Evaluate action** now shows **Create** (or **Update**), and
confirm the user **appears in Entra ID** with the correct UPN. For the scope fix, let a **scheduled
cycle** run (or restart provisioning) and confirm the previously out-of-scope user is created. Confirm
each gate in `05-testing.md`.

**Gate (Verify):** the provisioning log for the object shows **action = Create/Update** (no longer
**skipped / JoinNotFound**), the job is **Active/Enabled and not quarantined**, and the user is present
in Entra ID. Only then is the incident closed. Record the root-cause condition on the ticket (see
`07-best-practices.md`, closing the loop).
