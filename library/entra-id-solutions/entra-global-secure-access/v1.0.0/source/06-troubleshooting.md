# 6. Troubleshooting — Entra Global Secure Access (Internet & Private Access)

Symptom → likely root cause → fix. Start with **`ENTGSA-Discovery.ps1`** (is GSA activated and are the
named objects present and wired?) and **`ENTGSA-Validate.ps1`** (which gate is failing?) — most GSA issues
are a disabled profile, an unhealthy connector, a DNS mismatch, or a CA policy scoped wrong.

## The Global Secure Access blades show a licensing banner / Internet or Private profile won't enable
- **Root cause:** the tenant/users lack **Microsoft Entra Internet Access / Private Access** licensing;
  the Microsoft profile works on **P1**, but the SWG and ZTNA profiles need the Entra Suite / add-ons.
- **Fix:** assign the correct SKU (M365 admin center → **Billing → Licenses**) to the operator and in-scope
  users, then re-open **Connect → Traffic forwarding**. *Verify current SKU coverage and preview status —
  it changes.*

## The GSA client won't connect / shows a channel inactive
- **Root cause:** the profile for that channel is **Off**, the device can't reach the GSA edge (outbound
  443 blocked), the signed-in user isn't in `ENTGSA-Pilot`, or the client version is outdated/unsupported.
- **Fix:** confirm the profile is **On** (Connect → Traffic forwarding); allow outbound 443 to the GSA
  service URLs; sign in as a pilot user; update the client. `ENTGSA-Validate.ps1` confirms which profiles
  are enabled tenant-side.

## A published private app is unreachable (with VPN off)
- **Root cause:** the connector group is **unhealthy**, the **application segment** doesn't match the FQDN/
  port the user is hitting, the user isn't assigned to the app, or the **Private Access profile is Off**.
- **Fix:** run **`ENTGSA-ConnectorHealth.ps1`** — connectors must be **Active**; confirm the segment covers
  the exact FQDN/IP and ports; confirm `ENTGSA-Pilot` is assigned to
  `ENTGSA – PrivateApp – IntranetWeb – Pilot`; confirm the **Private Access** profile is On.

## The private app resolves to the wrong address / "site can't be reached"
- **Root cause:** a **DNS mismatch** — the client resolves the private FQDN to a public/old address instead
  of routing it through GSA, or the connector host can't resolve it internally.
- **Fix:** configure **Private DNS / DNS suffix** on the published app so the client resolves it via GSA;
  confirm the connector host uses **internal DNS** and can `nslookup`/`Test-NetConnection` the app's
  FQDN/port. This is the single most common Private Access failure (Requirement 2.7).

## Users still have flat network access (can reach hosts you didn't publish)
- **Root cause:** the app segment is **too broad** (a whole subnet), or an old VPN route is still active on
  the device alongside GSA.
- **Fix:** narrow the **application segments** to the specific hosts/ports needed; disconnect/remove the
  VPN route for apps now served by Private Access. ZTNA only limits access to the segments you actually
  publish.

## Legitimate websites are being blocked (over-filtering)
- **Root cause:** `ENTGSA – WebFilter – Baseline` blocks a category that a business site falls under, or a
  needed FQDN isn't allow-listed.
- **Fix:** review the **blocked** flows in the traffic logs (`ENTGSA-TrafficLogs.ps1`), remove the
  over-broad category or add an **allow** rule for the specific FQDN, and re-test. Start minimal and
  tighten in measured steps.

## Internet traffic isn't being filtered at all
- **Root cause:** the **Internet Access** profile is Off, the CA policy `ENTGSA – CA – InternetAccess –
  Pilot` isn't attaching the **security profile**, or the CA policy is still **Report-only**.
- **Fix:** enable the Internet profile; in the CA policy **Session → Use Global Secure Access security
  profile → `ENTGSA – SecurityProfile – Baseline`**; switch the policy from Report-only to **On** once
  validated. `ENTGSA-Validate.ps1` flags a security profile not linked into CA.

## A Conditional Access policy locked users (or an admin) out of GSA traffic
- **Root cause:** the CA grant is too strict for the pilot, or **break-glass** wasn't excluded.
- **Fix:** set the offending `ENTGSA – CA – *` policy back to **Report-only**, confirm **break-glass**
  accounts (global requirement G4) are **excluded**, and sign in as break-glass to recover. Re-enable after
  correcting the grant/scope.

## No rows in the traffic-log KQL
- **Root cause:** the **diagnostic setting** (`ENTGSA – Diag – TrafficLogs`) isn't sending to the workspace,
  the wrong workspace is queried, or no pilot traffic has been generated yet.
- **Fix:** confirm the diagnostic setting targets the Log Analytics workspace and the GSA log categories are
  selected; query the **correct** workspace; generate pilot traffic and allow ingestion latency.
  `ENTGSA-Report.ps1` prints the workspace it queried.

## Continuous Access Evaluation isn't revoking sessions quickly
- **Root cause:** CAE isn't enabled on the CA policy session controls, or the app/scenario doesn't support
  CAE for that flow.
- **Fix:** enable **Customize continuous access evaluation** on `ENTGSA – CA – PrivateApp – Pilot` /
  `ENTGSA – CA – InternetAccess – Pilot`; verify with a **Revoke sessions** test (Testing gate G4).

---
### First moves for any GSA issue
1. `ENTGSA-Discovery.ps1` — is GSA activated and are the profiles/connector groups/apps/policies present?
2. `ENTGSA-ConnectorHealth.ps1` — are the Private Access connectors healthy (for any reachability issue)?
3. `ENTGSA-Validate.ps1` — which gate is failing (profile off, segment wrong, filter not linked, CA scope)?
4. `ENTGSA-TrafficLogs.ps1` — what do the allowed/blocked flow logs say for the affected user?
5. Only then change configuration — disable rather than delete to roll back, and keep the **VPN fallback**.
