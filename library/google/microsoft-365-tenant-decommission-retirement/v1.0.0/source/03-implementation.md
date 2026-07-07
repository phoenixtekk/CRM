# Implementation

Execute the decommission in the six phases below, following **Assess → (Design →) Configure → Pilot
→ Validate → Expand**. Every phase has a **pass/fail gate** and, where it changes production, a
**rollback window**. Run each phase against the **pilot scope** (R8) first, validate, then expand to
the whole tenant. **Do not start Phase 2 until Phase 1 passes and R1 (migration sign-off) exists.**

Artifacts are named `<Purpose> – <Scope> – <Stage>` and reused verbatim in later phases, testing,
and the scripts. Establish these up front:

| Artifact | Name |
|---|---|
| Graph read app (tooling) | `Decommission Read – Source-Tenant – v1` |
| Evidence/closure store (R5) | `Decommission Evidence – Source-Tenant – v1` |
| Pilot scope (R8) | `Decommission Pilot – <domain/OU> – v1` |
| Change record for DNS/closure | `Decommission Change – Prod – v1` |

Set the operator environment once (R3), used by every tool:

```bash
export M365DECOM_TENANT_ID="<Directory (tenant) ID>"
export M365DECOM_CLIENT_ID="<Application (client) ID>"
export M365DECOM_CLIENT_SECRET="<from secret store — never committed>"
python -m pip install msal requests            # standard-library-first otherwise
```

---

## Phase 0 — Assess & Design (read-only)

1. Confirm **R1 migration sign-off** and that Google MX is authoritative for every domain
   (`dig MX <domain>`). If any domain still routes to Microsoft, that domain is **not** ready — remove
   it from this run.
2. Stand up **`Decommission Read – Source-Tenant – v1`** (R2) and confirm read-only consent.
3. Nominate **`Decommission Evidence – Source-Tenant – v1`** (R5) and the
   **`Decommission Pilot – <domain/OU> – v1`** scope (R8).
4. Obtain the **retention schedule + legal-hold register** (R4) and the named disposition approver.

**Gate 0 (design):** sign-off exists, tooling reads the tenant, evidence store and pilot scope named,
legal inputs in hand. *Fail →* resolve the missing input before proceeding.

---

## Phase 1 — Completeness verification (read-only)

*Goal: prove the migration actually landed before anything is torn down.*

1. Run the completeness verifier against the pilot scope:
   ```bash
   python scripts/verify_migration_completeness.py \
       --scope-file pilot-users.txt \
       --out evidence/phase1-completeness-pilot.json
   ```
   It reads, per user, mailbox item counts and last-activity, OneDrive usage, and group/shared-mailbox
   coverage via Graph **usage reports** and directory reads, and compares against an expected baseline
   you supply (the migration project's source counts).
2. Review the report. Investigate any user with **large residual mailbox/OneDrive size** or
   **recent Microsoft-side activity** (a signal they are still using M365, not Google).
3. **Expand:** re-run with the full user list (`--scope-file all-users.txt`).

**Gate 1 (completeness):** every in-scope user reconciles to the expected baseline within the agreed
tolerance, and no user shows recent Microsoft-side activity. *Fail →* return the exceptions to the
migration project; **do not proceed to teardown**. **Rollback:** none needed (read-only).

---

## Phase 2 — Data disposition vs retention / legal hold

*Goal: preserve what must be kept; dispose of the rest — on legal/records' authority.*

1. Produce the disposition inventory (read-only) — mailboxes, OneDrive, and sites that still hold
   data, joined to the R4 hold register:
   ```bash
   python scripts/inventory_app_and_orphans.py --mode data --out evidence/phase2-data-inventory.json
   ```
   *(The inventory tool covers identity/app objects **and** data-bearing objects; `--mode data`
   scopes it to disposition inputs.)*
2. Hand the inventory to **legal/records**. They mark each item **HOLD / RETAIN-UNTIL-<date> /
   DISPOSE** against the retention schedule. **This solution does not make that call.**
3. For **HOLD / RETAIN** items: export to **`Decommission Evidence – Source-Tenant – v1`** (R5) using
   the org's approved export path — Microsoft Purview eDiscovery export for held content, or the
   records team's tooling. *(Exact Purview export navigation is version-dependent — verify in your
   tenant.)* Record each export (item, size, hash, destination) in the evidence pack.
