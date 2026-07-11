# 7. Best Practices & Where to Go Next — Enablement Kit: Microsoft Defender for Cloud Apps

## Running the enablement kit well
- **Teach against a pilot, report-only.** Author the session policy in **monitor** mode and rehearse OAuth revocation/user suspension without executing them against production. Expand to enforcement only through the customer's change process.
- **Read-only by default.** The only configuration action is the report-only session policy (facilitator). Everything else is discovery, hunting, and reading.
- **Don't break integrations.** Revoking an OAuth app's consent can disable a legitimate business integration — always treat it as an approval-gated change with the app owner, never a live demo.
- **Use consistent object names.** The `<Purpose> – <Scope> – <Stage>` convention keeps the take-home artifacts findable and reusable. Keep it.
- **Save the artifacts.** The three saved queries, the report-only policy, the two shortlists, and the investigation doc are the take-home runbook.

## Operating MDA well (the habits to instill)
- **Start with discovery, then sanction deliberately.** Rank shadow IT by risk *and* usage; a high-risk app nobody uses is lower priority than a medium-risk app everyone uses. Sanctioning is a business decision — the operator surfaces the data.
- **Watch OAuth apps continuously.** Consent grants are a common, quiet path to data. Review new/over-privileged/unverified apps on a cadence.
- **Monitor before you block.** Every session/access policy earns enforcement by proving itself in report-only first; then stage the block to a ring with a rollback.
- **Triage anomalies with context.** Impossible travel and mass-download alerts need the user's normal pattern to judge — pivot in `CloudAppEvents` before you escalate.
- **Respect the approval gate.** App sanctioning, consent revocation, and user suspension are security/business decisions. The operator produces a clean, evidenced recommendation.
- **Mind licensing and preview.** App governance and some features are plan-/preview-gated; *verify current availability in your tenant* before promising a capability.

## Common anti-patterns to avoid
- Turning the enablement kit into a connect-every-app project (that is the Cloud App DLP / onboarding solution).
- Blocking an app or revoking OAuth consent live "to show it works" — you may break production.
- Enforcing a session policy before it has run report-only.
- Treating a high risk score as an automatic ban without considering business use and the approval process.

## Where to go next (adjacent catalog areas)
- **Cloud App DLP** — connect more apps and build the full information-protection/DLP program on top of MDA.
- **Identity / Zero Trust / Conditional Access** — the CA integration that powers session/access control and stronger app governance.
- **Threat Hunting** — deeper cross-pillar KQL beyond `CloudAppEvents`.
- **SOC / XDR operations** — incident queue, automation, and process design that consume MDA alerts.
- **Sibling Defender enablement kits** — Identity, Endpoint, and Office 365 enablement enablement kits to round out the SOC's operating skills.

The bottom line: a team that operates MDA with confidence — exposing shadow IT, governing apps and OAuth risk, authoring report-only-first policies, and running clean, approval-gated investigations — using a runbook they keep and reuse.
