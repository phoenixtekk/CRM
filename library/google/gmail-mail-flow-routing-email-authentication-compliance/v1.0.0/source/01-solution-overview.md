# Solution Overview

## What this is

This solution designs and configures the **Gmail enterprise mail plane** end to end for an
organization running (or moving to) Google Workspace: **inbound and outbound routing and hosts**,
**split and dual delivery** for coexistence with a legacy mail system, **email authentication
(SPF, DKIM, DMARC)** taken from monitor to enforcement, **content-compliance and routing rules**,
and **spam and attachment controls**. The outcome is mail that is **deliverable, authenticated, and
compliant** — designed on purpose rather than accreted by accident.

It is deliberately **distinct from a Workspace security baseline / DLP solution**. That work governs
*data* (DLP rules, Context-Aware Access, alerting). **This** work governs the *mail plane* — how
messages enter, leave, are routed, are authenticated, and are inspected by compliance rules. The two
are complementary; a reference to DLP appears only where a content-compliance rule and a DLP rule
could overlap and must be reconciled.

## How it works — the reference model

The mail plane is designed as five cooperating layers, each configured in the Google Admin console
(**admin.google.com → Apps → Google Workspace → Gmail**) and validated before the next is enabled:

1. **Routing & hosts.** Where mail enters and leaves. **Inbound gateway**, **outbound gateway /
   smart host**, and named **Routes** and **Hosts** entries determine the delivery path. During
   coexistence, **split delivery** (MX at one system, some mailboxes on the other) or **dual
   delivery** (a copy delivered to both) keeps both systems working through the migration.

2. **Email authentication.** **SPF** (which hosts may send as the domain), **DKIM** (a cryptographic
   signature Google adds to outbound mail), and **DMARC** (the policy that ties SPF/DKIM alignment to
   an action and requests reports). DMARC is rolled out on the documented **enforcement journey**:
   `p=none` (monitor) → `p=quarantine` → `p=reject`, advancing only when aggregate reports show
   legitimate mail is aligned.

3. **Content compliance & routing rules.** Admin-defined rules that inspect message content,
   headers, and recipients to **route**, **modify**, **quarantine**, or **reject** mail — e.g. add a
   disclaimer, route a domain to an archive connector, quarantine attachments matching a pattern, or
   enforce TLS to a partner.

4. **Spam, phishing & attachment controls.** Gmail's enhanced pre-delivery message scanning, custom
   **approved/blocked sender** lists, **attachment** and **anti-phishing/anti-malware** safety
   settings, applied per organizational unit.

5. **Observability.** DMARC **aggregate (RUA) reports**, the **Admin console Email Log Search**, and
   the **BigQuery / Reports API** email-flow signals used to prove authentication is passing and
   rules are routing correctly before enforcement tightens.

Every artifact this solution creates — a route, a DMARC record, a compliance rule, a validation
report, a service identity — is **named** with the convention `<Purpose> – <Scope> – <Stage>`
(e.g. `DMARC – corp.example – Enforce`, `Content Compliance – Outbound Disclaimer – Pilot`,
`Route – Archive Connector – Prod`) and the **same name is reused** in testing, troubleshooting, and
the scripts.

## Coexistence patterns (why split vs. dual delivery)

- **Split delivery** — the primary MX points at **one** system; Google is authoritative for the
  mailboxes hosted on Google and forwards the rest to the legacy host (or vice-versa). Used when
  mailboxes are being **cut over in waves** and each user lives on exactly one system at a time.
- **Dual delivery** — inbound mail is delivered to **both** systems (one authoritative, one a copy).
  Used briefly during transition so users can validate Gmail while the legacy system remains the
  system of record. Dual delivery is **temporary** by design — it doubles storage and can duplicate
  auto-replies, so it is retired at cutover.

The choice, the authoritative system, and the retirement trigger are decided in **Design** and
recorded so routing changes are auditable.

## Benefits

- **Deliverability** — correct SPF/DKIM/DMARC alignment and clean routing stop legitimate mail from
  silently landing in spam or being rejected by strict receivers.
- **Anti-spoofing** — a `p=reject` DMARC policy makes the organization's domains far harder to spoof
  in phishing, protecting the brand and recipients.
- **Compliance** — content-compliance rules apply disclaimers, archival routing, TLS enforcement,
  and quarantine consistently, with an audit trail.
- **Coexistence without outages** — split/dual delivery lets mail keep flowing while mailboxes move.
- **Evidence** — DMARC reports and email-log validation prove the mail plane is healthy before and
  after each change.

## Limitations & boundaries

- **DNS is external.** SPF/DKIM/DMARC and MX live in the authoritative **DNS** zone, which the
  organization (not Google) controls. This solution specifies the exact records; publishing them is a
  DNS change under change control.
- **Migration data movement is a separate tool.** Moving mailbox *content* from the legacy system is
  performed by a migration tool (**Google Workspace Migrate, GWMME, BitTitan MigrationWiz, CloudM**);
  this solution configures the **mail plane and coexistence routing** around that movement and defers
  each tool's console internals, licensing, and support to the vendor's own documentation.
- **Receiver behavior varies.** How a remote receiver treats a `quarantine`/`reject` result is the
  receiver's decision; DMARC states intent, it does not guarantee a specific inbox placement.
- **Gemini / preview features** referenced anywhere are flagged **"verify in your tenant"** because
  availability rolls out by edition and region.

## Deployment model

The solution follows the house model — **Assess → Design → Configure → Pilot → Validate → Expand** —
**pilot-first**, with explicit **pass/fail gates** at each stage and a **documented rollback** for
every production change. Mail flow, DNS, and cutover are high-impact: no DMARC policy advances, no MX
change ships, and no routing rule goes fleet-wide until the pilot passes its gate.
