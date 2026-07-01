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
