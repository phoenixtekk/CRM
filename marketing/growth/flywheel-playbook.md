# The Answer→Product Flywheel — operating playbook

Your unfair advantage: **a real practitioner question → an authoritative answer → a productized runbook
(existing or built in a day).** This document turns that from an ad-hoc thing you do into a weekly
machine. It already produced SRCANCHOR (source anchor) and CLDSYNCDX (cloud sync JoinNotFound) from live
forum questions.

## The loop (repeat weekly)
1. **Source questions (30 min).** Scan where your buyers ask, tagged by product area:
   - Reddit: r/Intune, r/entra, r/sysadmin, r/AZURE, r/msp
   - Microsoft Q&A (learn.microsoft.com/answers) + Microsoft Tech Community (Intune / Entra / Purview)
   - Spiceworks, the "Microsoft Intune" / "MEMCM" Discord & Slack communities, LinkedIn posts/comments
   - Your own `/create` queue (`create-queue.jsonl`) and `/start` leads — real demand, already yours
   Pick **3–5** that are (a) specific, (b) recurring, (c) map to Intune/Entra/Purview/Defender/Network.
2. **Triage against the catalog.** Run `python tools/flywheel-intake.py` (below) or
   `python tools/triage-ask.py --ask "<the question>"`:
   - **Covered** → you already have the product. Answer + soft-link the runbook.
   - **Partial / New** → it's a build candidate. Answer the question well now; queue the build.
3. **Answer publicly, help-first.** Post the best answer you can — ranked causes, exact steps, the fix.
   No hard sell. End with a soft, honest line: *"I wrote the full click-by-click runbook + scripts up
   here"* (link the store product or `/create`). Being the person who reliably solves it earns the click.
4. **Productize new ones (same/next day).** Run `/generate-solution` on the topic (the factory does the
   authoring), then `/publish-solution`. The "built in 1 day" promise is real because this pipeline is real.
5. **Repurpose the answer** into a LinkedIn post + a short demo (see `linkedin-playbook.md`). One answer =
   one product + one post + one video. Never write anything once.
6. **Capture the lesson.** If the answer corrected a doc, add it to `library/_index/AUTHORING_LESSONS.md`
   so the factory gets smarter (you did this for the cloud-sync watermark fix).

## Community answer template (paste, then fill)
> **TL;DR:** <one-line fix>.
>
> What's happening: <the mechanism, in 1–2 sentences — show you understand it>.
>
> Work through these in order:
> 1. <most likely cause> → <how to check> → <fix>
> 2. <next cause> …
> 3. <read the authoritative signal, e.g. the provisioning log by ObjectGuid>
>
> Most likely for your case: <the specific one given their details>.
>
> *(I wrote the full step-by-step + scripts for this exact scenario here: <link>. Happy to help debug
> if it still repros.)*

## Guardrails
- **Help first, sell never-directly.** Link-dropping is spam and gets you banned. Value earns the click.
- **Disclose** you're the author of the linked runbook. Communities reward honesty, punish astroturf.
- **One link max**, and only when it genuinely adds the full detail your comment can't.

## Metrics
- Track each answer's link with `?src=<community>` (reddit/msqa/techcommunity/linkedin) → your
  `tools/leadgen-digest.py` already reports arrivals→leads→conversion per source, so you learn which
  community actually converts and spend time there.
- Weekly scoreboard: questions answered · products linked · new products built · leads by source.

## The 20-minute daily version (if weekly feels big)
Answer **one** question a day, well. 5/week compounds fast — 250 authoritative answers a year, each a
permanent SEO + credibility asset, each a soft funnel into a catalog that already has the fix.
