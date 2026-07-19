# ADMIN_DOCS — Phoenixtekk Workplace Solutions

Operator/runbook documentation for the solution factory and the live Bagisto store.

> **Wiki.js docs publishing & gating** (docs.phoenixtekk.com): see the self-contained handoff guide
> [`WIKIJS_PUBLISHING_HANDOFF.md`](WIKIJS_PUBLISHING_HANDOFF.md) — how to publish solution docs
> (`tools/publish-wiki.py`) and gate them to subscribers/purchasers (`tools/wiki-access-sync.py`).

## Environment
- **Host:** `linuxg5` (Virtualmin + Apache + PHP-FPM — *not* cPanel).
- **Live store app root:** `/home/workplace/public_html` → `https://workplace.phoenixtekk.com/`.
  - Laravel app root = `public_html`; web docroot = `public_html/public` (storage symlinked).
  - Owned by the `workplace` system user.
- **Separate store (do not touch):** `/home/marketplace/public_html`. Purpose unconfirmed.
- **Bagisto version:** ~2.3.x (`composer.json` requires `php ^8.3`; pins `bagisto/laravel-datafaker 2.3.*`).
- **Database:** `workplace` on `127.0.0.1` (MySQL). Creds in `public_html/.env` — never print/commit.

## ⚠️ PHP version — critical
The site runs on **PHP 8.4 (FPM)**. The default CLI `php` on linuxg5 is **8.1.34**, which
**hard-fatals** on Bagisto's `^8.3` platform check. **Always run artisan and the loaders as
`php8.4`, and as the `workplace` user** so cache/storage files aren't left root-owned:

```bash
sudo -u workplace php8.4 artisan optimize:clear
sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/<slug>/bagisto-products.json
```

## Verified store configuration (from `--inspect`)
- Channel: `id=1`, code `default`
- Locale: `id=1`, code `en`
- Attribute family: `id=1` (Default)
- Inventory source: `id=1` (Default)
- Categories: Root=1, Solutions=2, Microsoft Solution=3, **Intune Solutions=4**, Entra ID
  Solutions=5, Defender Solutions=6, Sentinel Solutions=7, Azure Solutions=8, Backup & DR
  Solutions=9, Security Solutions=10, "BlitLocker" Solutions=11 *(likely typo for BitLocker)*,
  Infrastructure=12, Cloud=13.

Re-check anytime: `cd /home/workplace/public_html && sudo -u workplace php8.4 create-bagisto-products.php --inspect`

## Loading products (the loader)
`loader/create-bagisto-products.php` — generic, idempotent. Modes:
- `--inspect` — read-only; prints channels/locales/families/inventory/categories.
- `--file=<path> --dry-run` — validate + show CREATE/SKIP without writing.
- `--file=<path>` — create products (two-step create→update; attaches downloadable files).
CONFIG block at top is pre-set to the verified IDs above; verify with `--inspect` if the store changes.

## Backups (run before every load — mandatory)
```bash
ssh linuxg5
sudo -u workplace mkdir -p /home/workplace/backups
cd /home/workplace/public_html
# dump using .env creds without echoing them:
sudo -u workplace bash -lc 'set -a; . ./.env; set +a; \
  mysqldump -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" \
  > /home/workplace/backups/"$DB_DATABASE"-$(date +%Y%m%d-%H%M%S).sql' && echo OK
```
Restore: `sudo -u workplace bash -lc 'set -a; . ./.env; set +a; mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /home/workplace/backups/<file>.sql'`

## Subscription tiers (Memberships) — LIVE
Published 2026-06-14 via the main loader (not the old `setup-catalog.php`). Source:
`catalog/memberships/bagisto-products.json` (3 simple products + hero images). They live in the
**Memberships** category (id 18), created automatically by the loader's `--ensure-category`:
```bash
# deploy catalog/memberships/{bagisto-products.json, SUB*-hero.png} to solutions/memberships/, then:
sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/memberships/bagisto-products.json --ensure-category
sudo -u workplace php8.4 artisan indexer:index && sudo -u workplace php8.4 artisan optimize:clear
```
| Tier | SKU | Monthly | Annual |
|---|---|---|---|
| Individual | PTK-SUB-IND-001 | $499 | $5,988 |
| Professional | PTK-SUB-PRO-001 | $999 | $11,988 |
| Enterprise | PTK-SUB-ENT-001 | $1,499 | $17,988 |

