---
name: publish-solution
description: Stage 2 of the Phoenixtekk Workplace Marketplace factory. Takes a generated solution from the local library, validates its bagisto-products.json, backs up the live store database, deploys the listing + deliverable files to linuxg5, and loads the products into the live Bagisto store at workplace.phoenixtekk.com via the idempotent PHP loader (php8.4), then verifies and updates the library index. Trigger when the user wants to publish/load/deploy an already-generated solution to the store.
---

# /publish-solution — load a generated solution into the live store

**Usage:** `/publish-solution <slug>` — e.g. `/publish-solution windows-hello-for-business`

**Stage 2.** Writes to the **live** store, so it is deliberate and gated. Prereq: Stage 1
produced the solution in the library.

## Locate the solution in the library
- Look up `<slug>` in `library\_index\registry.json` → get `category_slug` and current `version`
  (or read `library\<category_slug>\<slug>\LATEST.txt`). Fallback: glob `library\**\<slug>\`.
- Source dir: `SRC = library\<category_slug>\<slug>\<version>\`
  - contract: `SRC\listing\bagisto-products.json`
  - deliverables: `SRC\deliverables\*` (filenames referenced by `downloads[].source`)
  - metadata: `SRC\solution.meta.json`

## Environment (linuxg5 — Virtualmin, NOT cPanel)
- Live app root: `/home/workplace/public_html`. **Only this store** (`/home/marketplace` is separate — do not touch).
- **Run as site owner with PHP 8.4:** `sudo -u workplace php8.4 …`. Default `php` is 8.1 and **fatals** on Bagisto's `^8.3` check.
- DB `workplace` on `127.0.0.1`; creds in `.env` — never print/hardcode.
- Verified config: channel `1`/`default`, locale `en`, family `1`, inventory `1`. Categories: `Intune Solutions`=4, `Entra ID Solutions`=5, `Defender Solutions`=6, `Sentinel Solutions`=7, `Azure Solutions`=8, `Backup & DR Solutions`=9, `Security Solutions`=10, `Infrastructure`=12, `Cloud`=13.

## Branding (white-label by default)
The factory is **white-label by default**: unless `solution.meta.json` has `"branding": "on"`, the
company name (Phoenixtekk / Workplace Marketplace / URL) must **not** appear in the deliverables, hero,
wiki page, or store copy (see generate-solution §0c). The compilers and `publish-wiki.py` already read
`meta["branding"]`, so a normal publish preserves whatever was generated. **Do not** run the branded
`tools/enrich-descriptions.py` against an **unbranded** solution (it injects "The Phoenixtekk way" /
company name) — it is only for the older branded catalog. If you must restyle an unbranded listing,
keep its copy white-label.

## Steps

### 1. Pre-flight validation (local, no writes)
- Validate `SRC\listing\bagisto-products.json` against `schema/bagisto-products.schema.json`.
- Recompute the discounted tiers — **abort** if either disagrees by > $0.01:
  `nonprofit.price == round(commercial.price * 0.60, 2)` and (when present)
  `government.price == round(commercial.price * 0.85, 2)`.
- Confirm every `downloads[].source` exists in `SRC\deliverables\` (all three products share them).
- New solutions emit **three** products (commercial/nonprofit/government); legacy 2-tier solutions
  (commercial/nonprofit only) still validate.

### 2. Back up the live DB first (mandatory)
```bash
ssh linuxg5 'sudo -u workplace mkdir -p /home/workplace/backups; cd /home/workplace/public_html && \
  sudo -u workplace bash -lc '"'"'set -a; . ./.env; set +a; \
  mysqldump -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" \
  > /home/workplace/backups/"$DB_DATABASE"-$(date +%Y%m%d-%H%M%S).sql'"'"' && echo BACKUP_OK'
