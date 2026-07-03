# Troubleshooting — Azure Virtual Desktop Remote Access (Azure Government / GCC High)

Symptom → likely cause → fix, focused on the failures that are **specific to the US sovereign cloud**. Most Gov-only AVD problems come down to three things: the **wrong portal/feed URL**, a **blocked `.us` endpoint**, or a **domain-join/MFA** issue. Work top-down.

> Admin at **`portal.azure.us`**; clients subscribe to **`rdweb.wvd.azure.us`**; scripts on **`AzureUSGovernment`** / Graph **`USGov`**.

---

## A. "We couldn't find any resources" in the client
- **Cause 1 — wrong (Commercial) feed URL.** The client was subscribed to `rdweb.wvd.microsoft.com` / `client.wvd.microsoft.com`.
  - **Fix:** Remove the workspace and re-subscribe to **`https://rdweb.wvd.azure.us`** (feed discovery `https://rdweb.wvd.azure.us/api/arm/feeddiscovery?aadtenant=<yourdomain>`).
- **Cause 2 — app group not registered to a workspace.**
  - **Fix:** AVD → **Workspaces → (your workspace) → Application groups → +** register `AVD App Group – <Scope> – Pilot` (see `03-implementation.md` Step 2.3 / test T3).
- **Cause 3 — user not assigned.**
  - **Fix:** App group → **Assignments → +** add `AVD Users – <Scope> – Pilot` (T5).
- **Cause 4 — wrong account/tenant.** User signed in with a Commercial or wrong-domain account.
  - **Fix:** Sign in with the Gov work account (`user@<name>.onmicrosoft.us` or your Gov domain) via `login.microsoftonline.us`.

## B. macOS client shows nothing / won't add the account
- **Cause — legacy app or Commercial endpoint.** Using the old Microsoft Remote Desktop macOS app or a Commercial feed.
  - **Fix:** Install **Windows App** from the **Mac App Store** → **+** → **Add Work or School Account** → subscribe to **`https://rdweb.wvd.azure.us`** (T7). Confirm the client endpoints `*.wvd.azure.us` and `*.servicebus.usgovcloudapi.net` are allowed on the device network.

## C. Admin portal redirects to Commercial
- **Cause — wrong tenant / wrong portal.** You opened `portal.azure.com` or you're actually on a Commercial/GCC tenant.
  - **Fix:** Use **`portal.azure.us`** / **`portal.office365.us`**. If sign-in still lands on `login.microsoftonline.com`, the tenant is not GCC High — re-confirm R1 before proceeding.

## D. Session host stuck at "Needs assistance" / agent won't register
- **Cause 1 — blocked Gov endpoints (most common).** `*.wvd.azure.us` or the `*.usgovcloudapi.net` agent/monitor endpoints are blocked by firewall/proxy.
  - **Fix:** Allow the full **Azure for US Government** session-host set (R7 / parity notes §3): `*.wvd.azure.us`, `*.service.windows.usgovcloud.microsoft`, `login.microsoftonline.us`, `*.prod.warm.ingest.monitor.core.usgovcloudapi.net`, `gcs.monitoring.core.usgovcloudapi.net`, `mrsglobalstugviffx.blob.core.usgovcloudapi.net`, etc. Re-run `AVDG-Validation.ps1` and Microsoft's *Agent URL Tool* (T8).
- **Cause 2 — fabric IPs proxied.** `169.254.169.254` / `168.63.129.16` are being intercepted/redirected.
  - **Fix:** Ensure these are never proxied or routed away (they must reach the Azure fabric directly).
- **Cause 3 — registration token expired.**
  - **Fix:** Regenerate the host-pool registration key and re-add the host.

## E. Domain join fails during host deployment
- **Cause 1 — MFA on the join account.** The domain-join account has MFA enabled.
  - **Fix:** Use a domain-join account **without MFA** (scoped, monitored). Re-deploy the host.
- **Cause 2 — no line of sight to DC/DNS.** The session-host VNet can't reach the domain controller/DNS.
  - **Fix:** Confirm VNet/DNS routing to the DC (R5/R7); fix the OU path if specified.
- **Cause 3 — Entra Domain Services + Intune expectation.** You expected Intune management but hosts are Entra-Domain-Services-joined.
  - **Fix:** Entra-Domain-Services-joined hosts **can't** be Intune-managed; switch to Entra-join or hybrid, or manage via GPO (parity notes §6).

## F. Sign-in loops / SSO prompts unexpectedly
- **Cause 1 — hybrid identity mismatch.** UPN or SID doesn't match across AD DS and Entra ID.
  - **Fix:** Correct the mismatch and re-sync Entra Connect (R5).
- **Cause 2 — SSO/passwordless feature not GA in Gov.** You configured an SSO/passwordless path that isn't available in Azure Government yet.
  - **Fix:** **Verify for Azure Government** (parity notes §7) that the specific SSO/WHfB/FIDO2/Entra-Kerberos path is GA in your Gov tenant; fall back to a supported method.

## G. Scripts connect to the wrong cloud / no data
- **Cause — default (Commercial) environment.** `Connect-AzAccount` / `Connect-MgGraph` ran without the Gov environment.
  - **Fix:** Use **`Connect-AzAccount -Environment AzureUSGovernment`** and **`Connect-MgGraph -Environment USGov`**. All five scripts default to Gov; don't override to Commercial.

## H. FSLogix profile won't load
- **Cause — identity/storage prerequisites for the model.** For Entra-join + Azure Files, users must be hybrid identities and the storage path configured accordingly.
  - **Fix:** Match FSLogix prerequisites to your identity model (R5 / best practices). **Verify for Azure Government** that the Azure Files Entra-Kerberos / cloud-only path you're using is GA in Gov before relying on it.

## I. A feature "should exist" but isn't in the Gov portal
- **Cause — parity lag.** The feature has shipped to Commercial but not yet to Azure Government.
  - **Fix:** Check `gcc-high-parity-notes.md` and Microsoft's current Gov docs; treat recently-announced features as **verify for Azure Government**. Design around GA-in-Gov capabilities only.

---

### Escalation checklist
1. Confirm cloud: `portal.azure.us` + `login.microsoftonline.us` (T1).
2. Confirm endpoints reachable: `AVDG-Validation.ps1` (T8).
3. Confirm objects/assignment: `AVDG-Discovery.ps1` (T3/T5).
4. Capture `AVDG-Report.ps1` output and attach to the ticket.
