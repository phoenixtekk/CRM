# Outlook / OWA / Exchange Client Connectivity Troubleshooting Toolkit

> **Version 1.0.0** · Category: Messaging · Solution code: OUTLOOKDX

> This is the online, maintained copy of the implementation guide. When this solution is updated, eligible customers are alerted and can return here for the current content. Downloadable PDF + scripts are attached on the store listing.



---


# Executive Summary

**Outcome.** "Outlook won't connect" is one of the highest-volume, most time-consuming ticket
categories any messaging support team carries — and, without a method, each one is solved by
guesswork: reboot, recreate the profile, escalate. This toolkit replaces the guesswork with a
**repeatable, layered diagnostic method** that resolves Outlook, Outlook on the web (OWA), and
mobile client-connectivity issues on **Exchange Online and hybrid** on first contact, with a
named root cause on every ticket.

**Approach.** The toolkit is a **symptom-to-root-cause decision tree** that walks a
connectivity problem down the four layers a mail client actually depends on — **Autodiscover
(discovery) → protocol endpoints (MAPI-over-HTTP / EWS / ActiveSync / OWA) → authentication
(modern auth / Conditional Access / MFA) → client profile and cached-mode state** — plus the
hybrid **free/busy** and **mobile** paths. At each node the playbook names the *exact* test to
run (`Test-OutlookConnectivity`, `Test-OutlookWebServices`, `Get-CASMailbox`, the Microsoft
Remote Connectivity Analyzer, sign-in logs) and the pass/fail branch, so the failing layer is
**isolated, not guessed**. Five PowerShell tools (Exchange Online PowerShell EXO V3 / Microsoft
Graph) automate the server-side half — a per-user connectivity and protocol assessment, an
Autodiscover/endpoint test, a modern-auth / Conditional-Access checker, a validation report,
and a scope/health helper.

**Why low-risk.** Every diagnostic is **read-only by default**; the single tool that can change
state defaults to a **dry-run that records the prior value** and requires an explicit `-Commit`
switch under change control. Nothing in the toolkit alters production mail flow, connectors, or
DNS as part of diagnosis. It is adopted the disciplined way — **Assess → Design → Configure →
Pilot → Validate → Expand** — proven on a pilot ticket batch against explicit pass/fail gates
before it becomes the standard first-contact runbook. Scripts carry **no hardcoded
credentials** and connect only via modern authentication.

**Bottom line.** The highest-volume mail tickets resolved on first contact — Autodiscover,
protocols, and authentication diagnosed by a repeatable decision tree with exact tests — means
less guesswork, faster fixes, fewer escalations, and, as the reporting loop surfaces systemic
causes, a *falling* volume of client-connectivity tickets over time.


---


# Solution Overview

## What this is

"Outlook won't connect" is one of the highest-volume tickets any messaging support team
handles — and, attacked without a method, it is guesswork: reboot, recreate the profile,
re-run the wizard, escalate. This solution replaces the guesswork with a **layered
client-connectivity diagnostic toolkit** for **Exchange Online** and **Exchange hybrid**:
a repeatable, symptom-to-root-cause method that walks a connectivity problem down through
the layers a mail client actually depends on, and names the **exact test** to run at each
node so the fault is *isolated* rather than *guessed*.

It is built for an L2–L4 Exchange / Microsoft 365 messaging admin who can "run to
implement": every diagnostic step has a real navigation path (Exchange admin center / M365
admin center) **and** an Exchange Online PowerShell (EXO V3) / Microsoft Graph cmdlet, so
the same fault can be diagnosed from a portal or from a script.

## The client-connectivity model (how a mail client connects)

A modern Outlook / OWA / mobile client reaches an Exchange Online (or hybrid) mailbox
through four dependent layers. The diagnostic method walks them **in order**, because a
failure in an early layer masquerades as a failure in a later one:

1. **Discovery — Autodiscover.** Before a client can talk to a mailbox it must *find* the
   right endpoints. Modern clients use **Autodiscover v2** (a JSON redirect at
   `https://autodiscover.<domain>/autodiscover/autodiscover.json`), falling back to the
   classic lookup order: **SCP** (Service Connection Point in AD, for domain-joined Outlook),
   the **root-domain** and **autodiscover.<domain>** HTTPS endpoints, an **HTTP redirect**,
   and finally the **`_autodiscover._tcp` SRV** record. In Exchange Online the target is
   `autodiscover.outlook.com` (Commercial) — **verify the sovereign-cloud host for
   GCC High / DoD**, which differ. Autodiscover is the #1 root cause of "can't set up a
   profile."
2. **Protocol endpoints.** Once discovered, the client connects over a protocol:
   **MAPI over HTTP** (the default and only supported Outlook desktop transport to Exchange
   Online — RPC-over-HTTP/Outlook Anywhere is retired), **EWS** (Exchange Web Services —
   free/busy, Out-of-Office, some add-ins and third-party tools), **Exchange ActiveSync
   (EAS)** (older mobile clients), and **OWA / Outlook on the web** (browser). Outlook for
   iOS/Android and the new Outlook use the **Microsoft sync technology / Graph**, not EAS.
   A protocol disabled on the mailbox (**`Get-CASMailbox`**) or blocked in transit is the
   classic "OWA works but Outlook doesn't" (or vice-versa) split.
3. **Authentication.** The client must prove identity. Exchange Online is **modern auth
   (OAuth 2.0) only** — **Basic Auth is retired**. The token is subject to **Entra
   Conditional Access** (device compliance, managed-device, location, app-based controls)
   and **MFA**. Auth failures show up as *repeating credential prompts* and *auth loops* —
   the fault is usually a Conditional Access grant the client/device can't satisfy, not a
   wrong password.
4. **Profile / client state.** Even with discovery, protocol, and auth healthy, the local
   client can be broken: a corrupt Outlook **profile**, a damaged **OST** (cached-mode data
   file), a stale **autodiscover cache / XML**, an add-in, or a machine-wide credential in
   Windows Credential Manager. This layer is isolated **last**, after the server-side layers
   are proven, and is confirmed by testing a *known-good* mailbox on the same client and the
   *affected* mailbox on a *known-good* client (or in OWA).

