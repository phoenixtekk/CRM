# 6. Troubleshooting — OneDrive for Business DLP (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing DLP for OneDrive. Most problems are
one of: a policy not matching, the *shared-externally* condition not firing, too many false positives, or
matches that raise no alert.

---

## Policy / detection

**A OneDrive DLP policy matches nothing even though the content clearly contains sensitive data.**
- Confirm the policy is actually **enabled and in a mode that evaluates** — a *disabled* policy does
  nothing; a **simulation** policy evaluates and logs but does not restrict. Check with
  `DLPOD-Discovery.ps1` (Mode column) or `DLPOD-Validate.ps1`.
- Confirm the policy actually **targets the OneDrive location** (`OneDriveLocation`) — a policy scoped
  only to SharePoint/Exchange won't see OneDrive content. `DLPOD-Validate.ps1` flags this.
- Check the **instance count and confidence** on the rule — if it requires ≥10 matches at High
  confidence and your test has 1, it correctly won't fire. Lower the threshold for testing, or add more
  sample instances.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (and
  longer for some content)** to take effect, and OneDrive content is scanned on a crawl cycle. Wait
  before concluding it's broken.
- Confirm the target account isn't in an **exclusion** and, if you scoped a pilot ring
  (`OneDriveSharedByMemberOf`), that the test user is in that group.

**A custom SIT never matches.**
- Test the SIT's **regex + keywords** in the SIT wizard's **Test** step with known-matching text. A too-
  strict regex, wrong **character proximity**, or a required keyword that isn't present will suppress all
  matches. Loosen and re-test incrementally.

**Matches appear in simulation but nothing is restricted.**
- That is **correct** — simulation logs what *would* happen without enforcing. To restrict, move the
  policy to **enforce** for the pilot ring (Implementation Phase 4). If you expected restriction, you're
  still in simulation.

## External-share condition

**The external-share rule doesn't fire when I share a sensitive file.**
- Confirm the rule carries the **AccessScope = NotInOrganization** condition (the *shared with people
  outside my organization* condition) — `DLPOD-Validate.ps1` reports this as `ExternalShareScope`. If it
  reads False, the rule is an at-rest rule only.
- Confirm the share is genuinely **external** — an internal-only share (or a link restricted to specific
  internal people) correctly does **not** match the outside-org condition.
- **"Anyone with the link"** shares depend on the **tenant permitting anonymous links**. If the tenant
  sharing setting blocks anonymous links entirely, the anyone-link path may not be exercisable to test —
  test with an external guest share instead. Check the sharing signal with `DLPOD-Scope.ps1`.
- Allow for **evaluation latency** — the sharing event must be processed before the rule acts.

**DLP isn't stopping "anyone" links even in enforce mode.**
- DLP acts on **sensitive** shares matched by the rule; a share of non-sensitive content is out of scope
  by design. Broad control over anonymous links is a **tenant sharing setting** (SharePoint admin center
  → Policies → Sharing), complementary to DLP (Req 2.3) — tighten it there if you need a blanket limit.

## False positives (the adoption killer)

**Users are getting policy tips on legitimate, non-sensitive content.**
- Export matches with `DLPOD-Report.ps1 -CsvPath ...`, classify TP/FP, and identify the driver.
- **Raise confidence** (medium→high) and/or **instance count** on the at-rest rule so single/low-
  confidence hits don't fire. (Keep the external-share rule sensitive — even one instance shared out
  matters.)
- Add **supporting keywords/proximity** to custom SITs so context is required.
- For a built-in SIT that over-matches your internal identifiers, move that category to **Exact Data
  Match** so only your real data matches.
- Add a targeted **exception** where justified (specific internal service account/site) — narrowly, with
  a documented reason.
- Re-simulate after each change and re-measure — don't stack multiple changes blind.

## Alerts / incident handling

**Policy matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data
  loss prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **audit logging is enabled** in the tenant — the report script and Activity Explorer rely on
  it.
- Confirm the **triage owner/queue** (`DLP Alerts – OneDrive – Triage`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.7).

**The report script returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run.
- Freshly created policies need **dwell time** — there may simply be no matches yet, and OneDrive
  content is scanned on a crawl cycle.
- Confirm **audit logging is on** and your account has the **View-Only DLP / audit** role.

## Connectivity / tooling

**`Connect-IPPSSession` or a DLP cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin.
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management) — a missing role surfaces as "cmdlet not recognized" or
  access denied.

**The sharing signal in `DLPOD-Scope.ps1` is blank / skipped.**
- The tenant sharing signal is read from **Microsoft Graph** (`/admin/sharepoint/settings`) and needs
  the **SharePointTenantSettings.Read.All** scope; the script **skips it gracefully** if Graph isn't
  connected or the scope isn't consented. Verify the setting directly in the SharePoint admin center
  (Policies → Sharing) — it is context only, not required for the DLP policy to work.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`. If a change
  landed, it was committed intentionally — the config helper never leaves a policy in **enforce**, so the
  safe recovery is always to set the policy back to **simulation** in the portal (one setting, no data
  change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| Policy matches nothing | Mode (disabled/sim), OneDrive targeted, instance count/confidence, propagation time, scope/exclusion |
| Custom SIT never fires | Test regex+keywords+proximity in the SIT wizard |
| Nothing restricted | Still in **simulation** — that's expected; enforce the ring to restrict |
| External-share rule not firing | AccessScope=NotInOrganization present, share is truly external, tenant allows the link type |
| "Anyone" links not stopped | DLP acts on *sensitive* shares; blanket anonymous-link limits are a tenant sharing setting |
| Too many false positives | Raise confidence/instance count, add keywords/EDM, exceptions, re-simulate |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Sharing signal blank | Graph scope SharePointTenantSettings.Read.All / check SharePoint admin center |
| Cmdlet/connect fails | Module updated, modern auth, correct DLP role |
