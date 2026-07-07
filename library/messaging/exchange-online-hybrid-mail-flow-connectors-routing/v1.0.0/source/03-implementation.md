# Implementation

Follow the house deployment model — **Assess → Design → Configure → Pilot → Validate → Expand** — with
explicit pass/fail gates and a documented rollback at each production-affecting step. Mail flow,
connectors, accepted domains, DNS, and transport rules are **high-impact to production mail**: change
them pilot-first, never fleet-wide in one move.

Every artifact is named with the convention `<Purpose> – <Scope> – <Stage>` and that exact name is
reused in testing, troubleshooting, and the scripts. Portal paths are Commercial; on GCC/GCC High/DoD
substitute the `*.office365.us` portals and **verify each feature in your own cloud** (R7).

---

## Phase 1 — Assess (read-only baseline)

**Goal:** capture the current mail-flow topology before touching anything.

1. Connect with a least-privilege admin: in EXO PowerShell,
   `Connect-ExchangeOnline -UserPrincipalName <admin-upn>` (modern auth; no stored credentials).
2. Run the Discovery script **read-only**:
   `\.Invoke-MailFlowDiscovery.ps1 -OutputPath .\baseline`. It enumerates accepted domains (+ type),
   inbound/outbound connectors (+ type/source), transport rules, remote domains, the HCW hybrid state,
   and resolves public MX for each domain. Save the report as **`MailFlow Baseline – Tenant – Prod`**.
3. Confirm the accepted-domain **types** match where mailboxes actually live (EXO vs on-prem vs
   partner). Flag any domain that is `Authoritative` but still has recipients elsewhere — that is a
   silent-NDR risk (see R3).
4. Record the current routing topology (cloud-authoritative / on-prem-inbound / CMT) and whether
   **centralized mail transport** is enabled (`Get-OnPremisesOrganization`, HCW state).

**Gate G1 (Assess complete):** baseline report saved; accepted-domain types and current routing
documented; any authoritative-domain-with-external-recipients risk flagged. Do not proceed until G1 is
met.

---

## Phase 2 — Design (on paper, no changes)

**Goal:** decide the target connectors, domain types, routing, transport rules, and the CMT decision.

1. **Accepted domains.** For each mail domain choose the target **type**: `Authoritative` if all
   recipients are (or will be) in EXO; `InternalRelay` during coexistence when the domain is shared
   with on-prem/partner. Name the primary shared domain **`Accepted Domain – Primary – Prod`**.
2. **Connectors.** Decide which connectors you need and their type:
   - Hybrid coexistence → rely on HCW connectors (`Inbound from on-prem`, `Outbound to on-prem`); plan
     to **re-run HCW**, not hand-edit.
   - Partner enforcement (a B2B partner or a hygiene gateway) → plan
     `Inbound Connector – Partner – Prod` and/or `Outbound Connector – Partner – Prod` with the
     partner's cert subject/IPs and required-TLS posture (R4).
3. **Routing topology.** Pick the target shape: cloud-authoritative (MX → EXO/EOP), on-prem-inbound
   (MX → on-prem gateway), or CMT.
4. **Centralized mail transport (CMT) decision.** Enable CMT **only** if on-prem must process outbound
   *cloud* mail (on-prem DLP/encryption/disclaimer gateway, or a required outbound smart host only
   on-prem can reach). Otherwise leave **CMT off** (EXO sends outbound directly). Record the decision
   and its justification.
5. **Transport rules.** List each needed mail-flow rule with condition → action, scope, and priority;
   name them (e.g. `Transport Rule – Partner TLS – Prod`, `Transport Rule – External Tag – Prod`).
   Design out loops: never let two rules redirect to each other, and scope tightly.
6. **Pilot scope.** Define the pilot: a pilot accepted domain or a small set of pilot recipients and
   controlled test mailboxes (`pilot-tx@…`, `pilot-rx@…`) plus an external test address you control.

**Gate G2 (Design approved):** target domain types, connector list, routing topology, CMT decision,
named transport rules, and pilot scope reviewed and approved under change control. A **rollback plan**
is written for each change (see the Rollback section). Do not configure until G2 is met.

---

## Phase 3 — Configure (in pilot first)

**Goal:** build the designed artifacts, validating with `-WhatIf`/dry-run before applying.

> Safety: the Configuration script defaults to **dry-run/`-WhatIf`**. It only makes changes when you
> pass **`-Commit`** (and it still honors `-WhatIf`). Preview every change first.

### 3a. Accepted-domain type

1. Preview: `Set-AcceptedDomain -Identity "<domain>" -DomainType InternalRelay -WhatIf`.
2. Apply (pilot domain first, under change control): remove `-WhatIf`. This creates/updates the
   **`Accepted Domain – Primary – Prod`** typing.

### 3b. Hybrid connectors (hybrid only)

1. Do **not** hand-create hybrid connectors. If coexistence connectors are missing or unhealthy,
   **re-run the current HCW** from a supported on-prem Exchange server. HCW provisions
   `Inbound from on-prem` and `Outbound to on-prem` with TLS + certificate/subject validation.
