# 7. Best Practices — Microsoft 365 Copilot Readiness Assessment & Deployment

- **Fix data hygiene before you license anyone.** Copilot surfaces everything a user can already reach; remediating oversharing *before* enablement is the single most important control — do it for every wave, not just the pilot.
- **Assess, then remediate, then enable — in that order.** A scored baseline (`Copilot Readiness - Tenant - Assess`) tells you what to fix and lets the pilot gate prove you fixed it; skipping the assessment is how oversharing reaches AI answers.
- **Pilot with a representative cross-section.** A small cohort spanning several roles gives value evidence that generalizes to the waves; a pilot of only power users overstates adoption.
- **Use group-based licensing.** Assign the Copilot SKU to `Copilot License - Pilot Cohort - Pilot` and the wave groups, not user-by-user — it makes enablement and roll-back repeatable.
- **Measure value from day one.** Stand up the value dashboard before the pilot ends so leadership sees activation, active use, and impact against agreed thresholds — evidence before the big licensing spend.
- **Remediate-then-license every wave.** Repeat the pilot's order for each wave: scan for oversharing, remediate, then license — new broad-access content appears over time.
- **Keep sensitive content labeled and audited.** A published sensitivity-label baseline plus Purview audit keeps sensitive material controllable and Copilot use accountable.
- **Name every object to the convention.** Use `<Purpose> - <Scope> - <Stage>` for the cohort, licensing, and wave groups and the scorecard, and reuse the names verbatim — it makes the rollout auditable and repeatable.
- **Verify licensing and preview facts, don't assume them.** Base-plan prerequisites, the Copilot SKU, and any preview features change; confirm current availability in your tenant before committing.
- **Leave the AI-use policy to the customer.** The deployment provides the technical controls (labels, DLP, audit); what Copilot may be used for and how AI content is handled is the customer's compliance/legal decision.

## Where to go next

- **Oversharing / data-security remediation** — a dedicated engagement for deep, tenant-wide SharePoint/OneDrive permission remediation (SharePoint Advanced Management / Restricted Content Discovery — *verify availability*).
- **Purview information protection & DLP** — extend the label baseline and add DLP to bound what Copilot processes.
- **Entra identity hardening** — Conditional Access and MFA hardening so the identity plane Copilot honors is strong.
- **Copilot agents & extensibility** — once adoption is proven, extend Copilot with agents and connectors (governed the same assess-then-enable way).
