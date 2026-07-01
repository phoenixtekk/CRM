# Help Center — Phoenixtekk Workplace Marketplace

End-user (operator) guide to creating and publishing solutions with the factory. For
infrastructure/runbook detail see `ADMIN_DOCS.md`; for the design see `README.md`.

## What this is
A two-step workflow that turns a topic into a finished, priced product on
**workplace.phoenixtekk.com**. You drive it with two slash commands in Claude Code.

## Step 1 — Author a solution
```
/generate-solution "Windows Hello for Business"
```
Claude will ask for:
- the **Commercial price** (the Non-Profit price is calculated automatically as 40% less),
- a short **solution code** for the SKUs (e.g. `WHFB`),
- the **category** (e.g. `Intune Solutions`).

It then writes the full solution into `solutions/<slug>/` — overview, requirements,
implementation steps, PowerShell scripts, testing, troubleshooting — compiles a branded
**Word + PDF**, zips the scripts, and produces the product data (`bagisto-products.json`).
Nothing goes live yet. Review the files.

## Step 2 — Publish it to the store
```
/publish-solution windows-hello-for-business
```
Claude validates the data, **backs up the store database**, deploys the files, loads the
**Commercial** and **Non-Profit** products (with the guide + scripts attached as
downloads), clears the cache, and verifies them in admin. You'll get a `CREATE / SKIP /
FAIL` line per product.

## The products you get per solution
| Product | Who it's for | Price |
|---|---|---|
| `<Title> — Commercial` | Private-sector orgs | Your anchor price |
| `<Title> — Non-Profit` | Qualifying non-profits | Exactly 40% less |

Each is a **downloadable** product: buyers receive the implementation guide (PDF) and the
PowerShell scripts (ZIP) on purchase.

## Memberships (subscriptions)
Three account-wide tiers — **Individual** ($499/mo), **Professional** ($999/mo),
**Enterprise** ($1,499/mo) — are set up **once** for the whole store, not per solution.
> Note: automatic recurring billing isn't wired up yet — these are listed at the monthly
> price (annual shown in the description) and handled manually until a billing extension is added.

## Tips
- Re-running `/publish-solution` is safe: existing products are skipped, not duplicated.
- If a product's download links are missing after publish, tell Claude — it re-attaches and re-runs.
- Keep `bagisto-products.json` as the single source of truth; edit it and re-publish to update data.