**Hybrid free/busy** is a special cross-org case that touches several layers at once:
availability lookups between on-prem and Exchange Online flow over **EWS** via the
**Organization Relationship / OAuth (or the legacy federation trust)**, using the
**Autodiscover** of the *target* org. It is called out explicitly in the playbook because
"free/busy shows hash marks in hybrid" is a distinct, recurring root cause.

## How the toolkit works — the layered diagnostic method

The core deliverable (`03-implementation.md`) is a **Diagnostic Playbook**: a
symptom → root-cause **decision tree**. You enter at the reported symptom (can't create a
profile · disconnects / password prompts · auth loop · free/busy fails · OWA/mobile fails),
and at each node the playbook gives you **one exact test** and a **pass/fail branch**:

- **Server-authoritative tests** you run yourself: **`Test-OutlookConnectivity`**,
  **`Test-OutlookWebServices`**, **`Get-CASMailbox`**, **`Get-CASMailboxPlan`**,
  **`Test-MigrationServerAvailability`**, mailbox / OWA / mobile-device policy cmdlets, and
  **Autodiscover** resolution checks (DNS, `autodiscover.json`, SCP).
- **Externally-run tests:** the **Microsoft Remote Connectivity Analyzer (RCA)** at
  `testconnectivity.microsoft.com` (Autodiscover, Outlook/EWS, ActiveSync, free/busy tests),
  the **Support and Recovery Assistant (SARA)**, and **message-header / connectivity-log**
  inspection.
- **Client-side isolation:** OWA-vs-Outlook, known-good mailbox / known-good client
  substitution, `Test E-mail AutoConfiguration`, and cached-mode / OST checks.

Five PowerShell tools (see below) automate the server-authoritative half of the tree so a
technician gets a per-user connectivity + CAS/protocol picture, an Autodiscover/endpoint
test, a modern-auth / Conditional-Access / protocol-enablement check, and a validation
report — **read-only or `-WhatIf` by default**.

## Deployment / adoption model

Even a diagnostic toolkit is adopted the house way — **Assess → Design → Configure →
Pilot → Validate → Expand** — so the *method* is proven before it becomes the standard
first-contact runbook:

- **Assess** the current client estate (Outlook builds, cached vs online mode, mobile
  clients, hybrid or cloud-only) and the top connectivity ticket categories.
- **Design** the decision tree to the organization's reality (which protocols are in use,
  Conditional Access posture, hybrid free/busy topology) and the named checks.
- **Configure** the tooling: install EXO V3 / Graph modules, grant the least-privilege
  diagnostic role, provision a **`ConnTest`** test mailbox, and dry-run the scripts.
- **Pilot** the playbook on a named pilot group and a batch of real tickets; measure
  first-contact resolution against a pass/fail gate.
- **Validate** against the gates in `05-testing.md` (Autodiscover resolves, each protocol
  connects, auth succeeds, free/busy returns).
- **Expand** to the whole service desk as the standard runbook, with the reporting script
  feeding a trend of ticket categories.

Because the toolkit is **diagnostic and read-only by default**, it is inherently low-risk:
nothing here changes production mail flow, connectors, or DNS. The one script that *can*
change state (protocol re-enablement / cache reset guidance) defaults to a dry-run and
requires an explicit `-Commit` switch, gated by change control.

## Benefits

- **First-contact resolution** of the highest-volume mail tickets — a method, not guesswork.
- **Isolates the layer** (discovery / protocol / auth / client) so escalations carry a
  root cause, not just a symptom.
- **Portal *and* PowerShell** for every check — usable by tier-2 and by automation.
- **Safe** — read-only / `-WhatIf` by default; no credentials in code; no production
  mail-flow changes.

## Limitations

- This is a **client-connectivity** toolkit. It diagnoses *reaching and authenticating to*
  the mailbox; it is **not** a mail-flow / transport, hygiene, or migration solution.
- **Version- and plan-dependent** behavior (Exchange Server build/CU, mobile client type,
  Conditional Access design, Commercial vs Government cloud endpoints) must be **verified in
  your own tenant/version** — the playbook flags these points rather than assuming them.
- Third-party security/proxy products (SSL-inspecting firewalls, CASB, MDM) can break
  discovery/auth; the playbook isolates *that* they are the cause and defers their consoles
  to the vendor's docs.


---


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


---


# Global Requirements — Microsoft 365 / Exchange Messaging Solutions

These requirements apply to **every** solution in the **Messaging** category (Exchange Online &
Exchange hybrid mail flow, connectors, mail hygiene, email authentication, federation, archiving,
client connectivity, and messaging support operations). They are the common foundation each solution
assumes is already in place (or stands up as part of its own Requirements section). Verify each before
starting a solution's implementation steps.

> **Vendor boundary (applies to every Messaging solution).** The **Exchange admin center (EAC)**, the
> **Microsoft 365 admin center**, **Exchange Online PowerShell (EXO V3 module)**, **Microsoft Graph**,
> and on-premises **Exchange Server / Active Directory** are authored at exact, current click-by-click
> and cmdlet detail from Microsoft's public documentation. Where a capability, default, or portal path
> is **version- or plan-dependent** (Exchange Server build/CU, EOP vs Defender for Office 365 plan,
> Exchange Online Archiving / auto-expanding archive availability, Commercial vs Government cloud), it
> is **cited or flagged "verify in your tenant/version"** — never invented. **Third-party mail hygiene,
> archiving, and signature/gateway products** are integrated at the pattern level; their internal
> consoles are deferred to the vendor's own docs. **Commercial vs Government (GCC/GCC High/DoD)** portal
> URLs and endpoints differ — where a solution's setup materially differs on a sovereign cloud, flag it
> (per the house Commercial-vs-Government rule). Automation is delivered as **PowerShell** (Exchange
> Online PowerShell / Graph) — never with hardcoded credentials or secrets in code.

## 1. Microsoft 365 tenant with Exchange Online
- **Description:** A Microsoft 365 tenant with **Exchange Online** and the appropriate licensing for the
  capability in scope (e.g. Exchange Online Plan 1/2, EOP, **Defender for Office 365** for advanced
  hygiene, Exchange Online Archiving / auto-expanding archive where required).
- **Why required:** All mail-flow, hygiene, archiving, and client configuration is performed against
  this tenant and depends on the right plan.
