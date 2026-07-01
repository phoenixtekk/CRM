# Universal Print Deployment & Print-Server Retirement

> **Version 1.0.0** · Category: Infrastructure · Solution code: UPRT

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary — Universal Print Deployment & Print-Server Retirement

Print servers are a quiet liability: a box (or several) you patch, back up, and pray never falls
over on a Monday morning, plus driver sprawl and GPO printer mappings that only work on the
corporate LAN. **Microsoft Universal Print** moves printing to a Microsoft-hosted cloud service —
printers are shared from Entra ID, deployed to users and devices through Intune, and reachable
wherever people work — so the print servers can be decommissioned entirely.

This is a complete, deploy-it-today package for migrating to Universal Print and retiring print
servers, written for an administrator with no prior Universal Print experience. It uses a
coexistence-then-cutover approach: connect the existing printers, prove cloud printing on a pilot,
then retire the old queues and servers.

## What you get
- A plain-language **Solution Overview** of how Universal Print works — the connector model, Entra ID printer sharing, Intune-driven printer deployment, and the path to retiring print servers.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite.
- An **Implementation Guide** of precise, click-by-click steps in the required order.
- Five **PowerShell scripts** for print-environment discovery, Universal Print readiness and print validation, a printer/deployment inventory report, safe remediation of failed deployments, and a printer-deployment group builder.
- **Testing** and **Troubleshooting** guides for confident rollout, plus field-proven **Best Practices.**

## What this delivers
Cloud-delivered printing for every user — printers registered through a Universal Print connector,
shared from Entra ID, and deployed by group through Intune so they appear automatically on managed
devices, reachable on or off the corporate network. Once the pilot validates printing, the old
print queues and servers are retired in a controlled cutover.

## The repeatable deployment model
Assess → Configure → Pilot → Validate → Expand — with a pilot gate before any server retirement.

## Outcome
Printers shared from Entra ID and deployed through Intune, reachable from anywhere, with the print
servers decommissioned — proven on a pilot before you scale, and deployable by a single administrator.


---


# 1. Solution Overview — Universal Print Deployment & Print-Server Retirement

## What Universal Print is
Microsoft Universal Print is a cloud-based print service hosted in Microsoft 365. Instead of an
on-premises print server hosting queues and drivers, printers are registered in the Universal Print
service, **shared from Entra ID**, and **deployed to users and devices through Intune**. Managed
Windows devices receive the printers automatically and print over HTTPS to the cloud service, which
routes the job to the printer — on or off the corporate network. The goal of this solution is to
get there in an orderly way and then **retire the print servers**.

## How it works
1. A printer reaches Universal Print one of two ways: it is **Universal Print-ready** (registers
   itself directly with the service), or it is a normal printer reached through a **Universal Print
   connector** — a small Windows service you install on a host that already sees those printers.
2. Once registered, an administrator **shares** the printer in the Universal Print portal. The share
   becomes an object in Entra ID that you can grant members and deploy.
3. **Intune printer deployment** assigns shared printers to Entra ID **groups**. Devices (or users)
   in a targeted group receive the printer automatically — no driver staging, no GPO mapping.
4. A user prints; the device sends the job to Universal Print over HTTPS; the service hands it to
   the printer directly (Universal Print-ready) or back through the connector to the physical printer.
5. Because routing is cloud-side, printing works the same **on the LAN, over VPN, or from home** —
   as long as the device and the connector host can reach the service.

## Why retire the print server
The connector is not a permanent replacement for a print server — it is the **bridge** that lets
existing printers participate in Universal Print during migration. Once printers are registered,
shared, deployed by Intune, and validated on a pilot, the old print queues and the server hosting
them no longer carry production traffic and can be decommissioned. That removes a patched, backed-up
box, ends driver sprawl, and eliminates LAN-only printing — the whole reason for the migration.

## What you can control
- Which printers are registered (connector-attached vs. Universal Print-ready) and their **share names.**
- Who can use each printer — membership of the printer's Entra ID share and the deployment group.
- How printers reach devices — **Intune printer deployment** targeted by group, per device or per user.
- Coexistence: run the old queues and Universal Print **side by side** during the pilot, then cut over.

