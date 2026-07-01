# 3. Implementation Guide — Universal Print Deployment & Print-Server Retirement

Follow these steps **in order**. You will work in the **Universal Print portal** (open
`https://portal.azure.com` and search `Universal Print`, or use the Microsoft Intune admin center),
on a **Windows connector host**, and in the **Microsoft Intune admin center** (`https://intune.microsoft.com`).

> Model: register existing printers through a connector, share them in Entra ID, deploy by group via
> Intune, validate on a pilot on and off network, then retire the old queues and servers.
> Reuse the names from the Requirements Guide verbatim.

## Step 0 — Assess the current print environment
1. Run `UPRT-Discovery.ps1` on each print server to list queues, ports, and drivers.
2. Run `UPRT-Report.ps1` for a consolidated printer inventory; mark each printer as Universal Print-ready or connector-attached.

## Step 1 — Enable and confirm Universal Print licensing
1. In the Universal Print portal (`https://portal.azure.com` → search `Universal Print`), open **Overview** and confirm the service is active and licensed.
2. Microsoft 365 admin center → **Billing → Licenses** — confirm the Universal Print allotment and that operators hold the **Printer Administrator** role.

## Step 2 — Install the Universal Print connector and register existing printers
1. On the chosen connector host, name the machine `UniversalPrint – Connector – Site1` (record this; it identifies the connector in the portal).
2. Download the **Universal Print connector** from the Universal Print portal (**Connectors → Add**, follow the download link) and install it on the host.
3. Launch the connector, sign in with the **Printer Administrator** account, and register the host. The connector enumerates the printers the host can already see.
4. Select the existing printers to bring into Universal Print and **Register** them. They now appear in the portal under **Printers**.
5. (Universal Print-ready printers register themselves directly from the device's own settings — no connector needed; confirm they appear under **Printers**.)

## Step 3 — Share the printers in Entra ID
1. Universal Print portal → **Printers** → select a registered printer → **Share**.
2. Set the **Share name** to `UniversalPrint – <Model/Location> – Shared` (e.g. `UniversalPrint – HQ-Floor2-MFP – Shared`). Reuse this convention for every printer.
3. Under **Members**, you can grant users/groups here, but for managed devices prefer Intune deployment (Step 5). **Share**.
4. Repeat for each printer being migrated.

## Step 4 — Verify a shared printer manually (pre-pilot smoke test)
1. On your admin device, **Settings → Bluetooth & devices → Printers & scanners → Add device → Search Universal Print for printers**, add the shared printer, and print a test page.
2. Confirm the job completes through the connector (or directly for Universal Print-ready). If this fails, fix it before deploying broadly — run `UPRT-Validation.ps1`.

## Step 5 — Build the printer-deployment groups
1. Entra → **Groups → New group** → Security → `UniversalPrint – Printers – Pilot` (a few representative devices/users). **Create**.
2. Create `UniversalPrint – Printers – Broad` (the rest of the population). **Create**.
3. Alternatively, run `UPRT-Set-PrinterDeploymentTargeting.ps1` to create these groups and stage their membership.

## Step 6 — Deploy printers to the pilot via Intune
1. Intune → **Devices → Manage devices → Configuration → Universal Print printer deployment** (or **Devices → Windows → Universal Print printer deployment**) → **Add / Create**.
2. Select the shared printer (e.g. `UniversalPrint – HQ-Floor2-MFP – Shared`).
3. **Assignments → Add groups →** `UniversalPrint – Printers – Pilot`. **Create**.
4. Repeat for each pilot printer. Targeted devices receive the printer automatically on next sync.

## Step 7 — Validate the pilot (on and off network)
1. On a pilot device synced to policy, confirm the deployed printer appears in **Printers & scanners** without manual add.
2. Print a test page **on the corporate LAN**, then **off network** (VPN off / home / hotspot) and confirm both complete.
3. Run `UPRT-Validation.ps1` (readiness + a test print) and `UPRT-Report.ps1` (deployment coverage). Complete the Testing Guide.

## Step 8 — Pilot gate, then expand to broad
1. Only after the pilot passes (Testing Guide gate) add the broad population: edit each printer deployment → **Assignments → Add groups →** `UniversalPrint – Printers – Broad`.
2. Re-validate coverage with `UPRT-Report.ps1`; remediate any failed deployments with `UPRT-Remediation.ps1` (default `-WhatIf`).

## Step 9 — Retire the old print queues and servers (coexistence → cutover)
1. During coexistence, the old queues and Universal Print run side by side. Watch the old print server's job logs; as Universal Print coverage grows, traffic on the old queues should fall to near zero.
2. When a printer's users are fully on Universal Print, **remove the old shared queue** (or block new connections) for that printer; leave it briefly disabled before deletion as a rollback hedge.
3. Once **all** migrated printers show no production traffic on the old server, decommission the print server (remove the print role / power down the box) and remove leftover GPO printer mappings.
4. Keep the connector host running — it remains the bridge for connector-attached printers.

---
### Order of operations
`Assess → Enable licensing → Install connector + register → Share in Entra ID → Manual smoke test →
Build groups → Deploy to pilot → Validate (on/off network) → Pilot gate → Expand → Retire servers`
