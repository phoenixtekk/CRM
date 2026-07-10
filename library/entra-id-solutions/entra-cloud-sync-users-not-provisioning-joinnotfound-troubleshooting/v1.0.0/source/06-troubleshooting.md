# Troubleshooting — Cloud Sync "Users Skipped / JoinNotFound / Not Provisioned" Symptom → Cause → Fix Matrix

This is the heart of the product: a comprehensive **symptom → likely cause → fix** matrix for
**Microsoft Entra Connect cloud sync** when users are **skipped, not created, or reported
JoinNotFound**. Work top-down within a section; the first cause listed is the most common. Everything
here stays **read-only** on the diagnostic side — the *fix* changes state and is applied in the owning
plane (see `03-implementation.md` Phase 3).

> **Product boundary:** cloud sync's **provisioning-service internals** — the exact pipeline behaviour,
> the full set of provisioning-log reason codes, and the internals of the **AADCloudSyncTools** cmdlets
> — are **deferred to Microsoft's official documentation**. This guide resolves the **agent-host,
> Active Directory, Entra, and Microsoft Graph** side and tells you which condition a symptom points at.

> Reuse names verbatim: **`Cloud Sync – AD to Entra – Configuration`**,
> **`Cloud Sync – In-Scope Users – OU`**, **`Cloud Sync – Pilot Scope – Pilot`**,
> **`Cloud Sync – Provisioning Agent Host`**, and Microsoft's **"Microsoft Entra Provisioning Agent"**,
> **"Microsoft Entra Connect Agent Updater"**, **"Microsoft Entra AD Synchronization Service"**.

---

## §The core symptom — provision on demand shows "User was skipped, JoinNotFound"

