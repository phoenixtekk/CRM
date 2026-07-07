# Troubleshooting

Common failure modes across the six phases, with resolutions. Symptoms are grouped by where they
appear. All tooling is read-only or dry-run by default, so most issues here are diagnostic, not
data-loss — the exceptions (DNS, closure) are called out.

---

## Authentication & tooling

**`ERROR: Set M365DECOM_TENANT_ID / … in the environment`**
The tools read credentials only from the environment (R3). Export `M365DECOM_TENANT_ID`,
`M365DECOM_CLIENT_ID`, and `M365DECOM_CLIENT_SECRET` from your secret store in the same shell, then
re-run. Never paste them into a file.

**`Token request failed: … invalid_client` / `AADSTS7000215`**
The client secret is wrong or expired. Regenerate the secret/cert for
`Decommission Read – Source-Tenant – v1` in **Entra → App registrations → Certificates & secrets**,
update the environment variable, and re-run. If you rotated to a certificate, confirm the tool's
`msal` app is configured for it.

**`Graph GET … -> 403` (Authorization_RequestDenied)**
The app is missing a scope or admin consent. In **App registrations → API permissions**, confirm the
read scopes from R2 are present **and** show "Granted for <tenant>". Application permissions require
admin consent — re-consent if the tick is missing.

**`msal not installed` / `--graph needs: pip install msal requests`**
Install the client libraries: `python -m pip install msal requests` (and `dnspython` for cleaner DNS
resolution in `map_dns_integration.py`).

**Runs are very slow / `429` retries in stderr.**
Graph is throttling a large tenant. The tools back off automatically on 429/5xx. For 100k+ users,
scope the run (`--scope-file`) and run in batches rather than the whole tenant at once; the reports
are additive.

---

## Phase 1 — completeness

**A user shows `FAIL` for a post-cutover Microsoft-side sign-in.**
That user is still using Microsoft 365 — completeness genuinely fails. Do not proceed to teardown for
that scope. Return the user to the migration project; re-run after they are confirmed on Google.

**Large OneDrive residual flagged but the user is definitely migrated.**
Common causes: version history, recycle-bin contents, or a shared-library sync not part of the
personal migration scope. Confirm with the migration project whether the residual is in-scope; if it
is expected and dispositioned, record it in the evidence and lower isn't required — adjust
`--residual-mb` only with sign-off, never to mask a real gap.

**`ABSENT — user not found in directory`.**
The account was already removed upstream. This is noted, not failed. Confirm it was intentional and
that any data it held was dispositioned in Phase 2 before it disappeared.

---

## Phase 2 — data disposition

**Inventory items remain `UNCLASSIFIED`.**
Legal/records has not yet marked them HOLD / RETAIN / DISPOSE. **Do not dispose of anything
unclassified** — the pre-closure guardrail (`decommission_report.py --precheck`) will FAIL while any
UNCLASSIFIED item remains. Escalate to the disposition approver.

**Held content cannot be exported.**
Purview eDiscovery export navigation and prerequisites are version-dependent — verify in your tenant.
If export stalls, confirm the operator has the eDiscovery role and that the hold is correctly scoped;
engage the records team's tooling if Purview export is unavailable in your edition.

---

## Phase 3 — licensing

**A held/needed account appears in `reclaimable`.**
It is missing from the hold/retain lists. Add its UPN to `--hold-file` (legal hold) or
`--retain-file` (still needed) and re-run the dry-run. Never `--apply` until the reclaimable list is
clean.

**`assignLicense -> 403` on `--apply`.**
Reclamation needs a write role (e.g. License Administrator + `Directory.ReadWrite.All`), which is
deliberately separate from the read tooling (R6). Assign the role just-in-time for the change window.

**Projected saving is 0.**
No `--price-file` was supplied, so per-SKU prices are unknown. Provide a CSV of `skuId,monthly_price`
(from your billing) to get a saving estimate; reclamation itself works without it.

**A license was reclaimed from an account that was still needed.**
License assignment is reversible while the subscription is active — re-assign it in the admin center
(or re-run with that user in scope of an add) within the change window. This is why subscriptions are
cancelled only after Phase 2 export completes.

---

## Phase 4 — identity & apps

**An app registration you removed broke something.**
App-registration deletion is deliberately *not* automated by the tool — it is a manual, evidenced
admin step precisely so it is deliberate. For service principals/accounts, always `--action disable`
first and soak through the rollback window; re-enable a disabled object rather than restoring a
deleted one.

**A service principal keeps reappearing.**
It is backed by an app registration or a first-party Microsoft service and is being recreated.
Disable the underlying app registration (evidenced), or confirm it is a required first-party SP that
should be KEPT.

**`--apply` did nothing.**
`--apply` acts only on ids/appIds present in `--scope-file`. Confirm the file lists the exact `id`
(or `appId`) values from the inventory JSON, one per line.

---

## Phase 5 — DNS & mail flow

**Mail bounces or misroutes after a DNS change.**
Highest-impact failure. **Restore the pre-change zone snapshot immediately** (you took one before the
change — Best Practices). Then re-plan: confirm MX points to Google (`aspmx.l.google.com`), SPF drops
`spf.protection.outlook.com` and includes `_spf.google.com`, and DMARC still passes.

**`map_dns_integration.py` returns empty records for a domain.**
Either the records genuinely don't exist, or the fallback resolver (`nslookup`) parsed poorly. Install
`dnspython` (`pip install dnspython`) for reliable results, and cross-check with `dig` (Testing T5).

**A Microsoft verification `MS=` / `msoid` record still resolves.**
Remove it only after the domain is removed from the tenant in Phase 6 (removing it too early can block
domain removal). Sequence: clear routing records → remove domain from tenant → clear verification
record.

---

## Phase 6 — closure

**`decommission_report.py --precheck` returns `FAIL`.**
It names the blocker. Typical causes: a gate has no evidence file (re-run that phase's tool to the
evidence dir), completeness is not PASS, a domain is still verified/routing (finish Phase 5), a
license is still assigned to a non-retained account (finish Phase 3), an app registration other than
`Decommission Read – Source-Tenant – v1` remains (finish Phase 4), or an UNCLASSIFIED disposition item
remains (Phase 2). Resolve, then re-run precheck until PASS before cancelling any subscription.

**Domain won't remove from the tenant.**
Microsoft blocks removal while objects still reference the domain (users, groups, apps) or DNS
verification records remain. Clear referencing objects and records first. Exact prerequisites are
version-dependent — verify in your tenant.

**"Where is the delete-tenant action?"**
Whether a tenant is deleted explicitly or lapses after all subscriptions are cancelled and
users/licenses cleared is version-dependent — verify current tenant-deletion requirements in your
tenant. Do not force anything; follow Microsoft's current documented path, and remember closure is
irreversible past the deletion window.