## Benefits
- **No print servers** — decommission the boxes you patch, back up, and worry about.
- **Print from anywhere** — cloud routing works on or off the corporate network.
- **Assign once, repeat everywhere** — deploy by group; new users in the group get the printer automatically.
- **Less driver sprawl** — devices use the in-box Universal Print client, not per-model drivers and GPO scripts.
- **Identity-based access** — printer access is governed through Entra ID groups.

## Limitations (be honest with buyers)
- Non-Universal-Print-ready printers need a **connector host** that stays online to relay jobs; that host must be reachable for those printers to print.
- Each connector has a printer-count and throughput ceiling; large estates may need more than one connector.
- Advanced finishing/print-accounting features depend on printer and connector support; verify per model.
- Devices and the connector host need reliable outbound HTTPS to the Universal Print endpoints.
- Universal Print requires eligible Microsoft 365 licensing with print volume allotment (see requirements).

## The repeatable deployment model
> Register existing printers via the connector → share them in Entra ID → deploy to groups via Intune
> → validate on a pilot (on and off network) → retire the old queues/servers → expand. Pattern:
> Assess → Configure → Pilot → Validate → Expand, with a pilot gate before server retirement.


---


# 2. Requirements Guide — Universal Print Deployment & Print-Server Retirement

Verify **every** requirement before configuring. Each entry: Description · Why · Verify ·
Implement-if-missing. Category-wide prerequisites are in `global-requirements-infrastructure.md`.

> Naming convention used throughout this solution (reuse verbatim):
> `<Purpose> – <Scope> – <Stage>`. The objects you will create are:
> - Connector host name: `UniversalPrint – Connector – Site1`
> - Registered/shared printer name: `UniversalPrint – <Model/Location> – Shared` (e.g. `UniversalPrint – HQ-Floor2-MFP – Shared`)
> - Printer-deployment group (pilot): `UniversalPrint – Printers – Pilot`
> - Printer-deployment group (broad): `UniversalPrint – Printers – Broad`

## 2.1 Universal Print licensing
Description: Eligible Microsoft 365 licensing that includes Universal Print and print-volume allotment.
Why: Universal Print is a licensed Microsoft 365 service; registered printers consume print-job allotment.
Verify: Microsoft 365 admin center → **Billing → Licenses**; the Universal Print portal loads at `https://portal.azure.com` → search `Universal Print`.
Implement: Assign a qualifying license (e.g. Microsoft 365 E3/E5, or a Universal Print add-on/Windows Enterprise plan that includes it); confirm print-volume allotment.

## 2.2 Entra ID and Intune (deployment plane)
Description: An Entra ID tenant with Intune, to share printers and deploy them by group.
Why: Printer sharing is an Entra ID object; Intune printer deployment targets Entra ID groups.
Verify: `https://entra.microsoft.com` and `https://intune.microsoft.com` both load.
Implement: See `global-requirements-infrastructure.md` G1–G3.

## 2.3 Connector host (for existing printers)
Description: A Windows host (Windows 10/11 or Windows Server) that already reaches your existing printers, to run the Universal Print connector.
Why: Non-Universal-Print-ready printers reach the service only through the connector; the host must stay online.
Verify: Run `UPRT-Validation.ps1`; confirm the candidate host can ping/print to the target printers and has outbound HTTPS.
Implement: Choose a reliable always-on host with line-of-sight to the printers; you will install the connector in the Implementation Guide.

## 2.4 Existing print inventory (servers, queues, drivers)
Description: A known inventory of current print servers, shared queues, and drivers to migrate.
Why: You cannot retire what you have not accounted for; the inventory drives the registration list.
Verify: Run `UPRT-Discovery.ps1` against each print server; run `UPRT-Report.ps1` for a consolidated list.
Implement: Capture the printer list, ports, and drivers; mark which printers are Universal Print-ready vs. connector-attached.

## 2.5 Network / firewall reachability
Description: Outbound HTTPS from devices and the connector host to the Universal Print endpoints.
Why: Devices submit jobs and the connector relays them to the service over HTTPS; blocked endpoints stall printing.
Verify: From a device and the connector host, the Universal Print sign-in and service endpoints are reachable (run `UPRT-Validation.ps1`).
Implement: Allow Microsoft's published Universal Print / Microsoft 365 URLs and IP ranges through the proxy/firewall.

