# 6. Troubleshooting — Cloud-App DLP (Defender for Cloud Apps)

Symptom-first fixes for the failures you actually hit extending DLP to third-party cloud apps. Most problems
are one of: a **file policy** not matching (connector/scan), a **session policy** not engaging (Conditional
Access App Control routing), too many false positives, or matches that raise no alert.

---

## File policy (data at rest, via API connector)

**A file policy matches nothing even though the file clearly contains sensitive data.**
- Confirm the app is **connected and healthy** — **Cloud apps → App connectors** shows the status. A file
  policy is **inert until the app's API connector is connected** and its **initial scan** has completed. Run
  `DLPCLOUD-ConnectorReadiness.ps1 -TargetApp <app>`.
- **At-rest scanning is periodic, not instant** — new/changed files can take time to be scanned and matched.
  Allow for scan latency before concluding it's broken.
- Check the policy **filters**: app, folder/site, sharing level, and the **content** filter (SIT confidence/
  instance count or sensitivity label). Too-strict filters suppress matches — loosen and re-test.
- Confirm the SIT/label the policy references actually exists — `DLPCLOUD-FilePolicy.ps1 ... -WhatIf` reports
  VALID/MISSING for each.

**The governance action (remove sharing / apply label / quarantine) didn't take effect.**
- Confirm the governance action is **enabled** on the policy (during pilot it is deliberately **alert-only**
  — that's expected; enable the action in Phase 5).
- Confirm the connector's **permissions** allow that action for that app — some actions require broader app
  admin consent; re-authorize the connector if needed.
- Governance runs on matched files going forward and on the next scan — allow time.

## Session policy (real time, via Conditional Access App Control)

**A session policy never engages (no monitor/block on download/upload).**
- The session plane works **only** on sessions Entra routes to the proxy. Confirm a **Conditional Access
  policy** with **Session → Use Conditional Access App Control** targets the user and app, and that it is
  **On** (not still report-only) for enforcement. `DLPCLOUD-ConnectorReadiness.ps1` and
  `DLPCLOUD-SessionScope.ps1` report this.
- Confirm the app is **onboarded** under **Cloud apps → Conditional Access App Control apps** and is a
  **supported app** for session control — some apps, **native/desktop clients**, and activities are not
  proxy-controllable. Test in a **browser** session first.
- The user must sign in **through the proxy** — an already-established session may not be routed. Sign out/in
  or start a fresh session.

**Session control breaks the app / users report errors in the proxied session.**
- Some apps have known session-control compatibility limits. Verify against Microsoft's featured/supported-app
  list; if the app isn't fully supported, fall back to **access policy** (allow/block) or **file policy**
  (at rest) instead of fine-grained session actions.
- Roll back instantly by setting the CA policy to **report-only** (`DLPCLOUD-SessionScope.ps1 -WhatIf` shows
  the rollback step) — no data change.

**Everything is enforcing tenant-wide during what should be a pilot.**
- The CA policy assignment is too broad. `DLPCLOUD-SessionScope.ps1` flags a policy enforcing for **All
  users** — narrow the assignment to `MDCA Pilot Ring – Stage1` and set State back to report-only until
  ready to expand.

## False positives (the adoption killer)

**Users are blocked/governed on legitimate, non-sensitive content.**
- Export matches with `DLPCLOUD-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise SIT confidence** (medium→high) and/or **instance count** so single/low-confidence hits don't fire.
- **Narrow the filter** — target specific apps/folders/sharing levels/owners rather than "all files".
- **Match on a sensitivity label** where it's more precise than a broad SIT.
- Add a targeted **exclusion** (owner/site/service account) where justified — narrowly, with a documented
  reason. Re-measure after each change — don't stack changes blind.

## Alerts / incident handling

**Policy matches occur but no alert appears / no one is notified.**
- Confirm the policy has **Create an alert** enabled. Check **Cloud apps → Alerts** and the **Microsoft
  Defender portal** incidents. `DLPCLOUD-Report.ps1` reads Cloud-Apps alerts via the Graph security API.
- Confirm the **triage owner/queue** (`MDCA Alerts – Triage – Operations`) exists and, if forwarding to
  **SIEM/Sentinel**, that the connector is healthy (Req 2.7).

**The report script returns no matches.**
- **Latency/dwell:** MDCA alerts and at-rest scans take time; widen `-Days` and re-run.
- Confirm your account holds **SecurityEvents.Read.All** (Graph) for the alerts read, and the right MDCA/
  Defender read role.
- Freshly created policies simply may not have matched yet.

## Connectivity / tooling

**`Connect-MgGraph` / `Connect-IPPSSession` or a cmdlet fails.**
- Ensure the **Microsoft.Graph** and **ExchangeOnlineManagement** modules are installed/updated and you're
  using a **modern-auth / MFA-capable** admin.
- Confirm the required **Graph scopes** (`Policy.Read.All`, `SecurityEvents.Read.All`,
  `InformationProtectionPolicy.Read`) are consented, and that your account holds the matching MDCA/compliance
  role — a missing role surfaces as access denied or empty results.

**The MDCA REST calls in the scripts are skipped or fail.**
- The REST calls are **optional** — they run only when `$env:MDCA_API_TOKEN` **and** `-McasUrl` are set. If
  skipped, that's expected; the Graph/S&C paths still work.
- If they fail, verify the **portal URL** (your tenant's MDCA URL) and that the **API token** is valid and
  has the needed scope. The token is read from the environment only — never hardcode it.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf`/spec-only by default**. `DLPCLOUD-FilePolicy.ps1` never
  creates an MDCA policy (there is no supported creation cmdlet) — it only emits a spec. The safe recovery
  for any enforcement is always to set the CA policy back to **report-only** / the session policy to
  **Monitor only** in the portal (instant, no data change).

**A file was quarantined / labeled / trashed and needs reversing.**
- **Quarantine** is recoverable from the app's admin quarantine location (or the user quarantine) — restore
  from there.
- An **applied sensitivity label** can be changed by a privileged user/admin per your label policy.
- **Trash** may be recoverable from the app's recycle bin within its retention window — act promptly. Prefer
  reversible governance (remove-sharing, apply-label, quarantine) over trash for this reason.

---

### Fast triage table

| Symptom | First check |
|---|---|
| File policy matches nothing | Connector connected/healthy + scan done; filters; SIT/label exists; scan latency |
| Governance action didn't apply | Action enabled (not still alert-only); connector permissions; allow time |
| Session policy never engages | CA App Control routing On; app onboarded & supported; browser session; fresh sign-in |
| Session control breaks app | App not fully supported — fall back to access/file policy; roll back to report-only |
| Enforcing tenant-wide in pilot | Narrow CA assignment to the pilot ring; set report-only (`DLPCLOUD-SessionScope.ps1`) |
| Too many false positives | Raise confidence/instance count; narrow app/folder/sharing filter; match on label; exclude |
| No alert on match | "Create an alert" on policy; Cloud apps → Alerts; triage owner; SIEM connector |
| Report returns nothing | Latency/dwell; `SecurityEvents.Read.All`; role; widen -Days |
| Cmdlet/connect fails | Modules updated, modern auth, Graph scopes + MDCA role |
| MDCA REST skipped/failed | Optional — needs env token + -McasUrl; verify portal URL + token scope |
