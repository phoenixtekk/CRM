# 7. Best Practices — AI Data-Exposure Assessment (Microsoft Purview)

- **Assess *before* you turn on Copilot.** The whole point is a decision-quality baseline ahead of AI
  adoption. A file Copilot can't reach can't be surfaced by a prompt — quantify the reachable-and-sensitive
  intersection first, then decide.
- **Measure reachability, not just protection.** Label and DLP coverage tell you what's *protected*;
  oversharing and AI-interaction signal tell you what's *reachable*. Exposure lives at the intersection —
  broadly-shared, unlabeled, sensitive content. Rank on that, not on the easiest-to-fix tickets.
- **The register is evidence, not a verdict.** The exposure score ranks findings for human review; *which*
  risks to remediate and *what* AI-exposure level is acceptable are compliance/records/privacy/legal calls.
  Hand over the ranked evidence; let them own the determination (GR §5).
- **Validate the fix path in simulation — never enforce in the assessment.** Prove the recommended
  remediation would land correctly by running auto-labeling in **simulation** (`TestWithoutNotifications`),
  which labels nothing. `-WhatIf` is the default on the pilot helper for the same reason — read every
  intended action before you `-Commit`. Enforcing a validated fix is a separate, change-controlled follow-on.
- **Treat a thin taxonomy or absent DLP as a top finding.** If there is no lever to protect content, every
  reachable-sensitive site is more exposed — the register applies a no-lever penalty precisely so this
  surfaces. Investing in labels/DLP is often the highest-leverage recommendation.
- **Verify availability, never assume it.** DSPM for AI, auto-labeling, advanced DLP, and the audit record
  types are evolving and licensing-dependent. When a blade, cmdlet, or RecordType isn't where this guide
  says, confirm it in your tenant and override the script's parameter — don't force a path that isn't there.
- **Keep auditing on.** The AI-interaction and broad-sharing signals are only as complete as the unified
  audit log feeding them. If the signal looks empty, check auditing and confirm AI usage has actually
  occurred — pre-adoption emptiness is expected and not a failure.
- **Parameterize the volatile values.** The AI RecordType and sharing Operations differ across tenants and
  change over time; pass `-AiRecordType` / `-SharingOperations` after confirming the current values rather
  than trusting a default blindly.
- **Preserve separation of duties.** Read exposure with a least-privilege reader role; keep the (simulation)
  policy-creation right separate. Reserve Global/Compliance Administrator for initial enablement only.
- **Make re-assessment recurring.** Data and AI usage drift, and each AI rollout wave changes the picture.
  Schedule the read-only `ScopeCheck → Discovery → RiskRegister` chain under
  `AI Exposure Re-Assessment – Estate – Recurring` so exposure is measured continually, not once.
- **Keep the assessment reproducible.** Retain the exports and the register as the dated baseline; the next
  re-assessment compares against it to show whether exposure is trending down as fixes are (separately)
  applied.
