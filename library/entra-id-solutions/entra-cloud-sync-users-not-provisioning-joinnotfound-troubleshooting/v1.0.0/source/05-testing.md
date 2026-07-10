# Testing — Confirming the Toolkit and the Fix

Two things get tested here. First, that the **toolkit itself runs correctly** — it must read a
**known-good** object as provisioning and a **known-bad** object (the JoinNotFound user) as skipped,
so you can trust its verdicts. Second, that a **fix actually cleared** the failing condition — the
decisive test is that, after remediation, **provision on demand creates the user** and the
**provisioning log shows action = Create**. Each check has an explicit **pass/fail gate**. Everything
here is **read-only** — you observe; you never force a state.

> Reuse names verbatim: **`Cloud Sync – AD to Entra – Configuration`**,
> **`Cloud Sync – In-Scope Users – OU`**, **`Cloud Sync – Pilot Scope – Pilot`**,
> **`Cloud Sync – Provisioning Agent Host`**, and Microsoft's **"Microsoft Entra Provisioning Agent"**,
> **"Microsoft Entra Connect Agent Updater"**, **"Microsoft Entra AD Synchronization Service"**.

## Test matrix overview

| # | Test | Where | Pass gate |
|---|---|---|---|
| T1 | Collector runs and writes a bundle | Agent host | Bundle written; both agent services named with state |
| T2 | Agent-health check is accurate | Agent host | Services Running / policy / 443 / proxy verdicts match reality |
| T3 | Provisioning-log read returns the reason | Operator workstation | The object's latest action/status/skipReason printed (JoinNotFound seen on the bad object) |
| T4 | Job / SP / org check is accurate | Operator workstation | Job Active/quarantine, SP present, `onPremisesSyncEnabled` verdicts match the portal |
| T5 | Object test classifies correctly | Domain member | Critical / in-scope / UPN-routable / duplicate-advisory match the AD facts |
| T6 | Known-good object reads as provisioning | Reference user | Provision on demand shows Create/Update; log agrees |
| T7 | Known-bad object reads as skipped | JoinNotFound user | Provision on demand shows "User was skipped / JoinNotFound"; the tools name the cause |
| T8 | Post-fix re-run provisions the user | Fixed user | Provision on demand = **Create**; log shows action=Create; user in Entra ID |

---

## T1 — Collector runs and writes a bundle
**Steps:** On `Cloud Sync – Provisioning Agent Host`, run
`CLDSYNCDX-Collect-Diagnostics.ps1 -OutFolder .\CloudSyncDiag` elevated.
**PASS:** The console shows the two agent service states and a timestamped
`Cloud Sync – Diagnostics – <timestamp>` zip/folder is written (with the Trace folder, and the
AADCloudSyncTools export if the module is present).
**FAIL:** The script errors or can't read the Trace folder / services → run elevated (R2) and re-test.

## T2 — Agent-health check is accurate
**Steps:** Run `CLDSYNCDX-Check-Agent.ps1` on the host and compare to `services.msc` and a manual
reachability test.
**PASS:** The Running/stopped, execution-policy, outbound-443, and proxy verdicts match what the host
actually shows.
**FAIL:** A verdict disagrees with reality (e.g. reports a service stopped that is running) → confirm
elevation and re-test.

## T3 — Provisioning-log read returns the authoritative reason
**Steps:** Run `CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid <bad-object-guid>` for the user that is
skipped.
**PASS:** The tool prints the latest provisioning entry with its **action**, **status = skipped**, and
**skipReason = JoinNotFound** plus the Import/Scope/Match/Evaluate step detail — matching what
**Entra Connect → Cloud sync → Logs** shows for that object.
**FAIL:** No entries returned for an object you know was evaluated → confirm the `ObjectGuid` is
correct and the Graph scopes (`AuditLog.Read.All`) are consented; try `-UserPrincipalName`.

## T4 — Job / SP / org check is accurate
**Steps:** Run `CLDSYNCDX-Check-Provisioning.ps1` and compare to **Entra Connect → Cloud sync →** the
configuration's status and agent health.
**PASS:** The job **Active/Enabled/Quarantined** verdict, the **"Microsoft Entra AD Synchronization
Service"** SP present/absent verdict, and `onPremisesSyncEnabled` match the portal.
**FAIL:** A verdict disagrees with the portal → confirm the `Synchronization.Read.All` /
`Directory.Read.All` scopes and that you targeted the correct configuration/SP.

## T5 — Object test classifies correctly
**Steps:** Run `CLDSYNCDX-Test-Object.ps1 -Identity <user> -InScopeOU <in-scope-DNs>` against a known
in-scope normal user and, separately, a built-in account.
**PASS:** The normal user reports **not critical**, **in scope**, **UPN routable**; the built-in
account reports **`IsCriticalSystemObject = true` (excluded by design)**. The duplicate advisory
matches whether a same-UPN object exists.
**FAIL:** A classification disagrees with the AD facts (`Get-ADUser … -Properties
IsCriticalSystemObject,proxyAddresses,distinguishedName`) → reconcile the supplied in-scope OU DNs.

## T6 — Known-good object reads as provisioning (no false positives)
**Steps:** For a user that provisions correctly, run **provision on demand** in the portal and
`CLDSYNCDX-Get-ProvisioningLog.ps1` for the same object.
**PASS:** Provision on demand shows **Create** (first time) or **Update** (already joined), and the log
agrees — confirming the tools read a working object as working.
**FAIL:** The tools report skipped on a user that is actually in Entra ID → confirm you targeted the
right object and that the tenant object is the one cloud sync owns (`onPremisesSyncEnabled`).

## T7 — Known-bad object reads as skipped (no false negatives)
**Steps:** For the JoinNotFound user, run **provision on demand** and the toolkit (Get-ProvisioningLog
+ the relevant Analyze branch).
**PASS:** Provision on demand shows **Import ✓ / In scope ✓ / Match ✓ → Evaluate: "User was skipped",
JoinNotFound**, and the toolkit names the underlying cause (already-exists / out-of-scope for the
scheduled cycle / critical object / quarantine).
**FAIL:** The toolkit reports all clean on a user that clearly isn't provisioning → the cause is beyond
the checks covered (escalate with the collected bundle and the provisioning-log output).

## T8 — Post-fix re-run provisions the user (the decisive test)
**Steps:** After remediating (Phase 3), run **provision on demand** for the user again, then
`CLDSYNCDX-Get-ProvisioningLog.ps1 -ObjectGuid <guid>` and `CLDSYNCDX-Check-Provisioning.ps1`.
**PASS:** Provision on demand's **Evaluate action = Create** (or **Update**), the provisioning log
shows **action = Create/Update** (no longer skipped/JoinNotFound), the job is **Active/Enabled and not
quarantined**, and the **user now exists in Entra ID** with the correct UPN. For a scope fix, a
scheduled cycle creates the previously out-of-scope user.
**FAIL:** Still skipped → return to the matching branch in `03-implementation.md` /
`06-troubleshooting.md`.

---

## Overall exit criteria
The toolkit passes T1–T7 (it reads a known-good object as provisioning and the known-bad object's true
skip reason), and for a closed incident **T8** confirms provision on demand now creates the user, the
provisioning log shows **action = Create**, and the user is present in Entra ID. Record results against
each gate before closing.
