# 3. Implementation — Microsoft 365 ↔ Google Workspace Coexistence

This is the ordered runbook. Execute the phases in order: **Assess → Configure → Pilot → Validate →
Expand**. Do **not** advance a phase until its exit gate (see `05-testing.md`) passes. Every object
is **named once and reused verbatim** in later steps, testing, troubleshooting, and the scripts.

**Conventions used below**
- Shared vanity domain: `contoso.com` · M365 inbound host: `contoso-com.mail.protection.outlook.com`
- Google smart host: `aspmx.l.google.com`
- Google role account (Exchange → reads Google availability): `svc-interop-exo@contoso.com`
- Exchange role account (Google → reads Exchange availability): `svc-interop-gcal@contoso.com`
- GCDS provisioning admin: `svc-gcds@contoso.com`
- Exchange outbound relay connector: **`Coexistence – EXO→Google Connector`**
- Google split-delivery host: **`Coexistence – M365 Host`** · routing rule: **`Coexistence – Split Delivery`**
- Directory-sync marker OU/group: **`Coexistence – Synced`** · Pilot group: **`Coexistence – Pilot Members`**

> Replace `contoso.com` and the host values with your real values, but keep the naming **pattern**
> identical so downstream steps and scripts line up.

---

## Phase 1 — Assess

### 1.1 Confirm access to both platforms
1. Sign in to **admin.google.com** (super-admin) and **admin.exchange.microsoft.com** /
   **admin.microsoft.com** (Exchange admin + Global Admin or least-privilege equivalent) — **R1**.

### 1.2 Capture the coexistence-readiness baseline
1. On an operator workstation, install the Exchange Online module:
   `Install-Module ExchangeOnlineManagement -Scope CurrentUser`.
2. Run **`scripts\GWCOEX-Discovery.ps1`** against the M365 tenant. It exports CSVs of: accepted
   domains and their **type** (authoritative vs internal relay), inbound/outbound **connectors**,
   the domain's **MX / SPF / DKIM / DMARC** as seen in DNS, **mail contacts / mail users**
   (Google-side representation), and any existing **Calendar Interop / organization sharing** config.
3. Separately record the current **Google** side (Domains, Gmail Routing/Hosts, Calendar Interop
   management state) and the **DNS** MX/SPF/DKIM/DMARC. Save all of this as the **rollback baseline**.

**Exit gate:** complete readiness baseline captured on both platforms and DNS; MX-primary direction
(**R4**) confirmed and written down. (Test **T1**.)

---

## Phase 2 — Configure

Configure the three pillars. Build each for the **pilot scope first**; expansion is Phase 5.

### 2.1 Mail routing / split delivery

#### 2.1a Exchange side — internal relay + connector to Google
1. In **Exchange admin center → Mail flow → Accepted domains**, open `contoso.com` and set the type
   to **Internal relay**. (This tells Exchange to *relay* unknown recipients instead of NDR.)
2. In **Mail flow → Connectors → Add a connector**, create an **outbound** connector
   **`Coexistence – EXO→Google Connector`**: From **Office 365** → To **Partner organization**; route
   by **domain** `contoso.com`; delivery via **smart host** `aspmx.l.google.com` (or the domain's
   full Google MX target); require **TLS** with a trusted CA subject. Save.
   - You may scope relay to the pilot initially by using a routing subdomain or a transport rule that
     limits the connector to **`Coexistence – Pilot Members`** during Phase 3.
3. Confirm mail for a Google-hosted pilot recipient now relays out of Exchange rather than NDRing
   (validated in Phase 4).

#### 2.1b Google side — split-delivery routing to M365
1. In **Google Admin console → Apps → Google Workspace → Gmail → Hosts**, add a host
   **`Coexistence – M365 Host`** = `contoso-com.mail.protection.outlook.com`, port **25**, require TLS.
