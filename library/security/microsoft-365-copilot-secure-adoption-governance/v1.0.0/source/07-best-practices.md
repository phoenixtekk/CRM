# 7. Best Practices — Microsoft 365 Copilot Secure Adoption & Governance

- **Fix oversharing first, then turn on Copilot.** Copilot exposure equals what the user can access —
  remediating broad sharing is the single most important thing you do, and it must come before
  enablement, not after.
- **Assess with data, not assumptions.** Run `COPILOT-Discovery.ps1` and `COPILOT-Report.ps1` to get a
  real baseline of broad, external, and unlabeled content before you touch anything.
- **Remediate with owners, safely.** Preview every change with `-WhatIf`, review broad grants with the
  content owners, and remove anonymous/org-wide links — but don't silently strip access people depend on.
- **Label the crown jewels.** Sensitivity labels are the protection Copilot honors and Copilot output
  inherits; prioritize labeling (and auto-labeling) your most sensitive content first.
- **Use restricted search as a temporary net.** Restricted SharePoint Search contains Copilot to
  curated sites while you remediate — but it also narrows legitimate search, so treat it as a bridge
  and lift it as sites are cleaned.
- **Layer DLP on top of labels.** A DLP-for-Copilot policy that excludes your most sensitive labels
  adds a second, policy-level control beyond label-based access.
- **Always pilot with a curated group.** A small `Copilot Adoption – Pilot Users – Pilot` group with
  license scoping catches exposure problems before the whole org can hit them.
- **Prove it with exposure probes.** The pilot gate is not "Copilot works" — it is "Copilot cannot
  surface what it shouldn't." Test that explicitly.
- **Govern the humans, not just the data.** Publish an acceptable-use policy, require review of
  AI-generated output, and name owners for governance, labels/DLP, and AI use.
- **Scope licensing to the group.** Use group-based licensing so Copilot access stays tied to the pilot
  group and can be rolled back by removing the group, not chasing individuals.
- **Stop the drift.** Stand up recurring access reviews and re-run discovery on a schedule so
  oversharing does not creep back after Copilot is live.
- **Document the cadence.** Record the remediated scope, published labels, DLP policies, and the pilot
  → expansion waves for audits and repeatability.
