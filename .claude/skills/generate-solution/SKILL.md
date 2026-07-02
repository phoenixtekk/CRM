---
name: generate-solution
description: Stage 1 of the Phoenixtekk Workplace Marketplace factory. Authors a complete, productized IT consulting solution for a given topic (Microsoft Intune / Entra / Defender / etc.) following the Phoenixtekk authoring standard, compiles it to Word+PDF, packages the PowerShell scripts, and emits a schema-conformant bagisto-products.json into the managed solution library ready for /publish-solution. Trigger when the user wants to create/author/generate a new marketplace solution from a topic.
---

# /generate-solution — author a productized marketplace solution

**Usage:** `/generate-solution "<topic>"` — e.g. `/generate-solution "BitLocker Encryption for Intune"`
Optionally attach a **shaping note** (see §0a), a **version directive** (see §0b), and/or a
**branding directive** (see §0c):
```
/generate-solution Implement COD and BYOD Device Management in Microsoft Intune
Notes: The solution must allow a single user account to sign in on both device types.
Version: New or +1
Brand: off or on
```

**Stage 1** of a two-stage factory. Produces files into the **solution library** only; never
touches the live store. `/publish-solution <slug>` (Stage 2) loads them into Bagisto.

## 0. Inputs to confirm before authoring
Ask only for what isn't already given:
1. **Commercial anchor price** (USD). Non-Profit = `round(commercial * 0.60, 2)`, computed automatically.
2. **Solution code** `<SOL>` — short uppercase token for SKUs (e.g. `BITLOCKER` → `BLCK`). Suggest one.
3. **Category** — must match a store category name: `Intune Solutions`, `Entra ID Solutions`,
   `Defender Solutions`, `Sentinel Solutions`, `Azure Solutions`, `Backup & DR Solutions`,
   `Security Solutions`, `Infrastructure`, `Cloud`, `Healthcare Solutions` (clinical/EHR/Epic,
   HIPAA/HITRUST), `Managed` (MSP managed-services operations + tool stack: PSA/RMM/patch, incident &
   problem management). New categories are created on first publish via the loader's `--ensure-category`.

Derive:
- `slug` = kebab-case of the title (e.g. `bitlocker-encryption-for-intune`).
- `category_slug` = kebab-case of the category (e.g. `intune-solutions`).
- `version` — resolved by the **version directive** and **solution-identity rule** in §0b (do not
  guess; §0b is the single source of truth for which `vN.N.N` folder this run targets).