```
Confirm the dump is non-empty before proceeding.

### 3. Deploy loader + co-located solution files
- Ensure `loader/create-bagisto-products.php` is in `/home/workplace/public_html/` (owned by `workplace`).
- Create server dir `/home/workplace/public_html/solutions/<slug>/` and copy into it **together**:
  - `SRC\listing\bagisto-products.json`
  - every file from `SRC\deliverables\` referenced by the JSON — the `downloads[].source` files **and** the `image` (`<SOL>-hero.png`) — so the loader resolves all bare filenames beside the JSON.
- Pattern: `scp` to `/tmp`, `chmod 644`, then `sudo -u workplace cp …` into place; `chown` stays `workplace`.

### 4. Dry run, then load
```bash
ssh linuxg5 'cd /home/workplace/public_html && \
  sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/<slug>/bagisto-products.json --dry-run'
# review, then for real:
ssh linuxg5 'cd /home/workplace/public_html && \
  sudo -u workplace php8.4 create-bagisto-products.php --file=solutions/<slug>/bagisto-products.json && \
  sudo -u workplace php8.4 artisan indexer:index && \
  sudo -u workplace php8.4 artisan optimize:clear'
```
**`indexer:index` is mandatory** — the loader writes products + attribute values, but the
storefront reads `product_flat`, which is only populated by the indexer. Skip it and the
products exist in admin but never appear on the public site.

Idempotent — existing SKUs SKIP, so re-running after a fix is safe. To recreate cleanly after a
partial/failed load, run once with `--purge` (deletes the JSON's SKUs), then load again.

**Republishing an existing solution (the `Version: New` replace-in-place and `+1` flows).** Because a
revision keeps the **same SKUs**, a plain load **SKIPs** both products — it will *not* apply the new
price, content, downloads, or image. To overwrite the live listing:
- **Price and/or downloads changed** (or any structural change) → run **`--purge`** then load fresh
  (the purge deletes the SKUs; the reload re-creates them with the new price, downloads, and image).
  Confirm with `--purge --dry-run` first — it should list *only* this solution's SKUs.
- **Only copy/image changed** → you may instead run **`--update-content`** (name/descriptions/meta,
  re-attaches downloads + image) and/or **`--sync-images`**, avoiding a purge.
Either way, finish with `indexer:index` + `optimize:clear`, and re-verify price/downloads/image in §5.

The base image (`image` field) is attached during a fresh load. To attach/repair the image on
**already-existing** products without recreating them, run `--sync-images` (idempotent — skips
products that already have an image), then `indexer:index`.

**Description HTML is auto-styled.** The storefront theme (Tailwind preflight) flattens headings
and list bullets, so the loader injects inline styles into `<h2-4>/<p>/<ul>/<ol>/<li>` at load
time (source JSON stays clean/semantic). To restyle or refresh copy on **existing** products
without recreating them, run `--update-content` (updates name/descriptions/meta), then `indexer:index`.

### 4b. 🔒 Security — downloadables MUST stay off the public disk
Paid deliverables (PDF/ZIP) are attached to the **private** disk (`storage/app/private/product_downloadable_links/`), NOT `storage/app/public/` (which is symlinked to `public/storage` and served to the web). Bagisto's purchased-download route streams them via `Storage::disk('private')->download()` behind customer auth. The loader handles this. **Verify after every publish:**
`curl -s -o /dev/null -w "%{http_code}" https://workplace.phoenixtekk.com/storage/product_downloadable_links/<id>-<file>.pdf` → must be **404** (never 200). If 200, the file is on the public disk — move it to `storage/app/private/...` and fix the loader. Note Cloudflare caches `/storage/*` (max-age 14400); if a paid file was ever fetched while public, **purge the Cloudflare cache** for that URL.

### 5. Verify (don't declare success without this)
- Confirm both SKUs exist, enabled, on channel `default`, priced right, HTML renders.
- For `downloadable`: open each in admin, confirm **download links attached** and files download. Headless file-attach is the fragile step — if links are missing, fix and re-run (backup is the fallback).
- Report `CREATE / SKIP / FAIL` per product.

