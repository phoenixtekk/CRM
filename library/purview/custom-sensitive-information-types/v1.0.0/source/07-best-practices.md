# 7. Best Practices — Custom Sensitive Information Types (Microsoft Purview)

- **Design the detector before you build it.** Pin down the identifier's exact format *and* the words
  that appear near it in real documents first. A SIT authored from a guessed pattern generates both
  false positives and false negatives; one authored from real samples doesn't.
- **Precision beats coverage.** A SIT that's too loose floods every downstream DLP policy with false
  positives and trains users to click through warnings — which is worse than not detecting at all. Tune
  for the confidence level that gives **usable precision** on real content, not maximal theoretical
  matching.
- **Always validate against negatives, not just positives.** Positives-only testing tells you the SIT
  can match; only a curated **negative / look-alike** set proves it won't over-match. Include hard
  negatives: numbers of the same length, the identifier stripped of its keyword, adjacent formats.
- **Use supporting evidence and proximity.** A bare regex on a number will match everything of that
  shape. Requiring a **supporting keyword within the character-proximity window** is what turns "any
  6-digit number" into "an Employee ID" — it's the single biggest precision lever.
- **Design confidence levels deliberately.** High (85) should require the primary match **plus**
  corroboration; reserve Low (65) for cases where the pattern alone is genuinely unambiguous. Set the
  **recommended** confidence to the level your validation proved, and have consuming policies use it.
- **A SIT detects — it never acts.** Keep the mental model clean: the SIT is the *detector*; blocking,
  labeling, retention, and alerting live in the **consuming policy**. Build/validate the detector here;
  configure the action there, and pilot that policy in **simulation/test first**.
- **Always pilot the consuming policy in simulation.** Reference the validated SIT from a DLP or
  auto-labeling policy run in **simulation/test** over a limited scope, watch what it *would* catch on
  real traffic, and only then enforce. Never point an enforcing policy at a brand-new SIT blind.
- **Always dry-run automation.** `CLSCUSTOM-Configuration.ps1` and `CLSCUSTOM-Set-Scope.ps1` default to
  **`-WhatIf`**. Read every planned line; run `-Commit` only after the validation gate passes.
- **Version and back up the rule package.** Keep the rule-package XML in source control and
  `CLSCUSTOM-Set-Scope.ps1 -Export` a backup before every change — so a bad edit is one restore away and
  you have a defensible history of the pattern.
- **Build once, reuse everywhere.** A well-tuned custom SIT is reused across DLP (endpoint, email,
  SharePoint/OneDrive, Teams, cloud), auto-labeling, retention, Insider Risk, Communication Compliance,
  and DSPM. Invest in one correct detector rather than many rushed ones.
- **Allow for publishing latency.** A new or changed SIT takes time to fully propagate to policies and
  classification. Don't declare a pattern broken on the first run — validate patience into the pilot.
- **Keep the identifier format current.** Formats drift (new prefixes, longer numbers, new variants).
  Re-validate against refreshed samples on a cadence and update the SIT before the drift creates blind
  spots.
- **Determinations belong to the data owner and governance.** Whether the detected data is sensitive,
  and whether classification drives **retention/records/legal** actions, is the data owner's and
  governance functions' call — the SIT supplies the method and evidence, not the verdict.
- **Verify licensing and availability against your tenant.** Creating SITs is broadly available, but the
  capabilities that consume them (advanced DLP, auto-labeling, Insider Risk, DSPM), the rule-package
  schema, and portal paths are plan-dependent and evolve — confirm, never assume.
