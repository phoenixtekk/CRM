# Documentation Validation Learning Loop — Run Report (2026-06-25)

**Scope:** Workplace Marketplace solution docs (CLAUDE.md §6).
**Solutions scanned:** 20 · **Human corrections detected:** 1 · **Applied:** 1 · **Remaining after run:** 0

## Correction processed

### `ios-iphone-shared-device-mode` — `03-implementation.md`, Step 9
**Human edit (Lee Lacy, on Wiki.js):** corrected the Cisco Webex store-app identification when adding
the app in Intune.

- **Before:** search **Webex** (publisher **Cisco**)
- **After:** search **Webex** (publisher **Cisco Systems, Inc.** — bundle ID `com.cisco.squared`,
  *not* 'Webex Meetings')

**Classification:** solution-specific fact **+** generalizable authoring rule.

**Actions taken (loop closed):**
1. Synced the fix into `source/03-implementation.md` (Step 9).
2. Rebuilt deliverables (`build-deliverables.py`) — `IOSSDM-Solution.pdf` (50,195 B), `.docx`, `IOSSDM-Scripts.zip`.
3. Bumped `solution.meta.json` `updated` → 2026-06-25.
4. Redeployed to linuxg5: DB backed up (`workplace-20260625-170013.sql`, 767 KB), updated PDF/ZIP/JSON
   copied into `/home/workplace/public_html/solutions/ios-iphone-shared-device-mode/`, loader
   `--purge` (SKUs 64/65) then reload → CREATE both SKUs (+2 downloads +image, new IDs 71/72),
   `artisan indexer:index` + `optimize:clear`.
5. Security verified: paid PDF/ZIP live on the **private** disk only; public URLs
   `…/storage/product_downloadable_links/71|72-IOSSDM-*.pdf|zip` → **404** (correct). Both SKUs
   enabled in `product_flat`, priced 1995 / 1197.
6. Republished the wiki page (`publish-wiki.py`) → UPDATE OK; learning baseline
   `wiki-baselines/ios-iphone-shared-device-mode.md` rewritten with the correction.

**Generalizable lesson added** to `AUTHORING_LESSONS.md` → Intune Solutions · Naming & objects
([2026-06-25] store-app): identify any store app by its **exact publisher name + bundle/package ID**
and disambiguate from similarly-named apps.

## Verification
Re-ran the detector after applying — **"Human-edited since last run: 0 / No new human corrections."**
The loop self-terminated for this page (wiki content now equals the rewritten factory baseline).

## Proposed SKILL change (HUMAN APPROVAL REQUIRED — not applied)
This correction is **high-impact** (selecting the wrong store app silently breaks the entire kiosk
lock-down), generalizes to **any** solution that deploys a specific managed store app, and complements
the existing "Always name the object you create" house-style rule. **Proposed** addition to
`generate-solution` SKILL §1 (Authoring standard), as a sibling bullet after "Always name the object
you create":

> - **Always identify a store app you deploy by exact publisher + bundle/package ID.** When a step
>   adds an app from the iOS/iPadOS App Store or managed Google Play, give the **exact store publisher
>   string** and the **bundle/package ID** (e.g. *publisher `Cisco Systems, Inc.`, bundle ID
>   `com.cisco.squared`*), and **disambiguate** it from similarly-named apps (e.g. *not 'Webex
>   Meetings'*). Store search returns multiple near-identical results; the exact publisher + ID is
>   what guarantees the admin selects — and kiosk-locks to — the right app.

Per CLAUDE.md §6, the source-sync + lessons-append above are automatic; **this SKILL house-style edit
is withheld pending owner approval.**
