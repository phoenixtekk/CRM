# 7. Best Practices — Technical Blocker Mitigation: Defender for Cloud Apps

Field-proven guidance for diagnosing a stalled MDCA rollout cleanly, fixing the *right* thing, and not disrupting user sessions.

## Diagnose before you touch a connector or a CA policy
- Run `TBMMCA-Discovery.ps1` and `TBMMCA-ConditionalAccess.ps1` **first**. Read the signal chain top-down; the earliest broken link is the blocker. A careless Conditional Access change can lock users out of an app — never edit CA on a hunch.
- A session policy that "never fires" is almost always a **Conditional Access App Control** scoping problem, not a broken policy — confirm the CA routing before touching the session policy.

## Change one thing, on the affected apps, monitor-first, then verify
- Apply exactly **one** documented fix, scoped to `MDCA Blocker Triage – Affected Apps – Diagnose`, keep session policies in **monitor** mode, then run `TBMMCA-Validate.ps1`. One change at a time keeps cause and effect clear.
- Never resume the estate-wide rollout until the affected subset passes its test gate.

## Session control is the whole Conditional Access chain
- Inline controls only work if Entra CA routes the session to the MDCA reverse proxy **and** the app is onboarded to session control. When it "does nothing," check the CA policy scope/enable-state and the app onboarding before assuming MDCA is broken.

## Keep enforcement approval-gated
- Diagnostics and re-tests run **monitor-first**. Moving a session policy to block / restrict / quarantine is a **SOC decision** — keep it approval-gated so a fix does not become an outage.

## Keep everything read-only until you deliberately fix
- Every script here is read-only, including the Conditional Access reads. Treat the *fix* (reconnect a connector, enable a discovery source, adjust a CA policy) as a separate, conscious action in the portal.

## Let connector, discovery, and session signal warm up
- Connector re-consent, discovery ingestion, and `CloudAppEvents` populate over minutes to hours. Give a fix time before calling it a failure, then re-validate.

## Keep licensing and preview facts current
- MDCA features are **plan-gated**, and CA App Control depends on the right Entra plan. Before concluding "it's broken," confirm the feature is even licensed — *verify current availability and plan requirements in your tenant.*

## Escalate with evidence, not a description
- If the blocker survives a correct fix, attach `MDCA Support Bundle – <case> – Escalate` (with the CA App Control analysis) to the case. A complete bundle resolves cases far faster than a written symptom.

## Where to go next
Once the rollout is unblocked, natural next steps in the catalog:
- **Cloud App Security DLP** to operate cloud-app data protection deeply.
- **Entra Conditional Access baseline** to harden the identity/CA layer that App Control rides on.
- **Defender XDR Deployment & Unified Onboarding** to correlate cloud-app alerts with endpoint, identity, and email signal in one portal.
- The **Sentinel** SOC/XDR integration to stream MDCA signal into a SIEM for long-term hunting.
