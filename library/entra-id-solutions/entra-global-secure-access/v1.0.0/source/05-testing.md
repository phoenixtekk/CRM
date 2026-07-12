# 5. Testing & Validation — Entra Global Secure Access (Internet & Private Access)

Validate on the **pilot** (`ENTGSA-Pilot`) and the pilot devices first. Each test has a **pass/fail**
signal. Do not expand until all gates pass. Reference scripts are named in each row.

## Test matrix

| # | Gate | What you do | Pass signal | Fail signal |
|---|------|-------------|-------------|-------------|
| 1 | **G1 Microsoft traffic** | On a pilot device signed in as a pilot user, open the GSA client status | Client shows **Connected**; **Microsoft** channel **Active**; M365 traffic tunneled | Client disconnected / Microsoft channel inactive |
| 2 | **G2 Private app reachable** | With the **VPN disconnected**, browse to the internal FQDN of `ENTGSA – PrivateApp – IntranetWeb – Pilot` | App loads over Private Access; no VPN needed | App unreachable / still needs VPN |
| 3 | **G2 No flat access** | From the same device, try to reach an internal host **not** in any published segment | Connection **fails** (only entitled segments are reachable) | Other internal hosts reachable (flat access) |
| 4 | **G2 Least privilege** | Sign in as a user **not** in `ENTGSA-Pilot` and try the private app | Access denied (not assigned) | Non-assigned user reaches the app |
| 5 | **G3 Internet block** | Browse to a site in a **blocked** category from `ENTGSA – WebFilter – Baseline` | Request is **blocked** by the SWG | Blocked category loads normally |
| 6 | **G3 Internet allow** | Browse to a normal business site | Loads normally; appears in traffic logs | Legitimate site blocked (over-filtering) |
| 7 | **G4 Conditional Access** | Access GSA traffic / the private app under `ENTGSA – CA – *` | **MFA / compliant device** is enforced as configured | Access granted without the required control |
| 8 | **G4 CAE revoke** | Revoke the pilot user's sessions (Entra → User → **Revoke sessions**) | Access is cut **near-real-time** (CAE) | Session persists long after revoke |
| 9 | **Logging** | Generate traffic, then run the traffic-log KQL | Rows appear for the pilot user's flows (allowed + blocked) | No rows / logging not flowing |

## Automated checks
- **`ENTGSA-Discovery.ps1`** — inventories GSA activation, enabled forwarding profiles, connector groups,
  published private apps + segments, filtering policies, and CA policies targeting GSA, so you can confirm
  the named objects exist with the expected configuration.
- **`ENTGSA-Validate.ps1`** — checks each **named** object from §3 is present and correctly wired (Microsoft
  profile on; private app has segments + `ENTGSA-Pilot` assigned; filtering policy linked to the security
  profile; CA policies target GSA and exclude break-glass) and **flags gaps** — the automated form of the
  gate table.
- **`ENTGSA-ConnectorHealth.ps1`** — reports each connector group and connector's **status/health** so you
  can confirm Private Access has a healthy path before testing G2.
- **`ENTGSA-Report.ps1`** — runs the **KQL** against the Log Analytics workspace to export traffic
  evidence: top destinations, allowed vs blocked, and per-user private-app access (the audit artifact).
- **`ENTGSA-TrafficLogs.ps1`** — focused KQL helper for **blocked/denied** flows and Private Access
  connection outcomes, for validating filtering and diagnosing reachability.

## Reference KQL (Global Secure Access traffic logs)
Run in **Log Analytics** (or via `ENTGSA-Report.ps1`). Table/field names may differ by tenant/preview —
verify against current schema.

```kql
// Allowed vs blocked internet traffic, last 24h
NetworkAccessTraffic
| where TimeGenerated > ago(24h)
| summarize Flows = count() by Action, DestinationFqdn
| order by Flows desc
```
```kql
// Private Access connections for the pilot app segments
NetworkAccessTraffic
| where TimeGenerated > ago(24h)
| where TrafficType == "Private"
| summarize Connections = count() by UserPrincipalName, DestinationFqdn, Action
| order by Connections desc
```

## Evidence to capture (for audit / go-live)
- Screenshot: GSA client showing **Connected** with the active channels.
- Screenshot: private app reachable **with VPN off**; and a **failed** connection to a non-published host.
- Screenshot: a blocked category page from the SWG.
- CA **Insights / report-only** results before enforcement, and enforcement confirmed after.
- `ENTGSA-Report.ps1` KQL export of allowed/blocked flows and per-user private-app access.

## Exit criteria (before Expand)
- [ ] G1 — Microsoft profile active and tunneling on pilot devices
- [ ] G2 — private app reachable **without VPN**, and **no** flat access to other hosts
- [ ] G3 — a blocked category is blocked; normal sites work
- [ ] G4 — Conditional Access enforced and **CAE** revokes access near-real-time
- [ ] Connectors healthy (`ENTGSA-ConnectorHealth.ps1`)
- [ ] Traffic logs flowing and queryable (`ENTGSA-Report.ps1`)
- [ ] `ENTGSA-Validate.ps1` shows no gaps for the pilot objects
