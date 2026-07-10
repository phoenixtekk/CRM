# /create — Self-Service Solution Generator (design + tiering)

**URL:** `https://workplace.phoenixtekk.com/create` — branded Phoenixtekk / Workplace, modern hero,
a single radius-30 chatbox. Visitors describe an outcome; the page **instantly triages** it against the
384-solution catalog and **queues a build** for anything new. This is the productized version of the
"Ask for it — built in 1 day" promise, and the destination for the **"Ask for a custom build"** button
on `/start` (which previously only scrolled to the form).

## The safe loop (why generation is queued, not fired live)
The `/generate-solution` factory writes files, runs build tools, and is a heavy AI process — it must
**never** be triggered directly by anonymous web input (cost, abuse, and quality risk). So `/create`:
1. **Instant triage** (client sees value immediately): scores the ask against `catalog-index.json` and
   shows the closest existing products with buy links + a verdict (`covered` / `partial` / `new`).
2. **Queues** the request to `create-queue.jsonl` + a Dolibarr prospect + emails admin & an auto-ack.
3. A **gated worker** (you in Claude Code, or a scheduled headless `claude` run like the existing
   `daily-learning-run.ps1`) pulls the queue, runs `tools/triage-ask.py`, and for approved *new* asks
   runs `/generate-solution` → `/publish-solution`, then notifies the requester with the listing.

So "auto-create" = **auto-triage + auto-queue + fast human/worker-gated build**, not an open firehose.

## Tiering — what a customer gets over an anonymous visitor
**Recognition (SHIPPED — v2, spoof-proof):** tier is decided by a **real logged-in store session**, not
a typed email. `/create` calls the store route **`/api/me`** (Laravel `web`/`customer` guard); if the
visitor is a logged-in Bagisto customer it returns their identity plus a short-lived **HMAC-signed token**
(secret `CREATE_TOKEN_SECRET`, server-only). `/create` passes that token to `create-endpoint.php`, which
grants tier `customer` **only when the token's HMAC verifies and hasn't expired**. Typing someone else's
email does **not** unlock customer perks (verified: a customer email with no token resolves to `anon`).
> Superseded: the earlier v1 that matched the posted email against the `customers` table was removed —
> it was guessable. The token mechanism replaces it.

| Capability | Anonymous | **Customer (recognized email)** | Subscriber (future) |
|---|---|---|---|
| Instant catalog triage + links | ✅ | ✅ | ✅ |
| Requests / day | 3 | 15 | higher / unmetered |
| Build queue priority | standard | **priority flag** | top priority |
| Choose audience tier (Commercial/NPO/Gov) | — | ✅ | ✅ |
| Request **GCC High** variant | — | ✅ | ✅ |
| Saved request history / revisions | — | ✅ (tie to account) | ✅ |
| Delivered output | emailed listing link | listing **+ gated wiki + downloads** (existing purchaser gating) | + white-label copy (MSP) |
| SLA | ~1 business day | faster | fastest |

**Why this split works:** the anonymous tier gives instant value (triage) to hook the lead, then the
*upsell is the build itself* — "sign in / create a free account to get it built, delivered to your
account, with tier & GCC options." It converts browsers into store accounts.

### Anti-abuse (SHIPPED)
- **Spoof-proof tiering** via the signed `/api/me` token (above) — email alone can't claim customer tier.
- **httpOnly `wm_c` cookie + IP rate caps** on both `/start` and `/create` endpoints (anon `/create`:
  3/day per cookie AND per IP; leads: 5/10min). Honeypot field on every form. Client-side localStorage
  soft cap for instant UX feedback.
- Data (`create-queue.jsonl`, `leads.jsonl`) is stored **outside the web root**.

### Next hardening (optional)
- Email-verification (one-time code) before an anonymous build is queued, to stop throwaway-email spam.
- A scope/profanity filter on the ask before it reaches the worker.
- Token bound to a session-id claim so it can't be replayed from another browser.

## Improvements worth adding
1. **Credits/quotas as monetization** — customers get N free builds/month; extra builds or rush SLA are
   paid. Turns the generator into a revenue line, not just lead capture.
2. **Preview-before-build** — for `new` asks, the worker can return a generated **outline / table of
   contents** first ("here's what your solution will contain — approve to build"), improving quality and
   setting scope expectations.
3. **De-dup at triage** — `covered` verdict (score ≥ 0.5) auto-replies with the product link and skips
   the build queue, so you don't rebuild what exists (the gap-only discipline, automated).
4. **Abuse guardrails** — honeypot + per-day rate caps (shipped); add email-verification before a build
   is queued for anonymous, and a profanity/scope filter so only legitimate MSP/IT asks reach the worker.
5. **Attribution** — `/create` carries `?src=` too, so board-sourced generator requests are tracked
   alongside `/start` leads in the same `pageviews.jsonl` / `leadgen-digest.py`.
6. **Feedback to the factory** — every real ask is a signal of demand; periodically mine
   `create-queue.jsonl` for the most-requested missing topics and build those first.

## Files
- `create/index.html` — the branded generator page (chatbox r30).
- `create/create-endpoint.php` — triage + tier recognition + queue + Dolibarr + email/auto-ack.
- `tools/triage-ask.py` — builds `library/_index/catalog-index.json` and scores an ask (worker + local).
- Server data: `create-queue.jsonl`, `catalog-index.json` in `/home/workplace/leaddata/`.