4. For **DISPOSE** items: only after the disposition approver signs the inventory, allow the tenant's
   normal deletion to proceed (or apply the retention-driven deletion the records team directs).

**Gate 2 (disposition):** every data item is classified; all HOLD/RETAIN items are exported and
evidenced; DISPOSE items are approved in writing. *Fail →* stop; unresolved-classification data is
never deleted. **Rollback:** exports are additive and safe; do not action any DISPOSE until sign-off,
so there is nothing to roll back before that point.

---

## Phase 3 — Licensing / subscription wind-down (dry-run → apply)

*Goal: stop duplicate spend, safely, without cutting off anything still needed for hold/export.*

1. Model the wind-down (dry-run, the default):
   ```bash
   python scripts/license_winddown_helper.py --out evidence/phase3-license-plan.json
   ```
   It reports assigned SKUs per user, seats reclaimable now (users fully migrated and not on hold),
   seats to **retain** (accounts still needed for export/hold from Phase 2), and the projected monthly
   saving. **Nothing is changed in dry-run.**
2. Review the plan with the billing owner. Confirm no reclaimable account is on the R4 hold register.
3. Apply reclamation for the pilot scope:
   ```bash
   python scripts/license_winddown_helper.py --apply --scope-file pilot-users.txt
   ```
   The tool removes license assignments (does **not** cancel subscriptions) for the named users.
4. **Expand** to the full set once the pilot reclaim is validated. Cancel or let lapse the underlying
   **subscriptions** only after Phase 2 export is complete and no account still needs a seat —
   subscription cancellation is done in the admin center under change control, not by the tool.

**Gate 3 (licensing):** reclaimable seats reclaimed, retained seats documented with reason, no held
account de-licensed, projected saving recorded. *Fail →* re-run dry-run and correct the scope.
**Rollback:** re-assign a license within the change window (assignment is reversible while the
subscription is still active) if an account is found to still be needed.

---

## Phase 4 — Entra app-registration + identity cleanup (dry-run → apply)

*Goal: remove the standing app trust and orphaned identities the migration left behind.*

1. Inventory app registrations, enterprise apps (service principals), credentials, and orphaned/stale
   objects (read-only):
   ```bash
   python scripts/inventory_app_and_orphans.py --mode identity \
       --out evidence/phase4-identity-inventory.json
   ```
   It flags: app registrations with **expired or long-lived secrets/certs**, **service principals**
   with no recent sign-in, **guest** accounts, disabled/never-signed-in accounts, and apps whose
   reply URLs/SSO clearly target the retired estate.
2. Classify each object with the app/identity owners: **KEEP (migrated to Google) / DISABLE / REMOVE**.
   Anything ambiguous is **disabled first**, not deleted, so it can be restored within the window.
3. Apply, pilot scope first, on a documented schedule:
   ```bash
   python scripts/inventory_app_and_orphans.py --mode identity --apply \
       --action disable --scope-file pilot-apps.txt
   ```
   Disable in the pilot, observe for the rollback window, then remove. **Expand** to the full tenant.
4. The tooling's own app, **`Decommission Read – Source-Tenant – v1`**, is the **last object removed**
   — only after it has produced the Phase 6 closure evidence.

**Gate 4 (identity):** every app/identity object is classified and actioned; nothing ambiguous is
deleted (only disabled); the schedule and approvals are evidenced. *Fail →* revert to disabled and
re-classify. **Rollback:** re-enable a disabled object within the window (deletion is deferred until
the disable soak passes).

---

