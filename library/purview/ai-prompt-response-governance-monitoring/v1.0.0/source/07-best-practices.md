# 7. Best Practices — AI Prompt/Response Governance & Usage Monitoring (Microsoft Purview)

- **Monitor before you govern.** Baseline what AI is actually used for and which prompts/responses touch
  sensitive data *first* (Step 2). Governance aimed at real usage is proportionate; governance aimed at
  assumptions over- or under-shoots.
- **Privacy-by-design is non-negotiable.** Turn on Communication Compliance **anonymization** so reviewers
  see pseudonymized aliases, and only de-anonymize through a defined, approved process. Monitoring people's
  prompts is HR/privacy-sensitive — build it to be fair and defensible from day one.
- **Separate the duties.** Keep **Communication Compliance Administrators** (configure), **Analysts**
  (triage on pseudonymized data), and **Investigators** (full detail, gated) as different people. No one
  should both write the policy and investigate individuals.
- **Always pilot in a limited/test scope.** Create the Communication-Compliance policy scoped to the pilot
  ring only, and the DLP-for-AI policy in **test** mode — `-WhatIf` is the default on the configuration
  helper for the same reason. Read every intended action before `-Commit`, and enforce/expand only after the
  gate passes with HR/privacy/legal sign-off.
- **Let HR/compliance/privacy/legal own the determination.** You provide the technical method and the
  evidence; *whether* a prompt is acceptable, what a match *means* for an individual, and any disciplinary,
  records, or legal-hold action are their calls. Capture the agreed policy definition before configuring.
- **Verify availability, never assume it.** Copilot monitoring in Communication Compliance, the DLP
  **Copilot** location, DSPM for AI, the `CopilotInteraction` record, and risky-AI-usage insider-risk
  indicators are new and evolving. When a source, location, or blade isn't where this guide says, confirm
  it in your tenant and use the closest current equivalent — don't force a path that isn't there.
- **Confirm the Copilot/AI DLP location before you enforce.** The location name that scopes DLP to Copilot
  is licensing-dependent and evolving; the configuration helper parameterizes it (`-DlpAiLocation`) rather
  than assuming it. Verify the exact location so the policy governs where you intend.
- **Keep auditing on.** AI usage monitoring is only as complete as the unified audit log feeding it. If
  monitoring looks empty, check auditing is on and that Copilot/AI has actually been used, and allow for
  audit ingestion latency.
- **Labels and sensitive information types are the levers — keep them healthy.** Both the
  Communication-Compliance conditions and the DLP-for-AI policy match on your classification. A thin
  taxonomy caps how precisely you can govern prompts and responses; invest there.
- **Right-size reviewer capacity before broadening.** A policy that over-collects buries reviewers and
  erodes the program. Tune conditions in the pilot so the broad-scope match volume is reviewable, and
  confirm capacity before expanding Communication Compliance.
- **Make usage review recurring.** AI adoption and the sensitivity of what people ask it drift. Schedule the
  read-only `ScopeConfig → Discovery → Monitor → Validate` chain under `AI Usage Review – Estate –
  Recurring` so governance stays measured, not measured once.
- **Keep an easy rollback.** Every enforced DLP-for-AI policy should be one change from returning to test,
  and the Communication-Compliance scope one change from returning to the pilot ring. Keep the validation
  evidence export as the before-state so any expansion can be safely reverted.
