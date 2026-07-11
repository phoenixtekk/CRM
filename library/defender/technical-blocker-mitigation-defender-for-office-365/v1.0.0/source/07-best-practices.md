# 7. Best Practices — Technical Blocker Mitigation: Defender for Office 365

Field-proven guidance for diagnosing a stalled MDO rollout cleanly, fixing the *right* thing, and never breaking mail delivery in the process.

## Diagnose before you touch mail flow
- Run `TBMMDO-Discovery.ps1` and `TBMMDO-MailFlow.ps1` **first**. Read the evaluation chain top-down; the earliest broken link is the blocker. Changing a transport rule or connector on a hunch can break delivery for the whole org.
- A "policy that never applies" is almost always a **precedence or scope** problem, not a broken feature — confirm which policy actually wins before editing the feature.

## Remember: one policy of each type wins per recipient
- MDO applies the **single highest-priority** matching policy of each type (preset over custom, by priority). If your policy is not winning, fix **priority or scope**, do not clone more policies — that compounds the precedence problem.

## Change one thing, on the affected recipients, then verify
- Apply exactly **one** documented fix, scoped to `MDO Blocker Triage – Affected Recipients – Diagnose`, then run `TBMMDO-Validate.ps1`. One change at a time keeps cause and effect clear.
- Never resume the tenant-wide rollout until the affected recipients pass their test gate.

## Treat routing changes as delivery-affecting
- MX, connector, and gateway changes affect **mail delivery**, not just security. Pilot on the affected recipients' path, confirm mail still flows, and have a rollback ready before any wider change.

## Keep everything read-only until you deliberately fix
- Every script here is read-only. Treat the *fix* as a separate, conscious action in the portal/Exchange PowerShell. Keep mail-remediation actions (soft-delete, ZAP, allow/block-list edits) **approval-gated** — those are the SOC's call.

## Let policy changes propagate
- Threat-policy edits and scope changes take time to apply across the service. Give a fix propagation time before re-testing, then validate with a fresh test message.

## Keep licensing and preview facts current
- MDO features are **plan-gated** (P1 for Safe Links/Attachments, P2 for Explorer/Attack Simulation). Before concluding "it's broken," confirm the feature is even licensed — *verify current availability and plan requirements in your tenant.*

## Escalate with evidence, not a description
- If protection survives a correct fix, attach `MDO Support Bundle – <case> – Escalate` with message-trace IDs to the case. A complete bundle resolves cases far faster than a written symptom.

## Where to go next
Once the rollout is unblocked, natural next steps in the catalog:
- **EOP / MDO email-security hygiene** to bring the whole email-protection baseline to standard.
- **Defender for Office 365 (P2) — Threat Explorer, Attack Simulation & AIR** to operate the email pillar deeply.
- **Defender XDR Deployment & Unified Onboarding** to correlate email alerts with endpoint, identity, and cloud-app signal in one portal.
- The **Sentinel** SOC/XDR integration to stream MDO signal into a SIEM for long-term hunting.
