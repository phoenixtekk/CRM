# 6. Troubleshooting — Enablement Kit: Microsoft Defender for Cloud

Symptom → cause → fix for the common issues when running the enablement kit and its lab helpers. For category-level prerequisites (licensing, roles, network) see `global-requirements-defender.md`.

## Defender for Cloud shows no data for the pilot subscription
- **Symptom:** The Overview/Secure Score is blank for the pilot subscription.
- **Cause:** `Microsoft.Security` provider not registered, the subscription only just added, or you are scoped to the wrong subscription.
- **Fix:** Confirm the subscription scope (top of the portal). Register the provider (**Subscriptions → Resource providers → Microsoft.Security → Register**). Allow a warm-up window for assessments (R2). Re-run `WSMDC-Validate.ps1`.

## Secure Score / recommendations are empty (Lab 1)
- **Symptom:** No score or recommendations appear.
- **Cause:** Assessments have not populated yet, or no resources exist to assess.
- **Fix:** Allow the warm-up window after onboarding (*timing varies — verify*). Ensure the pilot subscription has at least a few resources. Confirm `Microsoft.Security` is registered.

## No security alerts to triage (Lab 2)
- **Symptom:** **Security alerts** is empty.
- **Cause:** No Defender (CWPP) plan is On, a quiet environment, or the plan just enabled.
- **Fix:** Enable at least one plan on the **pilot** (R3) — *several are paid; verify cost*. Use the portal **sample alerts** action to generate benign alerts for the lab. Never simulate a real attack against production.

## `Get-AzSecurityPricing` / `Set-AzSecurityPricing` errors
- **Symptom:** The discovery/validate/lab scripts error reading or setting a plan.
- **Cause:** Missing Az.Security module, insufficient role, or a plan-name mismatch between Az versions.
- **Fix:** `Install-Module Az` and `Connect-AzAccount` (R5). Confirm the facilitator holds a change-capable role on the pilot (R4). Valid plan names include `VirtualMachines`, `StorageAccounts`, `Arm`, `KeyVaults`, `SqlServers`, `Containers`, `AppServices`, `Dns`, `Api` — *verify names for your Az version*.

## `WSMDC-SecureScore-Lab.ps1` didn't change anything
- **Symptom:** You expected a plan to be enabled; nothing changed.
- **Cause:** **By design** — the script is preview-first. Without `-Apply` (and a confirmation) it only reports what *would* change.
- **Fix:** This is correct for the enablement kit. Only the facilitator, on the **pilot**, with cost verified and approval, re-runs with `-Apply`. For training, the `-WhatIf`/preview output is the intended result.

## Azure Resource Graph queries return nothing (Labs 1/2/5)
- **Symptom:** `securityresources | take 5` returns no rows.
- **Cause:** The account lacks **Reader** on the subscription (ARG honors resource RBAC), or the scope filter excludes the pilot.
- **Fix:** Grant **Reader/Security Reader** on the pilot subscription (R6). Confirm the Resource Graph Explorer scope includes the pilot subscription. Some `securityresources` types populate only after assessments run.

## Regulatory compliance dashboard is empty (Lab 3)
- **Symptom:** No standards or controls appear.
- **Cause:** No standard assigned, or Defender CSPM (which enriches compliance) is not on.
- **Fix:** Confirm a standard is assigned (the default may need enabling), and that the relevant plan is on. *The choice of standard is the compliance team's* — for the lab, use whatever is assigned. Some standards require Defender CSPM — *verify availability*.

## Multicloud connector lab has nothing to show (Lab 4)
- **Symptom:** No AWS/GCP connector exists.
- **Cause:** No connector configured (expected — connectors are the CSPM-program solution's job).
- **Fix:** Run Lab 4 as the **concept** walk-through (R7). Standing up a real connector is out of scope for this enablement kit.

## `Connect-AzAccount` prompts repeatedly / wrong tenant
- **Symptom:** The scripts keep prompting or land in the wrong tenant/subscription.
- **Cause:** Multiple tenants/subscriptions in context.
- **Fix:** Run `Connect-AzAccount -Tenant '<tenant id>'` then `Set-AzContext -SubscriptionId '<pilot sub id>'`, and pass `-SubscriptionId` to every lab script.

## Portal blade paths don't match
- **Symptom:** A navigation path in the runbook doesn't exist.
- **Cause:** Microsoft periodically relocates Defender for Cloud blades.
- **Fix:** Use portal search for the feature name (e.g. "Secure Score", "Environment settings", "Regulatory compliance"). *Verify current navigation in your tenant* and update your copy of the runbook.
