# Testing & Validation — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Each phase in the Implementation Guide ends with a **gate**. This document defines the pass/fail checks for those gates. Run the read-only scripts (`EXOMIGG-Validation.ps1`, `EXOMIGG-Report.ps1`) plus the manual checks below. **A gate passes only when every check is PASS or explicitly waived in writing.**

> All connections use the GCC High endpoints (`-ExchangeEnvironmentName O365USGovGCCHigh`, `-Environment USGov`). A "connected to wrong cloud" failure (see `06-troubleshooting.md`) invalidates the entire test run.

---

## Gate 0 — Environment sanity (before Assess)

| # | Check | How | PASS |
|---|-------|-----|------|
| 0.1 | Correct cloud | `EXOMIGG-Discovery.ps1` reports environment per tenant | Both show **GCC High / USGov**, initial domains `*.onmicrosoft.us` |
| 0.2 | Modules current | `EXOMIGG-Validation.ps1` | ExchangeOnlineManagement + Microsoft.Graph present and Gov-connectable |
| 0.3 | Endpoints reachable | `EXOMIGG-Validation.ps1` | `login.microsoftonline.us`, `graph.microsoft.us`, `outlook.office365.us` reachable |

**FAIL 0.1** = you are pointed at Commercial; fix connection parameters before anything else.

---

## Gate 1 — Assess exit (readiness)

| # | Check | How | PASS |
|---|-------|-----|------|
| 1.1 | Both tenants GCC High (R0) | Discovery | Confirmed same sovereign cloud |
| 1.2 | Migration method + support (R1) | Change record | Native availability confirmed **or** third-party/PST path selected |
| 1.3 | Target licensing (R3) | Discovery / `portal.office365.us` | Enough US Gov mailbox licenses; native add-on present/orderable (verify for GCC High) |
| 1.4 | Roles (R2) | Discovery | Org Admin + Move Mailboxes + Global Admin assigned |
| 1.5 | DNS control (R6) | Manual | Can edit MX/TXT/CNAME for the domain |
| 1.6 | Baseline captured (R8/G6) | `EXOMIGG-baseline\` | DNS, mailbox inventory, permissions exported |

---

## Gate 2 — Configure exit

| # | Check | How | PASS |
|---|-------|-----|------|
| 2.1 | Validation clean, both tenants | `EXOMIGG-Validation.ps1` | All checks PASS on source **and** target |
| 2.2 | Engine authenticates | Native: org relationship set; Tool: vendor connectivity test | Chosen engine connects to **both** GCC High tenants via `login.microsoftonline.us` |
| 2.3 | Target MailUsers correct (native) | `EXOMIGG-Report.ps1` | Target MailUsers carry source **ExchangeGUID** + proxies; **not** prematurely licensed |
| 2.4 | Domain pre-added | `portal.office365.us` → Domains | Domain added to target; TXT created (verification pending is expected) |

---

## Gate 3 — Pilot exit (the critical gate)

Run for every mailbox in **`EXOMIGG-Pilot`**:

| # | Check | How | PASS |
|---|-------|-----|------|
| 3.1 | Move completed | Batch status / `EXOMIGG-Report.ps1` | Status Completed, no errors |
| 3.2 | Content present | Open OWA in target (`outlook.office365.us`) | Inbox, Sent, Calendar, Contacts present |
| 3.3 | Folder counts | `EXOMIGG-Report.ps1` item counts source vs target | Counts match within expected delta |
| 3.4 | Permissions/delegation | `Get-MailboxPermission` / `Get-RecipientPermission` | Delegates, SendAs, SendOnBehalf intact |
| 3.5 | Mail flow | Send/receive test to a pilot mailbox | Inbound + outbound succeed |
| 3.6 | Free/busy & calendar | Meeting invite test | Calendar and free/busy resolve |

**Any FAIL here stops expansion.** Diagnose in `06-troubleshooting.md`, remediate (`EXOMIGG-Remediation.ps1`, default `-WhatIf`), re-test.

---

## Gate 4 — Per-wave validation (Expand)

Repeat Gate 3 checks for each **`EXOMIGG-WaveN`** after its move. Do not start the next wave until the current wave is fully PASS.

---

## Gate 5 — Cutover validation

| # | Check | How | PASS |
|---|-------|-----|------|
| 5.1 | Domain released (source) | `Get-MsolUser -DomainName <domain>` equiv. / Discovery | No objects still bind the domain in source |
| 5.2 | Domain verified (target) | `portal.office365.us` → Domains | Domain shows **Verified** in target |
| 5.3 | MX cutover | `nslookup -type=mx <domain>` / MxToolbox | MX points to target GCC High |
| 5.4 | Autodiscover | Outlook profile rebuild | Autodiscover resolves to target |
| 5.5 | Mail flow both ways post-cutover | Test messages | External inbound + outbound OK |
| 5.6 | Transport rules/connectors | Target EAC | Rules/connectors/allow-block recreated |

---

## Gate 6 — Closeout

| # | Check | How | PASS |
|---|-------|-----|------|
| 6.1 | Final report archived | `EXOMIGG-Report.ps1` (all mailboxes) | Stored with change record |
| 6.2 | NDR mitigation | Auto-Complete cleared / X.500 added | No reply NDRs on migrated threads |
| 6.3 | Rollback baseline retained | `EXOMIGG-baseline\` | Retained per policy |

---

## Notes on GCC High testing

- **Validate with PowerShell, not Graph Explorer** — Graph Explorer is **not supported** in GCC High. (Microsoft Learn, *national cloud deployments*.)
- **OWA URL is `outlook.office365.us`**, not `outlook.office.com`.
- If any test tool "can't find the tenant," it is almost always pointed at the **Commercial** endpoint — recheck `-Environment USGov` / `-ExchangeEnvironmentName O365USGovGCCHigh`.