- **How to verify:** Sign in to the Microsoft 365 admin center; confirm the Exchange Online subscription
  and license counts under **Billing > Licenses**.
- **How to implement if missing:** Provision/assign the required licensing before starting.

## 2. Administrative access (least-privilege Exchange/365 roles)
- **Description:** Administrative access with the **least-privilege role** the solution names —
  typically **Exchange Administrator** (or specific EAC role groups such as Organization Management,
  Recipient/Records/Hygiene Management), and **Global Administrator** only where genuinely required
  (e.g. federation/ADFS, connector auth).
- **Why required:** Mail-flow, connector, hygiene, archiving, and federation changes require the
  corresponding admin role.
- **How to verify:** Confirm the role assignment in the Microsoft 365 admin center / Entra roles.
- **How to implement if missing:** Have a Global Admin assign the least-privilege role under change control.

## 3. Exchange Online PowerShell (EXO V3) + Graph toolchain
- **Description:** A workstation with the **ExchangeOnlineManagement (EXO V3)** PowerShell module and,
  where used, **Microsoft Graph PowerShell**; modern-auth / MFA-capable admin sign-in.
- **Why required:** Configuration, automation, and the provided scripts run through EXO PowerShell /
  Graph; Basic Auth is retired.
- **How to verify:** `Connect-ExchangeOnline` succeeds with the admin account; `Get-Module
  ExchangeOnlineManagement`.
- **How to implement if missing:** Install the module (`Install-Module ExchangeOnlineManagement`) and
  confirm modern-auth sign-in before running the steps.

## 4. DNS control for the mail domains
- **Description:** Ability to create/modify **DNS records** (MX, SPF (TXT), DKIM (CNAME), DMARC (TXT),
  Autodiscover, and connector/host records) for the domains in scope.
- **Why required:** Email authentication, mail routing/coexistence, connector validation, and client
  autodiscover all depend on DNS.
- **How to verify:** Confirm access to the authoritative DNS zone for each mail domain.
- **How to implement if missing:** Coordinate with whoever controls DNS; stage changes under change
  control (mail-flow and authentication changes are high-impact).

## 5. Hybrid Exchange & Active Directory (for hybrid solutions)
- **Description:** For **hybrid / on-premises** solutions, access to the on-premises **Exchange Server**
  organization (correct roles/CU), **Active Directory**, **Azure AD Connect** (directory sync), and the
  relevant network/firewall paths (e.g. for Edge/transport, hybrid connectors, autodiscover).
- **Why required:** Hybrid mail flow, Edge Transport, connectors, and federation read from and change
  the on-premises side.
- **How to verify:** Confirm on-prem Exchange admin access, AD access, and that directory sync is healthy.
- **How to implement if missing:** Obtain access and confirm the on-prem Exchange/AD/AAD-Connect health
  before making hybrid changes.

## 6. A pilot scope and change control
- **Description:** A **pilot group / accepted-domain / test mail flow** to validate on before fleet-wide
  rollout, and a **change-control** process for production changes (mail flow, connectors, DNS,
  authentication, hygiene policy are all high-impact).
- **Why required:** Every solution follows an **Assess → Design → Configure → Pilot → Validate → Expand**
  model; the pilot proves the design and change control protects production mail flow.
- **How to verify:** Confirm a named pilot scope and an approval/change window are available.
- **How to implement if missing:** Define a pilot scope and agree change control with the messaging/
  service owners before making production changes.

*The deployment model across every Messaging solution is the same: **Assess → Design → Configure →
Pilot → Validate → Expand**, with explicit pass/fail gates and a documented rollback for production
changes. Automation is delivered as **PowerShell** (Exchange Online PowerShell / Graph) — never with
hardcoded credentials or secrets in code.*


---


# Diagnostic Playbook — symptom → root cause

This is the core of the toolkit: a **layered decision tree** for Outlook / OWA / mobile
client-connectivity problems on Exchange Online and hybrid. Work it the house way —
**Assess → Design → Configure → Pilot → Validate → Expand** for *adopting* the method
(see below) — but for an individual ticket you **enter at the reported symptom** (§B) and
walk down the layers, running the **one exact test named at each node** and following its
**pass/fail branch**.

> **Golden rules (apply at every node):**
> 1. **Reproduce, isolate, resolve.** Confirm the symptom, then localize the failing *layer*
>    before changing anything.
> 2. **Walk layers in order:** Discovery (Autodiscover) → Protocol → Auth → Client. An early
>    failure masquerades as a later one.
> 3. **Compare against known-good:** the **`ConnTest`** mailbox (§Requirements 2) and a
>    known-good client / **OWA**. `<affected user on affected client>` vs `ConnTest on same
>    client` vs `affected user in OWA` triangulates server-vs-client instantly.
> 4. **Read-only first.** Every diagnostic here is read-only. Any *change* goes through change
>    control and the remediation script's `-Commit` gate.

---

## A. Adopting the method (Assess → Configure), do once

Before the tree is your standard runbook, stand it up:

1. **Assess** the estate: Outlook builds and cached-vs-online mode, mobile client mix
   (Outlook mobile/Graph vs legacy EAS), cloud-only vs hybrid, and Conditional Access posture.
   Pull the top client-connectivity ticket categories from the last 90 days.
2. **Configure** the toolkit:
   - Install the modules: `Install-Module ExchangeOnlineManagement`,
     `Install-Module Microsoft.Graph`.
   - Grant the least-privilege diagnostic role (Requirement 1) and provision **`ConnTest`**
     (Requirement 2).
   - Dry-run all five scripts against `ConnTest` (all read-only / `-WhatIf`) to confirm access.
3. **Pilot** the tree on a named pilot group and a batch of live tickets; **Validate** against
   the gates in `05-testing.md`; then **Expand** to the full service desk.

---

## B. Entry — pick the symptom

