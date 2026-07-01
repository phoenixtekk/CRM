# 1. Solution Overview — Software Renewals, Contracts & OEM Bundle Tracking

This is the only section that explains the *why*. Every later section is "do this" steps.

## The problem this solves
Software renewals fail in four predictable ways. They arrive with no warning, so there is no time to
negotiate or budget. They auto-renew at the wrong quantity or on worse terms because nobody reviewed
them. They lapse and break a production dependency because the date slipped past unseen. And the facts
needed to decide — contract terms, true-up clauses, OEM bundle entitlements, the renewal date itself
— sit in inboxes and PDFs no one can find. The fix is not heroics near each deadline; it is a
repeatable process that makes every renewal a planned decision, far enough ahead to act on.

## The renewal lifecycle
A renewal is not an event, it is a lifecycle with stages. The repeatable way tracks each contract
through:

1. Inventory — the contract, its products, quantity, cost, term, and renewal date are captured in
   the repository.
2. Watch — the renewal date is on the calendar and lead-time alerts are armed.
3. Alert — at each lead-time threshold the named owner is notified that a decision is approaching.
4. Decide — the owner and procurement liaison run the decision workflow: keep, change (quantity or
   terms), consolidate, or drop.
5. Act — procurement executes the decision (renew, renegotiate, or let lapse intentionally).
6. Close — the repository is updated with the new term, cost, and next renewal date, and the cycle
   restarts.

## The contract and entitlement repository
The single source of truth is the `Contract & Entitlement Repository – All Products – Master`. It is
one controlled record per contract holding the fields the lifecycle needs: vendor/publisher, product,
quantity, unit and total cost, contract start and end, renewal/notice dates, auto-renew flag, notice
period, true-up terms, the named renewal owner, the procurement liaison, and a link to the contract
document. A controlled spreadsheet or a SAM/CMDB table both work; the schema, not the tool, is what
matters. The repository feeds everything else — the calendar, the alerts, and the cost report all
read from it.

## OEM bundle mapping
OEM and suite bundles hide entitlements: a single purchase (a device OEM bundle, a publisher suite, a
volume agreement) often grants several products with one shared renewal or one shared expiry. If they
are tracked as separate line items, you double-count cost, miss that dropping one product strands the
others, or renew a component that the bundle already covers. The `OEM Bundle Map – Vendor Bundles –
Master` records each bundle, the parent SKU, the child entitlements it contains, and the single
renewal anchor — so the calendar shows one decision, not five disconnected ones.

## Lead-time alerting
A renewal date with no warning is useless. The `Lead-Time Alert Rules – Renewals – Tiered` fire at
tiered thresholds before each renewal — T-120, T-90, T-60, and T-30 days — so high-value or
contractual-notice renewals surface early enough to negotiate, and routine ones still get a final
reminder. Each alert names the renewal owner and the procurement liaison and points at the contract
record, so the recipient can act without hunting for context.

## The procurement coordination workflow
Alerts without a decision path just create noise. The `Renewal Decision Workflow – Per Contract –
Standard` defines what happens when an alert fires: the renewal owner reviews usage and need against
the repository, classifies the renewal (keep as-is / change quantity or terms / consolidate into a
bundle / drop), and hands a clear recommendation to the procurement liaison, who executes and records
the outcome. Every renewal closes with a documented decision and a refreshed next renewal date.

## What this delivers (the named artifacts)
- `Contract & Entitlement Repository – All Products – Master` — the single source of truth.
- `Renewal Calendar – All Products – Live` — a date-ordered view of every upcoming renewal.
- `OEM Bundle Map – Vendor Bundles – Master` — parent SKUs to child entitlements with one anchor.
- `Lead-Time Alert Rules – Renewals – Tiered` — T-120 / T-90 / T-60 / T-30 notifications.
- `Renewal Decision Workflow – Per Contract – Standard` — the keep / change / consolidate / drop path.
- `Renewal Owners – Pilot Scope – Group` and `Renewal Owners – All Products – Group` — who owns each
  renewal, used for alert routing.

## Scope and honest limits
- This solution governs the renewal *process* and its records. It reads subscription/renewal data
  from Microsoft Graph where the product exposes it, and otherwise relies on a CSV repository you
  maintain — it cannot invent a renewal date a vendor never gave you.
- It does not negotiate contracts or move money; it makes sure the right person decides in time.
- Microsoft Graph surfaces Microsoft 365 subscription/SKU data, not every third-party publisher's
  contract terms — those are captured in the repository by hand or by vendor export.

## The standard deployment model
> Inventory contracts → build the repository and calendar → map OEM bundles → arm lead-time alerts →
> define the decision workflow → validate on a pilot product family → expand to the full portfolio.
> Deployment model: Assess → Configure → Pilot → Validate → Expand.