### 6. Update the library after a successful publish
- Edit `SRC\solution.meta.json`: set `"status": "published"`, `"published_at": "<today>"`, refresh `"updated"`.
- **Versioning note:** `+1` forks a **new separate product** (new slug/SKUs) — it does **not**
  supersede or modify the source product, so publishing it is a normal fresh load and the original
  stays live. (`New` replaces a product in place — same slug, same SKUs, same version folder.) Only
  flip an on-disk version to `"status": "superseded"` if you ever keep multiple `vN.N.N` folders
  under one slug (uncommon).
- **Rebuild index:** `pwsh library\_index\rebuild-index.ps1` (flips status in INDEX.md/registry).
- Update root `FEATURES.md` (published), and `HELP_CENTER.md` if store-facing copy changed.

### 7. Publish documentation to Wiki.js (docs.phoenixtekk.com)
The solution guide is also published as the **living, always-current** copy on the self-hosted
Wiki.js, so subscribers/purchasers can return for updated content (see gating, §8).
**Full reference: [`WIKIJS_PUBLISHING_HANDOFF.md`](../../../WIKIJS_PUBLISHING_HANDOFF.md)** (repo root) —
this section is the condensed version.
- **Credentials (env only — never commit/print):** `WIKIJS_URL=https://docs.phoenixtekk.com`,
  `WIKIJS_TOKEN=<API token>` (Wiki.js → Administration → API Access → enable + page-write token).
  Stored untracked in `./.wikijs.env` (gitignored) and `/home/workplace/.wikijs.env` (600) on linuxg5.
  Load before running: `set -a; . ./.wikijs.env; set +a`.