2. Confirm after HCW: `Get-InboundConnector`, `Get-OutboundConnector` show the hybrid connectors with
   `ConnectorSource = HybridWizard`.

### 3c. Partner connectors (if in scope)

1. Preview with the Configuration script:
   `\.Set-MailFlowConfiguration.ps1 -PartnerConnector -PartnerDomain <partner.example> -TlsCertName "<subject>" -WhatIf`.
2. Apply with `-Commit` to create:
   - `New-InboundConnector -Name "Inbound Connector – Partner – Prod" -ConnectorType Partner
     -SenderDomains <partner.example> -RequireTls $true -TlsSenderCertificateName "<subject>"`
   - and/or `New-OutboundConnector -Name "Outbound Connector – Partner – Prod" -ConnectorType Partner
     -RecipientDomains <partner.example> -SmartHosts <smarthost> -TlsSettings DomainValidation
     -TlsDomain "<smarthost-subject>"`.
   Use IP restriction instead of cert where the partner authenticates by IP.

### 3d. Centralized mail transport (only if G2 chose CMT)

1. Enable CMT **through HCW** (the "route outbound mail through on-premises" option), not by manual
   connector edits. This is a deliberate, gated change — expect added latency and an on-prem
   dependency for outbound cloud mail.
2. If G2 chose **CMT off** (default), skip this — EXO sends outbound directly.

### 3e. Transport rules

1. Preview each rule: `New-TransportRule -Name "Transport Rule – Partner TLS – Prod" … -WhatIf` (or via
   `Set-MailFlowConfiguration.ps1 -TransportRule … -WhatIf`).
2. Apply with `-Commit`. Set an explicit **priority** and scope tightly (specific senders/recipients/
   domains). Keep rules that *redirect* mail to an absolute minimum and never mutually redirecting.

**Gate G3 (Configured in pilot):** artifacts exist with the exact designed names; `Get-*Connector`,
`Get-AcceptedDomain`, `Get-TransportRule` match the design; no rule forms a loop. Proceed to Validate.

---

## Phase 4 — Pilot & Validate (prove it before expanding)

**Goal:** prove mail routes correctly for the pilot scope, with clean traces and no loops.

Run the validation procedures in `05-testing.md`. In summary:

1. **Inbound:** send external → `pilot-rx@Accepted Domain – Primary – Prod`; confirm delivery and that
   message trace shows the expected inbound connector/path.
2. **Outbound:** send `pilot-tx@…` → an external address you control; confirm delivery and that trace
   shows the expected outbound path (direct, or via on-prem if CMT is on).
3. **Internal-relay:** to a recipient on the shared domain that lives **on-prem**, confirm the message
   relays out `Outbound Connector – OnPrem – Prod` rather than NDR'ing.
4. **Loop check:** confirm no message loops (trace does not show a message bouncing between EXO and
   on-prem, or between two transport rules).
5. **Trace clean:** for each test, message trace status is `Delivered` (or the intended action) with no
   `Failed`/`Pending` surprises, and headers show the expected connector and auth results.

**Gate G4 (Pilot validated):** all five checks pass for the pilot scope; traces clean; no loops. If any
check fails, **roll back** the offending change (below) and redesign. Do not expand until G4 is met.

---

## Phase 5 — Expand (production rollout)

**Goal:** extend the validated design to all domains/recipients.

1. Apply the validated accepted-domain types and connectors to the remaining production domains,
   **one change per change window**, re-running the relevant validation after each.
2. Update DNS (MX / any connector host records) only when the routing topology change requires it, and
   only after connectors are validated — DNS is high-impact and slow to revert.
3. Re-run the Reporting script (`New-MailFlowHealthReport.ps1`) after each expansion step and archive
   the report with the change record.

**Gate G5 (Expanded):** production mail for all in-scope domains routes correctly (inbound, outbound,
internal-relay), traces are clean, and the health report shows the target connectors/domain types with
no loops or misrouting.

---

## Rollback

Because every change is staged, each is individually reversible:

- **Accepted-domain type:** revert with `Set-AcceptedDomain -Identity "<domain>" -DomainType
  <previous>` (e.g. back to `Authoritative`). Captured in the baseline (R2).
- **Partner connector:** disable then remove: `Set-InboundConnector "Inbound Connector – Partner –
  Prod" -Enabled $false`, then `Remove-InboundConnector` (same for outbound). Never touch
  HCW-sourced connectors this way.
- **Hybrid connectors / CMT:** revert via HCW (re-run and choose the prior CMT setting); do not
  hand-edit HCW connectors.
- **Transport rule:** disable first (`Disable-TransportRule "Transport Rule – … – Prod"`), confirm mail
  flow recovers, then remove if unwanted.
- **DNS/MX:** revert the record to the pre-change value; allow for TTL propagation. Because DNS is
  slowest to revert, change it **last** and only after connectors validate.

Keep the **`MailFlow Baseline – Tenant – Prod`** report from Phase 1 as the source of truth for what
"good" looked like before the change.
