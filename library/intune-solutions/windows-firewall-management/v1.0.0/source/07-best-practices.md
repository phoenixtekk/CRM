# 7. Best Practices — Windows Firewall Management

- **Enable all three profiles.** Domain, Private, and Public should all have the firewall on — no exceptions.
- **Default-deny inbound, allow outbound.** The single highest-value posture; add explicit allow rules only for required inbound services.
- **Pilot before fleet.** Default-deny inbound can block legitimate listeners — confirm required services work on a pilot first.
- **Inventory inbound needs first.** Know what must accept inbound (Remote Help, remote management, LOB servers) and pre-build those allow rules.
- **One firewall authority.** Manage the firewall via Intune only — retire the GPO firewall and remove firewall settings from the security baseline to avoid conflicts.
- **Decide on local rule merge.** Choose whether local admins can add rules; for locked-down fleets, disable local merge.
- **Enable logging.** Log dropped packets to diagnose blocked legitimate traffic quickly.
- **Use stealth mode.** Keep devices from responding to unsolicited probes.
- **Name rules clearly.** `Allow-Inbound-<service>-<port>` so intent is obvious in audits.
- **Report regularly.** Track firewall state across the fleet with `WFM-RuleReport.ps1` / Intune reporting.
