# 6. Troubleshooting — HP Workforce Experience Platform (WXP) Integration with Intune

Work top-down and by **half**: first confirm the **agent app installs** (Intune side), then that the
**device actually reports into WXP** (agent registration + network), then that the **tenant connector**
is consented (Entra/cloud side). Most cases are one of: a wrong install command / missing enrollment
code, a bad detection rule, a blocked WXP endpoint, or an un-consented connector. Each symptom below
gives the **likely cause** and the **fix**.

> **Before you start:** remember HP renamed this platform (**TechPulse / Proactive Insights / Adaptive
> Endpoint Management → Workforce Experience Platform**). If a console menu, the agent filename, the
> enrollment-code label, or the connector app name doesn't match this guide, **verify the current value
> in the HP WXP admin console / your tenant** — the value moved, the mechanic didn't.

## Symptom: The HP WXP agent app never installs on the device
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in **`HP WXP - Pilot Devices`** and `HP WXP Agent - Pilot` is **assigned
   Required** (`HPWXP-Validation.ps1`, or Apps → Windows → the app → Assignments).
2. Force an Intune sync (Company Portal → **Sync**, or Settings → Accounts → Access work or school →
   **Sync**).
3. Check **Apps → Windows → HP WXP Agent - Pilot → Device install status** for an error.
4. Confirm the device is enrolled and managed (R4).

## Symptom: App shows "Failed" in Device install status
**Likely cause:** Wrong install command, bad `.intunewin`, or wrong install context.
**Fix:**
1. Re-check the **install command** matches HP's documented silent install syntax, **with the enrollment
   code passed correctly** (Step 6) — verify the exact parameter name in HP's agent docs.
2. Confirm **install behavior = System** and the vendor's silent switches are present.
3. Re-wrap the installer (Step 4) if the `.intunewin` is stale or missing dependencies.
4. Review the Win32 app install log on the device (`C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`).

## Symptom: The app reinstalls on every sync (install loop / flip-flopping status)
**Likely cause:** The **detection rule** does not correctly match the installed agent.
**Fix:**
1. On a reference device, confirm the exact **MSI product code** (or file path + version / registry
   key) the agent actually writes (R6).
2. Set the Win32 **detection rule** to that verified value (Step 6) — do not assume a product code.
3. Re-sync and confirm the app **stays Installed** (Testing Test 4).

## Symptom: Agent shows Installed in Intune but the device does not appear in the HP WXP console
**Likely cause:** The agent installed but **did not register to your WXP tenant** (missing/incorrect
enrollment code), or it cannot reach the WXP service endpoints.
**Fix:**
1. Confirm the **enrollment / company code** was passed on the install command (Step 6) and matches the
   code in the **HP WXP admin console** (R3) — a blank or wrong code installs the agent but leaves it
   unregistered.
2. From the device network, confirm outbound HTTPS to the **HP WXP service endpoints** (R9) — **verify
   the exact URLs in HP's documentation**; a proxy/firewall block or TLS inspection stops reporting.
3. Allow for **first-report delay** — devices can take time to appear; verify expected timing in HP's
   documentation before escalating.

## Symptom: The tenant connector / "Connect to Microsoft" step fails or shows not connected
**Likely cause:** Admin consent was not completed by a Global Administrator, or was cancelled.
**Fix:**
1. Re-run the **Connect to Microsoft / Intune** flow from the HP WXP admin console (Step 8) and complete
   it signed in as a **Global Administrator** (R7).
2. On the consent screen, **grant admin consent for the organization** (not just for yourself) and note
   the exact permissions requested.
3. Confirm the enterprise application was created — Entra → **Enterprise applications** — and run
   `HPWXP-Discovery.ps1 -ConnectorAppName "<name shown in your tenant>"`.

## Symptom: WXP is connected but shows no / few Intune-managed devices
**Likely cause:** Sync still in progress, insufficient consented scope, or devices out of scope.
**Fix:**
1. Allow the initial **cloud-to-cloud sync** to complete (verify expected timing in HP's docs).
2. Confirm the connector's granted **Graph permissions** cover device inventory read (review the
   enterprise application's permissions in Entra) — re-consent if a scope was declined.
3. Confirm the devices are actually **Intune-managed** (Devices → All devices) so they are in scope for
   correlation.

## Symptom: Discovery reports the connector "not found" but you completed consent
**Likely cause:** The connector's **display name differs** from the default (HP-renamed product).
**Fix:**
1. In Entra → **Enterprise applications**, find the HP application's **actual display name**.
2. Re-run `HPWXP-Discovery.ps1 -ConnectorAppName "<that exact name>"`.
3. The script also broadens its search for HP WXP name variants (workforce/experience/techpulse/
   proactive) — if it still misses, the app may be named unusually in your tenant; verify by object ID.

## Symptom: Works on some devices, not others
**Likely cause:** Group membership, network path, or a device-specific install failure.
**Fix:**
1. Confirm the affected devices are in the assigned group (`HPWXP-Report.ps1`).
2. Confirm each affected device can reach the WXP endpoints (R9) and shows the app **Installed**.
3. Re-sync stragglers; for persistent failures, review the IntuneManagementExtension log on the device.

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or the app install failed.
**Fix:**
1. Run `HPWXP-Report.ps1` to list which devices lack the installed agent.
2. Run `HPWXP-Remediation.ps1` **(`-WhatIf` first)** to correct the assignment if the group isn't
   assigned.
3. Re-sync stragglers and confirm enrollment (R4) and network access (R9).

## Escalation checklist
Before opening an HP WXP or Microsoft support case, collect: the `HPWXP-Discovery.ps1` output (with the
`-AppName` / `-ConnectorAppName` you used), the app's Device install status export, the exact install
command (with the enrollment-code parameter redacted), the detection rule value, the device's
IntuneManagementExtension log, whether the device appears in the WXP console, the connector enterprise
application's name/object ID and granted permissions, and confirmation that the WXP service endpoints
are reachable from the device network (isolates agent-registration from connector issues).
