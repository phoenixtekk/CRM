# 1. Solution Overview — Custom Sensitive Information Types (Microsoft Purview)

## What this solution is
A **sensitive information type (SIT)** is the pattern-matching classifier Microsoft Purview uses to
recognize a category of sensitive data — a credit-card number, a national ID, a health record — inside
files, email, chats, and endpoints. Purview ships **hundreds of built-in SITs**, but they only cover
data whose format is *standard*. They do **not** recognize the identifiers that are unique to **your**
organization: your **employee ID** format, your **customer/account number** scheme, your **project
codenames**, your **internal case/matter numbers**, your **part numbers**, or your **contract IDs**.
Until those patterns are taught to Purview, every DLP policy, auto-labeling policy, retention rule,
Insider Risk indicator, and Copilot/DSPM signal that keys off classification is **blind to your most
organization-specific data**.

This solution delivers **custom sensitive information types** end to end: it defines each org-specific
identifier as a SIT built from a **primary element** (a **regex** pattern, a **keyword list**, or a
**keyword dictionary**), optional **supporting elements** (corroborating keywords/regex found within a
**character-proximity** window), and one or more **confidence levels** (low / medium / high) — then
**validates** the SIT against known **positive and negative** samples, pilots it by attaching it to a
DLP or auto-labeling policy in **simulation/test mode**, tunes it for precision, and only then enforces
and expands. It uses only the **Microsoft Purview portal** (`https://purview.microsoft.com`),
**Security & Compliance PowerShell** (`Connect-IPPSSession`), and — for usage reporting — **Microsoft
Graph**. No third-party tooling.

> **A custom SIT is a *detector*, not an *action*.** Creating a SIT does not, by itself, block,
> label, retain, or alert on anything — it only makes the pattern *available* to reference in a DLP
> policy, an auto-labeling policy, a retention rule, a Communication Compliance / Insider Risk
> condition, or DSPM. This solution builds and validates the **detector**; the enforcement action is
> configured in whichever policy consumes it (and that policy is piloted in **simulation/test** first).

## Why this matters
- **Built-in SITs miss org-specific data.** Your employee IDs, account numbers, and project codenames
  don't match any standard SIT, so the data that is arguably *most* proprietary is the data Purview
  can't see — an unmonitored compliance gap and data-risk exposure.
- **Precision is the whole game.** A SIT that's too loose floods every downstream DLP policy with
  **false positives** (blocking legitimate work, training users to click through warnings); a SIT
  that's too tight has **false negatives** (the leak it existed to catch walks straight past). The
  value of this solution is a SIT tuned — with real positive/negative samples — to the **confidence
  level** that gives usable precision.
- **One detector, many uses.** A single well-built custom SIT is reused across **DLP** (endpoint,
  email, SharePoint/OneDrive, Teams, cloud), **auto-labeling**, **retention**, **Insider Risk**,
  **Communication Compliance**, and **DSPM** — build it once, correctly, and every capability that
  classifies data gets sharper.
- **It must be piloted, never switched on blind.** Because a SIT flows into high-impact policies, the
  house model applies: validate the detector, run the consuming policy in **simulation/test**, confirm
  precision on real content, then enforce and expand.

## How it works
1. **Discover the identifier and its format.** With the data owner, pin down the exact pattern of the
   org-specific identifier — its structure (prefix, length, digits/letters, check character, delimiters)
   and the words that appear *near* it in real documents ("Employee ID:", "Account #", "Matter No.").
2. **Design the SIT.** Choose the **primary element**: a **regex** for structured identifiers, a
   **keyword list** for a small fixed vocabulary, or a **keyword dictionary** for a large term set.
   Add **supporting elements** (corroborating keywords or a second regex) and a **character proximity**
   window so a bare number in the wild doesn't match but "Employee ID: EMP-123456" does. Assign
   **confidence levels** (High/Medium/Low = 85/75/65) reflecting how much corroborating evidence each
   pattern requires.
3. **Create the SIT.** In the Purview portal (**Data classification → Classifiers → Sensitive info
   types → Create**) or by importing a **rule package XML** via Security & Compliance PowerShell
   (`New-DlpSensitiveInformationTypeRulePackage`). Artifact: `Custom SIT – <Identifier> – Pilot`.
4. **Validate against known samples.** Before trusting it, test the SIT against a curated **positive**
   set (content that *should* match) and a **negative** set (look-alike content that must *not* match)
   using **`Test-DataClassification`** — measuring true/false positives and the confidence returned.
   This is the precision gate.
5. **Pilot in a consuming policy in SIMULATION/TEST.** Reference the validated SIT from a DLP policy
   (or auto-labeling policy) run in **simulation / test / disabled** mode over a limited scope — see
   what it *would* have caught on real traffic, without blocking anything.