## 2.6 Universal Print Administrator role
Description: The operator holds the **Printer Administrator** (or Global Administrator) role for Universal Print.
Why: Registering, sharing, and managing printers requires the Universal Print admin role.
Verify: Universal Print portal → **Settings → role** shows Printer Administrator; or Entra → **Roles and administrators**.
Implement: Assign **Printer Administrator** to the operator in Entra ID.

## 2.7 Pilot and broad deployment groups
Description: Entra ID security groups for the printer-deployment pilot and broad populations.
Why: Intune deploys printers by group; the pilot group is the gate before retirement.
Verify: Entra → **Groups**; `UniversalPrint – Printers – Pilot` and `UniversalPrint – Printers – Broad` exist.
Implement: Create them (Implementation Step 5 builds them, or use `UPRT-Set-PrinterDeploymentTargeting.ps1`).

---
## Checklist
- [ ] Universal Print licensing assigned (with print-volume allotment)
- [ ] Entra ID + Intune available (G1–G3)
- [ ] Connector host selected and reachable — `UPRT-Validation.ps1`
- [ ] Existing print inventory captured — `UPRT-Discovery.ps1` / `UPRT-Report.ps1`
- [ ] Network allows Universal Print endpoints — `UPRT-Validation.ps1`
- [ ] Printer Administrator role assigned
- [ ] `UniversalPrint – Printers – Pilot` and `UniversalPrint – Printers – Broad` groups created


---


# Global Requirements — Infrastructure Solutions (category-level)

These requirements apply to **every** solution in the **Infrastructure** category. They are
published once at the category level so individual listings stay small. Confirm these before
deploying *any* Infrastructure solution. Each entry: Description · Why · Verify · Implement-if-missing.

## G1. Microsoft Entra ID tenant
Description: An active Microsoft Entra ID (Azure AD) tenant.
Why: It is the identity backbone for Microsoft 365, Entra ID, and Intune-managed infrastructure — including device sign-in, group targeting, and shared cloud resources.
Verify: Sign in to `https://entra.microsoft.com` as an administrator.
Implement: Create a Microsoft 365 / Azure subscription, which provisions a tenant.

## G2. Microsoft 365 / Intune subscription
Description: A Microsoft 365 plan that includes Microsoft Intune and the cloud service the solution relies on.
Why: Intune delivers configuration, deployment, and policy targeting; the bundled Microsoft 365 services back the cloud capability being deployed.
Verify: `https://intune.microsoft.com` loads; **Tenant administration → Tenant status** shows active.
Implement: Assign Microsoft 365 E3/E5, Business Premium, or standalone Intune Plan 1.

## G3. Administrative roles
Description: Appropriate Entra / Intune admin roles for the operator.
Why: Creating cloud service settings, policies, and deployments requires elevated rights.
Verify: Entra → **Roles and administrators**; confirm **Intune Administrator** (plus any service-specific admin role the solution calls out).
Implement: Assign **Intune Administrator**; reserve Global Administrator for tenant-wide changes.

## G4. Device enrollment in Intune
Description: Targeted Windows devices are enrolled and manageable.
Why: Deployments and policies only reach enrolled, Entra-joined devices.
Verify: Intune → **Devices → All devices**; the device appears and is **compliant**.
Implement: Enable **Automatic Enrollment** and join devices to Entra ID.

## G5. Pilot security group
Description: A Microsoft Entra security group for the pilot population (users or devices).
Why: Every solution is piloted before fleet rollout — the pilot is the gate.
Verify: Entra → **Groups**; the pilot group exists.
Implement: Entra → **Groups → New group** → **Security** → add members.

## G6. Supported Windows baseline
Description: Windows 10 21H2+ or Windows 11 with current updates.
Why: Modern Intune and Microsoft 365 cloud features assume a patched, supported OS.
Verify: `winver`, or Intune → device → **Hardware**.
Implement: Deploy update rings or upgrade to Windows 11.

## G7. Network access to Microsoft cloud endpoints
Description: Outbound HTTPS to Microsoft 365, Entra, and Intune service URLs.
Why: Enrollment, policy sync, authentication, and the cloud service traffic depend on these endpoints.
Verify: From a device, reach `https://login.microsoftonline.com` and `https://enrollment.manage.microsoft.com`.
Implement: Allow Microsoft's published Microsoft 365 / Intune URL and IP ranges through the proxy/firewall.

