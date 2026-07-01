# Phoenixtekk Workplace Marketplace — Pricing Rules (source of truth)

These rules are applied by `/generate-solution` (Stage 1) and validated by
`/publish-solution` (Stage 2). Do not hardcode prices in the loader — they come from
each solution's `bagisto-products.json`, generated against these rules.

## Per-solution products (repeat for every solution) — THREE tiers

| Product       | SKU pattern           | Price rule                                                    |
|---------------|-----------------------|--------------------------------------------------------------|
| Commercial    | `PTK-<SOL>-COMM-001`  | The commercial **anchor** price — set from the effort scale below. |
| Non-Profit    | `PTK-<SOL>-NPO-001`   | **40% below commercial** → `round(commercial * 0.60, 2)`.    |
| Government    | `PTK-<SOL>-GOV-001`   | **15% below commercial** → `round(commercial * 0.85, 2)`.    |

`<SOL>` = short uppercase solution code (e.g. `WHFB`). Every new solution emits **all three**
products. (Discounted tiers are gated to verified customers — see eligibility validation in
`ADMIN_DOCS.md`; the price rule here is independent of that gating.)

> **Validation:** `/publish-solution` recomputes both discounts and refuses to load if the
> Non-Profit price ≠ `round(commercial*0.60,2)` or the Government price ≠ `round(commercial*0.85,2)`
> by more than $0.01.

## Commercial anchor — Effort & Complexity Scale (source of truth for the anchor price)

Set the **commercial anchor** by the level of **work/effort**, **number of technologies/services**,
and **complexity/risk** involved — not by guesswork. Pick the tier the solution actually lands in;
the anchor is a point inside that tier's band. **Monotonicity rule:** a new solution must price
**≥ the most-similar prior solution of equal-or-lower effort**, and if it is clearly *more* work than
the last one generated, it moves **up** a band. Record the chosen tier in `author_notes`.

| Tier | Band (commercial) | What it is — effort · technologies · complexity |
|------|-------------------|--------------------------------------------------|
| **T1 — Foundational** | $1,295–$1,595 | One simple policy/feature · 1 technology · few steps, low risk. |
| **T2 — Standard** | $1,595–$1,995 | One feature, moderate config · 1–2 technologies · pilot→prod. |
| **T3 — Advanced** | $1,995–$2,795 | Multi-component within one platform · 2–3 technologies · conditional logic / cross-feature. |
| **T4 — Project / Migration** | $2,995–$4,495 | Multi-phase project on a major workload with **coexistence/cutover** + 3rd-party tooling · 3–5 technologies · higher risk/irreversible ops. |
| **T5 — Enterprise Program** | $4,995–$8,995 | Multi-workstream **program** across M365 + Azure / **sovereign cloud (GCC High)** · many technologies · org-wide cutover · migration suites (Quest/ShareGate). |

Existing single-platform Intune solutions sit in **T2–T3** ($1,495–$2,495). Migration **projects**
are **T4**; cross-cloud multi-workstream **programs** are **T5**.

### Reference prices
| Solution | Tier | Commercial | Non-Profit (×0.60) | Government (×0.85) |
|---|---|---|---|---|
| Windows Hello for Business | T2 | $1,995.00 | $1,197.00 | $1,695.75 |
| Exchange 1:1 tenant-to-tenant migration | T4 | $3,495.00 | $2,097.00 | $2,970.75 |
| Commercial→GCC High migration program | T5 | $5,995.00 | $3,597.00 | $5,095.75 |

## Account-wide subscription tiers (created ONCE, not per solution)

Loaded by the one-time `catalog/setup-catalog.php`, not by per-solution publishes.

| Tier | SKU | Monthly | Annual |
|---|---|---|---|
| Individual | `PTK-SUB-IND-001` | $499 | $5,988 |
| Professional | `PTK-SUB-PRO-001` | $999 | $11,988 |
| Enterprise | `PTK-SUB-ENT-001` | $1,499 | $17,988 |

> **Billing note (deferred):** Bagisto core charges one-time prices natively. Real
> recurring billing for these tiers needs a subscription/recurring extension that is **not
> yet installed**. Until it is, the three tiers are published as catalog entries with the
> monthly price as the displayed price and the annual price in the description — they do
> **not** auto-charge. Decide and wire the billing mechanism before relying on recurring
> revenue. See `ADMIN_DOCS.md` → "Recurring billing".