**Output root for this run:**
`library\<category_slug>\<slug>\v<version>\` with subfolders `source\ scripts\ deliverables\ listing\`.

## 0a. Optional shaping note (`Notes:`)
The request may carry a free-form **shaping note** — extra detail that further shapes the solution
(scope, a required design constraint, an emphasis). It is part of the **same** `/generate-solution`
input — never a separate command.

**Parse it:**
- **Topic** = the text before the first note marker. **Note** = everything after it.
- **Canonical marker:** a line beginning `Notes:` (or `Comment:`). **Also accept** an inline
  `--note "<text>"` flag. Multiple `Notes:` lines are concatenated in order.
- Example: `Notes: The solution must allow a single user account to sign in on both device types.`

**Honor it (the note is binding authoring guidance, not decoration):**
1. **Echo it back** in the §0 input confirmation — *"Shaping note received: …"* — so a misread is
   caught before authoring.
2. **Let it materially shape** the Solution Overview scope, Requirements, and Implementation. (E.g. a
   "same account on both device types" note forces a single-identity design spanning COD enrollment
   **and** BYOD user-enrollment.)
3. If the note **conflicts** with the house standard or is technically infeasible, **flag it to the
   user** and propose the closest workable design — never silently ignore it.
4. **Internal only:** the note steers content but is **not printed verbatim** in the customer
   Word/PDF. It may become explicit documented content only when it naturally *is* a stated
   requirement.
5. **Persist for traceability:** record it in `solution.meta.json` as `"author_notes"` and as a
   one-line **Shaping notes** entry in the solution `README.md` (see §6).

If no note is present, proceed normally.

## 0b. Version directive (`Version:`) and solution identity
The request may carry a **version directive** — a free-form line, part of the **same**
`/generate-solution` input, that controls which `vN.N.N` folder this run targets and whether it
**replaces** or **increments**. Parse it like the shaping note:
- **Topic** = the text before the first marker (`Notes:` or `Version:`). The directive is the value
  after a line beginning **`Version:`** (also accept an inline `--version <value>` flag).
- **Accepted values:** `New` or `+1` (case-insensitive). Anything else → **flag it and ask**, don't guess.
- **Echo it back** in the §0 input confirmation — *"Version directive: New → replace v1.2.0 in place"*
  — so a misread is caught before authoring.

### Step 1 — resolve the solution's identity (the Rule)
**Identity is the slug (kebab-case of the title), and the slug is the source of truth.**
- **Same name/title → same solution.** Look up the slug in `library\_index\registry.json` (or the
  per-slug `LATEST.txt`). If it already exists, this run **overwrites/updates that existing
  solution** — never create a second slug for it.
- **Similar-but-different name/title → a DIFFERENT, separate solution.** Do **not** assume a similar
  title is the same thing. A different title yields a different slug and a brand-new solution (start
  at `v1.0.0`). When two titles are close enough that you're unsure whether the user means the
  existing solution or a new one, **stop and ask** — do not silently overwrite or silently fork.

### Step 2 — resolve the target from the directive
`New` operates on **one product** (the same slug). `+1` **forks a NEW, separate product** from an
existing similar one — both stay live. They are fundamentally different operations:

| Directive | Meaning | Result |
|-----------|---------|--------|
| **`New`** | Build/replace **this** product (same slug). | If the slug exists → **replace its contents in place** (same `vCUR` folder, same version number, same SKUs; overwrites the live listing at publish). If new → create **`v1.0.0`**. |
| **`+1`** | **Fork-to-new-sibling.** "There is a similar existing product — copy it as the base, apply the revisions, and ship the result as a brand-new SEPARATE product." | The **original product is untouched and stays live.** Create a **DIFFERENT product** with a **distinct identity** — new `slug`, new `sol_code`, new SKUs, and a **distinguishing title** — starting at its own **`v1.0.0`**. You end up with **two products** in the catalog, not one with version history. |
| **absent** | No directive. | Default to **`New`** (build/replace this product) — **never auto-fork.** If a same-title product already exists, say you defaulted and offer `+1` to fork instead. |

**Applying `+1` (the fork) — the important one:**
1. **Find the source product** = the existing solution most similar to the topic (look it up in the
   registry; e.g. a "COD & BYOD …" topic maps to `cod-and-byod-device-management`). If unclear which
   one, **ask**.
2. **Establish a distinct new identity and CONFIRM it with the user** before authoring — the new
   product must NOT collide with the source: new `slug`, new `sol_code` + SKUs (`PTK-<NEWSOL>-…`),
   and a `title` that clearly distinguishes it (the revision is the differentiator). Same
   solution-identity rule as everywhere: similar title ≠ same product → it gets its own slug/SKUs.
3. **Copy the source's latest version** (`source\ scripts\ listing\` etc.) into the new product's
   `v1.0.0\` folder as the starting point, then **apply the shaping-note revisions** throughout
   (overview/requirements/implementation/etc.), rename the `sol_code` token across files, set the new
   slug/title/SKUs/url_keys, rebuild deliverables + hero, and write fresh `solution.meta.json`
   (status `generated`, version `1.0.0`, `version_directive: "+1"`, record the source in
   `author_notes`). The source product's folder and live listing are **not modified**.
   *(This is the macOS ADE → "macOS ADE (Jamf Pro + Intune)" pattern: clone + revise → second product.)*
4. **Publish** is a normal fresh publish of the new slug/SKUs (its own listing) — it does **not**
   purge or supersede the original.

**Applying `New` (same product):** rewrite the existing `vCUR` folder in place (same `version`,
refresh `updated`); `LATEST.txt` stays `vCUR`; publish overwrites the same-SKU live listing
(`--purge` + reload). If the slug is new, create `v1.0.0`.

Record the resolved directive in `solution.meta.json` as `"version_directive"` (`"New"` | `"+1"` |
`"default:New"`) for traceability, alongside `author_notes` (§6).

## 0c. Branding directive (`Brand:`) — DEFAULT OFF (white-label)
The request may carry a **branding directive** — a free-form line, part of the **same**
`/generate-solution` input — that controls whether the **company name and branding (Phoenixtekk,
"Workplace Marketplace", workplace.phoenixtekk.com)** appear in the generated documentation and
materials. Parse it like the other directives:
- **Topic** = the text before the first marker (`Notes:` / `Version:` / `Brand:`). The directive is
  the value after a line beginning **`Brand:`** (also accept an inline `--brand` / `--no-brand` flag).
- **Accepted values:** `on` / `branded` / `yes` → **branded**; `off` / `unbranded` / `white-label`
  / `no` → **unbranded**. Anything else → **flag it and ask**, don't guess.
- **DEFAULT (no directive present) = `off` (UNBRANDED / white-label).** Per standing rule: **never add
  the company name or branding to any documentation unless `Brand:` explicitly says so.**
- **Echo it back** in the §0 input confirmation — *"Branding: OFF (white-label) — no company name in
  the deliverables"* — so a misread is caught before authoring.

**What the toggle governs (apply consistently across everything the factory generates):**
| Surface | Unbranded (default) | Branded (`Brand: on`) |
|---|---|---|
| Compiled **Word/PDF** (`build-deliverables.py`) | No cover name/subtitle/URL; neutral page footer (title + page). The navy/accent palette stays — it's a neutral document theme, not the company name. | "PHOENIXTEKK" cover, "Workplace Marketplace" subtitle, URL, and "Phoenixtekk ·" footer. |
| **Hero image** (`build-hero.py`) | Footer shows the **category only** (no company/URL). | "PHOENIXTEKK · <category> · workplace.phoenixtekk.com" footer. |
| **Source docs** (`source\*.md`) | Use neutral phrasing — e.g. *"the standard deployment model"* / *"the standard pattern"*, **not** "the Phoenixtekk pattern/way". No company name in body text. | The house "Phoenixtekk" phrasing is allowed. |
| **Scripts** (`scripts\*.ps1` `.NOTES`) | Neutral note line (e.g. *"Intune Solutions — read-only."*), **no** "Phoenixtekk Workplace Marketplace". | Company line allowed. |
| **Listing / sales copy** (`bagisto-products.json`, `sales-content.md`) | Drop the company name — rename the "The Phoenixtekk way" block to a neutral **"The repeatable way"**; no company name in descriptions. | "The Phoenixtekk way" + company name allowed. |

**How it's enforced:** the two compilers read **`solution.meta.json` → `"branding"`** automatically
(default `"off"`), so a plain `build-deliverables.py` / `build-hero.py` produces **white-label** output.
A `--brand` / `--no-brand` CLI flag overrides per-run. **Always set `"branding"` in
`solution.meta.json`** (§6) to the resolved value so rebuilds and `/publish-solution` stay consistent.

Record the resolved directive in `solution.meta.json` as `"branding"` (`"on"` | `"off"`) — for
traceability and so the compilers honor it.

## 0d. Commercial vs Government deliverables (research + fork when they differ) — STANDING RULE
The 3-tier pricing (Commercial · Non-Profit −40% · Government −15%) is a **pricing** model — it does
**not** mean the Government buyer receives the Commercial deliverable at a lower price. **Commercial
M365 tenants and Government tenants (GCC / GCC High / DoD) frequently differ in the actual setup**, so
a guide that is correct for Commercial can be *wrong* for Government.

**Always, before authoring any solution that touches a Microsoft cloud service** (M365 / Entra /
Intune / Defender / Purview / Sentinel / Azure), **research whether the Government tenant differs**,
including:
- **Admin portal URLs** — e.g. `portal.azure.us`, `portal.office365.us`, `endpoint.microsoft.us`,
  `login.microsoftonline.us`, `security.microsoft.us`, `compliance.microsoft.us`, `*.office365.us`.
- **Feature / endpoint availability & parity gaps** (features GA in Commercial that are delayed,
  limited, or absent in GCC High / DoD), **service rollout timing**, and **compliance constraints**.
- Different service endpoints/URLs the scripts must target, and different required network endpoints.

**Decision:**
- **If Government does NOT materially differ** → one deliverable, current behavior (Gov tier is
  price-only).
- **If Government DOES materially differ** → produce a **distinct Government deliverable**. Model:
  - Author a **Government variant** of the affected sections/scripts under `source-gov\` +
    `scripts-gov\` (only the files that differ; unchanged files are inherited from the Commercial
    `source\`). The Commercial deliverable stays attached to the **Commercial + Non-Profit** SKUs;
    the **Government deliverable** (`<SOL>-Solution-GOV.pdf` / `<SOL>-Scripts-GOV.zip`, built by
    `build-deliverables.py --variant gov`) is attached to the **Government SKU** (`PTK-<SOL>-GOV-001`).
  - Publish a **Government-tailored wiki page** (or a clearly-marked Government section) gated to the
    Government Purchasers group; keep the Commercial guide for Commercial/NPO purchasers.
  - Record `"gov_variant": true` in `solution.meta.json` and note the specific differences in
    `author_notes`.
- **Never invent** GCC High / DoD specifics — cite Microsoft's US-sovereign-cloud docs; where a
  difference is uncertain, state the Commercial path and flag "verify for GCC High" rather than guess.

*(This rule is enforced by the factory going forward and is being retrofitted across the existing
catalog. See CLAUDE.md §6 learning loop + `library/_index/AUTHORING_LESSONS.md` cross-cutting entry.)*

## 1. Authoring standard (the Phoenixtekk house style)
Author for a **novice Intune administrator** — buyer must be able to **"Click to Implement."**
- **Imperative, exact instructions.** "Click **Devices** → **Configuration** → **Create**." No *why* in steps — the *why* lives in the Solution Overview.
- **Always name the object you create.** Whenever a step creates something — a configuration profile,
  compliance policy, Conditional Access policy, device filter, Entra security group, enrollment/PreStage
  profile, app/assignment, App Protection policy, dynamic group, scope tag, etc. — the step **must state
  the exact name to give it** (e.g. *"…and name it `macOS ADE – Pilot`"*). Never write "create a policy"
  without the name. Use a **consistent, descriptive naming convention** — `<Purpose> – <Scope/Platform>
  – <Stage>` (e.g. `WHfB – Compliance – Pilot`, `CA – COD-BYOD Access`, `PILOT – COD-BYOD Users`) — so
  the admin can find, audit, and clean it up later. **Reuse that exact name verbatim** in every later
  step, the Testing/validation, Troubleshooting, and any scripts that reference the object.
- **Always identify a store app you deploy by exact publisher + bundle/package ID.** When a step adds
  an app from the iOS/iPadOS App Store or managed Google Play, give the **exact store publisher string**
  and the **bundle/package ID** (e.g. *publisher `Cisco Systems, Inc.`, bundle ID `com.cisco.squared`*),
  and **disambiguate** it from similarly-named apps (e.g. *not 'Webex Meetings'*). Store search returns
  multiple near-identical results; the exact publisher + ID is what guarantees the admin selects — and
  kiosk-locks to — the right app.
- **Exact, current navigation paths** in Intune/Entra, **in required configuration order** — give the
  **full drill-down** (every console → blade → tab), never an abbreviated "open X → Create".
- **Never assume prerequisites exist** — each requirement: Description · Why required · How to verify · How to implement if missing.
- **Consistent deployment model across all solutions** so repeat buyers recognize the pattern. Short, not overwhelming.
- **Apply the accumulated authoring lessons.** Before authoring (and before finalizing), **read
  [`library/_index/AUTHORING_LESSONS.md`](../../../library/_index/AUTHORING_LESSONS.md)** and apply
  every lesson relevant to this solution's category/topic. These are real corrections harvested from
  validation edits via the Documentation Validation Learning Loop (global CLAUDE.md §6) — honoring them
  is how the factory's accuracy compounds. If this run reveals a *new* generalizable lesson, add it.
- **Troubleshooting authored LAST.**

## 2. Author the sources → `…\v<version>\source\` (+ scripts\)
1. `source\01-solution-overview.md` — what it is, how it works, auth methods, benefits, limitations, the standard deployment model.
2. `source\02-requirements.md` — licensing, Entra, Intune, OS, hardware, TPM, cloud-only, network, certs. Each: Description / Why / Verify / Implement-if-missing.
   - Also emit `source\global-requirements-<category_slug>.md` — the requirements common to *every* solution in this category (lives once at category level, not per product).
3. `source\03-implementation.md` — exact ordered steps (enable, policies, enrollment, PIN, biometrics, security, pilot, production).
4. `scripts\*.ps1` — Discovery / Validation / Reporting / Remediation. Each header: Purpose · How to run · Expected results.
5. `source\05-testing.md` — validation procedures.
6. `source\06-troubleshooting.md` — **(write last)**.
7. `source\07-best-practices.md`, `source\08-deliverables-summary.md`, `source\executive-summary.md`.

## 3. Compile + package → `…\v<version>\deliverables\`
Write `solution.meta.json` first (Section 6), then run the factory compiler — it builds all
three deliverables from `source\` + `scripts\` (branded Word, branded PDF with cover+TOC+page
numbers+scripts appendix, and the scripts ZIP). No Office/pandoc needed (python-docx + reportlab):
```
python tools\build-deliverables.py --solution-dir "library/<category_slug>/<slug>/v<version>"
```
Produces `deliverables\<SOL>-Solution.docx`, `<SOL>-Solution.pdf`, `<SOL>-Scripts.zip` — the
**downloadable deliverables** attached to the products. (The compiler reads `sol_code`/`title`/
`version`/`created` from `solution.meta.json`; it honors the `source\` ordering in the script's
`SOURCE_ORDER`.) If the compiler libs are missing: `python -m pip install python-docx reportlab`.

### 3b. Product hero image
Author `listing\hero.json` (title_lines using the **solution title** in the 3-color split;
`from` card; `to` card; four `benefits` with icons from build-hero's library: shield, fingerprint,
chip, cloud, lock, key, chart, gear, device, users). Then render:
```
python tools\build-hero.py --solution-dir "library/<category_slug>/<slug>/v<version>"
```
Produces `deliverables\<SOL>-hero.svg` + `<SOL>-hero.png` (1200×1200, via headless Edge/Chrome).
Record `"hero": "<SOL>-hero.png"` in `solution.meta.json`. The hero is the product's base image.
Image rules (enforced by build-hero.py): the **solution title always fits** — the title font
auto-shrinks to keep ≥15px clear space from the border; the background imagery is **seeded per
solution** so each product looks a little different, while solutions in the **same category share a
palette** (cohesive). To refresh the image on an already-published product, regenerate then
`pwsh tools\refresh-image.ps1 -Slug <slug>` (loader `--replace-images`).

## 4. Pricing (apply `pricing.md`) — THREE tiers, effort-scaled anchor
- **Set the Commercial anchor from the Effort & Complexity Scale in `pricing.md`** (T1–T5 by
  work/effort · #technologies · complexity). Don't guess: pick the tier the solution truly lands in
  and choose a point in its band. **Monotonicity:** price **≥ the most-similar prior solution of
  equal-or-lower effort**; if this solution is clearly more work than the last generated, move up a
  band. **Record the chosen tier** in `author_notes` (e.g. `"pricing: T4 — multi-phase migration"`).
- **Non-Profit** = `round(commercial * 0.60, 2)` (40% off). **Government** = `round(commercial *
  0.85, 2)` (15% off).
- Subscriptions are NOT generated here (account-wide; see `catalog/`).

## 5. Emit the contract → `…\v<version>\listing\bagisto-products.json`
Conform to `schema/bagisto-products.schema.json`. **Three products** (`commercial`, `nonprofit`,
`government`), `type: downloadable`, all sharing the same downloads + image. `downloads[].source` =
**bare deliverable filenames** (e.g. `WHFB-Solution.pdf`) — publish co-locates them with the JSON on
the server. Set
`"image": "<SOL>-hero.png"` on **all three** products (the generated hero → product base image).
Each product needs its own `url_key` (default `<slug>-<audience>`, e.g. `…-commercial`,
`…-nonprofit`, `…-government`).

**Sales content must be detailed, vibrant, and persuasive** (see `tools/enrich-descriptions.py` for
the canonical template + tone). Every commercial `description` includes, in this order:
1. A compelling **`<h3>` hook** (the transformation) + a vivid problem paragraph.
2. **"Run it yourself — simpler, cheaper, and proven"** — the core value: you do NOT need a consultant;
   the package is **self-guided, click-by-click documentation** a novice admin can follow end-to-end,
   plus tested PowerShell scripts. Three bullets: **Simpler** (exact ordered steps, click-to-implement),
   **Cheaper** (one fixed price vs an open meter; comparable consulting runs ~$1,500–$3,000/day),
   **Tested** (pilot-first Assess→Configure→Pilot→Validate→Expand with validation scripts + pass/fail gates).
3. **What's inside** (the docs + 5 scripts, richly phrased).
4. **The Phoenixtekk way** (repeatable model; buy once, unlimited devices) — **only when `Brand: on`**.
   When **unbranded** (default, §0c), title this block **"The repeatable way"** and omit the company name.
5. **The bottom line** (outcome) + the delivery line.

The NPO description swaps in a condensed "Run it yourself — and stretch every dollar" block (40% off
+ eligibility note). The **Government** description swaps in a condensed block (15% off + a line that
covers public-sector/GCC realities + eligibility note: verification of government/public-sector status
required). Both discounted tiers note that **eligibility is verified** before the discount applies
(see `ADMIN_DOCS.md` → eligibility validation). Keep it honest and specific. Mirror the value in
`listing\sales-content.md`.
For the existing catalog, `tools/enrich-descriptions.py` regenerates all 12; publish with the loader's
`--update-content` (which re-styles HTML **and re-attaches downloads + image** — never run a bare
content update, as Bagisto's `update()` drops relations not in the payload).

## 6. Write metadata, summary, pointer, and shelf copy
- `…\v<version>\solution.meta.json`:
```json
{
  "slug": "<slug>", "title": "<Title>", "category": "<Category>", "category_slug": "<category_slug>",
  "sol_code": "<SOL>", "version": "<version>", "status": "generated",
  "created": "<YYYY-MM-DD>", "updated": "<YYYY-MM-DD>", "published_at": null,
  "version_directive": "New | +1 | default:+1",
  "branding": "off",
  "author_notes": [],
  "products": [
    { "sku": "PTK-<SOL>-COMM-001", "audience": "commercial", "price": 0.00 },
    { "sku": "PTK-<SOL>-NPO-001",  "audience": "nonprofit",  "price": 0.00 },
    { "sku": "PTK-<SOL>-GOV-001",  "audience": "government",  "price": 0.00 }
  ],
  "deliverables": ["<SOL>-Solution.pdf", "<SOL>-Scripts.zip"]
}
```
(Use today's date from the environment context. Fill real prices. `author_notes` = the verbatim
shaping note(s) from §0a, or `[]` if none. `version_directive` = the resolved §0b directive
(`"New"`, `"+1"`, or `"default:+1"` when none was given) — for traceability/reproducibility.
`branding` = the resolved §0c directive (`"off"` default / white-label, or `"on"`) — the compilers
read this to decide whether to stamp the company name on the deliverables + hero.)
- `…\v<version>\README.md` — one-glance summary (title, category, version, SKUs, prices, what's
  included, file list). If a shaping note was given (§0a), add a **Shaping notes** line recording it.
- `library\<category_slug>\<slug>\LATEST.txt` — single line: `v<version>`.
- **Deliverables shelf:** copy the `deliverables\` files to `library\_deliverables\<slug>\`.

## 7. Validate + index + hand off
- Re-validate `listing\bagisto-products.json` against the schema; confirm `nonprofit.price == round(commercial.price*0.60,2)`; confirm each `downloads.source` exists in `deliverables\`.
- **Rebuild the index:** run `pwsh library\_index\rebuild-index.ps1` (regenerates `INDEX.html` + `INDEX.md` + `registry.json`).
- Update root `FEATURES.md` (solution authored).
- Tell the user: **"Authored `library\<category_slug>\<slug>\v<version>\`. Open `library\_index\INDEX.html` to review. Then run `/publish-solution <slug>`."**
