# 7. Best Practices — HP Workforce Experience Platform (WXP) Integration with Intune

These practices keep the WXP integration precise, predictable, and reversible. They assume the
deployment model in the Solution Overview: the **HP WXP agent deployed as a Required Intune Win32 app**
carrying your enrollment code, plus a **tenant connector** established by an Entra admin-consent flow —
deployed pilot-first.

## Package the agent the Intune way
- **Wrap once, deploy many.** Package the HP-provided installer into a single `.intunewin` and deploy it
  as **`HP WXP Agent - Pilot`**. Re-wrap only when HP ships a new agent version.
- **Inject the enrollment code in the install command, never by hand.** The whole point of
  agent-via-Intune is zero-touch registration to *your* WXP tenant — put the enrollment code in the
  install command line (Step 6). **Verify the exact parameter name in HP's agent documentation.**
- **Get the detection rule right first.** A wrong MSI product code or file/version detection causes
  reinstall loops and false failures. Capture the detection value from a **reference device** and test
  it (Testing Test 4) before you widen.
- **Install as System, silent.** Use the vendor's silent switches and a System install context so it
  applies without a signed-in user.

## Keep the enrollment code and console values verified, not assumed
- **Treat HP-renamed labels as tenant-specific.** HP has renamed this platform (TechPulse / Proactive
  Insights / Adaptive Endpoint Management → Workforce Experience Platform). The **console menus, agent
  filename, enrollment-code label, connector app name, Graph scopes, and WXP endpoint URLs vary** — read
  the current values from the **HP WXP admin console / HP documentation**, and record them in your
  runbook so the next admin isn't guessing.
- **Confirm the connector app's display name in your tenant** and pass it to the scripts via
  `-ConnectorAppName`; don't assume `HP Workforce Experience`.

## Establish the connector cleanly
- **One Global-Admin consent, reviewed.** The WXP→Intune connection is a one-time admin-consent action.
  **Read the exact permissions on the consent screen** before granting — WXP should request **read**
  access to device inventory; question anything broader.
- **Record what consent created.** After consent, note the enterprise application (name + object ID) in
  your runbook so you can review or revoke it later (Entra → Enterprise applications).

## Deploy pilot-first and reversibly
- **Assign to `HP WXP - Pilot Devices`, never "All devices" first.** Expand in waves after each gate
  passes.
- **Rollback is unassignment (+ optional uninstall).** Removing the app assignment stops new installs;
  add an **Uninstall** assignment to remove the agent where needed. Revoking the enterprise application
  in Entra severs the cloud connection. Because this is an added app + a consented app, both halves are
  reversible without touching enrollment.

## Position WXP alongside, not instead of, Microsoft-native monitoring
- **Keep Endpoint Analytics enabled.** WXP adds hardware/sustainability/proactive-support telemetry;
  Endpoint Analytics remains the Microsoft-native startup/reliability score. Run **both** — see the
  *Endpoint Analytics Deployment & Optimization* solution. Do not disable Endpoint Analytics to "avoid
  overlap."
- **Use WXP for what it uniquely sees.** Prioritize WXP for **battery/thermal/SSD/component health**,
  **sustainability/CO₂ and lifecycle** reporting, and **proactive/predictive** support — the signals a
  software-only DEX score cannot produce. For the vendor-neutral health/experience view, see the
  *Endpoint Health & Digital Experience Monitoring* solution.

## Operate and monitor
- **Report before you widen.** Run `HPWXP-Report.ps1` each wave; only broaden when installed-coverage
  matches the assigned group **and** the devices actually appear in the WXP console.
- **Remediate with `-WhatIf` first.** `HPWXP-Remediation.ps1` and `HPWXP-Set-ScopeTargeting.ps1` preview
  by default — read the plan, then apply.
- **Watch the network path.** If devices install the agent but don't report, the WXP **service
  endpoints** are usually blocked or TLS-inspected — allow HP's published URLs and exempt
  inspection-sensitive endpoints (R9).

## Change control
- **Version the agent and the runbook.** When HP ships a new agent, re-wrap, bump the app version, and
  note the enrollment-code/parameter and any renamed console labels. Re-run Discovery and Report to
  confirm no regressions.
- **Review after major changes.** Re-verify the connector permissions and agent reporting after HP
  platform renames/updates or major Windows releases before expanding further.