## Recurring billing (DEFERRED — important)
Bagisto core has **no native recurring billing**. The subscription tiers currently publish
as catalog entries showing the **monthly** price (annual in the description); they **do not
auto-charge**. Before relying on recurring revenue, install and wire a subscription
extension and re-model the tiers. Until then, treat subscription "sales" as manual.

## Discounted-tier eligibility (Non-Profit / Government) — verification
Every solution now ships **three** tiers: Commercial (anchor), **Non-Profit −40%**, **Government −15%**
(see `pricing.md`). The discounted tiers are **gated to verified customers** via Bagisto customer
groups:

| Group (customer_groups) | id | code | Who |
|---|---|---|---|
| General | 2 | `general` | default for new customers = **Commercial** pricing |
| Non-Profit (Verified) | 4 | `non-profit` | verified 501(c)(3) → may buy the `*-NPO-001` SKU |
| Government (Verified) | 5 | `government` | verified public-sector → may buy the `*-GOV-001` SKU |

**Verification tool:** `tools/verify-eligibility.py` returns `eligible` / `review` / `ineligible` and
the exact group-assignment SQL. Layers (each independent, degrade gracefully):
- **Government** — keyless **email-domain** check (`.gov`/`.mil`/`.fed.us`/state `.us`) [always on];
  **SAM.gov** Entity API when `SAM_GOV_API_KEY` is set.
- **Non-Profit** — **IRS Pub78** EIN lookup when `data/irs_pub78.csv` is staged (free IRS bulk
  download); **TechSoup** validation when `TECHSOUP_API_KEY` is set (partner onboarding required).
```
python tools/verify-eligibility.py --type government --email a@agency.gov [--uei UEI]
python tools/verify-eligibility.py --type nonprofit  --email x@org.org --ein 12-3456789
```
**Workflow:** customer requests a discounted tier → submits proof (EIN/501(c)(3) letter, or gov
entity/UEI) → run the tool → `eligible` auto-approves, `review` needs an admin to eyeball the proof →
on approval, set `customers.customer_group_id` to 4 (non-profit) or 5 (government) on linuxg5.

**To activate the automated layers, provide (env on linuxg5, never commit):**
- `SAM_GOV_API_KEY` — free key from sam.gov (Account Details → API key).
- `TECHSOUP_API_KEY` (+ partner onboarding) — TechSoup/NGOsource validation.
- (optional) stage `data/irs_pub78.csv` from the IRS Tax Exempt Organization Search bulk data.

**Enforcement model — verify-then-assign (no checkout block, by design, 2026-06-27).** Decision: the
discounted `*-NPO-001` / `*-GOV-001` SKUs are **intentionally visible/purchasable** — we do **not**
hard-block at checkout. Eligibility is enforced operationally: a buyer is **verified** (tool above) and
**assigned** to the `non-profit`/`government` group; the wiki docs for what they bought are gated by the
`Purchasers: <slug>` group regardless of tier. If abuse appears later, the optional cart/checkout event
listener (reject the discounted SKU unless `customer_group_id` ∈ {4,5}) can be added then.

> Purchaser→wiki gating handles all three tiers: `tools/wiki-provision.py` derives the slug from the
> product `url_key` stripping `-commercial|-nonprofit|-government`, so a Government purchase grants the
> same `Purchasers: <slug>` doc access.

## After any bulk change
`sudo -u workplace php8.4 artisan optimize:clear`

## Safety rules
- Only touch `/home/workplace/public_html` unless explicitly directed.
- Run everything as `workplace` with `php8.4`, never as root, never bare `php`.
- Never print/commit `.env` secrets. Loader is idempotent — verify in admin after running.