| # | Reported symptom | Go to |
|---|------------------|-------|
| 1 | New profile won't set up / "can't connect to the server" on setup | **Node D1 (Discovery)** |
| 2 | Outlook was working, now disconnects / repeating password prompts | **Node D3 (Auth)** first, then D2/D4 |
| 3 | Credential prompt never accepts the password (auth loop) | **Node D3 (Auth)** |
| 4 | Free/busy shows hash marks (`/////`) — especially hybrid | **Node D5 (Free/busy)** |
| 5 | OWA works but Outlook desktop doesn't (or vice-versa) | **Node D2 (Protocol)** |
| 6 | Mobile mail (iOS/Android) won't sync | **Node D6 (Mobile)** |
| 7 | Only one user; everyone else is fine | Start at **D0**, expect a **per-mailbox** cause |
| 8 | Many users at once | Start at **D0**, expect a **DNS / CA / service** cause |

---

## C. D0 — Scope the blast radius (always first)

**Test:** Is it one user, one client, one site, or everyone?
- Run the health helper script (`Get-ClientConnectivityScope.ps1`) or check the **service
  health** dashboard (M365 admin center → **Health → Service health**, Exchange Online).
- Compare the affected user in **OWA** (browser, off-network if possible) vs Outlook desktop.

**Branch:**
- **Everyone / many** and **OWA also fails** → suspect a **service incident** or a **tenant-wide
  DNS / Conditional Access** change → jump to **D1** (DNS) and **D3** (CA), skip client work.
- **One user, OWA works, Outlook fails** → **per-mailbox / client** cause → **D1 → D2 → D3 → D4**.
- **One client, all mailboxes fail on it, fine elsewhere** → **client machine** cause → **D4**.

---

## D1 — Discovery layer (Autodiscover)

**Symptom fit:** can't set up a profile; "can't connect to server" on first launch; hybrid
free/busy failing at the discovery step.

### D1.1 — Does Autodiscover resolve to the right endpoint?
**Test (external, authoritative):** Remote Connectivity Analyzer → **Outlook Autodiscover**
test for the affected user (`testconnectivity.microsoft.com`; **verify the sovereign RCA host
for GCC High/DoD**). Also:
- DNS: `Resolve-DnsName autodiscover.<domain> -Type CNAME` — cloud-only expects
  `autodiscover.outlook.com` (**Commercial**; verify sovereign host).
- Autodiscover v2 JSON:
  `Invoke-RestMethod "https://autodiscover.<domain>/autodiscover/autodiscover.json?Email=<user>&Protocol=Autodiscoverv1"`
- The endpoint-test script (`Test-AutodiscoverEndpoints.ps1`) runs these together per user.

**Branch:**
- **RCA Autodiscover PASS** → discovery is healthy → go to **D2 (Protocol)**.
- **RCA Autodiscover FAIL, DNS wrong/missing** → **root cause: Autodiscover DNS**. Remediate:
  stage the correct `autodiscover.<domain>` record (cloud-only → `autodiscover.outlook.com`;
  hybrid → per coexistence design) with the DNS owner **under change control**; re-test RCA.
- **RCA PASS but domain-joined Outlook still misbehaves** → suspect a stale **SCP** or client
  cache → **D1.2**.

### D1.2 — Client-side discovery (domain-joined Outlook)
**Test:** On the client, hold **Ctrl** + right-click the Outlook tray icon → **Test E-mail
AutoConfiguration** (uncheck Guessmart; check "Use AutoDiscover") and read the returned URLs /
log. Check the SCP (hybrid/on-prem): `Get-ClientAccessService | Select
Name,AutoDiscoverServiceInternalUri`.

**Branch:**
- Returns the **correct** EXO/hybrid endpoints → discovery fine on this client → **D2**.
- Returns a **stale/wrong** URL or errors → clear the local **autodiscover cache** (delete the
  cached `Autodiscover*.xml` under the Outlook profile and any stale registry Autodiscover
  overrides — **verify current per Outlook build**), then re-run. In hybrid, correct the SCP
  `AutoDiscoverServiceInternalUri` if it points at a decommissioned server (change control).

---

## D2 — Protocol layer (MAPI/HTTP · EWS · OWA · EAS)

**Symptom fit:** "OWA works but Outlook doesn't" (or the reverse); a specific feature
(free/busy, OOF, add-in) fails while mail flows.

### D2.1 — Is the protocol enabled on the mailbox?
**Test:** `Get-CASMailbox <user> | Format-List
MapiEnabled,EwsEnabled,OWAEnabled,ActiveSyncEnabled,*Enabled` and compare against `ConnTest`.
Also check the plan default: `Get-CASMailboxPlan | Format-List`. The assessment script
(`Get-ClientConnectivityAssessment.ps1`) reports this per user.

**Branch:**
- The failing client's protocol is **`False`** (e.g. `MapiEnabled : False` while OWA works)
  → **root cause: protocol disabled on mailbox**. Remediate via the remediation script
  (`Set-MailboxProtocolAccess.ps1`, dry-run by default; `-Commit` gated) or
  `Set-CASMailbox <user> -MapiEnabled $true` under change control; re-test.
- All required protocols **`True`** → protocol is enabled → the fault is **transport/auth**,
  not enablement → **D2.2**.

### D2.2 — Does the protocol actually connect (server-authoritative)?
**Test:** Server-side connectivity cmdlets and RCA:
- `Test-OutlookConnectivity -MailboxId <user>` (MAPI/HTTP path health).
- `Test-OutlookWebServices -Identity <user>` (Autodiscover + EWS + OOF + free/busy provider
  reachability). *Note: availability of these cmdlets/parameters is version-dependent —
  verify in your tenant/on-prem build.*
- RCA → **Outlook Connectivity**, **Exchange ActiveSync**, and **EWS** tests.

**Branch:**
- Cmdlet / RCA **PASS** → protocol connects server-side; the client can't → **client layer D4**.
- **EWS fails** specifically → an EWS-only feature (free/busy/OOF/add-in) breaks while MAPI
  mail works → check `EwsEnabled`, `EwsAllowOutlook`, and any **EWS application access policy**
  (`Get-CASMailbox <user> | Select Ews*`); for cross-org free/busy go to **D5**.
- **PASS server-side but user still fails and OWA is fine** → strongly implies **auth** or
  **client** → **D3**, then **D4**.

---

## D3 — Authentication layer (modern auth · Conditional Access · MFA)

**Symptom fit:** repeating credential prompts; auth loop; "your organization needs more
information"; worked yesterday, blocked today (policy change).

