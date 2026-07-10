# Solution Overview

## What this toolkit is

This is a **diagnostics toolkit**, not a deployment guide. It assumes you already run — or are
supposed to run — **Microsoft Entra Connect cloud sync**: the lightweight **provisioning agent** that
synchronizes users, groups, and contacts from on-premises **Active Directory (AD)** into **Microsoft
Entra ID**. Something in that flow has stopped working: the configuration looks complete, the agent
shows healthy, but **no accounts are being created in Entra ID**. When you run **provision on demand**
for a user you see **Import ✓ / In scope ✓ / Match ✓**, and then the **Evaluate action** step reports
**"User was skipped"** with **SkipReason: JoinNotFound** — *"not a newly discovered entry to be
provisioned … nor one with an update to flow to a previously matched target."* This toolkit collects
the agent and tenant state, reads the authoritative per-object reason, and points you at the fix.

The core idea: **a cloud sync "users not provisioning" failure is almost never "cloud sync is
broken."** It is one specific condition — the target already exists from a previous sync method, the
user's OU is outside the configuration's scoping filters, the configuration is not enabled, the job is
quarantined, an object-deletion threshold is blocking export, or a service principal is missing —
producing a symptom (**JoinNotFound / skipped / nothing created**) that looks like a total failure. If
you can name the condition, you can name the fix. The whole toolkit exists to help you name it fast.

## Cloud sync is NOT Connect Sync — this matters

Microsoft ships **two** on-premises-to-Entra synchronization engines, and they fail for different
reasons:

- **Microsoft Entra Connect *cloud sync*** — a **lightweight provisioning agent** installed on a
  domain-joined server; the **cloud service does the heavy lifting**. Configuration lives in the Entra
  admin center. This is what the scenario above uses, and it is what **this toolkit diagnoses**.
- **Microsoft Entra Connect *Sync*** (the older, full "Azure AD Connect" client) — a full
  synchronization engine (the `ADSync` service, the Synchronization Service Manager `miisclient.exe`)
  running on a dedicated server. Different tooling, different logs, different failure modes.

A common trap: an engineer who **last set this up years ago with Connect Sync** applies Connect Sync
habits (the sync scheduler, `Start-ADSyncSyncCycle`, the sync rules editor) to a **cloud sync**
configuration where none of that applies. Cloud sync is driven by the **provisioning service** and its
**synchronization job**, read in the **provisioning logs** — not the ADSync engine. This toolkit keeps
you on the correct engine.

## What "JoinNotFound / skipped" actually means

When cloud sync evaluates a source (AD) object, it runs an ordered pipeline the **provision on demand**
screen shows step by step:

1. **Import** — the object was read from AD.
2. **Determine if in scope** — does the object match the configuration's **scoping filters** (the
   organizational units the configuration is set to synchronize)? *Note: provision on demand
   **ignores** scoping filters (see below); the scheduled cycle does not.*
3. **Match user** — does a **target** object already exist in Entra ID to **join** to (a soft/hard
   match on `userPrincipalName` / `mail` / anchor), or is this a **new** object to **create**?
4. **Determine object action** (Evaluate) — decide **Create**, **Update**, or **Delete**.
5. **Provision** — perform the action against the target.

**JoinNotFound** is a **skip at step 4**: the engine found **no existing target to join** *and* the
object is **not, at that moment, a valid new-provision candidate** — so there is nothing to create and
nothing to update, and the object is **skipped**. Read literally, it means *"I have nothing to do with
this object."* The job of diagnosis is to find out **why** it is neither a join nor a create — almost
always one of the named conditions below.

## A subtlety that trips people up — provision on demand ignores scope

**Provision on demand** runs the pipeline **for the one object you pick, ignoring the configuration's
scoping filters** — so you can run it on a user who is *outside* the configured OUs. That has two
consequences you must hold in mind:

- If **provision on demand skips** an object, the cause is usually **not** scope *for that on-demand
  run* — look at **match/already-exists**, critical-object exclusion, or a stalled job.
- The **scheduled cycle only creates in-scope users.** So an object can provision fine on demand yet
  **never** get created by the recurring cycle because its **OU is not in the scoping filters**. Scope
  is diagnosed against the **scheduled** behaviour, not the on-demand run.

## The conditions this toolkit isolates

1. **The target already exists in Entra ID.** A matching object — commonly a **leftover from a prior
   sync method** (e.g. an earlier Connect Sync deployment) or a **cloud-only** account with the same
   `userPrincipalName` / `proxyAddresses` — makes the evaluate step a soft-match/no-op, so nothing is
   created.
2. **The configuration is not enabled, or the user's OU is not in the scoping filters.** The scheduled
   cycle will not create out-of-scope users. After changing scope or the configuration, you must
   **restart provisioning** to clear watermarks so objects are re-discovered.
3. **Excluded-by-design objects.** `IsCriticalSystemObject` (built-in accounts and groups) and
   replication-victim objects are filtered out by default — testing with one of those looks like a
   failure but is expected.
4. **The job is quarantined.** If calls to the target consistently fail (for example bad admin
   credentials), the synchronization job is **quarantined** and nothing exports until you clear it.
