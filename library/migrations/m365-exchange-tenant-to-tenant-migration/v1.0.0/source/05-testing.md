# 5. Testing — Microsoft 365 Exchange Online Tenant-to-Tenant Migration (1:1 Domains)

Each test below is a **phase exit gate**. Run the test, record the result, and only advance when the gate is **PASS**. Tests reference the named objects from `03-implementation.md` verbatim. The final **Acceptance Gate** (T7) must pass before the project is declared complete.

---

## T1 — Assessment completeness gate (exit Assess)

**Purpose.** Confirm the source is fully inventoried and mapped.

**Steps.**
1. Run `scripts\EXOMIG-Discovery.ps1` against the source tenant.
2. Confirm `mapping.csv` (R11) has a target row for every source mailbox, shared mailbox, room/equipment mailbox, and group.
3. Confirm `permissions.csv` (R12) lists FullAccess/SendAs/SendOnBehalf.

**PASS:** every source object has a mapping row; permission inventory exists.
**FAIL:** any source object lacks a mapped target, or permission export is incomplete → return to Assess.

---

## T2 — Plan approval gate (exit Plan)

**Steps.**
1. Confirm waves are assigned (`Wave` column populated; `EXO T2T – Pilot Wave` defined).
2. Confirm routing domain chosen (R9) and coexistence model decided.
3. Confirm cutover window, lowered-TTL plan, and written rollback plan exist (G5/G6).

**PASS:** approved plan with waves, routing decision, cutover window, rollback plan.
**FAIL:** any missing → return to Plan.

---

## T3 — Preparation readiness gate (exit Prepare)

**Steps.**
1. `EXOMIG-Validation.ps1` pre-flight: target users have Exchange Online plans (R1).
2. Confirm routing/coexistence domain is an accepted domain in the target.
3. Confirm `svc-quest-migration` exists in both tenants and is excluded from blocking Conditional Access policies (R8).
4. In Quest On Demand, confirm both tenants show **Connected** and `EXO T2T – Contoso – Migration Project` + `EXO T2T – Pilot Wave` exist (R4).
5. Confirm `Coexistence – Source→Target Connector` and `Coexistence – Target→Source Connector` exist.

**PASS:** all five confirmed.
**FAIL:** any missing → return to Prepare.

---

## T4 — Pilot validation gate (exit Pilot)

**Steps.**
1. After migrating + delta of `EXO T2T – Pilot Wave`, run `EXOMIG-Validation.ps1` post-migration for sample pilot users: **item-count parity** for mail, calendar, contacts (source vs target).
2. A pilot user opens https://outlook.office.com on the target and confirms migrated mail/calendar/contacts are present and correct.
3. Send a test message **source → pilot user** and **pilot user → source**; confirm both deliver (coexistence mail flow).
4. If free/busy coexistence is enabled, a source user looks up a pilot user's free/busy and vice versa.

**PASS:** parity within expected tolerance (no missing folders/items), mail flows both ways, free/busy works (if enabled), **no data loss**.
**FAIL:** content gaps, one-way or no mail flow, broken free/busy → diagnose (see `06-troubleshooting.md`), remediate, re-test before any bulk migration.

---

## T5 — Bulk migration readiness gate (exit Migrate)

**Steps.**
1. `EXOMIG-Report.ps1` shows every wave pre-staged and delta passes current (deltas small and fast).
2. Confirm permissions re-applied via `EXOMIG-Remediation.ps1` (spot-check FullAccess/SendAs in the target).
3. Report shows near-100% completed with **zero unresolved failed mailboxes**.

**PASS:** all waves staged, deltas current, permissions applied, no unresolved failures.
**FAIL:** stuck/failed mailboxes or stale deltas → remediate before scheduling cutover.

---

## T6 — Cutover verification gate (exit Cutover)

**Steps.**
1. Confirm a **final delta** ran immediately before cutover.
2. Confirm `contoso.com` is **removed** from the source (Settings → Domains no longer lists it) and **verified** in the target (Settings → Domains shows Healthy).
3. Confirm primary SMTP stamped: spot-check migrated mailboxes show `@contoso.com` as **primary** (`EXOMIG-Validation.ps1`).
4. Confirm DNS: `nslookup -type=mx contoso.com` resolves to the target endpoint; Autodiscover CNAME → `autodiscover.outlook.com`; SPF includes `spf.protection.outlook.com`; target DKIM published.
5. Send an external test message to `user@contoso.com`; confirm it lands in the **target** mailbox.

**PASS:** domain moved + verified, primary addresses stamped, MX/Autodiscover/SPF/DKIM correct, external mail delivers to target.
**FAIL:** domain won't remove/verify, wrong MX, or mail not delivering → `06-troubleshooting.md`.

---

## T7 — Acceptance Gate (exit Validate — project sign-off)

All of the following must be **PASS** to declare the migration complete:

| # | Acceptance criterion | PASS condition |
|---|----------------------|----------------|
| 1 | Mail flow both ways | External in to `@contoso.com` lands in target; outbound from target sends as `@contoso.com`. |
| 2 | Pilot/sample content parity | Item-count parity (mail/calendar/contacts) within tolerance for sampled users; no missing folders. |
| 3 | Free/busy | Cross-mailbox free/busy works within the target tenant. |
| 4 | Domain verified in target | `contoso.com` shows Healthy in target Settings → Domains; absent from source. |
| 5 | MX / Autodiscover correct | MX → target endpoint; Autodiscover → `autodiscover.outlook.com`; clients reconnect. |
| 6 | Delta caught up | Final delta complete; no pending changes; report shows complete. |
| 7 | No data loss | Validation parity + user spot-checks confirm no lost mail/calendar/contacts. |
| 8 | Outbound authentication | Outbound from target passes SPF/DKIM/DMARC at external recipients. |

**PASS:** all eight criteria met → proceed to Decommission.
**FAIL:** any criterion unmet → do not decommission; remediate first.

---

## T8 — Decommission completeness gate (exit Decommission)

**Steps.**
1. Source mailboxes converted/removed per plan; source licenses reclaimed.
2. Coexistence connectors removed; routing-domain artifacts cleaned.
3. `svc-quest-migration` removed from CA exclude lists in both tenants (R8 reversed).
4. Migration service accounts disabled/removed.
5. Discovery/validation/report CSVs archived.

**PASS:** all five confirmed.
**FAIL:** any temporary exclusion or service account still active → complete cleanup.
