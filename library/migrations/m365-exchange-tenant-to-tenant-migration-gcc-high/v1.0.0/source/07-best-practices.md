# Best Practices — Exchange Online Tenant-to-Tenant Migration (Government / GCC High)

Field-tested guidance for running a 1:1-domain Exchange Online migration **within GCC High**. These complement the ordered steps in `03-implementation.md`; they do not replace them.

---

## 1. Decide the migration engine before anything else

- **Confirm the cloud boundary first.** If either tenant is Commercial, native cross-tenant migration is **off the table** — commit to a third-party tool or PST immediately and stop planning around native. (Microsoft Learn: cross-cloud not supported.)
- For **GCC High → GCC High**, treat native cross-tenant migration as **Public Preview** and **confirm eligibility in writing** with Microsoft / your account team before you design around it. Keep a third-party tool as a fallback so the project is not blocked by preview availability. (verify for GCC High.)

## 2. Always pin the sovereign cloud in every tool and script

- Bake `-ExchangeEnvironmentName O365USGovGCCHigh` and `-Environment USGov` into every connection — never rely on defaults. The most common GCC High failure is a script silently authenticating against Commercial.
- Use the **`*.us` portals** exclusively (`portal.office365.us`, `admin.exchange.office365.us`, `entra.microsoft.us`, `security.microsoft.us`, `compliance.microsoft.us`, `portal.azure.us`). Bookmark them to avoid muscle-memory Commercial URLs.
- Register **every** migration/vendor app against **`login.microsoftonline.us`** and the vendor's **US Gov** service instance.

## 3. Respect the licensing sequence (native)

- Purchase US Gov licenses and the **Cross-Tenant User Data Migration** add-on through an **authorized US Gov reseller / AOS-G partner** — and **verify the add-on is orderable on your agreement before relying on native**. (verify for GCC High.)
- **Never license the target MailUser before its `ExchangeGUID` is stamped** — that provisions a new empty mailbox and breaks the move. Assign licenses during the 30-day grace period after the move, or only once the ExchangeGUID and proxies are correct. (Microsoft Learn.)
- Expect **proxy-address scrubbing**: unverified SMTP domains are removed when an Exchange plan is applied. Plan address/branding accordingly.

## 4. Gate every phase — never skip the pilot

- Treat the **Pilot exit** as the hard gate: no expansion until every pilot mailbox passes content, permissions, and mail-flow checks.
- Migrate in **named waves** (`EXOMIGG-Wave1..N`), validating between each. Size waves to your **validated** throughput, not an optimistic estimate.
- Keep the phase gates from `05-testing.md` as documented, signed-off checkpoints in the change record.

## 5. Protect data and stay compliant (GCC High context)

- GCC High hosts **CUI/ITAR/DFARS-scoped** data. Keep migration hosts, PST files, mapping CSVs, and reports **inside** the authorized boundary; do not export CUI to Commercial workstations or storage.
- Prefer **certificate-based / app-only** auth for unattended scripts over stored passwords; use **PIM-eligible** (time-bound) admin roles.
- Never place tenant secrets, tokens, or full mailbox exports in shared or public locations. Redact identifiers in any report shared outside the boundary.

## 6. DNS and cutover discipline

- **Lower MX TTL early** (e.g., 5 minutes) so cutover is fast and reversible.
- **Pre-add** the domain to the target and create the TXT record days ahead — verification failing while the domain is still in the source is **expected**, not an error.
- Have the **rollback** (re-point MX/Autodiscover to source, re-add domain to source) written and rehearsed before cutover day.

## 7. Communications and endpoints

- Notify users the **OWA URL is `outlook.office365.us`** and that Outlook profiles may need rebuilding; clear Auto-Complete to avoid NDRs.
- Allow-list the **GCC High endpoint list** (`.us`) on proxies/firewalls, and re-check monthly — GCC High publishes changes 30 days ahead on its **own** endpoint article, separate from Commercial.

## 8. Don't assume Commercial features exist

- Assume newer Commercial conveniences (e.g., **Cross-Tenant Identity Mapping**, **Graph Explorer**) are **absent** in GCC High until Microsoft documents them for US Gov. Validate Graph with PowerShell, not the web explorer. (verify for GCC High.)
- When a Commercial runbook references a portal or feature, **map it through `gcc-high-parity-notes.md`** before following it.

## 9. Keep the three surfaces coherent

- The wiki page, the repo source, and the store deliverable (PDF/scripts) should always agree. When a live GCC High correction is made, sync it back into `source/` and republish so the runbook stays accurate.
