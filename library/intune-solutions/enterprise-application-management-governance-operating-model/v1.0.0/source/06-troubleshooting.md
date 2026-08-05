# Troubleshooting

This section addresses the ways the operating model stalls in practice — both technical (the scripts
and the Intune/Entra objects) and organisational (the process itself). Each entry gives the
**symptom**, the **cause**, and the **fix**.

> **Government tenants:** if a script returns no data on a GCC High / DoD tenant, first confirm you
> passed `-GraphEnvironment USGov`; the default `Global` endpoint returns nothing against a sovereign
> tenant. Console URLs are `endpoint.microsoft.us` and `portal.azure.us`.

---

## Technical — scripts and objects

### Symptom: `Connect-MgGraph` fails or a script returns no applications

**Cause:** the Graph SDK is missing, consent was declined, or (on Government) the wrong environment
was targeted.

**Fix:** confirm the module with `Get-Module Microsoft.Graph -ListAvailable`; install it with
`Install-Module Microsoft.Graph -Scope CurrentUser -Force` if absent. Re-run the script and
**Accept** the consent prompt. On a Government tenant add `-GraphEnvironment USGov`. If your tenant
requires admin consent for the **Microsoft Graph Command Line Tools** enterprise application, have a
Global Administrator grant it once (Entra → Enterprise applications → the app → Security → Permissions
→ Grant admin consent), then re-run.

### Symptom: `APPOPS-Validation.ps1` reports a scope tag, role, or group as MISSING that you believe you created

**Cause:** almost always a **name mismatch**. The script matches on the exact display name, including
the en dash (`–`, U+2013) and single spaces — a hyphen-minus (`-`) or a double space fails the match.

**Fix:** open the object in the console and compare its name character for character with Section 3.
The safest correction is to copy the name from the implementation guide and paste it into the
object's rename field. Do not "fix" the script's expected names; fix the object so the whole model
stays consistent (Testing, scripts, and the register all rely on the exact names).

### Symptom: `APPOPS-Remediation.ps1 -Apply` fails with a 400 or "property cannot be updated"

**Cause:** the PATCH body must carry the correct `@odata.type` for the specific app type
(`win32LobApp`, `winGetApp`, `iosStoreApp`, etc.). The script reads it from the app and echoes it
back, so this normally only occurs if the app object was deleted between the read and the write, or
the signed-in account lacks `DeviceManagementApps.ReadWrite.All`.

**Fix:** confirm the account holds the ReadWrite scope (re-run and check the consent), and re-run the
script so it re-reads the current app object. If a specific app persistently fails, stamp its
governance metadata manually in **Apps → All apps → <app> → Properties → Edit → Notes** and apply the
scope tag there.

### Symptom: `APPOPS-Export-ApprovalEvidence.ps1` finds no audit events

**Cause:** Intune audit-log retention is shorter than the window you requested. Intune retains audit
events for a limited period; a change from a year ago will not appear.

**Fix:** reduce `-DaysBack` to within your tenant's retention, or — for long-term evidence — route
Intune audit logs to a Log Analytics workspace (Tenant administration → Diagnostic settings) so the
trail outlives the built-in retention. This is worth doing before you rely on the export for a formal
audit.

### Symptom: the deployment engineer can see apps but cannot edit them

**Cause:** the app the engineer is trying to edit carries only the **Default** scope tag, which is
outside the custom role's assigned scope tags.

**Fix:** apply `Scope – App Management – Prod` or `Scope – App Management – Pilot` to the app (via
`APPOPS-Remediation.ps1` or manually). An app with no management scope tag is, by design, outside the
deployment engineers' reach — that is the boundary working, not a bug.

### Symptom: creating an Entra group fails with a permissions error

**Cause:** the tenant restricts security-group creation (Entra → Groups → General → *Users can create
security groups* = No) and your account is not in the delegated group or a directory role.

**Fix:** have a Global Administrator or Groups Administrator either assign you **Groups
Administrator** or add you to the group nominated in the group-creation setting (Requirement R4).

---

## Organisational — the process

### Symptom: the board approves everything; nothing is ever deferred or rejected

**Cause:** the evidence pack is not being demanded before items are tabled, so the board is presented
only with items that already look complete — and it has no basis to say no. Or the sponsor has not
made it safe to reject.

**Fix:** enforce the evidence-pack requirement (Step 9, item 6) — the chair refuses to table an item
missing any required evidence. Confirm the sponsor (R1) will back a rejection. A board that never
defers is not disciplined; it is a rubber stamp, and Testing Gate 6 will not pass.

### Symptom: urgent applications keep bypassing the intake form

**Cause:** urgency is being treated as an exemption rather than a change tier.

**Fix:** reframe urgency inside the model — an urgent application is a Tier 3/Tier 4 change with
compressed dwell times and immediate Security involvement, handled *fast* but not *outside* the
process. Have the executive sponsor restate that intake is the only route. Every tolerated bypass
teaches the next requester that the bypass exists.

### Symptom: the board is drowning in trivial version-update approvals

**Cause:** the Tier 1 pre-approval (standard change) rule was not implemented, or is defined too
narrowly.

**Fix:** implement Step 9 item 7 — a version update to an approved app with no change to data
handling, egress, or licence is pre-approved and consumes no ARB slot. Widen the standard-change
definition as confidence grows. This one rule typically removes 60–80% of the board's volume and is
the difference between a viable board and an abandoned one.

### Symptom: applications keep becoming orphaned despite the register

**Cause:** the leaver process does not reassign a departing owner's applications.

**Fix:** add "reassign owned applications in the register" to the IT leaver checklist, and have the
register custodian run the overdue/unowned sweep monthly (`APPOPS-Discovery.ps1`, the *No governed
owner* count). An owner who has left is the single most common route to orphaned applications; catch
it at the leaver event, not at the next audit.

### Symptom: the register and Intune disagree about what exists

**Cause:** applications are installed on endpoints outside Intune (user-installed, legacy image,
departed process) and were never reconciled.

**Fix:** run the quarterly reconciliation (Requirement R8) — compare Intune **Discovered apps** (and
Defender for Endpoint software inventory where available) against the register, and either bring each
shadow application into governance or plan its removal. Track the shadow count on the scorecard so it
trends down rather than being rediscovered at each audit.

### Symptom: nobody will hold the Security Reviewer role

**Cause:** the organisation has no security function, or Security declines the workload.

**Fix:** escalate to the sponsor (R1). Where a security function genuinely does not exist, the model
still runs, but record the **compensating control** explicitly in the standards document — for
example, a required external annual assessment for any `Confidential`/`Restricted` application —
rather than pretending the gate exists. A gate with no owner is not a gate.

### Symptom: the model was built, then quietly stopped being used after a few months

**Cause:** the scorecard is not reported anywhere with authority, so nobody notices the decay.

**Fix:** put the monthly `APPOPS-Report.ps1` scorecard on the standing agenda of a governance forum
that can act on it, and show the **trend**, not just the snapshot. A falling ownership-coverage line
in front of the right people prompts correction; the same number in a folder does not. This is the
maintenance practice that most determines whether the model survives its first year.
