# Solution Overview

## What this is

This solution is the **decommission and retirement runbook** for the *old* Microsoft 365 tenant
after an enterprise (80k–150k+ users) has cut over to Google Workspace, Google Cloud Platform, and
Gemini Enterprise. Migration projects almost always end at "everyone is live on Google" — and then
the source Microsoft 365 / Entra tenant sits for months: still licensed, still holding mailboxes and
Drive/OneDrive data, still trusted by app registrations and SSO integrations, still authoritative in
DNS for lingering records. That residual tenant is three problems at once — **duplicate cost**
(paying for both platforms), **risk** (orphaned identities, standing app secrets, unmanaged data),
and **compliance exposure** (records you may be legally obliged to keep, or obliged to dispose of).

This runbook turns "someone should shut that down eventually" into a **clean, auditable exit**: prove
the migration is actually complete, dispose of or export data in line with retention and legal-hold
obligations, wind down licensing and Entra app registrations, re-point or remove every DNS record and
integration that still pointed at Microsoft, and then **formally close the tenant** — with evidence
captured at every gate.

## The retirement model

The work is organized as six phases, executed pilot-first with pass/fail gates and rollback windows,
following the house model **Assess → (Design →) Configure → Pilot → Validate → Expand**:

1. **Completeness verification.** Prove — with data, not assertion — that mail, calendar, contacts,
   Drive/OneDrive/SharePoint, Teams/Chat, and shared mailboxes/resources reached Google. No teardown
   step runs until completeness passes its gate.
2. **Data disposition vs retention / legal hold.** Inventory what data still lives only in Microsoft
   365, cross-reference the org's **retention schedule** and any **legal holds / eDiscovery** matters,
   export what must be preserved to the org's records store, and dispose of the rest. *Legal-hold and
   records-retention determinations are made by the org's legal/records/compliance functions — this
   solution provides the technical inventory, export method, and evidence.*
3. **Licensing / subscription wind-down.** Reclaim and reduce paid seats, cancel or let lapse
   subscriptions once data disposition is complete, and stop recurring spend — staged so nothing is
   cancelled while it is still needed for export or hold.
4. **Entra app-registration + identity cleanup.** Inventory app registrations, enterprise apps
   (service principals), expiring/expired credentials and secrets, stale/guest accounts, and orphaned
   objects; remove or disable what the Google move made obsolete, on a documented schedule.
5. **DNS / integration re-point-or-remove.** Map every DNS record (MX, SPF, DKIM, DMARC, CNAME, TXT,
   autodiscover, SRV) and every external integration still bound to the Microsoft tenant; re-point
   what must survive to Google and remove what is dead — under change control, because mail-flow
   records are high-impact.
6. **Formal tenant closure.** Once everything above has passed, execute the vendor closure path
   (subscription cancellation → deletion window) and capture the closure evidence pack.

## How it works

Because the entire lifecycle runs on the *Microsoft* side of the migration, the source-of-truth for
checks is the **Microsoft Graph API** and the Microsoft 365 / Entra admin centers. Per the Google
category's automation rule, the five included tools are **Python** — they call **Microsoft Graph via
`msal` (auth) and `requests` (calls)**, read-only or dry-run by default, so an engineer can *run to
inventory and validate* rather than eyeball admin-center screens across a tenant of this size. The
Google side of the destination (Workspace, Cloud Identity) is referenced only where a DNS record or
integration must be **re-pointed to Google** — those steps cite the Google Admin console at exact
detail.

## Reference design

```
  ┌─────────────────────── SOURCE (retiring) ───────────────────────┐
  │  Microsoft 365 tenant  +  Microsoft Entra ID                    │
  │   mailboxes · Drive/OneDrive/SharePoint · Teams · app regs ·    │
  │   enterprise apps (SPs) · licenses/subscriptions · DNS trust    │
  └───────────────┬─────────────────────────────────────────────────┘
                  │  Microsoft Graph (read-only / dry-run)
                  │  via Python msal + requests
        ┌─────────▼──────────┐   evidence   ┌────────────────────────┐
        │ Decommission tools │─────────────▶│ Evidence & closure pack │
        │  1 completeness    │              │  (per-gate JSON/CSV +   │
        │  2 license wind-dn │              │   final report)         │
        │  3 app/orphan inv. │              └────────────────────────┘
        │  4 DNS/integration │
        │  5 checklist report│
        └────────────────────┘
                  │  re-point survivors
                  ▼
  ┌─────────────────── DESTINATION (live) ──────────────────────────┐
  │  Google Workspace / Cloud Identity — MX, SPF/DKIM/DMARC, SSO    │
  └─────────────────────────────────────────────────────────────────┘
```

The Graph app registration created for the tooling is named **`Decommission Read – Source-Tenant –
v1`** (application permissions, read-only scopes) and is itself removed in Phase 4 as the last object
to go, after it has produced the closure evidence.

## Benefits

- **Auditable exit.** Every gate produces evidence (JSON/CSV inventories, a signed checklist), so the
  closure survives audit and answers "prove nothing was orphaned and obligations were met".
- **Cost stops for good.** Licensing wind-down and tenant closure end duplicate spend that otherwise
  runs for months post-migration.
- **Risk reduced.** Standing app secrets, orphaned service principals, guest accounts, and stale
  trusts are enumerated and removed — shrinking the attack surface the migration left behind.
- **Compliance-safe.** Data disposition is gated on retention/legal-hold, and the technical evidence
  is handed to legal/records for their determination — the runbook never disposes of data unilaterally.
- **Safe by default.** All tooling is read-only or `--dry-run` until an operator explicitly passes
  `--apply`; production-affecting steps (DNS, closure) run under change control with rollback windows.

## Limitations & boundaries

- **Legal determinations are deferred.** Whether a mailbox is under hold, which records must be kept
  and for how long, and whether disposition is permitted are **legal/records/compliance decisions**.
  This solution inventories and evidences; it does not decide.
- **Microsoft-side vendor detail is exact; preview features are flagged.** Graph endpoints, admin
  paths, and closure mechanics reflect current public Microsoft documentation. Anything version- or
  preview-dependent is flagged **"verify in your tenant"** rather than asserted.
- **Third-party integrations are handled at the pattern level.** Where an external app (ServiceNow,
  SAP, an SIEM, a backup vendor) trusts the Microsoft tenant, the runbook tells you how to *find* and
  *classify* the dependency; the vendor's own re-point/removal steps are deferred to their docs.
- **Not a migration tool.** This runs *after* cutover; it verifies completeness but does not move data.
  If completeness fails its gate, you return to the migration project — you do not proceed to teardown.

## Deployment model

**Assess → (Design →) Configure → Pilot → Validate → Expand**, pilot-first, with explicit pass/fail
gates and a documented rollback for every production-affecting change. In this solution the "pilot"
is a **bounded scope** — a single domain, a small set of mailboxes/accounts, or one DNS zone — proven
end-to-end (inventory → disposition → cleanup → re-point) before the same procedure is expanded to the
whole tenant. Closure itself is irreversible past the vendor's deletion window, so it is the last gate
and requires all prior evidence signed off.
