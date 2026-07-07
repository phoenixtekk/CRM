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
