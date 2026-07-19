# Phoenixtekk Workplace Solutions — Solution Factory

A repeatable pipeline that turns a topic into a published, priced consulting solution on
**https://workplace.phoenixtekk.com/** (Bagisto ~2.3.x on `linuxg5`).

```
  /generate-solution "<topic>"            /publish-solution <slug>
  ─────────────────────────────►          ─────────────────────────────►
  author → package (docx/pdf+scripts)      validate → backup DB → deploy →
  → emit bagisto-products.json             load (php8.4) → verify in admin
        (Stage 1, files only)                  (Stage 2, writes live store)
```

## Layout
| Path | Purpose |
|---|---|
| `.claude/skills/generate-solution/` | Stage 1 skill — author + package a solution from a topic |
| `.claude/skills/publish-solution/` | Stage 2 skill — load a generated solution into the live store |
| `schema/bagisto-products.schema.json` | The contract between the two stages |
| `loader/create-bagisto-products.php` | Generic idempotent product loader (`--inspect` / `--dry-run`) |
| `catalog/` | One-time account-wide subscription tiers (`setup-catalog.php` + `subscriptions.json`) |
| `pricing.md` | Pricing rules (NPO = commercial × 0.60; subscription tiers) |
| `library/` | **Managed solution library** — every generated solution, categorized & versioned (see `library/README.md`) |
| `library/_index/INDEX.html` | Visual dashboard — metrics, status donut, per-category chart, collapsible click-to-open file browser |
| `library/_index/INDEX.md` | Same data as Markdown (auto-generated) |
| `FEATURES.md` · `ADMIN_DOCS.md` · `HELP_CENTER.md` | Required project docs |

## Where solutions land (the library)
```
library\<category>\<slug>\v<version>\{source,scripts,deliverables,listing}\
library\<category>\<slug>\LATEST.txt          ← current version pointer
library\_deliverables\<slug>\                 ← flat shelf of just the buyer files
library\_index\INDEX.md                       ← open this to see everything
```
Each solution is self-contained (copy/zip the `<slug>\v<version>\` folder = the whole product).
The index is regenerated from each solution's `solution.meta.json` by
`library\_index\rebuild-index.ps1` (the skills run it automatically).

## Key facts (don't relearn the hard way)
- **Run loaders/artisan as `sudo -u workplace php8.4 …`** — default `php` is 8.1 and fatals on Bagisto's `^8.3` check.
- **Channel/locale are CODES for attribute scoping, IDs for the `channels` pivot.** Inventories keyed by source id.
- **Only two products repeat per solution** (Commercial + Non-Profit). Subscriptions + categories are account-wide.
- **Back up the DB before every load.** The loader is idempotent (existing SKUs skip).
- Verified store config: channel 1/`default`, locale `en`, family 1, inventory 1; `Intune Solutions`=category 4.

## Quick start
1. `/generate-solution "Windows Hello for Business"` → review `solutions/windows-hello-for-business/`.
2. (once, ever) deploy `catalog/` and run `setup-catalog.php` to publish the subscription tiers.
3. `/publish-solution windows-hello-for-business` → products go live.

See `HELP_CENTER.md` to operate it, `ADMIN_DOCS.md` to run/troubleshoot it.
