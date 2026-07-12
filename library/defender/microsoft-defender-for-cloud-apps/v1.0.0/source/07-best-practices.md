# 7. Best Practices — Microsoft Defender for Cloud Apps

Field-proven guidance for keeping the Defender for Cloud Apps deployment clean, the team sharp, and the proof-of-concept safe and conclusive.

## Connect & Govern (Phase A)

### Start every policy in report-only, scoped to a pilot
- Create activity, file, session, and access policies in **monitor / report-only** first, scoped to `MDCA Pilot Users – Pilot Ring – Pilot`. Watch behavior, tune out false positives, then enforce. A CASB that blocks legitimate work on day one loses the room.
- Move to enforce for the pilot, confirm, then broaden the Conditional Access scope in waves — never enforce tenant-wide first.

### Connect Microsoft 365 first, then priority third-party apps
- The Microsoft 365 connector gives the fastest, richest signal. Add high-value third-party apps (`MDCA App Connectors – Priority SaaS – Prod`) next by data sensitivity, not by ease. Connectors are out-of-band API integrations — they add signal without user impact.

### Use the Defender for Endpoint feed for discovery where you can
- If devices are MDE-onboarded, the built-in **Defender for Endpoint → Cloud Apps** integration is the lowest-friction Cloud Discovery source — no log collector to maintain. Fall back to a log collector / SWG feed only where MDE is not the source.

### Treat OAuth app governance as a standing risk surface
- Risky **OAuth app** consents exfiltrate data with no stolen password. Keep `MDCA OAuth App Risk – Tenant – Report` running, review flagged apps (over-privileged scopes, unverified publishers) on a cadence with `MDCAFULL-OAuthRisk.ps1`, and keep **revocation approval-gated** — it can break legitimate integrations. Revocation decisions belong to the security team.

## Enable the team (Phase B)

### Teach against the pilot, read-only
- Run the labs against `MDCA Pilot Users – Pilot Ring – Pilot`. The only configuration action is the report-only session policy (facilitator); everything else is discovery, hunting, and reading. Rehearse OAuth revocation and user suspension without executing them against production.

### Use consistent object names and save the artifacts
- The `<Purpose> – <Scope> – <Stage>` convention keeps take-home artifacts findable and reusable. The three saved queries, the report-only policy, the two shortlists, and the investigation doc **are** the runbook — keep them and use them to onboard new analysts.

### Instill the operating habits
- **Discover first, then sanction deliberately** — rank shadow IT by risk *and* usage; a high-risk app nobody uses is lower priority than a medium-risk app everyone uses.
- **Monitor before you block** — every session/access policy earns enforcement by proving itself report-only first, then stage the block to a ring with a rollback.
- **Triage anomalies with context** — pivot in `CloudAppEvents` for the user's normal pattern before escalating impossible-travel or mass-download alerts.

## Prove value (Phase C)

### Keep the PoC scoped, monitor-first, and reversible
- Scope the activity policy to **pilot users only** and keep it in **audit mode with no governance action**. Preview every change with `-WhatIf` first (`MDCAFULL-PoC.ps1 -Action Enable/-Action Teardown`).

### Benign signal only — never real exfiltration
- Use Microsoft's **sample Cloud Discovery log** and **benign policy-matching activity** exclusively. **Never** exfiltrate real data, connect a malicious app, or grant a risky OAuth consent to "test." A PoC proves the product surfaces the signal; it is not a data-loss exercise.

### Set the bar before you run, then tear down completely
- Agree the **evaluation criteria** in writing first and feed them into `MDCAFULL-PoC.ps1 -Action Score` so the verdict is objective. Afterwards, delete the policy, the discovery report, and any PoC connector, resolve the `MDCA-PoC-TESTSIGNAL` alerts, and confirm with `MDCAFULL-Validate.ps1 -Check PoC`. Keep only the scorecard.

## Across all phases

### Keep enforcing and revoke actions approval-gated until trusted
- Block, suspend-session, revoke-app, and teardown are disruptive or destructive. Leave them `-WhatIf`- or approval-gated during the pilot and early expansion; moving toward automatic enforcement is the security team's decision, made after validation.

### Let discovery and hunting tables warm up
- Discovery data and `CloudAppEvents` populate over minutes to hours. Confirm streaming with `MDCAFULL-Validate.ps1 -Check Signal` before judging coverage, and re-baseline with `MDCAFULL-Report.ps1 -SaveBaseline` after each expansion. If session control is unlicensed, record it as "not licensed," not "failed."

### Keep licensing and preview facts current
- MDCA, **app governance**, and **Conditional Access App Control** are license-gated and evolve, and App Control supports a changing set of apps. Before relying on a capability, **verify current availability, licensing, and supported apps in your tenant.**

### Defer the data-governance decisions to the owners
- What counts as sensitive data, which apps are sanctioned, and acceptable-use policy are **the customer's compliance/security determinations**. This solution delivers the technical CASB onboarding, the operating skills, and the proof — the classification and policy decisions stay with the owners.

## Where to go next
Once MDCA is connected, the team is enabled, and value is proven, natural next steps in the catalog:
- The **Cloud-App DLP (Defender for Cloud Apps) — Microsoft Purview** solution to layer data-loss-prevention on the connected apps and move from audit to real governance org-wide.
- The **Microsoft Defender XDR — Unified Onboarding** accelerator (**DEFXDR**) to correlate MDCA with Endpoint, Identity, and Office 365 in one portal.
- The **Microsoft Defender for Endpoint** to establish the MDE feed that powers Cloud Discovery.
- **Entra Conditional Access baseline** and identity-governance solutions to strengthen the access layer that App Control depends on.
- The **Sentinel / SOC-XDR integration** solution to stream MDCA into a SIEM for long-term hunting.

The bottom line: a fully connected, team-operated, value-proven Defender for Cloud Apps — exposing shadow IT, governing apps and OAuth risk, authoring report-only-first policies, and running clean, approval-gated investigations — the whole CASB lifecycle in one package.
