# 1. Solution Overview — Sensitive Information Types Implementation (Microsoft Purview)

## What this solution is
Every data-protection control in Microsoft Purview — DLP, auto-labeling, retention, insider risk, DSPM,
Communication Compliance — keys off the same underlying question: *does this content contain sensitive
data, and how confident are we?* The answer comes from **sensitive information types (SITs)** — the
pattern-based classifiers Purview uses to recognize credit-card numbers, national IDs, health identifiers,
bank account numbers, and hundreds of other data patterns. Microsoft ships a large, growing library of
**built-in SITs** (verify the current count in your tenant), each with a tested regex/checksum pattern,
**supporting keyword/format evidence**, and defined **confidence levels**.

This solution is a repeatable, evidence-driven way to **select the right built-in SITs for your in-scope
data categories, test them against representative sample content, and tune how they are applied** —
confidence level and instance count — so the detection layer is accurate *before* it drives any policy.
It uses only the **Microsoft Purview portal**, **Security & Compliance PowerShell**
(`Connect-IPPSSession`), and **Microsoft Graph** — no third-party classification tooling. Its defining
discipline is that SIT accuracy is **measured** (in the portal Test experience and in a DLP policy run in
**SIMULATION mode**) and **tuned for a low false-positive rate**, not assumed.

> **Scope boundary.** This solution delivers the **technical method and evidence** for selecting, testing,
> and tuning **built-in** SITs. *Which* data categories are in scope, *which* SITs legally satisfy a
> regulation, and the *acceptable* false-positive threshold are **business, compliance, privacy, and legal
> determinations** — deferred to those functions. Building **custom** SITs, **Exact Data Match**, and
> **trainable classifiers** for gaps built-in SITs can't cover are adjacent solutions; here we get the
> built-in library right first.

## Why this matters
- **Built-in SITs are the fastest path to coverage** — a large tested library exists out of the box, so
  most common data categories (payment cards, SSNs/national IDs, IBANs, health record numbers) are already
  covered without authoring anything. Selecting well beats building custom.
- **The default confidence and instance count are where accuracy is won or lost.** A built-in *Credit Card
  Number* SIT firing at a single low-confidence match on internal reference numbers trains users to ignore
  every alert. Choosing **High confidence** and a realistic **instance count** is the single biggest
  false-positive lever — and it costs nothing to change.
- **You cannot edit a built-in SIT's pattern — but you can test it and tune its use, and copy it to tune
  further.** Purview lets you **create an editable copy** of a built-in SIT when the shipped one
  over/under-matches your data; knowing when to reach for that (versus just raising confidence/instance
  count) is the skill this solution teaches.
- **The same SIT selection drives the whole Purview estate.** Get the built-in SIT layer accurate here and
  DLP, auto-labeling, retention, and insider risk all inherit trustworthy detection.

## How it works
1. **The built-in SIT library defines what Purview can detect.** Each built-in SIT is a tested pattern
   (regex + checksum where applicable) plus **supporting evidence** (keywords, proximity, format) and
   **confidence levels** — **Low / Medium / High** (surfaced numerically as roughly **65 / 75 / 85**). A
   higher confidence level means more corroborating evidence was found, so fewer false positives.
2. **Selection** maps each in-scope data category to the built-in SIT (or small set of SITs) that detects
   it — reusing built-in wherever it fits, flagging only genuine gaps for the custom/EDM/trainable
   solutions.
3. **Testing** proves each selected SIT actually detects your representative sample content and does **not**
   fire on look-alike non-sensitive content — using the portal **Test** experience (upload a file, see
   matches + confidence) and, at scale, a **DLP policy run in SIMULATION** against real traffic.
4. **Tuning** adjusts *how the SIT is used* — the **confidence level** and **instance count (min/max)** it
   triggers at — measured against the test/simulation results, to drive the false-positive rate down while
   keeping true positives. Where the shipped SIT still over/under-matches, an **editable copy** of the
   built-in SIT is tuned (supporting keywords, proximity, confidence).
