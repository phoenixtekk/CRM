# Executive Summary — Custom Sensitive Information Types (Microsoft Purview)

Microsoft Purview ships hundreds of built-in sensitive information types — but they only recognize data
whose format is *standard*. They do **not** recognize the identifiers unique to **your** organization:
your employee IDs, customer/account numbers, case and matter numbers, part numbers, contract IDs, and
project codenames. Until those patterns are taught to Purview, every DLP, auto-labeling, retention,
Insider Risk, and DSPM control that keys off classification is **blind to your most organization-specific
data** — a compliance gap and a data-risk exposure hiding in plain sight.

This solution closes that gap. It delivers **custom sensitive information types** end to end — built from
**regex**, **keyword lists/dictionaries**, **supporting evidence**, **character-proximity**, and
**confidence levels** — then **validates** each one against known **positive and negative** samples,
pilots it inside a consuming policy in **simulation/test**, tunes it for precision, and enforces and
reuses it across the tenant. It uses only the **Microsoft Purview portal**, **Security & Compliance
PowerShell**, and **Microsoft Graph** — no third-party tooling — and is written for a competent Microsoft
365 / compliance administrator working **with** the data owner.

## What you get
- A plain-language **Solution Overview** of custom SITs — the building blocks (primary element,
  supporting evidence, character proximity, confidence levels), how a SIT is *reused* across DLP,
  labeling, retention, Insider Risk, and DSPM, and the crucial distinction that a **SIT detects, it does
  not act**.
- A **Requirements Guide** with verify / implement-if-missing for every prerequisite: the identifier's
  exact format, curated **positive and negative** samples, the SIT-management role, the PowerShell/Graph
  toolchain, the primary-element and confidence design, the data owner, and a consuming policy with a
  pilot scope.
- An **Implementation Guide** that designs the detector, builds it (portal *or* rule-package XML),
  **validates it against samples** (the precision gate), pilots it in a **simulation** policy on real
  content, tunes it, and only then enforces and expands — with pass/fail gates and rollback at every step.
- **Five PowerShell tools** (Security & Compliance PowerShell / Graph): a discovery/inventory script, a
  rule-package import helper, a **`Test-DataClassification`-based validation** script that scores the SIT
  against positive/negative samples, a where-used report, and a rule-package export/update helper —
  **read-only or `-WhatIf` by default, no secrets**.
- **Testing** and **Best Practices** that prove precision on positives *and* look-alikes before anything
  enforces.

## Why it matters
- **The gap is real and unmonitored.** The data that is most proprietary — your own identifiers — is
  exactly the data no built-in SIT can see. Custom SITs are the only way to bring it under Purview.
- **Precision is the value.** A loose SIT floods DLP with false positives and trains users to ignore
  warnings; a tight one misses the leak. This solution tunes to **usable precision**, proven on real
  samples, not guesswork.
- **Build once, reuse everywhere.** A single well-built custom SIT sharpens every downstream classifying
  policy — DLP, auto-labeling, retention, Insider Risk, Communication Compliance, DSPM.
- **Pilot-first, always.** A SIT feeds high-impact policies; the consuming policy is validated in
  **simulation/test** on real content before it ever enforces.

## The bottom line
Your organization's **unique identifiers detected in Microsoft Purview** — configured, validated against
positive and negative samples, piloted, and tuned for precision — a reusable, defensible detector that
makes every data-protection control sharper. A fraction of the cost of a consulting engagement,
self-guided and tested.

*The capabilities that consume custom SITs (advanced DLP, auto-labeling, Insider Risk, DSPM) are
licensing-dependent (Microsoft 365 E5 / E5 Compliance; some in preview) and the Purview portal,
rule-package schema, and cmdlets evolve; verify capability availability and portal paths against your own
licensing and tenant. Whether detected data drives retention, records, or legal actions is deferred to
your compliance, records, and legal functions.*