---
The repeatable deployment model (all solutions): Assess → Configure → Pilot → Validate → Expand.


---


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


---


# 5. Testing Guide — Universal Print Deployment & Print-Server Retirement

Run after the pilot deployment applies (Implementation Step 7) and again before retiring any server.

## Test 1 — Printer registered and shared
Do: Universal Print portal → **Printers**; confirm each migrated printer is **Registered** and **Shared** with the name `UniversalPrint – <Model/Location> – Shared`.
Expected: Every targeted printer appears as Shared with the agreed name.

## Test 2 — Connector healthy
Do: Universal Print portal → **Connectors**; check `UniversalPrint – Connector – Site1` status; run `UPRT-Validation.ps1` on the host.
Expected: Connector shows **Active/Healthy**; the host has outbound HTTPS to the service.

## Test 3 — Printer deploys automatically to the pilot
Do: On a synced pilot device (member of `UniversalPrint – Printers – Pilot`), open **Settings → Printers & scanners**.
Expected: The deployed printer appears **without** a manual add.

## Test 4 — Test print on the corporate network
Do: From the pilot device on the LAN, print a test page to the deployed printer (or run `UPRT-Validation.ps1`).
Expected: The job completes and paper is produced.

## Test 5 — Test print off network
Do: Disconnect from the corporate LAN (VPN off / home / hotspot) and print the same test page.
Expected: The job completes — cloud routing works off network (the connector host must be reachable for connector-attached printers).

## Test 6 — Deployment coverage report
Do: Run `UPRT-Report.ps1`.
Expected: A per-printer / per-group deployment inventory showing the pilot group covered.

## Test 7 — Old-queue traffic falling (pre-retirement)
Do: On the old print server, review the print queue's job activity over the coexistence window.
Expected: Production jobs on the old queue trend to near zero as Universal Print takes over.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass; pilot devices print on **and** off network through Universal Print |
| Retirement gate | Test 7 confirms near-zero old-queue traffic for a printer before its old queue/server is removed |


---


# 6. Troubleshooting Guide — Universal Print Deployment & Print-Server Retirement

Use `UPRT-Validation.ps1` / `UPRT-Discovery.ps1` for device and print-environment state,
`UPRT-Report.ps1` for deployment coverage, and `UPRT-Remediation.ps1` (default `-WhatIf`) for safe fixes.

## A. Printer not appearing on a device
| Symptom | Cause | Remediation |
|---|---|---|
| Deployed printer never shows up | Device not synced, or not in the target group | Sync the device; confirm membership of `UniversalPrint – Printers – Pilot`/`Broad`; run `UPRT-Remediation.ps1` |
| Some devices get it, others don't | Mixed group membership or stale assignment | Run `UPRT-Report.ps1` for coverage; reconcile group membership |
| Printer added manually but not via Intune | Printer shared but no Intune printer deployment | Create the Universal Print printer deployment and assign the group (Implementation Step 6) |

## B. Print jobs fail or hang
| Symptom | Cause | Remediation |
|---|---|---|
| Jobs stuck "Sending" | Connector host offline/unreachable | Check `UniversalPrint – Connector – Site1` status in the portal; ensure the host is on and has outbound HTTPS |
| Works on LAN, fails off network | Connector host not reachable, or endpoint blocked off-site | Confirm the connector host stays reachable; allow Universal Print endpoints on the off-network path |
| Job errors immediately | Printer not Shared, or user lacks access | Confirm the printer is Shared; deploy via Intune group rather than per-user share |

## C. Connector problems
- Connector shows Offline: confirm the Windows service is running on the host, the host signed in with the Printer Administrator account, and outbound HTTPS to the service is open. Re-run `UPRT-Validation.ps1`.
- Printers missing from the connector: re-open the connector app and re-register the printers the host can see; large estates may need a second connector.

## D. Licensing / volume
- Printer registration blocked or jobs rejected: confirm Universal Print licensing is assigned and print-volume allotment is not exhausted (Microsoft 365 admin center → Billing → Licenses).

## E. Old queue and new printer both present (during coexistence)
- This is expected during coexistence. Once the printer's users are validated on Universal Print, remove the old shared queue (disable first) so users stop selecting the legacy path.

