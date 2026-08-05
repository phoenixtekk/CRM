# 7. Best Practices — ServiceNow ↔ Microsoft Intune Integration (Device Inventory & CMDB Sync)

## Identity & credentials
- **Dedicated, named app registration.** Use one app (`SVC – ServiceNow CMDB – Intune Read`) for this
  feed only — never a shared or personal app — so it is auditable and independently revocable.
- **Least privilege, read-only.** Grant only the four read scopes the feed needs. Never grant
  `…ReadWrite.All` or `…PrivilegedOperations.All`. A CMDB feed must not be able to change Intune.
- **Track secret expiry.** A silently expired client secret is the #1 cause of a dead feed. Record the
  expiry, set a renewal reminder, and prefer a **certificate** credential where the connection
  supports it. Rotate additively (new secret → update ServiceNow → remove old).
- **Store the secret in a vault**, not in a ticket, wiki, or script.

## Reconciliation & CMDB hygiene
- **Serial number is the anchor.** Make serial number the shared IRE identifier across **all** device
  discovery sources (Intune, Workspace ONE, SCCM, Discovery) so devices reconcile onto one CI. Devices
  with no serial cannot reconcile by serial — surface them (coverage report) and handle separately.
- **Register Intune as a discovery source** and keep the out-of-box hardware identifier — don't invent
  a bespoke identifier that only the Intune feed uses.
- **Let IRE do the matching.** Route the import through IRE (Store connector does this) rather than a
  naive coalesce, so multi-source reconciliation and CI class precedence behave correctly.
- **Don't overwrite authoritative fields blindly.** Decide, per field, whether Intune or another
  source is authoritative (e.g. Intune for compliance/last-check-in; procurement/HAM for
  location/cost) so the feed enriches rather than clobbers.

## Scope & scheduling
- **Import only what you'll use.** Enable the device stream first; add the app stream only if the
  service desk/asset processes consume app inventory — the detected-apps dataset is large.
- **Daily is usually enough.** Match the schedule to how fresh the CMDB must be; more frequent runs
  cost Graph calls and instance load for little benefit on inventory data.
- **Pilot before fleet.** Always validate a pilot scope (Test 1–8) before widening to the whole fleet.

## Workspace ONE transition
- **Run both feeds in parallel**, reconcile on the shared serial identifier, and only **retire the
  Workspace ONE schedule** once the Intune feed's coverage matches or exceeds it (coverage report).
- **The CI is the constant.** During cutover the device CI persists; only its discovery source changes
  from Workspace ONE to Intune. Don't delete and recreate CIs.
- **Keep the boundaries clean:** re-establishing the *feed* (this solution) is separate from the
  *device migration* (WS1PROG) and from *license reconciliation* (SNOWSAM/SWDISC).

## Operations
- **Watch the import/data-stream logs** for transform and IRE errors after each run; a rising error
  count is an early warning.
- **Alert on staleness.** If the CMDB last-updated stops advancing, treat it as an incident — usually
  an expired secret, revoked consent, or a paused schedule.
- **Re-run `SNOWINT-Validate-Sync.ps1` periodically** (not just at go-live) to keep duplicates at zero
  and catch drift.
- **Document the design** — app ID, scopes, connection name, CMDB classes, identifier rule, schedule —
  so the next admin can operate it.

## Government / sovereign cloud
- Use the **`.us` Graph and sign-in endpoints** end to end for GCC High / DoD; never mix Commercial
  and sovereign endpoints. Run the scripts with `-Cloud USGov` / `USGovDoD`. **Verify for GCC High**
  that the connector release supports the sovereign endpoint before committing to the Store connector.
