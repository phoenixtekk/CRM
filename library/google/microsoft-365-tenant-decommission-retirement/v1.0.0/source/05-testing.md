# Testing & Validation

Each phase gate is validated with the procedure below. Run every test against the **pilot scope**
first, then re-run at tenant scope during **Expand**. Record each result in
**`Decommission Evidence – Source-Tenant – v1`**. A phase is not "done" until its test **passes**.

> All read-only tests can be run repeatedly and safely. Tests that confirm a *write* (license removed,
> app disabled, DNS changed) are run **after** the change, within the rollback window.

---

## T1 — Migration completeness (Gate 1)

- **Procedure:** Run `verify_migration_completeness.py` at full scope; open the JSON report.
- **Expected PASS:** Every in-scope user reconciles to the expected baseline within tolerance;
  residual mailbox/OneDrive sizes are at/under the agreed threshold; **no** user shows Microsoft-side
  activity after the cutover date.
- **FAIL signal:** Any user with an unexplained large residual or recent Microsoft-side sign-in/mail
  activity → that user is not fully migrated. Return to the migration project; do not proceed.

## T2 — Data disposition classification (Gate 2)

- **Procedure:** Open `phase2-data-inventory.json`; confirm every item carries a legal/records
  classification (HOLD / RETAIN-UNTIL-<date> / DISPOSE) and that HOLD/RETAIN items have a recorded
  export (destination + hash) in the evidence pack.
- **Expected PASS:** 100% of items classified; every HOLD/RETAIN item exported and evidenced; every
  DISPOSE item carries the approver's sign-off.
- **FAIL signal:** Any unclassified item, or a HOLD item with no export record → stop; do not dispose.

## T3 — License wind-down (Gate 3)

- **Procedure:** Run `license_winddown_helper.py` (dry-run) after applying reclamation; the "seats
  still assigned" figure should equal only the **retained** (documented) accounts.
- **Expected PASS:** Reclaimable seats show as reclaimed; retained seats match the documented list with
  reasons; **no** account on the R4 hold register is de-licensed; projected saving recorded.
- **FAIL signal:** A held/needed account shows de-licensed, or reclaimable seats remain assigned →
  re-assign (rollback) or re-run apply, and correct the scope.

## T4 — App & identity cleanup (Gate 4)

- **Procedure:** Run `inventory_app_and_orphans.py --mode identity` (read-only) after the disable/remove
  actions.
- **Expected PASS:** No unexpected app registration remains except `Decommission Read – Source-Tenant
  – v1`; no service principal with the retired estate's reply URLs remains enabled; flagged
  guest/stale accounts are disabled or removed per the schedule; nothing ambiguous was deleted (only
  disabled).
- **FAIL signal:** A standing secret/cert on a still-enabled app, or an orphaned SP still enabled →
  disable and re-classify.

## T5 — DNS / integration (Gate 5)

- **Procedure:** For each domain, verify DNS externally, independent of the tooling:
  ```bash
  dig MX <domain> +short          # expect Google (aspmx.l.google.com / smtp.google.com)
  dig TXT <domain> +short         # SPF should include _spf.google.com, NOT spf.protection.outlook.com
  dig TXT _dmarc.<domain> +short  # DMARC record present and policy intact
  dig CNAME google._domainkey.<domain> +short   # Google DKIM selector resolves
  dig CNAME autodiscover.<domain> +short        # Microsoft autodiscover REMOVED (NXDOMAIN)
  ```
  Send a test message to a user on the domain and confirm delivery to Google.
- **Expected PASS:** MX → Google; SPF/DKIM/DMARC pass and reference Google, not Microsoft; Microsoft-only
  records (autodiscover, `enterpriseregistration`, Teams SRV, stale `MS=` verification) return NXDOMAIN;
  test mail delivers to Google; no integration still resolves to the retired tenant.
- **FAIL signal:** Mail bounces/misroutes, SPF/DMARC fails, or a Microsoft record still resolves →
  restore the pre-change zone snapshot (rollback) and re-plan.

## T6 — Pre-closure guardrail (Gate 6)

- **Procedure:** Run `decommission_report.py --precheck` before cancelling any subscription.
- **Expected PASS (all-green):** all prior gates evidenced; no domain still verified-and-routing; no
  license assigned to a non-retained account; no app registration except the tooling app; zero
  unresolved HOLD items.
- **FAIL signal:** Any red check → resolve the named blocker before cancelling.

## T7 — Closure evidence pack (Gate 6)

- **Procedure:** Generate `M365DECOM-closure-report.html`; confirm it is stored in the evidence store
  and contains every phase's gate result, the disposition sign-offs, the license saving, the identity
  actions, the DNS end-state, and the subscription-cancellation dates.
- **Expected PASS:** Report generated, complete, and archived; subscriptions show cancelled with the
  deletion date recorded; tooling app removed as the final step.
- **FAIL signal:** Missing evidence, or a subscription still active → do not declare closure complete.

## End-to-end pilot acceptance

Before expanding tenant-wide, the pilot scope must pass **T1–T5** end to end (completeness → disposition
→ license → identity → DNS) with evidence, and a rollback must have been demonstrated at least once
(e.g. re-enable a disabled app, restore a zone snapshot) to prove the safety net works.
