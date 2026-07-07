# Requirements

These are the **solution-specific** prerequisites for configuring the Gmail mail plane. They build
on the shared **[Global Requirements — Google Workspace & Gemini Solutions](global-requirements-google.md)**
(Workspace/Cloud Identity tenant with super-admin, source M365/Entra for coexistence, DNS control,
identity source of truth, a pilot OU/group + change control, and security/compliance stakeholders).
Do not re-do the shared six here — verify them, then satisfy the additions below.

Each requirement lists **Description / Why required / How to verify / How to implement if missing.**

---

## 1. Verified domains with authoritative DNS access (per routed domain)

- **Description:** Every domain that sends or receives mail (primary, secondary, and any send-as
  vanity domains) must be **verified in Google Workspace** and you must hold access to its
  **authoritative DNS** zone to publish MX, SPF, DKIM, and DMARC records.
- **Why required:** Routing, coexistence, and all three authentication mechanisms are DNS-published.
  A domain that is unverified or whose DNS you cannot change cannot be authenticated or routed.
- **How to verify:** **Admin console → Account → Domains → Manage domains** shows each domain and its
  verification state. Confirm you can create a test TXT record in each zone and see it resolve
  (`dig TXT _test.<domain>` / the included `mailplane_dns_audit.py`).
- **How to implement if missing:** Add and verify the domain under **Manage domains**; obtain
  delegated or change-controlled access to each authoritative DNS zone before starting.

## 2. Super-admin (or scoped Gmail admin) and Admin SDK API access

- **Description:** A **super-admin** for the console configuration, plus a **Google Cloud project**
  with the **Admin SDK API** enabled and either a delegated service account (domain-wide delegation
  scoped to the read-only Directory/Reports scopes used here) or an OAuth client for the read-only
  scripts.
- **Why required:** Routing, compliance rules, and safety settings are configured in the Admin
  console; the assessment/validation scripts read directory, domain, and email-flow data through the
  Admin SDK / Reports API.
- **How to verify:** Confirm the admin role at **Account → Admin roles**; in Google Cloud confirm the
  **Admin SDK API** is enabled and the scopes are authorized under **Security → API controls →
  Domain-wide delegation**.
- **How to implement if missing:** Assign the role; create/enable the Cloud project + Admin SDK API;
  authorize the least-privilege scopes. **No key files are committed** — scripts use OAuth or
  Application Default Credentials (ADC).

## 3. Documented current mail flow & coexistence source of record

- **Description:** A written statement of the **current MX / mail path** for each domain, which
  system is **authoritative** during coexistence, and whether **split** or **dual** delivery applies —
  including the legacy host's inbound smart-host FQDN and any partner/relay hosts.
- **Why required:** You cannot safely design routes and hosts without knowing the current path;
  split vs. dual delivery and the authoritative system drive every routing decision and the cutover
  rollback.
- **How to verify:** `dig MX <domain>` for each domain (or `mailplane_dns_audit.py`) plus the
  legacy-side admin center; confirm the recorded path matches reality.
- **How to implement if missing:** Discover and document the current flow first; agree the
  authoritative system and coexistence pattern in **Design** before configuring any route.

## 4. A monitored DMARC reporting mailbox / RUA destination

- **Description:** A dedicated mailbox or aggregate-report processing destination to receive **DMARC
  RUA (aggregate) reports** — e.g. `dmarc-reports@<domain>` or a processor endpoint — and a person or
  process that reviews them.
- **Why required:** DMARC is advanced **only** on evidence. Aggregate reports are the evidence that
  legitimate senders are aligned; without a reviewed RUA destination you cannot safely leave
  `p=none`.
- **How to verify:** Confirm the mailbox/endpoint exists and is monitored; the DMARC record's `rua=`
  will point at it. The included `dmarc_rua_analyzer.py` parses the reports it receives.
- **How to implement if missing:** Create the mailbox (or provision the processor), assign an owner,
  and reference it in the DMARC record before publishing `p=none`.

## 5. Inventory of legitimate senders per domain

- **Description:** A complete list of every system that **legitimately sends as each domain** —
  Google Workspace, the legacy mail system (during coexistence), marketing/ESP platforms, ticketing,
  ERP/HR, scanners/MFPs, and relays — with each one's sending host or include mechanism.
- **Why required:** SPF has a hard **10-DNS-lookup limit** and DMARC enforcement will fail
  legitimate mail from any sender not aligned. The inventory is what makes an SPF record correct and
  DMARC safe to enforce.
- **How to verify:** Cross-check the sender list against **DMARC aggregate reports** (which reveal
  every source actually sending as the domain) using `dmarc_rua_analyzer.py`; reconcile gaps.
- **How to implement if missing:** Build the inventory from the ESP/app owners and from an initial
  `p=none` DMARC monitoring window before advancing enforcement.

## 6. Compliance & routing policy definitions

- **Description:** The **content-compliance and routing requirements** the mail plane must enforce —
  e.g. outbound disclaimers, TLS-required partner domains, archival/journaling routes, attachment
  restrictions, keyword/pattern quarantine — sourced from legal, security, and records stakeholders.
- **Why required:** Content-compliance rules encode policy; without the policy definitions the rules
  are guesses, and an over-broad rule can silently quarantine or reject legitimate mail.
- **How to verify:** Confirm each rule requirement has a named policy owner and an approved
  action (route / modify / quarantine / reject) and scope (which OU/domain).
- **How to implement if missing:** Gather the definitions from the stakeholders in **Assess/Design**;
  reconcile any overlap with existing **DLP** rules before authoring content-compliance rules.

## 7. A pilot mail cohort and rollback plan for mail-flow changes

- **Description:** Beyond the shared pilot OU/group: a **pilot mail cohort** (a small OU whose users
  can tolerate mail-flow experimentation) and a **written rollback** for each high-impact change —
  MX/route change, DMARC advancement, and cutover — with the exact prior value to restore and the
  DNS TTL.
- **Why required:** Mail-flow, DNS, and cutover changes are the highest-impact in this solution;
  pilot-first validation and a known-good rollback are the safety net the house model requires.
- **How to verify:** Confirm the pilot OU exists, TTLs are lowered ahead of changes, and each planned
  change has a documented prior value and revert step.
- **How to implement if missing:** Create the pilot OU; lower DNS TTLs on the affected records at
  least one TTL-window before the change; write the rollback into the change ticket.