- **Preview (no token):** `python tools/publish-wiki.py --solution-dir "<SRC>" --dry-run`
  (renders `deliverables/<SOL>-wiki.md` from `source\` in the same order as the compiler).
- **Publish:** `python tools/publish-wiki.py --solution-dir "<SRC>"` — creates/updates the page at
  `solutions/<category_slug>/<slug>` via GraphQL (idempotent — re-runs UPDATE, never duplicate).
  **Pages are always published (live) by default.** (Use `--draft` only to stage without publishing.)
  Gating controls *who can read* a published page — apply §8 so a published page isn't world-readable.
- Record the Wiki.js page path in `solution.meta.json` as `"wiki_path"` for traceability.
- **Wiki.js quirks (the tools handle these — preserve them if you write new API calls):**
  (a) Cloudflare blocks the default `urllib` agent (error 1010) → always send a **browser User-Agent**.
  (b) `pages.singleByPath` throws `PageNotFound`/`6003` when a page is absent → tolerate = create.

### 8. Gate access + alert customers (Wiki.js)  ⟵ subscriber/purchaser benefit
- **Gating (#3) — BUILT: `tools/wiki-access-sync.py`.** Eligible viewers = **active subscribers OR
  one-time purchasers of this solution**. Model: `Guests` is DENY on `solutions/` (closes public
  read); a **Subscribers** group is ALLOW on `solutions/**`; a per-solution **`Purchasers: <slug>`**
  group is ALLOW on that solution's path. Run `python tools/wiki-access-sync.py --registry
  library/_index/registry.json` (dry-run) then `--apply`. It also provisions a Local Wiki.js account
  (`sendWelcomeEmail`) per eligible customer and reconciles group membership.
  - **Eligibility file** (`--eligibility-file elig.json`): `{ "subscribers": [emails],
    "purchasers": { "<slug>": [emails] } }`. Generate from the store DB on linuxg5:
    - subscribers: `SELECT c.email FROM pt_sub_subscriptions s JOIN customers c ON c.id=s.customer_id
      WHERE s.status IN ('active','trialing') AND s.current_period_end > NOW();`
    - purchasers: `SELECT oi.sku, o.customer_email FROM order_items oi JOIN orders o ON o.id=oi.order_id
      WHERE o.status IN ('completed','processing');` then map sku → slug via the registry.
  - **Gating quirks (the tool handles these):** every NEW Wiki.js group is seeded with a default
    ALLOW on path `""` (the whole wiki) — access groups must **replace** their rules, not append, or
    members read everything (`set_access_rule` does this). And Wiki.js breaks allow/deny ties toward
    **DENY**, so do **not** put the `solutions` deny on any group a customer can belong to (e.g.
    Public Users) — it would lock out paying customers; the deny lives **only on `Guests`**.
  - **Purchase → access is AUTOMATED.** `tools/wiki-provision.py` runs on linuxg5 via cron
    (`*/15 * * * *`, workplace user) and reconciles: reads the store DB (active subs + paid orders;
    slug derived from product `url_key`), then provisions a Local Wiki.js account per eligible
    customer (welcome email) and sets group membership — `Subscribers` (all solutions) and/or
    `Purchasers: <slug>` (that solution). Refund/lapse → removed next run. Staff (Administrators
    group) are never auto-revoked. Dry-run: `sudo -u workplace python3 /home/workplace/wiki-provision.py`.
    NOTE: the `Purchasers: <slug>` GROUP must exist first — created at publish time by
    `wiki-access-sync.py` (§8 gating). So always run the gating step when publishing a new solution.
  - **Internal-folder lockdown:** `wiki-access-sync.py` also denies Guests on internal folders
    (agent-output, SystemDocs, marketing, Marketplace, Workplace, Phoenixtekk, txtya, aigartha,
    OpenClaw, Analytikul, TekkDomains, LibreChat). Public tier = home + Intune/Microsoft/JamfPro KB.
  - **Verify after any change:** anonymous must be blocked, public home must still load:
    `curl -s -o /dev/null -w "%{http_code}" https://docs.phoenixtekk.com/en/solutions/intune-solutions/<slug>`
    → **403**; `… https://docs.phoenixtekk.com/` → **200**. (Admin tokens bypass gating, so test a
    real customer view with a throwaway Local user in one `Purchasers: <slug>` group, then delete it.)
- **Alerts (#4) — TODO `tools/notify-update.*`:** on a publish/update, **generate a draft
  announcement** (email to all customers + members, plus an on-site/Wiki.js notice) and **hold it for
  human approval** before sending — never auto-send bulk mail.

### 9. 🔗 Report the review links (MANDATORY — the factory's last generation step)
**Owner directive (2026-07-16): every factory run that produces or republishes product solutions MUST
end by reporting a summary of URL links to those products.** Never finish a run with only names and
counts — the owner reviews by clicking. This is part of "done", exactly like the wiki mirror.

Generate the links with the tool — **derive, never type them from memory** (a wrong link is worse than
none; the tool reads `url_key` from each listing and `wiki_path`/`wiki_gated` from each meta, so it
handles free products (`<slug>-free`, public wiki) and `wiki_path` overrides correctly):
```bash
# after publishing one or more slugs in this run:
python tools/report-links.py --slug <slug> [--slug <slug> ...] --verify
# or, for a whole wave published today:
python tools/report-links.py --since <YYYY-MM-DD> --verify
```
- **Always pass `--verify`** — it checks each URL live and marks anything unexpected ⚠ (store must be
  **200**; wiki **403** = correctly gated, **200** = intentionally public/free tier). Exit code 2 means
  a link failed: **fix it or say so in the report — never emit a dead URL.**
- Output shape is automatic: **inline pairs for 1–3 products, a table for a wave.** Paste it into the
  Shipped summary as-is.
- This satisfies the global standing rule in `~/.claude/CLAUDE.md` ("Shipped reports — always include
  marketplace + wiki URLs"); the tool is the mechanical implementation of it.

## Rollback
Restore the step-2 dump:
`ssh linuxg5 'cd /home/workplace/public_html && sudo -u workplace bash -lc '"'"'set -a; . ./.env; set +a; mysql -h "$DB_HOST" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /home/workplace/backups/<file>.sql'"'"''`
then `optimize:clear`.
