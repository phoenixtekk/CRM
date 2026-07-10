# Job-Board Lead-Gen Engine — Strategy, Attribution & Deployment

**Goal:** use job-board postings (Dice first, then LinkedIn/Indeed/etc.) as *lead generation*. A
browsing VP / IT Director / CISO reads a keyword-dense **productized-service profile**, clicks through to
a **tracked landing page** on the Workplace, and either browses 380+ solutions or uses the
**"Ask for it — built in 1 day"** intake form. Every arrival and every lead is attributed to the board it
came from and lands in the CRM.

---

## 1. Assets in this folder
| File | Use |
|---|---|
| `dice-profile-paste.md` | Copy/paste blocks for Dice's Title / Summary / Skills fields (productized-service framing). |
| `workplace-marketplace-resume.docx` / `.pdf` | The uploadable résumé (branded). Same content, two formats. |
| `workplace-marketplace-resume.md` | Editable source for the résumé. |
| `landing/index.html` | The tracked landing page (product wall + AI-chatbox intake form). |
| `landing/lead-endpoint.php` | Backend: pageview logging + lead → email + Dolibarr prospect. |

## 2. Attribution model — one tagged link per board
Point every board at the **same** page with a distinct tag. The page reads the params, stamps them on
the form, and beacons the arrival:

| Board | Link to paste in the posting/profile |
|---|---|
| Dice | `https://workplace.phoenixtekk.com/start?src=dice&utm_source=dice&utm_medium=jobpost&utm_campaign=leadgen` |
| LinkedIn | `…/start?src=linkedin&utm_source=linkedin&utm_medium=jobpost&utm_campaign=leadgen` |
| Indeed | `…/start?src=indeed&utm_source=indeed&utm_medium=jobpost&utm_campaign=leadgen` |

**What's captured:**
- **Every arrival** (even no form fill) → `pageviews.jsonl`: source, UTM, referrer, path, IP, user-agent, timestamp. This is your "who visited, from where" signal.
- **Every lead** (form submit) → email to **admin@phoenixtekk.io** + a **Dolibarr prospect** (tagged with the source) + a `leads.jsonl` never-lose copy.
- Store links on the page **carry `?src=` through** to workplace.phoenixtekk.com so store-side analytics also see the board.

> Privacy note: you can identify *the visit* (source/IP/UA/referrer) but not *the person* until they
> submit. That's the honest ceiling without login. The form is where anonymous → known.

## 3. The intake form (your spec, refined)
- Name + Work email, then the **"Describe the solution you want"** field rendered as an **AI chatbox**
  (`border-radius: 30px`, glow on focus, round send button).
- Ghost example prompt shows how to write the ask:
  *"I want to enroll iOS Shared iPhones, COD and BYOD devices using ADE with MFA enforcement for Enrollment"* — disappears once they type.
- Banner: **"Can't find what you need? Ask for it — we'll build it in 1 day."**
- Spam defense: hidden honeypot field + IP rate-limit (5/10 min) in the endpoint.

## 4. Improvements worth adding (recommended)
1. **Per-board landing variants** — same page, `?src=` already does it; optionally swap the hero headline per board with `?msg=`.
2. **"Build in 1 day" as a real SLA** — auto-reply email to the lead ("We received your ask; you'll hear back within 1 business day"), and an internal timer/label in Dolibarr so the promise is tracked, not just claimed. (The factory genuinely can author a new solution in ~a day, so this is credible — don't over-promise scope.)
3. **Feed the ask into the factory** — a qualified ask like the ADE example is literally a `/generate-solution` topic. Triage: is it already in the 384-catalog? If yes → send the product link; if no and it's viable → build it, then reply with the new listing. This closes the loop the résumé promises.
4. **Weekly attribution digest** — a small script tailing `pageviews.jsonl` + `leads.jsonl` grouped by `src` tells you which board actually converts, so you spend posting effort where it pays.
5. **Retarget/measure at the store** — add the same `src` to a UTM on the store so you can see which board's visitors actually purchase.
6. **A/B the CTA** — try "Book a 15-min build review" vs. "Ask for it" to see which converts higher-intent C-levels.

## 5. Compliance / positioning guardrail
Dice is a job-seeker platform; a **transparent productized-service** profile (what we built) is the
low-risk framing — it doesn't impersonate an individual employee. Keep it honest: it's a service/fractional
capability, the "experience" is the catalog, and the CTA is a real site. If any board's ToS disallows
service listings in candidate profiles, use their **employer/services** side or a sponsored post instead.

---

## 6. Deployment — what I need from you to go live
The page + endpoint are **built and ready**; putting them on `workplace.phoenixtekk.com/start` touches the
live store host (linuxg5) and needs a few decisions/secrets. Give me the go-ahead on these and I'll deploy
+ verify end-to-end:

1. **URL path** — confirm `workplace.phoenixtekk.com/start` (recommended) vs. a subdomain like `get.phoenixtekk.com`. (Subpath on the Laravel app needs a route/rewrite; a subdomain is cleaner but needs a Cloudflare DNS record you'd add.)
2. **Email delivery** — either (a) confirm I may reuse the store's existing SMTP (`MAIL_*` in the Bagisto `.env`) to send lead mail to **admin@phoenixtekk.io**, or (b) give me SMTP creds for a `leads@phoenixtekk.com` sender. Without SMTP the endpoint falls back to PHP `mail()`, which often lands in spam.
3. **Dolibarr** — confirm I may create a server-side `/home/workplace/.leadform.env` holding the existing Dolibarr API key (copied from `~/.claude/.dolibarr.env`) so the endpoint can create prospects. I'll verify a test lead appears in `crm.phoenixtekk.com` and is tagged by source.
4. **Cloudflare** — if we use a subdomain, you'll need to add the DNS record (I'll give you the exact value); a subpath needs no DNS change.

**Once you confirm**, deployment is: recon the vhost/docroot (read-only), place `index.html` + `lead-endpoint.php` under the chosen path, drop the `.leadform.env` (600), send a test pageview + test lead, confirm the email arrives at admin@phoenixtekk.io and the prospect appears in Dolibarr, then hand you the per-board links. Nothing goes live on the shared host until you say go.
