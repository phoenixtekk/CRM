# Testing & Validation — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Run these test cases at **Gate 4 (Validate)** and after every expansion wave. Each case has an explicit **pass/fail**. Capture evidence (screenshots / script output) for your change record. Scripts referenced here connect to **US Gov** endpoints (`-Environment AzureUSGovernment` / `USGov`).

> Tenant reminder: admin at **`portal.azure.us`**, clients subscribe to **`rdweb.wvd.azure.us`**.

---

## T1. Tenant & environment is Azure Government
- **Steps:** Sign in to `portal.azure.us`; confirm redirect through `login.microsoftonline.us`; run `AVDG-Discovery.ps1`.
- **Pass:** Portal is `.us`, sign-in is `login.microsoftonline.us`, Discovery reports environment **AzureUSGovernment**.
- **Fail:** Any Commercial URL (`portal.azure.com`, `login.microsoftonline.com`) appears — you are on the wrong cloud; stop.

## T2. Resource provider registered
- **Steps:** `AVDG-Validation.ps1`, or portal **Subscriptions → Resource providers**.
- **Pass:** `Microsoft.DesktopVirtualization` = **Registered**.
- **Fail:** NotRegistered → run `AVDG-Remediation.ps1` (review `-WhatIf` plan first).

## T3. AVD objects exist with correct names
- **Steps:** Confirm host pool `AVD Host Pool – <Scope> – Pilot`, workspace `AVD Workspace – <Scope> – Prod`, app group `AVD App Group – <Scope> – Pilot`.
- **Pass:** All three exist, correctly named, app group **registered** to the workspace.
- **Fail:** Missing object or unregistered app group → resources won't appear in clients.

## T4. Session hosts healthy
- **Steps:** AVD → **Session hosts**; or `AVDG-Validation.ps1`.
- **Pass:** Every host **Status = Available**, agent/SxS versions current.
- **Fail:** **Needs assistance / Unavailable** → almost always a blocked `.us` endpoint (T8) or a domain-join issue (MFA on the join account).

## T5. Assignment scoped to pilot group
- **Steps:** App group → **Assignments**.
- **Pass:** Only `AVD Users – <Scope> – Pilot` assigned.
- **Fail:** Broader/other group assigned → correct before proceeding.

## T6. Windows client subscribes to the Gov feed
- **Steps:** On Windows, subscribe with **`https://rdweb.wvd.azure.us`**; sign in with the Gov account.
- **Pass:** Workspace and resources appear.
- **Fail:** "We couldn't find any resources" → confirm the **Gov** feed URL (not `rdweb.wvd.microsoft.com`), correct account, and T3/T5.

## T7. macOS client subscribes to the Gov feed
- **Steps:** On macOS, Windows App → **Add Work or School Account** → subscribe to **`https://rdweb.wvd.azure.us`**.
- **Pass:** Resources appear and a desktop connects.
- **Fail:** No resources → same checks as T6; confirm Windows App (not the legacy Microsoft Remote Desktop macOS app pointed at Commercial).

## T8. Government endpoints reachable from session hosts
- **Steps:** `AVDG-Validation.ps1` endpoint check, and/or Microsoft's *Agent URL Tool* on a host.
- **Pass:** `*.wvd.azure.us`, `*.service.windows.usgovcloud.microsoft`, `login.microsoftonline.us`, and the `*.usgovcloudapi.net` agent/monitor endpoints all reachable on 443.
- **Fail:** Any blocked → open it in the firewall/proxy (R7); re-test.

## T9. Desktop connection and published app launch
- **Steps:** As a pilot user, connect to the desktop; launch a published app.
- **Pass:** Desktop session established over 443; app launches; input/display normal.
- **Fail:** Connection drops or app won't launch → check host health (T4), profile/identity (T10), endpoints (T8).

## T10. Identity / profile behavior for the chosen model
- **Steps:** Sign in as a pilot user; confirm SSO/prompt behavior and FSLogix profile load (if configured) matches the chosen model (R5).
- **Pass:** Sign-in succeeds per design; profile loads (if FSLogix configured); no repeated auth loops.
- **Fail:** Auth loops or profile errors → verify hybrid sync (UPN/SID match), or Entra-only profile prerequisites. **Verify for Azure Government** that any SSO/passwordless/external-identity feature you depend on is available in Gov (see `gcc-high-parity-notes.md`).

## T11. Report generated
- **Steps:** `AVDG-Report.ps1`.
- **Pass:** Report lists inventory + pass/fail and shows **no open Sev-1/Sev-2**.
- **Fail:** Open Sev-1/Sev-2 → remediate before Gate 4 sign-off.

## T12. Rollback rehearsed
- **Steps:** In a controlled window, remove then re-add the pilot group assignment.
- **Pass:** Access is revoked and restored as expected; back-out is documented.
- **Fail:** Rollback doesn't behave as documented → fix the runbook before expanding.

---

### Exit criteria (Gate 4)
All of T1–T12 **pass**, evidence captured, and the Report shows no open Sev-1/Sev-2. Only then proceed to **Stage 5 — Expand**.
