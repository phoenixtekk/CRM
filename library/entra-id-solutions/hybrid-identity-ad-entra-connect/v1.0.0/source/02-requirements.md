# 2. Requirements Guide — Hybrid Identity with Active Directory & Microsoft Entra Connect

Verify every requirement before configuring. Each entry: Description / Why / Verify /
Implement-if-missing. Category-wide prerequisites are in `global-requirements-entra-id-solutions.md`.

## 2.1 Entra ID licensing
Description: Microsoft Entra ID P1 (P2 if you also want risk-based sign-in or PIM).
Why: Hybrid features (Seamless SSO, password writeback, Conditional Access for hybrid join) need P1+.
Verify: M365 admin center -> `Billing -> Licenses`.
Implement: Assign M365 E3/E5, EMS, or standalone Entra ID P1/P2.

## 2.2 Entra Connect host server
Description: A dedicated, patched, domain-joined Windows Server 2016 or later for Connect Sync.
Why: The sync engine runs as a service here and must reach AD and Entra ID over HTTPS.
Verify: Server is domain-joined, patched, TLS 1.2 enabled; run `HYBID-Discovery.ps1`.
Implement: Provision a server (not a production domain controller), patch it, enable TLS 1.2, and install the ActiveDirectory PowerShell module.

## 2.3 Healthy Active Directory
Description: AD replication, DNS, and time sync are healthy across domain controllers.
Why: Sync reads from AD; replication or DNS faults stall or corrupt synchronization.
Verify: `dcdiag` and `repadmin /replsummary` clean on a DC; run `HYBID-Discovery.ps1`.
Implement: Resolve replication, DNS, and time-sync errors before synchronizing.

## 2.4 UPN and domain hygiene
Description: User UPNs use a public, verified, routable domain (no `.local`); no duplicate UPNs or proxyAddresses.
Why: Non-routable or duplicate UPNs/proxyAddresses cause sign-in failures and sync errors (merged/split accounts).
Verify: Entra -> `Identity -> Settings -> Domain names` shows the public domain Verified; run `HYBID-Discovery.ps1` (flags `.local` UPNs and duplicates).
Implement: Add and verify the public domain in Entra; add the matching UPN suffix in AD; update user UPNs; resolve duplicates with `HYBID-Remediation.ps1`.

## 2.5 Authentication method decision
Description: A decision on the primary authentication method — PHS, PTA, or federation.
Why: It is the single most consequential design choice and drives the install options.
Verify: A documented decision (default PHS) and whether Seamless SSO and password writeback are wanted.
Implement: Default to password hash sync with Seamless SSO; choose PTA or federation only for a stated requirement, and keep PHS enabled as a backup.

## 2.6 Administrative roles
Description: Hybrid Identity Administrator for ongoing work; Global Administrator for the first-sync consent.
Why: Configuring directory sync and authentication needs these roles.
Verify: Entra -> `Roles and administrators`.
Implement: Assign `Hybrid Identity Administrator`; use a `Global Administrator` only for the one-time first-sync grant.

## 2.7 Break-glass accounts
Description: Two cloud-only emergency access accounts excluded from broad policies.
Why: An identity change can lock out admins; break-glass accounts restore access.
Verify: Entra -> `Users`; two cloud-only `@onmicrosoft.com` admins exist.
Implement: Create them, exclude from Conditional Access/MFA-broad policies, store credentials securely, and monitor their sign-ins.

## 2.8 Pilot scope group
Description: An AD organizational unit (or group) of representative pilot users/devices.
Why: Every change is validated on a pilot before the fleet.
Verify: An OU such as `Hybrid Pilot Sync Scope - Pilot - Pilot` exists with representative members.
Implement: Create the pilot OU and place pilot users/devices in it; see Implementation Step 1.

## 2.9 Network access
Description: Outbound HTTPS (443) from the Connect host to Entra ID and Microsoft 365 endpoints.
Why: Sync, authentication agents, and tokens depend on these endpoints.
Verify: From the host, reach `https://login.microsoftonline.com`; Microsoft 365 URL/IP ranges allowed.
Implement: Allow the Microsoft 365 / Entra published URL and IP ranges through proxy/firewall.

---
## Checklist
- [ ] Entra ID P1/P2 licensing assigned
- [ ] Entra Connect host server ready (domain-joined, patched, TLS 1.2) — `HYBID-Discovery.ps1`
- [ ] Active Directory healthy (`dcdiag`, `repadmin`)
- [ ] UPN/domain hygiene fixed (public verified domain, no duplicates) — `HYBID-Discovery.ps1`
- [ ] Authentication method decided (default PHS) and Seamless SSO/writeback choices made
- [ ] Hybrid Identity Administrator role assigned; Global Admin available for first sync
- [ ] Two break-glass accounts created and excluded from broad policies
- [ ] Pilot sync scope OU/group created
- [ ] Network allows Entra/Microsoft 365 endpoints from the host