### D3.1 — Modern auth in effect and no legacy-auth block?
**Test:** `Get-OrganizationConfig | Select OAuth*`;
`Get-CASMailbox <user> | Select *AuthenticationPolicy*`; the auth/CA checker script
(`Test-ModernAuthConditionalAccess.ps1`) summarizes org + per-user auth posture.

**Branch:**
- Modern auth **on**, no restrictive auth policy → **D3.2**.
- A **Basic-Auth-only** legacy client or an authentication policy blocking the app → **root
  cause: unsupported/blocked legacy auth** → move the user/app to a modern-auth client
  (change control).

### D3.2 — Is Conditional Access blocking this client/device?
**Test (authoritative):** Entra **sign-in logs** for the user → filter by the failing **client
app** and read **Status / failure reason** and the **Conditional Access** tab (which policy,
Success/Failure/Not applied). Cross-reference **Entra → Protection → Conditional Access**
policies (device compliance, Hybrid Azure AD Join, app-based / Intune app protection, location).

**Branch:**
- A CA policy shows **Failure** for this sign-in (e.g. "device not compliant", "require
  approved client app") → **root cause: Conditional Access grant unmet**. Resolve the *device/
  app* condition (enroll/comply, use an approved client) — **do not** weaken the CA policy as a
  fix; if the policy is misscoped, correct scope via the CA owner under change control.
- **MFA registration incomplete** ("more information required") → complete MFA registration.
- CA **Not applied / Success** but client still loops → **stale token / cached credential** →
  **D4** (Credential Manager / re-auth).

---

## D4 — Client / profile / OST layer (isolate last)

**Symptom fit:** server layers all PASS; one client or one profile misbehaves; corrupt data
file; add-in interference.

### D4.1 — Is it the mailbox or the client? (substitution test)
**Test:** (a) Set up **`ConnTest`** on the *affected* client; (b) set up the *affected user* on
a *known-good* client (or confirm the affected user works in **OWA**).

**Branch:**
- **`ConnTest` also fails on this client** → **client machine** cause (proxy/SSL-inspection,
  credential store, Office build) → D4.2/D4.3.
- **Affected user works elsewhere / in OWA** → **local profile / OST / cache** cause → D4.2.

### D4.2 — Profile / OST / autodiscover-cache reset
**Test/Remediate (client-side, low-risk, reversible):**
- Recreate the **Outlook profile** (Control Panel → Mail → **Show Profiles** → add a new
  profile; keep the old one until validated).
- For a suspected corrupt **OST**, close Outlook and let cached mode rebuild the OST from the
  server (rename, don't delete, until confirmed) — **verify current OST path/behavior for the
  Outlook build**.
- Clear the stale **Autodiscover cache** (D1.2) and any machine-wide entries in **Windows
  Credential Manager** for `MicrosoftOffice*` / the mail host, then re-auth.
- Run **SARA** (Support and Recovery Assistant) → Outlook scenario for automated fixes.

### D4.3 — Machine / network interference
**Test:** Compare RCA (external, off-network) vs on-network behavior (from **D0**).
**Branch:**
- **Works off-network, fails on-network** → an **SSL-inspecting proxy / firewall / CASB** is
  breaking Autodiscover or the OAuth flow → engage network owner; defer the security appliance's
  console to its vendor docs.
- Add-in suspected → start Outlook in **safe mode** (`outlook /safe`); if it connects, disable
  add-ins to isolate.

---

## D5 — Hybrid free/busy (cross-org availability)

**Symptom fit:** free/busy shows **hash marks** (`/////`) between on-prem and Exchange Online
mailboxes.

**Test (on-prem Exchange Management Shell + RCA):**
- `Get-OrganizationRelationship | Format-List`; `Get-FederationTrust`;
  `Test-OrganizationRelationship -Identity <rel> -UserIdentity <on-prem user>`.
- RCA → **Free/Busy** test (target the cross-org user).
- Confirm **Autodiscover of the *target* org** (D1) and **EWS** reachability (D2.2) both ways.

**Branch:**
- `Test-OrganizationRelationship` **FAIL** → fix the relationship / OAuth (or legacy federation)
  config with the hybrid owner (change control).
- Relationship OK but **EWS/Autodiscover of the other org fails** → resolve that org's D1/D2
  first — free/busy inherits their health.
- Both OK, still hash marks for **one user** → check that user's **`EwsEnabled`** and any EWS
  application access policy (**D2.2**).

---

## D6 — Mobile (Outlook mobile / Graph vs legacy EAS)

**Symptom fit:** iOS/Android mail won't sync or set up.

**Test:**
- Identify the client: **Outlook for iOS/Android / new Outlook** use Microsoft sync
  technology / **Graph** (not EAS); native/older mail apps use **Exchange ActiveSync**.
- `Get-CASMailbox <user> | Select ActiveSyncEnabled`; `Get-MobileDevice -Mailbox <user>`;
  `Get-MobileDeviceStatistics`; the OWA/EAS mailbox policy (`Get-CASMailbox` /
  `Get-MobileDeviceMailboxPolicy`). RCA → **Exchange ActiveSync** test.

**Branch:**
- **`ActiveSyncEnabled : False`** and the client uses EAS → enable EAS (remediation script /
  `Set-CASMailbox -ActiveSyncEnabled $true`, change control) — or move the user to **Outlook
  mobile** (Graph), the recommended client.
- Device is **quarantined / blocked** by mobile device policy or a **Conditional Access
  app-protection** grant → the fault is **auth/policy (D3)**, resolve there (enroll in Intune /
  approved app), not by disabling the policy.
- Autodiscover for the mobile setup fails → **D1**.

---

## E. Pass/fail gates & rollback (for any change made during triage)

Any remediation triggered above (DNS Autodiscover fix, protocol re-enable, SCP correction,
relationship fix) is a **production change** — apply it under change control with these gates
and rollbacks:

| Change | PASS gate | Rollback |
|--------|-----------|----------|
| Autodiscover DNS corrected | RCA **Autodiscover** PASS; new profile sets up for `ConnTest` + affected user | Restore prior DNS record (kept as pre-change note) |
| Protocol re-enabled (`Set-CASMailbox`) | `Get-CASMailbox` shows `True`; `Test-OutlookConnectivity` PASS; client connects | `Set-CASMailbox … $false` (prior value recorded by the remediation script's dry-run) |
| SCP `AutoDiscoverServiceInternalUri` corrected | `Test E-mail AutoConfiguration` returns correct URL | Restore prior URI |
| Org relationship / federation fix | `Test-OrganizationRelationship` PASS; RCA free/busy PASS | Revert relationship config to recorded prior state |

**Rule:** the remediation script defaults to a **dry-run report** that records the *current*
value before any change; you `-Commit` only after the change is approved, and you keep the
recorded prior value as the rollback.


---


# Testing & Validation

Validate the toolkit against these gates. Each test states the **procedure** and the
**expected pass/fail signal**. Run them against the **`ConnTest`** baseline first (everything
should PASS), then against an affected user during a real ticket. These same gates are the
pilot exit criteria in the deployment model.

> Run diagnostics read-only. Only after a change is approved and applied (change control) do
> you re-run the relevant gate to confirm the fix.

---

## Gate 1 — Autodiscover resolves (Discovery layer)

- **Procedure:** Remote Connectivity Analyzer → **Outlook Autodiscover** test for `ConnTest`
  and the affected user. Also `Resolve-DnsName autodiscover.<domain> -Type CNAME` and the
  `Test-AutodiscoverEndpoints.ps1` script.
- **PASS:** RCA reports **Autodiscover succeeded**; DNS returns the expected host
  (`autodiscover.outlook.com` for Commercial cloud-only — verify sovereign host); the script
  returns a healthy JSON/endpoint response.
- **FAIL:** RCA cannot complete Autodiscover, or DNS returns a wrong/absent record → root cause
  is the Discovery layer (playbook **D1**).

## Gate 2 — Each required protocol connects (Protocol layer)

- **Procedure:** `Get-CASMailbox <user>` (enablement) → `Test-OutlookConnectivity -MailboxId
  <user>` and `Test-OutlookWebServices -Identity <user>` → RCA **Outlook Connectivity**, **EWS**,
  **ActiveSync** tests. `Get-ClientConnectivityAssessment.ps1` summarizes enablement.
- **PASS:** Required protocols show **`True`** in `Get-CASMailbox`; the `Test-*` cmdlets return
  **Success**; RCA protocol tests pass. `ConnTest` connects in Outlook and OWA.
- **FAIL:** A required protocol is `False`, or a `Test-*` cmdlet / RCA test fails → Protocol
  layer (playbook **D2**).

## Gate 3 — Authentication succeeds (Auth layer)

- **Procedure:** Sign in as the user in Outlook desktop **and** OWA; inspect Entra **sign-in
  logs** (client app + Conditional Access result); `Test-ModernAuthConditionalAccess.ps1`.
- **PASS:** Sign-in logs show **Success** for the client app; Conditional Access shows
  **Success / Not applied** (no blocking Failure); no repeating credential prompt.
- **FAIL:** Repeating prompt / auth loop; sign-in log shows a **Conditional Access Failure** or
  MFA registration required → Auth layer (playbook **D3**).

## Gate 4 — Free/busy returns (hybrid) 

- **Procedure (hybrid only):** In Outlook/OWA, open the scheduling assistant for a cross-org
  attendee; on-prem EMS `Test-OrganizationRelationship -Identity <rel> -UserIdentity <user>`;
  RCA **Free/Busy** test.
- **PASS:** Availability shows real busy/free (not hash marks); `Test-OrganizationRelationship`
  and RCA free/busy **PASS**.
- **FAIL:** Hash marks (`/////`); relationship/free-busy test fails → playbook **D5**.
- **N/A:** Cloud-only tenants skip this gate.

## Gate 5 — Mobile syncs

- **Procedure:** Set up the affected user in **Outlook mobile** (Graph) and, if EAS is in use,
  a native mail app; `Get-CASMailbox <user> | Select ActiveSyncEnabled`; `Get-MobileDevice
  -Mailbox <user>`; RCA **Exchange ActiveSync** test.
- **PASS:** Outlook mobile syncs; EAS device is not quarantined/blocked; RCA ActiveSync passes
  (if EAS in scope).
- **FAIL:** Won't set up / device quarantined / EAS disabled → playbook **D6**.

## Gate 6 — Substitution isolation is conclusive (Client layer)

- **Procedure:** Confirm `ConnTest` on the affected client and the affected user on a known-good
  client / in OWA (playbook **D4.1**).
- **PASS:** The substitution cleanly localizes the fault to **server-side** (affected user fails
  everywhere) or **client-side** (only this client/profile fails) — you can state which.
- **FAIL:** Result is ambiguous → re-scope at **D0**; you have not yet isolated the layer.

---

## Regression / re-test after any remediation

After a change (Autodiscover DNS, protocol re-enable, SCP fix, relationship fix), re-run the
**specific gate** for that change plus a full `ConnTest` pass:

- `ConnTest` sets up cleanly in Outlook **and** OWA.
- The affected user now passes the gate that previously failed.
- No previously-passing gate has regressed (run Gates 1–3 as a smoke test).

**Pilot exit criterion:** the playbook resolves the target first-contact-resolution rate on the
pilot ticket batch, with every closed ticket carrying a named root-cause node (D1–D6) — before
expanding to the whole service desk.


---


# Troubleshooting

Common failure modes when running the toolkit and its scripts, and the resolutions. These are
the *meta* problems — issues with the diagnostic process itself. For the client-connectivity
faults you are diagnosing, the symptom→root-cause tree is `03-implementation.md`.

---

## Connecting / tooling

**`Connect-ExchangeOnline` fails or prompts endlessly.**
Ensure the **ExchangeOnlineManagement (EXO V3)** module is installed and current
(`Update-Module ExchangeOnlineManagement`). Basic Auth is retired — you must complete
modern-auth / MFA sign-in. Behind a proxy, the auth pop-up may be blocked; test from an
unproxied path. For Government clouds, pass the correct environment
(`Connect-ExchangeOnline -ExchangeEnvironmentName O365USGovGCCHigh` / `O365USGovDoD`) —
**verify the value for your cloud**.

**`Test-OutlookConnectivity` or `Test-OutlookWebServices` is "not recognized."**
These cmdlets' availability and parameters are **version-dependent** (and differ between EXO and
on-prem EMS). The assessment script degrades gracefully and reports `N/A - cmdlet unavailable`.
Fall back to the **Remote Connectivity Analyzer** (Outlook Connectivity / EWS tests) for the
same signal. Do not assume a cmdlet exists — verify in your tenant/build.

**Graph checks in `Test-ModernAuthConditionalAccess.ps1` return nothing.**
`Connect-MgGraph` needs the read scopes `Policy.Read.All`, `AuditLog.Read.All`,
`Directory.Read.All`. **Sign-in log** queries require **Entra ID P1 or above**; without it the
sign-in section is empty — read the sign-in logs manually in the Entra portal instead. If
consent is missing, an admin must grant the scopes once.

**Scripts throw "mailbox not found" for a valid user.**
Directory replication/lag or a proxy-address vs UPN mismatch. Try the **primary SMTP address**
and confirm with `Get-Mailbox <user>`. In hybrid, a mailbox may be **on-prem** — run the on-prem
equivalent in Exchange Management Shell.

---

## Discovery-layer diagnosis pitfalls

**RCA Autodiscover passes but the domain-joined client still misbehaves.**
Outlook on a domain-joined machine prefers the **SCP** over DNS. RCA tests the *external* path,
not the SCP. Check `Get-ClientAccessService | Select AutoDiscoverServiceInternalUri` and the
client's `Test E-mail AutoConfiguration` output; a stale SCP or a decommissioned server URI beats
a correct public record.

**`Test-AutodiscoverEndpoints.ps1` shows CNAME "REVIEW".**
Cloud-only Commercial expects `autodiscover.outlook.com`. A hybrid tenant may **intentionally**
point Autodiscover at the on-prem endpoint — "REVIEW" is not automatically a fault; confirm
against the org's coexistence design. For **GCC High / DoD**, the expected host differs — pass
`-ExpectedCname` with the correct sovereign value.

**The v2 JSON endpoint returns a redirect/401.**
A redirect can be normal (to the sovereign or on-prem endpoint); follow it. A 401 from an
*internal* run but 200 from RCA (external) implicates an **SSL-inspecting proxy / CASB** breaking
the request — test off-network.

---

## Auth-layer diagnosis pitfalls

**"Auth loop" but Conditional Access shows Success/Not applied.**
The token is fine server-side; the loop is **local** — a stale entry in **Windows Credential
Manager** (`MicrosoftOffice*`) or a cached broker token. Clear the credential and re-auth
(playbook D4.2). Don't keep re-reading CA when it already says Success.

**Sign-in log shows the failure but names a policy you didn't expect.**
CA policies stack; a *report-only* policy can look like a block in some views. Read the
**per-policy Result** column (Success / Failure / Not applied / Report-only) — only **Failure**
on a **required grant** blocks. Fix the device/app condition; **never disable a CA policy** as a
quick fix.

**New Outlook / Outlook mobile behaves differently from classic Outlook.**
They authenticate as **different client apps** (and use Graph, not EAS). Filter the sign-in log
by the correct **client app** — a grant that blocks one client may not apply to another, which is
exactly why "new Outlook works, classic doesn't" (or vice-versa) happens.

---

## Protocol / free-busy / mobile pitfalls

**`Get-CASMailbox` shows a protocol True but the client still can't use it.**
Enablement ≠ reachability. A `True` protocol can still fail on **transport (proxy/firewall)** or
**auth**. Run `Test-OutlookConnectivity` / RCA (D2.2), then check auth (D3). Also check for an
**EWS application access policy** that scopes EWS per app even when `EwsEnabled` is `True`.

**Free/busy still shows hash marks after the org relationship tests pass.**
Free/busy inherits the **target org's** Autodiscover + EWS health and the **individual user's**
`EwsEnabled`. Confirm the *other* org's D1/D2 and the specific user's EWS before concluding the
relationship is at fault (playbook D5).

**Mobile device is "quarantined" and enabling ActiveSync doesn't help.**
Quarantine/block is a **device-access / mobile-device-policy** or **Conditional Access
app-protection** decision, not a protocol switch. Resolve it at the policy layer (approve the
device / enroll in Intune / use the approved app) — re-enabling EAS alone won't release a
quarantined device.

---

## Remediation-safety pitfalls

**`Set-MailboxProtocolAccess.ps1` "did nothing."**
That is the **safe default** — it is a **dry-run** until you pass `-Commit`. Confirm the printed
CURRENT vs INTENDED, get change approval, then re-run with `-Commit`. Keep the printed prior value
as your rollback.

**A change fixed one user but you're unsure it's safe fleet-wide.**
Never bulk-`-Commit` from a single-user diagnosis. Validate against the **Testing & Validation**
gate for that change on `ConnTest` + the affected user first, confirm no other gate regressed,
then expand under change control. DNS / Autodiscover / SCP / relationship changes are high-impact
to production mail — treat them accordingly.

**You changed a Conditional Access policy to unblock a user.**
Revert it. Weakening CA is a security regression and rarely the real fix; the correct resolution
is to satisfy the device/app condition. If the policy is genuinely misscoped, the CA owner
corrects scope under change control — not the triage technician mid-ticket.


---


# Best Practices

Durable practices for running the client-connectivity toolkit and reducing the volume of
Outlook / OWA / mobile connectivity tickets over time.

## Diagnose by layer, always in order

- **Discovery → Protocol → Auth → Client.** Resist jumping to "recreate the profile" — that is
  a *client-layer* fix and it wastes the ticket when the fault is Autodiscover or Conditional
  Access. Walk the layers; the playbook's D-nodes enforce the order.
- **Reproduce before you remediate.** A fix applied to an unreproduced symptom can't be
  validated and often masks the real cause.

## Make `ConnTest` and OWA your instruments

- Keep a healthy **`ConnTest`** baseline mailbox and use it in *every* isolation: affected user
  vs `ConnTest` on the same client localizes server-vs-client in seconds.
- **OWA is your protocol-independent oracle.** "Works in OWA, fails in Outlook" instantly rules
  the mailbox/auth healthy and points at the desktop protocol/client layer.

## Prefer server-authoritative and external tests

- Trust `Get-CASMailbox`, `Test-OutlookConnectivity`, `Test-OutlookWebServices`, and the Remote
  Connectivity Analyzer over client symptoms — they are authoritative.
- Run **RCA off-network** (or a hotspot) to expose SSL-inspecting proxies / CASB that break
  Autodiscover or the OAuth handshake internally.

## Treat auth loops as policy, not passwords

- A repeating credential prompt is almost never a wrong password — it is a **Conditional Access
  grant the device/app can't satisfy** or an incomplete MFA registration. Read the **Entra
  sign-in logs** (client app + CA result) before touching the client.
- **Never weaken a Conditional Access policy to "fix" a user.** Resolve the *device/app*
  condition (enroll/comply, approved client). If a policy is genuinely misscoped, correct scope
  through the CA owner under change control.

## Respect the version/plan/cloud boundaries

- Autodiscover hosts, RCA endpoints, and some endpoint availability **differ on GCC High / DoD**
  — verify the sovereign values per tenant, never assume Commercial paths.
- `Test-*` cmdlet and parameter availability, OST path/behavior, and mobile client type are
  **version-dependent** — verify in your tenant/build rather than hardcoding.

## Steer clients toward the supported path

- **MAPI over HTTP** is the only supported Outlook desktop transport to Exchange Online
  (Outlook Anywhere/RPC is retired) — treat "enable RPC" requests as out of date.
- **Modern auth only** — Basic Auth is retired; migrate any lingering Basic-Auth client.
- **Outlook mobile (Graph)** over legacy EAS for mobile — fewer connectivity and policy
  failure modes.

## Change safely

- Diagnostics are read-only; the remediation script defaults to a **dry-run** that records the
  prior value. Only `-Commit` after approval, and keep the recorded prior value as the rollback.
- DNS / Autodiscover / SCP / connector-adjacent changes are **high-impact to production mail** —
  stage them under change control with the pass/fail gates in `05-testing.md`.

## Reduce future volume (close the loop)

- Tag every closed ticket with its **root-cause node (D1–D6)**; feed the reporting script's
  output into a monthly trend.
- A cluster on one node is a **systemic fix**: recurring Autodiscover DNS → fix the record and
  documentation; recurring CA auth loops → fix onboarding (device enrollment / approved-app
  guidance); recurring protocol-disabled → fix the mailbox plan / provisioning default.
- Keep the playbook current as Outlook builds, mobile clients, and Conditional Access posture
  change — it is a living runbook, not a one-time document.


---


# Deliverables Summary

Everything included in the **Outlook / OWA / Exchange Client Connectivity Troubleshooting
Toolkit**, on one page.

## Documentation

| Document | What it gives you |
|----------|-------------------|
| **Solution Overview** | The client-connectivity model (Autodiscover → protocols → auth → client), the layered diagnostic method, benefits, limitations, and the Assess→Expand adoption model. |
| **Requirements Guide** | Solution-specific prerequisites — diagnostic-capable least-privilege role, the `ConnTest` baseline mailbox, correct Autodiscover DNS, modern auth / Conditional Access read access, RCA + SARA access, and hybrid free/busy prerequisites — each with how to *verify* and *implement*. Builds on the shared Messaging requirements. |
| **Diagnostic Playbook** | The core: a symptom→root-cause **decision tree** (D0 scope; D1 Discovery; D2 Protocol; D3 Auth; D4 Client; D5 hybrid free/busy; D6 Mobile) with the exact test and pass/fail branch at each node, and change-control gates + rollback for any remediation. |
| **Testing & Validation** | Six pass/fail **gates** (Autodiscover resolves, protocols connect, auth succeeds, free/busy returns, mobile syncs, isolation is conclusive) plus regression re-test and the pilot exit criterion. |
| **Troubleshooting** | Common failure modes across every layer and their resolutions. |
| **Best Practices** | Durable practices for diagnosing by layer, using `ConnTest`/OWA as instruments, treating auth loops as policy, respecting version/cloud boundaries, and closing the loop to reduce future ticket volume. |
| **Executive Summary** | Crisp outcome/approach/why-low-risk for decision-makers. |

## PowerShell scripts (5)

All scripts use the **ExchangeOnlineManagement (EXO V3)** module and/or **Microsoft Graph**,
connect only via **modern authentication** (no stored credentials), and are **read-only or
`-WhatIf`/dry-run by default**.

| # | Script | What it does |
|---|--------|--------------|
| 1 | **`Get-ClientConnectivityAssessment.ps1`** | *Discovery (read-only).* Per-user client-access + protocol picture: `Get-CASMailbox` enablement (MAPI/EWS/OWA/ActiveSync), plan defaults, and server-side `Test-OutlookConnectivity` / `Test-OutlookWebServices` results, compared against the `ConnTest` baseline. Outputs an object/table per user. |
| 2 | **`Set-MailboxProtocolAccess.ps1`** | *Remediation (safe-by-default).* Re-enables a disabled client protocol (`Set-CASMailbox`). Defaults to a **dry-run report** that records the current value; changes only with explicit `-Commit`; supports `-WhatIf`. Prints the recorded prior value for rollback. |
| 3 | **`Test-AutodiscoverEndpoints.ps1`** | *Validation.* Tests the Discovery layer per user: Autodiscover DNS (CNAME/SRV), the Autodiscover v2 JSON endpoint, and (hybrid) the SCP `AutoDiscoverServiceInternalUri`. Read-only; reports the resolved endpoint vs the expected host. |
| 4 | **`Test-ModernAuthConditionalAccess.ps1`** | *Validation.* Summarizes the Auth layer: org modern-auth (`Get-OrganizationConfig` OAuth), per-user auth policy (`Get-CASMailbox`), and — via Microsoft Graph — the Conditional Access policies and recent sign-in results for the user's mail client app. Read-only. |
| 5 | **`Get-ClientConnectivityScope.ps1`** | *Scope / health helper.* Answers D0 "how big is the blast radius": runs the assessment across a set of users, buckets pass/fail, and flags whether a fault is per-mailbox, per-site, or tenant-wide. Read-only reporting. |

**Safety note.** Diagnostics never change state. The one remediation script defaults to a
dry-run and requires `-Commit` under change control, keeping the recorded prior value as the
rollback (per the gates in Testing & Validation).
