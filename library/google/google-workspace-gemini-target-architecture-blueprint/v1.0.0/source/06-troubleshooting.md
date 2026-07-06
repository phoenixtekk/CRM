# Troubleshooting — Common Architecture Pitfalls

These are the failure modes that erode an owned target architecture in a large Google Workspace +
Gemini transformation, with the symptom, root cause, and the corrective move. Each references the
principle or gate it protects.

## 1. Competing identity sources of truth (shadow provisioning)

- **Symptom:** duplicate/mismatched users, licensing gaps, access that "shouldn't exist." Discovery
  finds more than one thing creating identities.
- **Root cause:** a workstream provisioned its own users instead of consuming the one pipeline —
  violates **GWARCH-ID-1**.
- **Fix:** name the single authoritative source (ADR GWARCH-ADR-ID-01), collapse shadow sources onto
  the one provisioning path, and re-run `GWARCH-Validation.ps1` until Gate 1 passes. Prevent recurrence
  with the identity contract in `03`.

## 2. Break-glass admin depends on the federated IdP

- **Symptom:** a plausible scenario where an Entra/IdP outage locks administrators out of a 150k-user
  Google estate.
- **Root cause:** SSO and administrative access were coupled — violates **GWARCH-ID-2** and the Gate 1
  "must pass" break-glass check.
- **Fix:** stand up an emergency super-admin path that does **not** traverse the federated IdP; test it
  after every federation change. Never ship a federation change without this.

## 3. Coexistence bridges that never sunset

- **Symptom:** mail dual-delivery, directory bridges, or legacy holds still running long after the wave
  they supported completed.
- **Root cause:** the bridge had no sunset condition — violates **GWARCH-P5 / GWARCH-COL-2**.
- **Fix:** attach a written sunset condition and owner to every bridge; review the list at each ARB;
  escalate any bridge past its date. Gate 2 fails until every bridge is bounded.

## 4. Permissions copied instead of remodeled (legacy over-sharing)

- **Symptom:** post-migration, content is over-shared exactly as it was in SharePoint/OneDrive;
  external exposure appears in the target.
- **Root cause:** source ACLs were replicated rather than rebuilt from the group model — violates
  **GWARCH-DRV-3** and closed-by-default (**GWARCH-P4**).
- **Fix:** remodel access from the identity/group taxonomy (Pattern DRV-C), default external sharing
  closed per scope, and validate a sample at Gate 3.

## 5. AI enabled ahead of governance

- **Symptom:** Gemini/agents can reach a data class whose DLP, sharing, or retention controls aren't in
  place yet.
- **Root cause:** AI enablement outran governance — violates **GWARCH-P6 / Pattern AI-C**; fails the
  Gate 5 "must pass" check.
- **Fix:** disable Gemini/agent access for that class until Domain 4 controls exist; enable per scope
  through the AI control center only after the data-class governance is validated. Track the gate in
  the ADR log.

## 6. Ungoverned agents in production

- **Symptom:** agents acting on Workspace data with no recorded owner, scope, or review.
- **Root cause:** no agent lifecycle — violates **GWARCH-AI-2**.
- **Fix:** register every production agent through the agent-platform governance surface with an owner
  and a data/actions scope; retire orphans. The agent inventory must be complete for Gate 5.

## 7. Designing on preview capabilities as if GA

- **Symptom:** a design depends on a Gemini Enterprise feature that changes, disappears, or behaves
  differently than the screenshot it was drawn from.
- **Root cause:** a preview/rolling-out capability was assumed GA instead of **verified in tenant**.
- **Fix:** maintain the preview-capability risk register (GA vs preview + contingency); design to the
  capabilities actually present in your tenant; re-verify at each ARB. Never invent behavior.

## 8. Policy applied to individuals, not scopes

- **Symptom:** inconsistent DLP/sharing/retention/Gemini access; exceptions multiply; new capabilities
  land ungoverned.
- **Root cause:** governance by exception instead of by scope — violates **GWARCH-P3**.
- **Fix:** refactor ad-hoc, individual-level policy onto the GWARCH-Scope OU/group model; keep
  source→target scope mapping deterministic (`GWARCH-Set-ScopeTargeting.ps1`). Treat any individual-level
  policy as a defect.

## 9. Decisions made outside the ADR log

- **Symptom:** two workstreams build conflicting things; no one can say why a choice was made; auditors
  find undocumented design.
- **Root cause:** decisions live in slides/email, not the ADR log — erodes **GWARCH-P1** authority.
- **Fix:** every consequential decision becomes an ADR (supersede, never overwrite); the ARB governs
  against the single log; Gate 7 fails on un-reconciled conflicts.

## 10. The architecture drifts from the real estate

- **Symptom:** the compiled document, the ADR log, and the built estate disagree.
- **Root cause:** no re-baselining; the design was validated once and never re-measured
  (**GWARCH-P8**).
- **Fix:** re-run `GWARCH-Discovery.ps1` + `GWARCH-Validation.ps1` on a cadence; feed drift back as
  gaps into the ADR log and ARB; keep the three surfaces coherent (`07` §9).

## Script-level issues

- **`Connect-MgGraph` fails / insufficient scopes:** consent the exact read scopes listed in each
  script header; a Global Reader role covers the discovery scopes. Re-run after consent.
- **Empty or partial output at 150k scale:** discovery/report scripts page and can run long on a large
  tenant; let them complete, run from a stable session, and export to file rather than console.
- **Remediation script "did nothing":** by design — `GWARCH-Remediation.ps1` defaults to `-WhatIf` and
  only prints guidance; it makes no changes unless explicitly run with `-WhatIf:$false` after review.