2. In **Apps → Google Workspace → Gmail → Routing**, add a **Recipient address map / split-delivery**
   rule **`Coexistence – Split Delivery`**: for envelope recipients **not** hosted in Google, route
   to **`Coexistence – M365 Host`**. Keep the rule scoped to the pilot OU during Phase 3.
3. This is the mirror of internal relay: Google delivers to its own mailboxes and forwards the rest
   to Exchange Online.

#### 2.1c Authentication (DNS)
1. **SPF:** publish a single TXT that authorizes **both** senders, e.g.
   `v=spf1 include:_spf.google.com include:spf.protection.outlook.com -all`.
2. **DKIM:** enable and publish a **separate selector** for each platform (Google: `google` selector;
   M365: the two `selector1/2._domainkey` CNAMEs). Both sign independently.
3. **DMARC:** during the transition keep a monitoring-friendly policy (`p=none` with `rua=` reporting,
   or `quarantine` with a wide `pct`) so a relay misstep is *visible*, not silently dropped. Tighten
   only after Validate.

### 2.2 Free/busy calendar interop

#### 2.2a Create the two role accounts
1. In **Google Admin console → Directory → Users**, create **`svc-interop-exo@contoso.com`** — a
   standard, Calendar-enabled user Exchange will use to read Google availability. Do not use it as a
   person's mailbox.
2. In **Microsoft 365 admin center → Users**, create **`svc-interop-gcal@contoso.com`** — a standard
   licensed mailbox Google will use to read Exchange availability. If the endpoint uses basic auth,
   set the password to **non-expiring** and exclude the account from blocking Conditional Access.

#### 2.2b Google → Exchange (Google users see Exchange availability)
1. In **Google Admin console → Apps → Google Workspace → Calendar → Calendar Interop management**,
   check **"Allow Google Calendar to display Exchange users' availability."**
2. Click **Add an Exchange endpoint** and choose the endpoint type your tenant offers —
   **Microsoft 365 (Graph API)** (provide **Tenant ID**, **Application (client) ID**, **client
   secret** from an app registration granted the required Calendars permission) **or** legacy **EWS**
   (`https://outlook.office365.com/EWS/Exchange.asmx` with role account `svc-interop-gcal@contoso.com`).
   *(Graph endpoint availability may be preview/rolling-out — verify in your tenant.)*
3. Optionally enable **Show event details** (title/location) instead of availability-only; event-level
   privacy is respected.

#### 2.2c Exchange → Google (Exchange users see Google availability)
1. Still in **Calendar Interop management**, set the **Google role account**
   **`svc-interop-exo@contoso.com`** that Exchange will authenticate as when reading Google availability.
2. On the Exchange side, configure organization availability sharing so Outlook resolves the Google
   users. Where event-detail visibility is wanted, raise the calendar detail level, e.g.
   `Set-MailboxCalendarFolder <user>:\Calendar -DetailLevel LimitedDetails` for pilot users (default
   is availability-only).
