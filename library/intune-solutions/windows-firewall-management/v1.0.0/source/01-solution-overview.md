# 1. Solution Overview — Windows Firewall Management

## What this is
Windows Defender Firewall is the built-in host firewall on every Windows device. This solution
manages it centrally through Microsoft Intune: enforcing it **on** for all network profiles,
setting default inbound/outbound behavior, deploying standardized firewall **rules**, and reporting
each device's firewall state — so the host firewall is consistent and auditable across the fleet.

## How it works
1. An Intune **firewall policy** (Endpoint security → Firewall) sets the firewall **on** for the
   **Domain, Private, and Public** profiles.
2. It defines **default actions** — typically **inbound = Block**, **outbound = Allow** — plus
   logging, stealth mode, and unicast-response behavior.
3. An optional **firewall rules** policy deploys specific allow/block rules (ports, apps, IP scopes).
4. Intune applies and **reports** the firewall state; devices that drift are visible.

## What you can manage
- **Firewall enabled** per profile (Domain/Private/Public).
- **Default inbound/outbound** actions.
- **Logging** (dropped packets, successful connections) and log size/path.
- **Stealth mode**, **shielded** mode, unicast response to multicast/broadcast.
- **Custom firewall rules** (allow/block by port, program, protocol, or address).

## Benefits
- **Consistent enforcement** — the firewall is on everywhere, no exceptions.
- **Default-deny inbound** — reduces exposure to lateral movement and scanning.
- **Centralized rules** — one managed rule set instead of per-device drift.
- **Visibility** — fleet-wide firewall-state reporting for compliance and audits.

## Limitations (be honest with buyers)
- Firewall settings can **conflict** with a legacy GPO firewall or the security baseline — manage in one place.
- Overly strict rules can block legitimate apps — pilot and validate first.
- Custom rules must be maintained as your app/port landscape changes.
- Some specialized scenarios (server roles, IPsec connection security rules) need extra design beyond this baseline.

## The standard deployment model
> **Create the firewall policy (on + default-deny inbound) → (optional) deploy rules → assign to a
> pilot → validate → expand.** repeatable pattern: **Assess → Configure → Pilot → Validate → Expand.**