## F. Diagnostics quick reference
```powershell
Get-Printer | Select-Object Name, DriverName, PortName, Shared, Published
Get-PrintConfiguration -PrinterName "<name>"          # per-queue settings
Get-Service -Name "PrintWorkflowUserSvc*","Spooler"   # local print services
# Universal Print via Graph (uses Invoke-MgGraphRequest against /print endpoints):
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/printers" | Out-String
Invoke-MgGraphRequest -Method GET -Uri "/v1.0/print/shares"   | Out-String
```

## G. When to escalate
If the printer is Registered + Shared, the connector is healthy, the device is synced and in the
correct group, endpoints are reachable on the failing network, and jobs still fail, collect the
connector logs and `UPRT-Validation.ps1` output and open a Microsoft support case for Universal Print.


---


# 7. Best Practices — Universal Print Deployment & Print-Server Retirement

- **Pilot before you retire, always.** Prove printing on a small `UniversalPrint – Printers – Pilot` group, on and off network, before adding the broad group or touching a print server. The pilot gate is the single most important practice.
- **Coexist, then cut over.** Run the old queues and Universal Print side by side; only remove an old queue once that printer's users are fully on Universal Print and traffic has fallen to near zero.
- **Name everything consistently.** Use `<Purpose> – <Scope> – <Stage>` for the connector, shared printers, and deployment groups, and reuse the names verbatim. Consistent share names make deployment, reporting, and troubleshooting far easier.
- **Deploy by group, not by user.** Assign printers to Entra ID groups through Intune so new members get the printer automatically — assign once, repeat everywhere.
- **Mind the connector host.** It is the bridge for non-Universal-Print-ready printers; keep it always-on, patched, and reachable. Split large estates across multiple connectors to stay under printer-count and throughput ceilings.
- **Confirm off-network printing explicitly.** The whole point is print-from-anywhere; test from home/VPN-off, not just the LAN.
- **Disable before delete.** When retiring an old queue, disable it briefly before deletion so you have a fast rollback if a job path was missed.
- **Clean up the old plumbing.** Remove GPO printer mappings and leftover drivers after cutover so devices stop trying the old path.
- **Watch coverage and licensing.** Track deployment coverage with `UPRT-Report.ps1` and keep an eye on print-volume allotment as you expand.
- **Document the migration.** Record which printers are Universal Print-ready vs. connector-attached, their share names, group assignments, and the retirement date of each old server for audits and repeatability.


---


# 8. Deliverables Summary — Universal Print Deployment & Print-Server Retirement

## Documentation
| Document | Purpose |
|---|---|
| Executive Summary | Business case and what's in the box |
| 1. Solution Overview | What Universal Print is, the connector model, Entra ID sharing, Intune deployment, why retire the server |
| 2. Requirements Guide | Every prerequisite with Verify / Implement-if-missing, plus the naming convention |
| Global Requirements (Infrastructure) | Category-wide prerequisites, published once |
| 3. Implementation Guide | Exact, ordered steps (license, connector, share, deploy, validate, retire) |
| 5. Testing Guide | Validation procedures with pass/fail and retirement gates |
| 6. Troubleshooting Guide | Field issues and remediation |
| 7. Best Practices | Field-proven recommendations |

## PowerShell scripts
| Script | What it does |
|---|---|
| `UPRT-Discovery.ps1` | Discovers print servers/queues/drivers via the PrintManagement module (read-only) |
| `UPRT-Validation.ps1` | Universal Print readiness checks + a test print (read-only) |
| `UPRT-Report.ps1` | Printer + deployment inventory across queues and Universal Print (read-only) |
| `UPRT-Remediation.ps1` | Safely fixes failed printer deployments — default `-WhatIf` |
| `UPRT-Set-PrinterDeploymentTargeting.ps1` | Builds the printer-deployment groups and stages membership |

## What the buyer receives
- This implementation guide as a branded Word document and PDF.
- All five PowerShell scripts in a single ZIP.
- A repeatable process: Assess → Configure → Pilot → Validate → Expand, with a pilot gate before server retirement.

## Outcome
Cloud-delivered printing for every user — printers shared from Entra ID and deployed through Intune,
reachable on or off network — with the old print servers decommissioned, proven on a pilot before scale.
