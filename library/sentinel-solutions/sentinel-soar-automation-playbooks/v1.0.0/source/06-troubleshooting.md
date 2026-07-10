# 6. Troubleshooting Guide — Microsoft Sentinel SOAR: Automation Rules & Playbooks (Logic Apps)

Common failures, their cause, and the fix. Work top-down; most issues are permissions or scope.

## The automation rule runs but the playbook does not

- **Symptom:** The incident is assigned/tagged, but no enrichment/notify/ticket comment appears; the playbook shows no run.
- **Cause:** Microsoft Sentinel does not have permission to run playbooks in the SOAR resource group.
- **Fix:** `Microsoft Sentinel` → `Configuration` → `Automation` → `Active playbooks` → `Configure permissions` → select `rg-sentinel-soar` → `Apply` (Implementation Step 7). Re-trigger the incident and check the playbook `Runs history`.

## Playbook run fails at a Sentinel action ("comment not added / incident not updated")

- **Symptom:** The Logic App run shows `Failed` on `Add comment to incident` or `Change incident status`, often with a 403.
- **Cause:** The playbook's managed identity lacks **Microsoft Sentinel Responder** on the workspace/resource group.
- **Fix:** Enable the system-assigned identity (`Identity` blade), then assign Microsoft Sentinel Responder to it (`SENTSOAR-Set-PlaybookIdentity.ps1` or Implementation Step 6). Re-run the failed run.

## The automation rule never fires

- **Symptom:** New incidents get no auto-triage at all.
- **Cause:** The rule's conditions do not match (too narrow), the rule is disabled, or another higher-priority rule changed the incident first.
- **Fix:** `Automation` → open `Auto-Triage - New Incidents - Pilot` → confirm it is `Enabled` and its condition (analytics rule name / severity) actually matches your pilot incidents. Check `Order` so it is not pre-empted. Widen the condition if needed, but keep the pilot narrow.

## Teams or email notification does not arrive

- **Symptom:** Enrichment works but no Teams card / no email.
- **Cause:** The Teams or Office 365 Outlook API connection is unauthorized, expired, or the target channel/mailbox is wrong.
- **Fix:** Open `Notify - Teams-Email - Pilot` → the Teams/Outlook action → re-authorize the connection with the low-privilege service account (Requirement 2.5). Confirm the channel ID / recipient. Re-run.

## The approval card never appears (response playbook)

- **Symptom:** `Response - Contain - Pilot` starts but the SOC Approvals channel gets no card, or it never resumes.
- **Cause:** The Teams connection for the approval action is unauthorized, the channel is wrong, or the approvers cannot see the channel.
- **Fix:** Re-authorize the Teams connection; confirm the `SOC Approvals` channel and that approvers are members (Requirement 2.7). Note that `Post an Adaptive Card and wait for a response` will wait up to the Logic App run limit — a very old run may have timed out; re-run.

## Response playbook made a real change during the pilot

- **Symptom:** A user was actually disabled / a device actually isolated during the pilot.
- **Cause:** `SimulateMode` was set to `false`, or the enforced branch was not correctly gated behind the `SimulateMode` condition.
- **Fix:** This must not happen in the pilot. Open `Response - Contain - Pilot` → confirm the `SimulateMode` variable initializes to `true` and that every platform action sits inside the `SimulateMode = false` branch only (Implementation Step 5). Remove any enforced-action role from the playbook's identity for the pilot (`SENTSOAR-Set-PlaybookIdentity.ps1` flags this). Reverse the change on the affected user/device and record it.

## Device isolation / user disable action errors when enforced (Expand)

- **Symptom:** After moving an action to enforced, it fails with a permission or "not found" error.
- **Cause:** The managed identity lacks the specific platform permission (Defender for Endpoint isolation permission, or a Graph/Entra role to disable a user), or the target platform is not onboarded/licensed.
- **Fix:** Grant the identity the exact least-privilege permission for that one action (Implementation Step 6.2 / Step 10). Confirm Defender for Endpoint is onboarded and the device/user resolves (`SENTSOAR-SimulateResponse.ps1` verifies the target). *Verify current availability/licensing in your tenant.*

## Playbook not selectable in the automation rule

- **Symptom:** `Run playbook` in the automation rule does not list your playbook.
- **Cause:** The playbook does not use the `Microsoft Sentinel incident` (or alert) trigger, or Sentinel lacks run permission on its resource group.
- **Fix:** Confirm each playbook starts from the `Microsoft Sentinel incident` trigger (Implementation Steps 2-5) and that `Configure permissions` covered `rg-sentinel-soar` (Step 7).

## Costs climbing / too many runs

- **Symptom:** Logic App action count and cost rise faster than expected.
- **Cause:** The automation rule scope is too broad, or a playbook has many actions running on every incident.
- **Fix:** Run `SENTSOAR-Report.ps1` to see run counts per playbook. Narrow the automation-rule condition, split heavy enrichment into a separate playbook, or reduce per-run actions. Add an expiration to pilot rules.

---

If a problem persists, re-run `SENTSOAR-Discovery.ps1` and `SENTSOAR-Validate.ps1` and compare against the objects named in the Implementation Guide — nearly every issue is a missing role, an unauthorized connection, or a mis-scoped automation rule.
