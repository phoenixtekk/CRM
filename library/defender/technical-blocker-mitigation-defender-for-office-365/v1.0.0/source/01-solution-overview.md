# 1. Solution Overview — Technical Blocker Mitigation: Defender for Office 365

## What this solution is
This is a **diagnostic and troubleshooting playbook** for a **stalled Microsoft Defender for Office 365 (MDO) rollout**. It assumes you have configured MDO and hit a wall — protection that does not apply, or mail flow that fights the configuration. Its job is to answer three questions quickly and in order:

1. **Which blocker do I actually have?** (read-only discovery of routing, policy, and precedence — not guesswork)
2. **What is the exact, documented fix?** (a targeted manual step, applied deliberately)
3. **Does the policy now apply?** (verification against message trace and advanced hunting before you resume)

It targets the four blocker classes that stall almost every MDO deployment:

- **Mail-flow / routing conflicts** — mail does not route through **Exchange Online Protection (EOP)** first (misconfigured MX, an inbound connector, or a third-party gateway in front), so Safe Attachments / anti-phish never see the message.
- **Policy precedence** — a **preset security policy**, a higher-priority **custom policy**, or an **exclusion** silently overrides the policy you think is active; only one policy of each type wins per recipient.
- **Safe Links / Safe Attachments not applying** — the policy exists but is **not scoped** to the affected recipients, or is disabled/misconfigured, so links are not rewritten and attachments are not detonated.
- **Licensing gap** — the plan a feature needs (MDO P1 for Safe Links/Attachments, P2 for Threat Explorer/Attack Simulation) is not assigned. *Verify current plan requirements in your tenant.*

## How Defender for Office 365 evaluation actually works (so you can find the break)
MDO has an evaluation chain, and a blocker is always a break in one specific link:

1. **Licensing/activation** — the tenant has the MDO plan and the feature is available.
2. **Mail routing** — inbound mail reaches **EOP** (correct MX / accepted domains / no bypassing connector) so the service can act on it.
3. **Policy selection & precedence** — for each recipient, MDO applies the **single highest-priority** matching policy of each type (preset > custom by priority), honoring inclusions/exclusions.
4. **Feature application** — the selected Safe Links / Safe Attachments / anti-phishing policy is **enabled** and **scoped** to the recipient, so links are rewritten and attachments detonated.
5. **Verification** — **message trace** shows the action, and advanced-hunting tables (`EmailEvents`, `UrlClickEvents`) show the protection engaging.

Find the earliest broken link and you have found the blocker. The discovery script reports the state of each link so you are not guessing.

## The standard deployment model (applied to a blocker)
> **Assess → Configure → Pilot → Validate → Expand.**
> **Assess** — run read-only discovery and mail-flow/precedence analysis to pinpoint the earliest broken link. **Configure** — apply the single documented fix for that blocker (a manual portal/PowerShell step, not a script action). **Pilot** — re-test on the **affected recipient subset** only. **Validate** — confirm the policy now applies via message trace and hunting. **Expand** — resume the stalled rollout to the remaining recipients.

## Scope
- Diagnosing and clearing the four blocker classes above for a stalled MDO rollout.
- Read-only discovery, mail-flow / precedence analysis, validation, status reporting, and a support-ready bundle.
- Documented manual fixes for each blocker, applied affected-recipient-first.
- Clear escalation criteria and the exact data to collect when the root cause is a Microsoft service issue.

## Out of scope
- **A full email-security build / hygiene baseline** — that is the adjacent *EOP/MDO hygiene* solution; this one unblocks a rollout already in progress.
- **Deep P2 operations** (Threat Explorer hunting, Attack Simulation, AIR tuning) — see the *Defender for Office 365 P2* solution.
- **Mail remediation and response** — soft-delete, ZAP, and tenant allow/block-list changes stay **approval-gated** and are the SOC's decision.
- **Licensing determinations** — the guide tells you *which* plan a feature needs and how to verify it; assigning it is the customer's licensing function.

## Connections and authentication used
- The **unified Defender portal** (`security.microsoft.com`) — **Email & collaboration → Policies & rules → Threat policies**, Explorer, and message entities.
- **Exchange admin center / Exchange Online Management PowerShell** — accepted domains, connectors, preset and custom threat policies, and message trace (all read-only here).
- **Microsoft Graph advanced-hunting API** (via `Microsoft.Graph`) for read-only `EmailEvents` / `UrlClickEvents` validation.
- Least-privilege roles: **Security Reader** / **Global Reader** / **View-Only** Exchange roles for all read-only diagnostics; **Security Administrator** (and the appropriate Exchange role) only to apply a fix.