5. **An object-deletion threshold is blocking changes.** Where Connect Sync and cloud sync **coexist**
   (both exporting to one tenant), the accidental-deletion-prevention threshold can block the run.
6. **A missing service principal — `AzureDirectoryServiceAuthorizationFailed`.** If the **"Microsoft
   Entra AD Synchronization Service"** service principal is absent, the agent cannot authorize; sync
   must be re-enabled to recreate it.
7. **Agent health / connectivity.** The **"Microsoft Entra Provisioning Agent"** and **"Microsoft
   Entra Connect Agent Updater"** services must be **Running**, the agent must show **Healthy** in the
   portal, and outbound **80/443** to the documented endpoints must be open.

## The named artifacts this toolkit refers to

Diagnosis is comparison, so the toolkit reuses **exact names** for the objects you supply or inspect.
Reuse these verbatim (they appear in the scripts and the troubleshooting matrix); the en-dash is `–`:

| Artifact | Name |
|---|---|
| The cloud sync configuration | `Cloud Sync – AD to Entra – Configuration` |
| An organizational unit that IS in the scoping filters | `Cloud Sync – In-Scope Users – OU` |
| Pilot / test scope OU | `Cloud Sync – Pilot Scope – Pilot` |
| The domain-joined server running the agent | `Cloud Sync – Provisioning Agent Host` |
| The timestamped diagnostics output folder | `Cloud Sync – Diagnostics – <timestamp>` |

Microsoft's own fixed names are reused verbatim too: the **"Microsoft Entra Provisioning Agent"** and
**"Microsoft Entra Connect Agent Updater"** Windows services, and the **"Microsoft Entra AD
Synchronization Service"** service principal.

## The five diagnostic tools

All five are **read-only**. They observe; they never remediate.

- **`CLDSYNCDX-Collect-Diagnostics.ps1`** — the entry point, run **on the provisioning-agent host**. A
  single on-device collector that snapshots agent-service state, PowerShell execution policy, and proxy
  configuration, then (if the **AADCloudSyncTools** module is present) runs
  `Export-AADCloudSyncToolsLogs` and gathers the agent **Trace** folder, zipping everything to a
  timestamped output folder.
- **`CLDSYNCDX-Check-Agent.ps1`** — focused **agent-health** checks on the host (services Running,
  execution policy sane, outbound 443 reachability, config/proxy present) with **PASS/FAIL** per
  precondition and the exact remedy for each FAIL.
- **`CLDSYNCDX-Get-ProvisioningLog.ps1`** — a Microsoft Graph read-only query of the **provisioning
  logs** for a given AD **ObjectGuid** or **UPN**, printing the latest entries with the **action**,
  **status**, and **skipReason** (e.g. `JoinNotFound`) plus the per-step detail — the **authoritative**
  per-object reason.
- **`CLDSYNCDX-Check-Provisioning.ps1`** — a Microsoft Graph read-only check of the cloud sync
  **synchronization job** (Active / Enabled / **Quarantined** with reason), whether the **"Microsoft
  Entra AD Synchronization Service"** service principal exists, and the org's `onPremisesSyncEnabled` —
  flagging `AzureDirectoryServiceAuthorizationFailed` and object-deletion-threshold symptoms.
- **`CLDSYNCDX-Test-Object.ps1`** — a local **Active Directory** read-only check for one user:
  `IsCriticalSystemObject`, whether its OU is under the operator-supplied in-scope OU DNs, whether its
  UPN suffix is a routable/verified domain, and an advisory on a possible same-UPN/`proxyAddresses`
  object — to catch the excluded / out-of-scope / already-exists conditions.

## Where the vendor boundary sits

This toolkit authors the **AD, agent-host, Entra, and Microsoft Graph** side at exact, click-by-click
detail — that is where your read-only scripts and portal checks live. **Microsoft product internals —
the cloud sync provisioning service pipeline, the exact wording of provisioning-log reason codes, and
the AADCloudSyncTools cmdlet internals — are deferred to Microsoft's official documentation.** The
toolkit tells you *what* the agent, the AD object, and the configuration must present; the remediation
steps live in the owning plane.

## How to use the rest of this toolkit

- **`02-requirements.md`** — the read access and vantage points to have ready before you diagnose.
- **`03-implementation.md` (Diagnostic Workflow)** — the ordered **Collect → Analyze → Remediate →
  Verify** workflow and the **symptom → tool** map. Start here during an incident.
- **`05-testing.md`** — pass/fail gates that confirm the toolkit runs correctly and that a fix actually
  cleared the failing condition.
- **`06-troubleshooting.md`** — the comprehensive **symptom → likely cause → fix** matrix for "users
  skipped / JoinNotFound / not provisioned." This is the heart of the product.
- **`07-best-practices.md`** — repeatable triage habits, evidence collection, and clean escalation.

**Standing constraint for the whole toolkit:** every script and check here is **read-only**.
Diagnostics observe; they never change the AD object, the tenant, the configuration, or the agent. You
decide the fix; the toolkit only tells you where it is. The workflow adapts the category-standard
**Assess → Configure → Pilot → Validate → Expand** model to a diagnostic shape:
**Collect → Analyze → Remediate → Verify.**