**Symptom:** In **Entra Connect → Cloud sync →** the configuration → **Provision on demand**, the steps
show **Import ✓ / Determine if in scope ✓ / Match user ✓**, then **Determine object action (Evaluate)
→ "User was skipped"** with **SkipReason: JoinNotFound** — *"not a newly discovered entry to be
provisioned … nor one with an update to flow to a previously matched target."* `CLDSYNCDX-Get-
ProvisioningLog.ps1` prints the same reason for the object's `ObjectGuid`.

**What it means:** the evaluate step found **no existing target to join** *and* the object is **not a
valid new-provision candidate at that moment** — so there is nothing to create and nothing to update.
JoinNotFound is the *result*; the sections below are the *causes*. Work them in order.

1. **A matching target already exists in Entra ID (most common).** If an object with the same
   `userPrincipalName` / `proxyAddresses` / anchor already exists — commonly a **leftover from a prior
   sync method** (an earlier Entra Connect *Sync* deployment) or a **cloud-only** account — the evaluate
   step resolves to a soft-match/no-op and creates nothing. Run `CLDSYNCDX-Test-Object.ps1` for the
   duplicate advisory and check Entra ID for an existing object with that UPN/proxyAddress.
   **Fix:** reconcile the duplicate — remove or rename the stale cloud object, or let the soft-match
   join it; align `userPrincipalName` / `proxyAddresses` so exactly one target matches. (`Match user ✓`
   on the on-demand screen does **not** mean "matched to a new create"; it means the match step ran.)
2. **The object isn't a valid create candidate for the scheduled cycle (scope).** Provision on demand
   **ignores** scope, so it can evaluate a user the scheduled cycle would never create. If the user's
   OU is **not in the scoping filters** of `Cloud Sync – AD to Entra – Configuration`, the scheduled
   cycle skips it — even though on-demand ran. Run `CLDSYNCDX-Test-Object.ps1 -InScopeOU <dns>`.
   **Fix:** add the user's OU to the configuration's scoping filters (or move the user into
   `Cloud Sync – In-Scope Users – OU`), then **restart provisioning** to clear watermarks.
3. **The object is excluded by design.** `IsCriticalSystemObject = true` (built-in accounts/groups) and
   replication-victim objects are filtered out. Testing with one of those *always* looks like
   JoinNotFound. `CLDSYNCDX-Test-Object.ps1` reports the critical flag.
   **Fix:** test with an ordinary user in a known in-scope OU; the exclusion is intentional.
4. **A stale watermark after a recent change.** If you just changed scope, mapping, or the
   configuration, already-seen objects aren't re-evaluated automatically.
   **Fix:** **restart provisioning** on the configuration so objects are re-discovered.

---

## §Nothing is being created at all (fleet-wide, not one user)

**Symptom:** No users are provisioning; it isn't limited to one object. `CLDSYNCDX-Check-
Provisioning.ps1` shows the job or org state.

1. **⭐ Stale watermark after an earlier quarantine or after a fix — the #1 "healthy but creates
   nothing" cause.** If the job **was quarantined earlier** (or the tenant domain finished verifying
   *after* the first cycle, or scope/mapping changed), cloud sync already **saw and parked** those
   objects and advanced its **watermark** past them. Now that the job is **Healthy**, those users are no
   longer **"newly discovered"** — so **every** account re-evaluates to **JoinNotFound** and nothing is
   created. **Clearing the quarantine does NOT fix this** — it doesn't re-open already-seen objects (and
   if it's not currently quarantined, *Clear quarantine* is greyed out entirely). **Fix:** on the
   configuration/agent page, click **Restart sync** — a *full* restart that resets **watermarks +
   escrows + quarantine**, so every in-scope object is re-discovered as new. Graph equivalent:
   `POST /servicePrincipals/{spId}/synchronization/jobs/{jobId}/restart` resetting
   `Watermarks,Escrows,Quarantine`. Then re-run **Provision on demand** on one user → expect
   **action = Create**. (This is the classic pattern when someone reports "it was quarantined earlier,
   now it shows OK, but the same JoinNotFound appears for all users.")
2. **The configuration is not Enabled.** A configuration that was created but left disabled never runs
   the scheduled cycle. **Fix:** enable `Cloud Sync – AD to Entra – Configuration`.
3. **The synchronization job is quarantined.** If calls to the target consistently fail (commonly bad
   admin credentials for the agent, or a persistent tenant-side error), the job is **quarantined** and
   nothing exports. `CLDSYNCDX-Check-Provisioning.ps1` reports the quarantine and its reason/escrow.
   **Fix:** resolve the underlying auth failure (e.g. `Repair-AADCloudSyncToolsAccount`), then
   **Restart sync** (not just *Clear quarantine* — see cause 1). Clearing quarantine without fixing the
   underlying error just re-quarantines.
4. **New-tenant domain move — verify the domain first.** If you moved a custom domain from an old tenant
   into this new tenant (removing it from the old one), confirm it is **Verified** in the new tenant
   (**Entra ID → Settings → Domain names**) *before* expecting creates — users' UPN suffix must be a
   verified domain at evaluation time. If it verified only after the first (parked) cycle, do the
   **Restart sync** in cause 1 so the now-valid users are re-discovered.
3. **An object-deletion threshold is blocking the run.** In **Connect + cloud sync coexistence** (both
   exporting to one tenant), Entra's accidental-deletion-prevention threshold can block the export.
   **Fix:** investigate why the run wants to change that many objects, then
   `Disable-AADCloudSyncToolsDirSyncAccidentalDeletionPrevention -tenantId <tid>` for the run and
   **re-enable** the safeguard afterward.
4. **`AzureDirectoryServiceAuthorizationFailed` — the sync service principal is missing.** If the
   **"Microsoft Entra AD Synchronization Service"** service principal is absent, the agent can't
   authorize and the whole job fails. `CLDSYNCDX-Check-Provisioning.ps1` flags the missing SP and reads
   `onPremisesSyncEnabled`. **Fix:** re-enable directory sync to recreate the SP —
   `PATCH /organization/<tid> { "onPremisesSyncEnabled": true }`.
5. **The agent is unhealthy or offline.** If the agent isn't running or can't reach the service, no
   cycle runs — see §Agent health.

---

## §Agent health — the provisioning agent isn't working

**Symptom:** The agent shows **not healthy** (not green) in **Entra Connect → Cloud sync → agents**, or
sync recently stopped. `CLDSYNCDX-Check-Agent.ps1` shows the first FAIL on the host.

1. **A required service is stopped.** The **"Microsoft Entra Provisioning Agent"** and **"Microsoft
   Entra Connect Agent Updater"** services must both be **Running**. **Fix:** start the stopped service
   (and set it to Automatic); if it won't stay running, collect the Trace folder with
   `CLDSYNCDX-Collect-Diagnostics.ps1` and review.
2. **Outbound 80/443 blocked.** The agent needs outbound **80/443** to the documented Microsoft
   endpoints. `CLDSYNCDX-Check-Agent.ps1` tests a sample 443 endpoint. **Fix:** open the documented URLs
   through the proxy/firewall from `Cloud Sync – Provisioning Agent Host`.
3. **Proxy misconfiguration.** If the host uses a proxy, the agent must be configured for it. The check
   reports whether a proxy/agent config is present. **Fix:** configure the agent's proxy per Microsoft
   guidance and restart the agent services.
4. **Execution policy blocks the tooling.** An over-restrictive (or `Unrestricted`, which is a
   different risk) execution policy can interfere with running the diagnostic/AADCloudSyncTools scripts.
   The check reports the policy. **Fix:** run the tools with `-ExecutionPolicy Bypass` for the session,
   or set a workable per-process policy; don't leave the machine `Unrestricted`.
5. **Agent version out of date.** A very old agent can misbehave; the **Agent Updater** service keeps it
   current. **Fix:** confirm the updater service is running, or reinstall the current agent — **deferred
   to Microsoft documentation** for the install steps.

---

## §Scope & matching — the object is not a create candidate

**Symptom:** One user (or one OU's users) never appears in Entra ID, though the agent is healthy and
other users provision.

1. **OU not in the scoping filters.** The single most common scope cause: the user's OU isn't included
   in the configuration's scoping filters, so the **scheduled cycle** never creates them (even though
   provision on demand can). Run `CLDSYNCDX-Test-Object.ps1 -InScopeOU <dns>`.
   **Fix:** add the OU to the scope (or move the user into `Cloud Sync – In-Scope Users – OU`), then
   **restart provisioning**.
2. **Watermark not cleared after a scope change.** You added the OU but didn't restart — objects already
   seen aren't re-evaluated. **Fix:** restart provisioning.
3. **Non-routable / unverified UPN suffix.** A user whose UPN suffix is a non-routable domain (e.g.
   `.local`) or a domain not **Verified** in the tenant can fail to provision cleanly or land on the
   `onmicrosoft.com` fallback. `CLDSYNCDX-Test-Object.ps1` flags a non-routable/unverified suffix.
   **Fix:** add and verify the public domain in Entra, add the matching UPN suffix in AD, and update the
   user's UPN.
4. **Duplicate attribute conflict.** Two AD objects (or an AD object and a cloud object) sharing a
   `userPrincipalName` or `proxyAddresses` value cause match ambiguity and a skip.
   **Fix:** resolve the duplicate so exactly one object holds the value.
5. **Group/contact vs user expectations.** Cloud sync provisions the object types the configuration is
   set for; confirm you're testing the right object type for the configuration's mapping.

---

## §Already-exists — the "prior sync method" trap

**Symptom:** The user clearly exists in AD and is in scope, but cloud sync creates nothing; the object
already has a counterpart in Entra ID.

1. **Leftover from an earlier Entra Connect *Sync* deployment.** If this tenant was previously synced
   with the older Connect Sync client, cloud-side objects (possibly still marked on-prem-synced) already
   exist. Cloud sync matches to them and does nothing new — exactly the scenario behind an engineer who
   "last set this up years ago with a different sync method." **Fix:** decide the authority: retire the
   old objects/soft-match cleanly, or align anchors so cloud sync owns them; confirm only one sync engine
   is authoritative for a given object.
2. **Cloud-only account with the same UPN/proxyAddress.** A manually-created cloud user collides with
   the AD user on `userPrincipalName` / `proxyAddresses`. **Fix:** reconcile (convert/soft-match or
   remove the cloud-only object), then re-run provision on demand.
3. **Object was deleted but is in the recycle bin.** A soft-deleted Entra object retaining the UPN can
   block a fresh create. **Fix:** permanently remove or restore the soft-deleted object as appropriate,
   then re-provision.

---

## §Coexistence & thresholds — Connect Sync and cloud sync together

**Symptom:** Both Connect Sync and cloud sync export to the same tenant and changes are blocked or
inconsistent.

1. **Accidental-deletion threshold tripped.** A large delta (from a scope change or a mis-filter) trips
   the export deletion safeguard and blocks the run. **Fix:** confirm the change is intended, then
   temporarily `Disable-AADCloudSyncToolsDirSyncAccidentalDeletionPrevention -tenantId <tid>`, let the
   run complete, and **re-enable** the safeguard.
2. **Two engines contending for the same objects.** If Connect Sync and cloud sync both target
   overlapping objects, they contend. **Fix:** scope each engine to a disjoint set of objects/OUs so
   only one owns each object; coexistence is supported but must be scoped deliberately.

---

## §Reading the authoritative reason — provisioning logs

The **provisioning logs** are the source of truth. Read them by the AD **`ObjectGuid`** — the reliable
key — rather than by display name.

1. **Use the ObjectGuid.** `CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid <guid>` returns the object's
   entries with **action**, **status**, **skipReason**, and step detail. In the portal:
   **Entra Connect → Cloud sync → Logs**, filter by the object.
2. **No log entry for the object.** If nothing appears, the object was never evaluated — it's likely
   **out of scope** for the scheduled cycle (run provision on demand to force an evaluation and generate
   a log entry), or the job isn't running (see §Nothing is being created).
3. **The reason isn't JoinNotFound.** The tool prints whatever the real reason is (a different skip
   reason, a failure with an error code such as `AzureDirectoryServiceAuthorizationFailed`, or a
   success). Match the printed reason to the section above.

---

## §Script / tooling issues

1. **`Connect-MgGraph` fails or lacks scopes.** Install the SDK (`Install-Module Microsoft.Graph -Scope
   CurrentUser`) and consent to the read scopes the script header lists
   (`AuditLog.Read.All`, `Directory.Read.All`, `Synchronization.Read.All`).
2. **AADCloudSyncTools not found on the host.** `CLDSYNCDX-Collect-Diagnostics.ps1` still gathers the
   services state and the Trace folder without it; install the module
   (`Install-Module AADCloudSyncTools`) and `Connect-AADCloudSyncTools` for the full log export.
3. **Access denied reading the Trace folder or services.** Run the host-side scripts **elevated** (R2);
   they're read-only, but elevation is needed for visibility.
4. **The ActiveDirectory module is missing for the object test.** Install RSAT / the ActiveDirectory
   module and run `CLDSYNCDX-Test-Object.ps1` on the agent host or a domain member.
5. **The synchronization job or SP can't be found.** Cloud sync's job lives on the provisioning service
   principal for the configuration; `CLDSYNCDX-Check-Provisioning.ps1` searches for it. If your tenant
   names or structures it differently, pass the service principal id explicitly and confirm the
   configuration exists under **Entra Connect → Cloud sync**.

---

## When to stop diagnosing and escalate to Microsoft

Diagnosis here is read-only by design. When the **agent host, Active Directory, scope, matching, and
job** side is confirmed clean (the checks pass, the object is in scope, no duplicate, the job is Active
and not quarantined) but provision on demand still reports **JoinNotFound** or a create still doesn't
happen, treat it as a **cloud sync service issue** and open a Microsoft support case. Hand over: the
`CLDSYNCDX-Collect-Diagnostics.ps1` bundle (agent services + Trace + AADCloudSyncTools export), the
`CLDSYNCDX-Get-ProvisioningLog.ps1` output for the object's `ObjectGuid`, the
`CLDSYNCDX-Check-Provisioning.ps1` job/SP/org state, and a statement that the on-prem/scope/match side
is clean. A complete package turns a multi-round case into a single decisive one.
