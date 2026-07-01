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
