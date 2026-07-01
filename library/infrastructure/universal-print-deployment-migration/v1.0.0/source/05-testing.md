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