6. **Tune for precision.** Adjust the regex, supporting evidence, proximity, and confidence threshold
   used in the policy until false positives are acceptable and true positives are still caught. Re-run
   validation after each change.
7. **Enforce and expand.** With sign-off, move the consuming policy from simulation to **enforce** and
   widen scope; reuse the same SIT in other policies (retention, auto-label, Insider Risk). Maintain
   the SIT as the identifier format evolves.

## The building blocks of a custom SIT
| Element | What it is | When to use |
|---|---|---|
| **Primary element — Regex** | A regular expression matching the identifier's structure | Structured IDs: employee/account/case/part numbers, contract IDs |
| **Primary element — Keyword list** | A fixed set of exact terms | Small, stable vocabulary (a handful of codenames) |
| **Primary element — Keyword dictionary** | A large managed term set (up to very large) | Big lists (product SKUs, drug names, all project codenames) |
| **Supporting element** | Extra keywords/regex that must appear *near* the primary match | Corroboration to cut false positives (e.g. the label "Employee ID" near the number) |
| **Character proximity** | The window (default **300** characters) in which supporting evidence must appear | Ties the number to its context so a random number doesn't match |
| **Confidence level** | **High (85) / Medium (75) / Low (65)** per pattern | Higher confidence = more corroborating evidence required = fewer false positives |
| **Recommended confidence** | The default confidence a consuming policy uses | Set to the level your validation proved precise |

## What you can control
- The **identifier(s)** turned into custom SITs and each one's **primary element** (regex / keyword
  list / dictionary).
- The **supporting evidence** and **character-proximity** window that corroborate a match.
- The **confidence levels** defined and the **recommended** level consuming policies default to.
- The **positive/negative validation sample sets** the SIT is proven against.
- Which **DLP / auto-labeling / retention / Insider Risk** policy consumes the SIT — and that it runs
  in **simulation/test first**.
- The **pilot scope** validated before any enforcement.

## Limitations (be honest with buyers)
- **A SIT detects; it does not act.** Blocking, labeling, retaining, and alerting are configured in the
  **consuming policy**, not the SIT. This solution builds and validates the detector and pilots it via
  a consuming policy; the enforcement decision lives in that policy.
- **Pattern matching is probabilistic.** Regex and keyword matching produce false positives and
  negatives; the confidence level trades one against the other. There is no "perfect" regex — the goal
  is **usable precision**, proven on samples, not theoretical completeness.
- **Licensing-dependent downstream.** Creating custom SITs is broadly available, but the capabilities
  that *consume* them (advanced DLP, auto-labeling, Insider Risk, DSPM) are often **E5 / E5 Compliance**
  and some are in preview. **Verify availability against your own licensing and tenant** — do not assume
  a consuming capability is present.
- **Rule-package / cmdlet detail evolves.** Portal paths, the rule-package XML schema, and the
  `DlpSensitiveInformationType*` / `Test-DataClassification` cmdlets are current to Microsoft's public
  docs but **evolve** — verify against your tenant before relying on an exact path or parameter.
- **Publishing takes time.** A new or changed SIT can take time to become fully available to policies
  and to appear in classification results; validate patience into the pilot.
- **No secrets in automation.** The provided scripts use interactive modern-auth sign-in and never
  embed credentials.

## Naming convention (used in every doc and script)
Every artifact this solution creates is named `<Purpose> – <Scope> – <Stage>` and reused verbatim
across the docs, scripts, and portal. The standard set (running example: an **Employee ID** identifier):

| Artifact | Name |
|---|---|
| Custom SIT (pilot) | `Custom SIT – Employee ID – Pilot` |
| Custom SIT rule package | `Custom SIT Rule Package – Pilot` |
| Positive validation sample set | `Custom SIT Test – Positive` |
| Negative validation sample set | `Custom SIT Test – Negative` |
| Validation result report | `Custom SIT Validation – Report` |
| SIT inventory / evidence snapshot | `Custom SIT Inventory – Evidence` |
| Consuming DLP policy (simulation) | `Custom SIT DLP – Simulation` |
| Consuming DLP policy (enforced) | `Custom SIT DLP – Enforce` |

## The standard deployment model
> Discover the identifier + its format → design the SIT (primary element, supporting evidence,
> proximity, confidence) → create it → **validate against positive/negative samples** → pilot it in a
> consuming policy in **simulation/test** → tune for precision → enforce and expand (reuse across
> policies) → maintain.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce)** — with
> pass/fail gates and rollback, and regulatory/records/legal determinations deferred to the relevant
> governance functions.
