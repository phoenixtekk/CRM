# 6. Troubleshooting — Azure Monitor & Log Analytics: Foundation, Alerts & Dashboards

Symptom → root cause → fix for the failures you are most likely to hit. Re-run **`OBSAZMON-Validate.ps1`**
and **`OBSAZMON-Report.ps1`** after each fix to confirm. Work on the **pilot** first.

## No telemetry in the workspace / tables empty
- **Symptom:** `Heartbeat` or resource-log queries return nothing for pilot resources.
- **Cause:** No diagnostic setting on the resource (policy not remediated for the pilot), the DCR isn't
  associated / AMA not installed, or you are querying too soon (ingestion latency).
- **Fix:** Confirm the pilot resources have a **diagnostic setting → `log-obsazmon-platform`** (portal:
  resource → Diagnostic settings; or `OBSAZMON-Report.ps1`). For VMs, confirm the **Azure Monitor
  Agent** extension is present and the VM is **associated** to `dcr-obsazmon-vminsights`. Allow a few
  minutes for first ingestion. Verify you are querying the **right workspace**.

## Policy assigned but nothing is being deployed/remediated
- **Symptom:** `OBSAZMON-Policy-Diagnostics-Subscription` shows resources non-compliant but no
  diagnostic settings get created.
- **Cause:** Enforcement is **DoNotEnforce** (by design at first), **no remediation task** has run, or
  the assignment's **managed identity lacks roles**.
- **Fix:** This is expected while staged. To act: create a **remediation task** (scoped to the pilot
  first), ensure enforcement is **Enabled** for that scope, and confirm the assignment's **system-assigned
  managed identity** holds **Monitoring Contributor** + **Log Analytics Contributor** at scope (§2.4).
  Re-assign with `--location` if no identity was created.

## Metric alert never fires
- **Symptom:** CPU clearly high on a pilot VM but `OBSAZMON-Alert-VMCPUHigh-Pilot` stays quiet.
- **Cause:** Wrong **scope/resource**, threshold/aggregation/window too lax, the rule is **disabled**,
  or the metric namespace is wrong for the resource type.
- **Fix:** Confirm the rule's **scope** includes the pilot VM, the **signal** is `Percentage CPU` with a
  sensible **aggregation** (Avg/Max) and **evaluation window**, and the rule is **Enabled**. Lower the
  threshold briefly to force a fire, then reset.

## Log (scheduled query) alert never fires
- **Symptom:** A pilot VM stopped reporting but `OBSAZMON-Alert-HeartbeatMissing-Pilot` didn't fire.
- **Cause:** The KQL query/threshold/time-window doesn't match reality, or the alert's evaluation
  frequency is longer than your patience.
- **Fix:** Run the alert's KQL manually in **Monitor → Logs** and confirm it returns rows for the silent
  VM; align the **threshold** (e.g. `count == 0` over the last N minutes) and **frequency** to the
  heartbeat interval. Check the workspace the rule targets.

## Notifications don't arrive
- **Symptom:** Alert shows "fired" but no email/Teams/Slack/PagerDuty message.
- **Cause:** Action group has the wrong/expired **webhook URL** or **integration key**, email caught in
  spam, or the alert isn't linked to `OBSAZMON-AG-Platform-Ops`.
- **Fix:** Use the action group's **Test** to send to each channel and fix the failing one; regenerate a
  stale webhook/PagerDuty key (store it in Key Vault); confirm the alert rule's **action group** is set.

## Ingestion cost spikes unexpectedly
- **Symptom:** Workspace bill or data volume jumps after a rollout wave.
- **Cause:** A verbose log category enabled estate-wide, a chatty resource type, or high-cardinality
  custom logs on the Analytics tier.
- **Fix:** Run `OBSAZMON-Report.ps1` **top-ingesters**; drop unneeded log categories, move high-volume
  low-query data to **Basic/Auxiliary** tier, and set a **daily cap**. Remediate future waves more
  selectively. *Verify current tier/pricing.*

## VM insights / container insights not populating
- **Symptom:** The VM insights map or container insights views are empty.
- **Cause:** AMA not deployed, VM/cluster not associated to a DCR, the container-insights add-on not
  enabled, or an outbound-network/private-link restriction blocking the agent.
- **Fix:** Confirm the **AMA extension** on the VM and its **DCR association**; for AKS confirm the
  **container insights** add-on; verify the agent can reach the required Azure Monitor endpoints
  (proxy/private-link config). *Verify AMA availability for the OS/region.*

## Workbook or dashboard shows errors / no data
- **Symptom:** Tiles error or stay blank.
- **Cause:** Query references a table with no data yet, a workspace/resource parameter is unset, or the
  viewer lacks **Log Analytics Reader**.
- **Fix:** Confirm the underlying tables have pilot data (Gate 1), set the workbook's **workspace/scope
  parameters**, and grant viewers **Log Analytics Reader**. Validate each query from
  `OBSAZMON-Queries.kql` standalone first.

## "Access denied" running the scripts or assigning policy
- **Symptom:** `OBSAZMON-Discovery.ps1`/deployment fails, or you can't assign the policy.
- **Cause:** Missing Contributor / Monitoring Contributor / Resource Policy Contributor at the scope, or
  wrong subscription context.
- **Fix:** `Set-AzContext` to the right subscription; have an Owner grant the roles in §2.1; re-run.

---
If a failure isn't covered here, capture the resource, the workspace, the exact query/rule, and the
`OBSAZMON-Validate.ps1` / `OBSAZMON-Report.ps1` output before changing anything — most issues are a
missing diagnostic setting, a mis-scoped alert, or a stale notification channel.