5. **Validation** confirms, against explicit pass/fail gates, that each category's SIT detects the true
   positives, rejects the negatives, and sits at/under the agreed false-positive rate.
6. **Adoption** hands the tuned, validated SIT selection to the downstream controls (DLP, auto-labeling,
   retention) with a documented **threshold register** so every policy uses the same settings.

## Confidence levels & instance count (the two tuning dials)
- **Confidence level (Low/Medium/High).** How much corroborating evidence Purview found. **Start at High**
  for most categories — it requires the strongest evidence (correct format *plus* checksum *plus* nearby
  keywords) and dramatically cuts false positives. Lower only when High misses true positives you can prove
  are real.
- **Instance count (min / max).** How many distinct matches must appear in one item to trigger. A single
  card number is noise; **ten in one file** is a likely bulk leak. Raising the minimum instance count
  focuses detection on exfiltration-shaped events and cuts single-hit false positives.
- These two dials are set **per use** (per DLP rule / auto-label rule) — the built-in SIT is shared, but
  each policy chooses the confidence and instance count. This solution records them once in a **threshold
  register** so every downstream policy is consistent.

## Where selected SITs are consumed (why accuracy compounds)
- **Data classification → Content explorer / Activity explorer** — see *where* SIT-matched content lives and
  *what* is happening to it (requires the Content Explorer roles).
- **Data Loss Prevention** — SITs as rule conditions across email, cloud, Teams, endpoint.
- **Auto-labeling** (sensitivity and retention) — apply labels automatically where a SIT matches.
- **Insider Risk, Communication Compliance, DSPM** — SIT signals feed risk and posture.
> One accurate SIT selection here is inherited by all of the above — which is why testing and tuning the
> built-in layer first pays off across the estate.

## Naming convention (used in every doc and script)
Every artifact this solution creates uses a consistent name, reused verbatim across the docs, scripts, and
the Purview portal. The standard set:

| Artifact | Name |
|---|---|
| Category → SIT map (register) | `SIT Selection Register` |
| Confidence/instance settings record | `SIT Threshold Register` |
| Test corpus (fake sample data) | `SIT Test Corpus – <Category>` |
| Measurement DLP policy (simulation) | `SIT Measure – <Category> – Simulation` |
| Editable copy of a built-in SIT (only if needed) | `<Built-in name> – Tuned Copy – Classification` |
| Pilot user ring | `SIT Pilot Ring – Stage1` |

## Limitations (be honest with buyers)
- **You cannot change a built-in SIT's shipped pattern.** You tune its *use* (confidence, instance count)
  or create an **editable copy** to adjust supporting evidence — but the original built-in pattern is fixed.
- **Some SITs and testing features are licensing-/plan-dependent or in preview**, and the portal evolves —
  this solution flags **"verify your licensing/tenant"** rather than asserting availability or an exact
  library count that may differ in your tenant.
- **A SIT detects a *pattern*, not *meaning*.** A built-in number pattern will match any content in that
  format — which is exactly why testing and tuning against your real look-alike data matters. Categories
  that are conceptual rather than pattern-based (e.g. source code, contracts) need **trainable classifiers**,
  not a built-in SIT.
- **Which SITs legally satisfy a regulation, and the acceptable false-positive threshold, are
  compliance/legal determinations** — this solution configures and proves the detector; it does not make
  the determination.

## The standard deployment model
> **Assess** the built-in SIT library against your in-scope data categories → **Design** the category→SIT
> selection and target confidence/instance settings → **Configure** the test corpus and a **simulation**
> measurement policy → **Pilot** (test → measure → tune) → **Validate** against pass/fail gates (true
> positives detected, negatives rejected, false-positive rate ≤ threshold) → **Expand** by handing the
> validated selection + threshold register to the downstream controls. Every measurement is done in the
> portal Test experience or in **simulation** first — no enforcement is introduced by this solution.
