# 6. Troubleshooting — Datadog Deployment for Hybrid & Cloud Estates

Symptom → root cause → fix for the failures you are most likely to hit. Re-run **`OBSDDOG-Validate.ps1`**
and **`OBSDDOG-Report.ps1`** after each fix to confirm. Work on the **pilot** first. Never resolve an
issue by hard-coding a key — fix the **secret-store reference** instead.

## Agent installs but the host doesn't appear in Datadog
- **Symptom:** `install-datadog-agent.sh` / `Install-DatadogAgent.ps1` completes, but the host isn't on
  the Host Map.
- **Cause:** Wrong/empty **API key**, wrong **site** (agent talking to the wrong region), or blocked
  **outbound network** to the Datadog endpoints.
- **Fix:** Run `datadog-agent status` — it shows the API-key and endpoint status. Confirm the key was
  read from the **secret store** and the **`DD_SITE`** matches your org's site. Verify egress/proxy to
  the Datadog site endpoints (`datadog-agent status` reports connectivity). *Verify current endpoints for
  your site in Datadog's docs.*

## Agent reports but has no/incorrect tags
- **Symptom:** Host is present but dashboards/monitors scoped by `env:pilot` don't see it.
- **Cause:** The installer's `env`/`service`/`team` tags weren't passed, or `datadog.yaml`/host tags
  differ from what the monitors filter on.
- **Fix:** Re-run the installer with the correct `--env/--service/--team` (or fix `tags:` in
  `datadog.yaml`) and restart the agent; confirm the tags on the host in Datadog match the monitor
  filters exactly.

## Terraform provider auth fails
- **Symptom:** `terraform plan` errors with 403/authentication or "API key invalid."
- **Cause:** Missing/invalid **`DD_API_KEY`** or **`DD_APP_KEY`** env vars, wrong **site**, or the APP
  key belongs to a different org/user.
- **Fix:** Export both keys from the **secret store** into the environment (not into `.tf`), set the
  provider **`api_url`/site** correctly, and confirm the APP key is valid for the target org. Never
  commit keys to fix this.

## Azure integration not connecting
- **Symptom:** The Datadog Azure integration status shows the subscription not connected / no metrics.
- **Cause:** The app registration lacks **Monitoring Reader** at scope, the client secret is
  wrong/expired, or the wrong tenant/subscription ID.
- **Fix:** Confirm the app registration has **Monitoring Reader** (and Reader) at the target scope,
  regenerate the client secret into the **secret store**, and re-`apply` the `datadog_integration_azure`
  resource with the correct tenant/subscription IDs. *Verify current required roles in Datadog's docs.*

## AWS integration not connecting
- **Symptom:** AWS integration status shows the account not connected.
- **Cause:** The cross-account **IAM role** trust/policy is wrong, or the external ID / role ARN doesn't
  match what the `datadog_integration_aws` resource declares.
- **Fix:** Verify the IAM role trusts Datadog's account with the correct external ID and carries the
  current integration policy; align the role ARN in Terraform and re-`apply`. *Verify the current policy
  in Datadog's docs.*

## A key was found in code or state
- **Symptom:** Secret scan (Gate 5) flags an API/APP key or client secret in `main.tf`, an installer, or
  committed state.
- **Cause:** A key was inlined instead of referenced from the secret store, or state was committed to the
  repo.
- **Fix:** Remove the key, **rotate it immediately** (it is compromised once committed), move it to the
  secret store, purge it from Git history, and move Terraform **state** to a secured backend. Re-run the
  secret scan.

## Monitor never fires
- **Symptom:** A pilot condition is clearly true but the monitor stays green.
- **Cause:** The monitor's **query/scope** doesn't match the pilot tags, the threshold/window is too lax,
  or it's evaluating a metric the agent isn't sending.
- **Fix:** Open the monitor, run its **query** in the metric explorer, and confirm it returns pilot data;
  align the **scope tags** and **threshold/window**; ensure the underlying metric is being collected
  (agent integration enabled).

## Monitor fires but no notification
- **Symptom:** Monitor goes to Alert but no Slack/Teams/PagerDuty message.
- **Cause:** The notification **@-handle** is wrong/not connected, or the integration (Slack/PagerDuty)
  isn't authorized in Datadog.
- **Fix:** Confirm the Slack/Teams/PagerDuty integration is **connected** in Datadog and the monitor
  message uses the correct **`@handle`**; send a **test notification** from the monitor.

## Logs arrive unparsed or in the wrong index
- **Symptom:** Pilot logs show up as raw text or in an unexpected index.
- **Cause:** `OBSDDOG-Pipeline-AppLogs` parsing rules don't match the log format, or the index
  filter/retention routes them elsewhere.
- **Fix:** Adjust the pipeline's parser (grok/JSON) to the actual format, confirm the **index filter**
  and **retention**, and re-`apply`. Watch cost — index only what you'll query.

## Ingestion / host count higher than expected (cost)
- **Symptom:** Datadog bill or host count climbs after a wave.
- **Cause:** Agents on decommissioned hosts still counted, all products enabled everywhere, or all logs
  indexed.
- **Fix:** Run `OBSDDOG-Report.ps1` to list reporting hosts and ingestion; remove agents from dead hosts,
  disable unneeded products per host, and tighten log indexing. Roll out further waves more selectively.
  *Plan/pricing is a Datadog-side decision — verify in Datadog's docs.*

---
If a failure isn't covered here, capture `datadog-agent status`, the `terraform plan` output, the
integration status page, and the `OBSDDOG-Validate.ps1` / `OBSDDOG-Report.ps1` output before changing
anything — most issues are a wrong site/key, a mis-scoped tag, or an unconnected integration.
