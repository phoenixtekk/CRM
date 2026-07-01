# 2. Requirements Guide — Zero Trust Network Access (ZTNA) with Netskope Private Access

Verify every requirement before configuring. Each entry: Description, Why, Verify, and
Implement-if-missing. Category-wide prerequisites are in `global-requirements-network.md`; the items
below are specific to ZTNA / Netskope Private Access.

## 2.1 Netskope Private Access entitlement
Description: The Netskope tenant has the Private Access (ZTNA) module enabled and licensed.
Why: Private Access is the service that publishes apps and brokers per-app access; without it there
is nothing to configure.
Verify: Sign in to your Netskope tenant admin console and confirm the Private Access capability is
present and licensed (defer the exact location to the Netskope documentation).
Implement: Engage your Netskope account team or reseller to enable and license the Private Access
module on the tenant.

## 2.2 Publisher (connector) host capacity
Description: A supported host (VM or appliance) in each network segment that hosts private apps, on
which a `publisher` can run and make outbound connections to the Netskope cloud.
Why: The `publisher` is the data-plane connector that reaches your internal apps; it must sit where
it can resolve and route to those apps and dial outbound to Netskope.
Verify: Confirm a candidate host exists per site/segment with outbound internet egress; run
`NSZTNA-Discovery.ps1` to record candidate hosts and their reachability.
Implement: Provision a host meeting Netskope's `publisher` sizing, allow outbound egress to the
Netskope cloud, then deploy the `publisher` (deferred to Netskope documentation for the exact image
and steps).

## 2.3 Private application inventory
Description: A documented inventory of every private app to be reached without the VPN — name,
internal host(s)/FQDN, port(s), and protocol.
Why: Each app becomes a named private-application object mapped to specific hosts/ports; an
incomplete inventory is the main cause of broken access at cutover.
Verify: Review the inventory; run `NSZTNA-Discovery.ps1` to capture VPN routes/hosts currently in
use as a starting list.
Implement: Build the inventory from VPN split-tunnel routes, DNS, and app owners; record each app as
`Private App – <App> – Inventory`.

## 2.4 Entra ID groups for app entitlement
Description: Microsoft Entra security groups that map users to the apps they are entitled to.
Why: Access policy is identity- and group-based; clean groups make least-privilege access
repeatable and auditable.
Verify: Entra portal, Groups; run `NSZTNA-Validation.ps1` to confirm the entitlement groups exist
and have members.
Implement: Create the groups (see `NSZTNA-Set-AccessGroupTargeting.ps1`), naming each
`Access Group – <App or Role> – <Stage>`.

## 2.5 The Netskope client deployed to endpoints
Description: The Netskope client (steering agent) installed and enrolled on target endpoints.
Why: The client steers private-app traffic to Netskope so sessions can be brokered per app; without
it the endpoint has no path to published apps.
Verify: On a pilot device, confirm the client is installed and enrolled; run `NSZTNA-Validation.ps1`
to check client presence/state.
Implement: Deploy the client via Intune (see global requirement G3) and enroll the device.

## 2.6 Device posture signals
Description: A device-posture source (managed/compliant state, certificate, or Netskope posture
check) usable in the access policy.
Why: Least-privilege access is identity- and posture-based; posture ensures only healthy, managed
devices reach sensitive apps.
Verify: Confirm devices are Intune-enrolled and compliant (`https://intune.microsoft.com`); run
`NSZTNA-Discovery.ps1` to record managed/compliance posture.
Implement: Enforce Intune compliance policies and deploy any required certificate, then reference
the posture in the access policy.

## 2.7 DNS resolution for private apps
Description: Endpoints (via Netskope) can resolve the internal names of published apps.
Why: Private apps are reached by name; name resolution must work through the ZTNA path, not only on
the old VPN.
Verify: From a pilot device with the client active, resolve a published app's FQDN; run
`NSZTNA-Validation.ps1` to test resolution/reachability of a published app.
Implement: Configure private DNS for the published apps per Netskope guidance (deferred to Netskope
documentation).

## 2.8 A pilot group and a VPN coexistence window
Description: An Entra security group of pilot users/devices, and an agreed window during which the
VPN and ZTNA run side by side before cutover.
Why: Access changes are disruptive if rushed; coexistence lets the pilot prove every app before the
VPN is retired, and provides the rollback path (fall back to VPN).
Verify: Entra, Groups: the pilot group `Access Group – Pilot – Pilot` exists; the coexistence window
and rollback are approved (global requirement G7).
Implement: Create the pilot group (`NSZTNA-Set-AccessGroupTargeting.ps1`) and document the
coexistence schedule and the fall-back-to-VPN rollback.

---
## Naming convention (use verbatim everywhere)
Every artifact is named `<Purpose> – <Scope> – <Stage>` and reused exactly across all guides:
- `Publisher – <Site> – Pilot` / `Publisher – <Site> – Production` — `publisher` (connector) per site.
- `Private App – <App> – Pilot` / `Private App – <App> – Production` — published private-application object.
- `Access Policy – <App or Role> – Pilot` / `Access Policy – <App or Role> – Production` — per-app access rule.
- `Access Group – <App or Role> – Pilot` / `Access Group – <App or Role> – Production` — Entra entitlement group.

## Checklist
- [ ] Netskope Private Access module enabled and licensed
- [ ] `Publisher` host capacity per site/segment with outbound egress
- [ ] Private application inventory documented (host/port/protocol)
- [ ] Entra entitlement groups created — `NSZTNA-Validation.ps1`
- [ ] Netskope client deployed and enrolled on endpoints
- [ ] Device posture (Intune compliance / certificate) available to policy
- [ ] DNS resolves published app names through the ZTNA path
- [ ] Pilot group + approved VPN coexistence window and rollback
