# Requirements

These are the **solution-specific** prerequisites for the client-connectivity troubleshooting
toolkit. They build on the shared category prerequisites in
**`global-requirements-messaging.md`** (Microsoft 365 tenant with Exchange Online;
least-privilege Exchange/365 admin access; the EXO V3 + Graph toolchain; DNS control for the
mail domains; hybrid Exchange & Active Directory access for hybrid scenarios; and a pilot
scope with change control). Verify the shared six first, then confirm the items below before
running the playbook.

---

## 1. A diagnostic-capable, least-privilege admin role

- **Description:** An admin account that can read client-access and mailbox connectivity
  configuration and run the `Test-*` cmdlets — typically **Exchange Administrator**, or the
  narrower **View-Only Recipients / View-Only Configuration** role groups plus the roles that
  back `Test-OutlookConnectivity` / `Test-OutlookWebServices`. **Global Administrator** is
  *not* required for read-only diagnosis and should not be used for routine triage.
- **Why required:** The playbook reads `Get-CASMailbox`, `Get-CASMailboxPlan`, mobile-device
  and OWA mailbox policies, and runs connectivity tests; the scripts connect with this role.
- **How to verify:** `Connect-ExchangeOnline` as the account, then confirm a read works:
  `Get-CASMailbox <test-user> | Format-List`. Confirm the role in the M365 admin center /
  Entra **Roles and administrators**.
- **How to implement if missing:** Have a Global Admin assign **Exchange Administrator** (or
  the view-only role groups) under change control.

## 2. A dedicated test mailbox — `ConnTest`

- **Description:** A licensed, non-VIP **test mailbox** used as the known-good baseline for
  every connectivity test — named here **`ConnTest`** (e.g. `conntest@<domain>`) and reused
  by that exact name throughout the playbook, tests, and scripts.
- **Why required:** Isolation requires a *known-good* subject: you compare the affected user
  against `ConnTest` on the same client, and `ConnTest` against a known-good client, to
  localize the fault to server vs client. Server-side `Test-OutlookConnectivity` also targets
  a specific identity.
- **How to verify:** `Get-Mailbox ConnTest` returns the mailbox; it can sign in to OWA and set
  up in Outlook cleanly today.
- **How to implement if missing:** Create a licensed mailbox `ConnTest`, confirm it is
  healthy (OWA + Outlook), and exclude it from restrictive Conditional Access test policies so
  it is a true baseline (or, deliberately, include it to reproduce a CA fault).

## 3. Correct Autodiscover DNS for every mail domain

- **Description:** For each accepted domain, the public **Autodiscover** record is correct:
  in cloud-only Exchange Online this is a **CNAME** `autodiscover.<domain>` →
  `autodiscover.outlook.com` (**Commercial**; **verify the sovereign host for GCC High/DoD**).
  Hybrid may instead point Autodiscover at the on-prem endpoint per the org's coexistence
  design. The classic Autodiscover lookup order (SCP → root/autodiscover HTTPS → HTTP redirect
  → SRV) must resolve to the intended endpoint.
- **Why required:** Autodiscover is the discovery layer; a wrong or missing record is the #1
  root cause of "can't create a profile" and breaks free/busy in hybrid.
- **How to verify:** `Resolve-DnsName autodiscover.<domain> -Type CNAME`; the Remote
  Connectivity Analyzer **Autodiscover** test; and, for domain-joined Outlook,
  `Get-ClientAccessService | Select AutoDiscoverServiceInternalUri` (on-prem/hybrid) for the
  SCP.
- **How to implement if missing:** Stage the correct Autodiscover record with the DNS owner
  under change control (DNS is high-impact); confirm via RCA before closing.

## 4. Modern authentication and a known Conditional Access posture

- **Description:** **Modern authentication (OAuth)** is in effect (Basic Auth is retired in
  Exchange Online) and you know the **Entra Conditional Access** policies that apply to mail
  clients — device compliance, managed-device / Hybrid Azure AD Join, app-based (Intune app
  protection), and location grants — because a CA grant the client cannot satisfy is the most
  common auth-loop root cause.
- **Why required:** The authentication layer of the tree depends on reading CA state and the
  per-mailbox / org auth configuration; without it, auth loops are un-diagnosable.
- **How to verify:** `Get-OrganizationConfig | Select OAuth*`; `Get-CASMailbox <user> |
  Select *AuthenticationPolicy*`; review CA policies in **Entra > Protection > Conditional
  Access** and the user's **sign-in logs** for the failing client app / failure reason.
- **How to implement if missing:** Confirm modern auth is enabled and obtain read access to
  Conditional Access and Entra sign-in logs (Security Reader / Global Reader) before triaging
  auth faults.

## 5. Access to the external test tools (RCA + SARA)

- **Description:** Ability to reach the **Microsoft Remote Connectivity Analyzer** at
  `https://testconnectivity.microsoft.com` (Autodiscover, Outlook Connectivity, EWS/free-busy,
  ActiveSync tests) and to run the **Microsoft Support and Recovery Assistant (SARA)** on an
  affected Windows client. **For Government clouds, confirm the correct sovereign RCA endpoint
  and any endpoint availability — verify per tenant.**
- **Why required:** RCA reproduces discovery/protocol/auth from *outside* the corporate
  network (isolating internal proxy/firewall/SSL-inspection faults); SARA automates common
  Outlook client fixes.
- **How to verify:** Load `testconnectivity.microsoft.com` from an out-of-network host; SARA
  installs and runs on a test client.
- **How to implement if missing:** Whitelist the tools / provide an out-of-network test path
  (phone hotspot) so RCA reflects true external behavior.

## 6. Hybrid free/busy prerequisites (hybrid scenarios only)

- **Description:** For hybrid free/busy diagnosis: a healthy **Organization Relationship**
  (or federation trust) between on-prem and Exchange Online, working **EWS** endpoints on
  both sides, correct **Autodiscover** for the *target* org, and access to the **Exchange
  Management Shell** on-prem for `Test-OrganizationRelationship` /
  `Test-FederationTrust`.
- **Why required:** Cross-org availability lookups traverse the relationship + EWS +
  Autodiscover of the other org; diagnosing "free/busy shows hash marks" requires reading all
  three.
- **How to verify:** `Get-OrganizationRelationship`, `Get-FederationTrust`,
  `Test-OrganizationRelationship -Identity <rel> -UserIdentity <on-prem user>` (on-prem EMS);
  RCA **free/busy** test.
- **How to implement if missing:** Engage the hybrid owner to confirm relationship/federation
  and EWS health before diagnosing free/busy. Cloud-only deployments can skip this item.