3. Ensure the Exchange endpoint is reachable from Google on **port 443** with a public-CA TLS cert
   (allowlist Google's Interop egress ranges if you block inbound).

### 2.3 Directory sync (unified GAL)

#### 2.3a Google side — GCDS from AD/LDAP
1. In **Google Admin console → Directory → Users**, create the provisioning admin
   **`svc-gcds@contoso.com`** with directory + shared-contacts privileges.
2. Install **GCDS** on a supported host (separate from the domain controller is recommended) with
   LDAP access to AD (389/636).
3. In **GCDS Configuration Manager**:
   - **Google Domain Configuration** → domain `contoso.com`; **Authorize** with `svc-gcds@contoso.com`.
   - **LDAP Configuration** → server type **MS Active Directory**, base DN, and a read account; **Test
     connection**.
   - **User Accounts / Groups / Shared Contacts** → search rules that select the **`Coexistence –
     Synced`** OU/group. Provision **shared contacts** for M365-only recipients so they appear in
     Google's directory.
   - **Sync** → **Clear cache → Simulate sync**; review **Proposed changes**; confirm no unexpected
     deletions, then run once for the pilot.
4. GCDS is **one-way** — it never modifies AD.

#### 2.3b Microsoft side — provision from the same source
1. Ensure users are provisioned into **Entra/Exchange** from the same source of truth (Entra Connect /
   cloud sync from AD, or native Entra).
2. Represent **Google-only** recipients in Exchange as **mail contacts / mail users** (so they appear
   in the GAL and route via 2.1a). Tag coexistence-synced objects with the **`Coexistence – Synced`**
   marker for later cleanup.

**Exit gate:** all three pillars configured and scoped to the pilot; DNS auth (SPF/DKIM/DMARC) in
place. (Test **T2**.)

---

## Phase 3 — Pilot

1. Populate **`Coexistence – Pilot Members`** with representative users on **both** platforms plus one
   resource/room and one shared mailbox equivalent.
2. Confirm the mail relay, split-delivery rule, and Interop endpoint are scoped to the pilot (subdomain,
   transport rule, or OU) so production users are unaffected.
3. Run **`scripts\GWCOEX-Set-ScopeTargeting.ps1`** to (re)point the coexistence scope at
   **`Coexistence – Pilot Members`**. It defaults to **`-WhatIf`** — review the planned scope change,
   then re-run with `-Apply`.

**Exit gate:** coexistence live for the pilot only; production unchanged. (Test **T3**.)

---

## Phase 4 — Validate

Run **`scripts\GWCOEX-Validation.ps1`** for each pilot user; it checks the three pillars per user:
1. **Mail routing** — send a probe from Google→M365 and M365→Google for pilot recipients; confirm
   delivery (no NDR) and correct headers (relayed via the connector / split-delivery host).
2. **Free/busy** — confirm a Google user resolves an Exchange user's availability *and* an Outlook user
   resolves a Google user's availability (both directions).
3. **Directory** — confirm each pilot user appears in the **other** platform's directory/GAL (Google
   shared contact ↔ Exchange mail contact) and resolves when addressed.

Run **`scripts\GWCOEX-Report.ps1`** to produce a **coexistence coverage** report (per user: mail-route
OK, free/busy both-ways OK, directory-present OK) with an overall coverage percentage.

If a check fails, use `06-troubleshooting.md`; if remediation is needed, run
**`scripts\GWCOEX-Remediation.ps1`** (defaults to **`-WhatIf`** — review, then `-Apply`).

**Exit gate:** 100% of pilot users pass all three pillars, both directions. (Test **T4**.)

---

## Phase 5 — Expand

1. Widen each pillar's scope from **`Coexistence – Pilot Members`** to the full fleet:
   - remove the pilot scoping on the **connector / transport rule** and the Google **split-delivery
     rule** (or point them at the whole domain/OU);
   - broaden the **GCDS** search rules to all coexistence OUs and schedule GCDS on its interval;
   - confirm the Interop endpoint covers all users.
2. Re-run **`GWCOEX-Set-ScopeTargeting.ps1 -Scope AllUsers`** (defaults to `-WhatIf`; re-run with
   `-Apply`).
3. Re-run **`GWCOEX-Validation.ps1`** on a broad sample and **`GWCOEX-Report.ps1`** for fleet coverage.
4. Only after coverage is proven, tighten **DMARC** to an enforcing policy.

**Exit gate:** fleet coverage report green; DMARC enforced; rollback plan current. (Test **T5**.)

---

## Rollback (any phase)

Because every change is captured in the Phase 1 baseline, rollback is deterministic:
- Revert the **Accepted Domain** type to its prior value and **disable** `Coexistence – EXO→Google
  Connector`.
- Disable the Google **`Coexistence – Split Delivery`** routing rule.
- Uncheck **Calendar Interop** endpoints.
- **Pause GCDS** (do not delete synced objects until consolidation).
- Restore prior **MX/SPF/DKIM/DMARC** DNS if they were changed.

Coexistence is a transition state — see `07-best-practices.md` for the controlled **decommission** at
consolidation.