## Phase 5 — DNS / integration re-point-or-remove (dry-run → apply, under change control)

*Goal: re-point survivors to Google, remove dead Microsoft records — without breaking mail.*

1. Map the dependencies (read-only):
   ```bash
   python scripts/map_dns_integration.py --domains-file domains.txt \
       --out evidence/phase5-dns-map.json
   ```
   For each domain it resolves MX, SPF (TXT), DKIM (selector CNAMEs), DMARC, autodiscover, `enterprise
   registration`/`enterpriseenrollment` CNAMEs, Lync/Teams SRV, and the `MS=`/`msoid` verification
   records, and classifies each as **RE-POINT-TO-GOOGLE / REMOVE / KEEP**. It also lists Entra
   **verified domains** and app **reply URLs** as integration signals.
2. Confirm the target Google records for anything re-pointed (Google MX
   `smtp.google.com` / `aspmx.l.google.com`; Google DKIM selector `google._domainkey`; SPF
   `include:_spf.google.com`) in the **Google Admin console → Apps → Google Workspace → Gmail →
   Authenticate email / Setup**.
3. Under change record **`Decommission Change – Prod – v1`**, apply to the **pilot domain first**:
   remove Microsoft-only records (autodiscover, `enterpriseregistration`, Teams SRV, `MS=` verification
   once the domain is removed from the tenant), correct SPF to drop `include:spf.protection.outlook.com`,
   and confirm DMARC still passes. Watch mail flow through the rollback window.
4. **Expand** to remaining domains one zone at a time. The tool itself only *plans*; DNS edits are made
   in the authoritative zone (or via its API) under change control — never blind.

**Gate 5 (DNS/integration):** for each domain, survivors point at Google, dead Microsoft records are
gone, SPF/DKIM/DMARC still pass (`dig`/MXToolbox verification), and no integration is left pointing at
the retired tenant. *Fail →* roll back the zone change. **Rollback:** restore the prior zone snapshot
(take one before every change) within the change window.

---

## Phase 6 — Formal tenant closure (irreversible past the deletion window)

*Goal: close the tenant and capture the evidence pack.*

1. **Pre-closure guardrail check** (read-only) — confirm nothing blocks a clean closure:
   ```bash
   python scripts/decommission_report.py --precheck \
       --evidence-dir evidence/ --out evidence/phase6-precheck.json
   ```
   It verifies all prior gates are evidenced, no domain is still verified-and-routing, no license is
   still assigned to a non-retained account, no app registration remains except the tooling app, and
   no unresolved HOLD item exists.
2. Remove each **verified domain** from the tenant (**Entra admin center → Settings → Domain names →**
   remove), which requires the domain's records to be cleared first (Phase 5). *(Domain-removal
   prerequisites are version-dependent — verify in your tenant.)*
3. **Cancel the subscriptions** (Microsoft 365 admin center → **Billing → Your products →** cancel),
   which starts Microsoft's **data-retention grace period** before deletion. Record the dates.
4. Generate the **closure evidence pack**:
   ```bash
   python scripts/decommission_report.py --evidence-dir evidence/ \
       --out evidence/M365DECOM-closure-report.html
   ```
5. Remove the tooling app **`Decommission Read – Source-Tenant – v1`** as the final object.
6. Allow the tenant to progress to deletion per Microsoft's process. *(Whether/where a "delete tenant"
   action is exposed vs. lapse-after-cancellation is version-dependent — verify current tenant-deletion
   requirements in your tenant; some tenants require all subscriptions removed and licenses/users
   cleared first.)*

**Gate 6 (closure):** precheck all-green, subscriptions cancelled, closure report generated and stored
in **`Decommission Evidence – Source-Tenant – v1`**, tooling app removed. *Fail →* precheck names the
blocker; resolve it before cancelling. **Rollback:** reversible only within Microsoft's grace period —
re-activate a cancelled subscription before the deletion date if a blocker is found; past the deletion
window closure is final.
