# 1. Solution Overview — Zero Trust Architecture: Conditional Access Baseline & Rollout

## Zero Trust and why identity is the control plane
Zero Trust replaces the old "trusted internal network" with a simple rule: never trust, always
verify. Every access request is authenticated, authorized, and evaluated against policy, regardless
of where it comes from. In a Microsoft cloud estate the place that rule is actually enforced is the
identity plane — Microsoft Entra — and the mechanism is Conditional Access. If a request cannot
satisfy the CA policy for the persona and resource it is reaching, it does not get in. That is why a
Conditional Access baseline is the foundation of a Zero Trust program.

## The Conditional Access model — signals, conditions, controls
A Conditional Access policy is an if-then statement. The **if** is a set of **assignments and
conditions**: which users/groups (and exclusions), which target resources (cloud apps or user
actions), and conditions such as device platform, location, client app, sign-in risk, and user risk.
The **then** is a set of **controls**:

- **Grant controls** — allow only if the sign-in meets a requirement: require MFA, require a specific
  authentication strength (for example phishing-resistant MFA), require a compliant device, require a
  hybrid Entra-joined device, require app protection policy, or block access entirely. Multiple
  controls can be combined with AND / OR.
- **Session controls** — shape the session once granted: sign-in frequency, persistent browser
  session, app-enforced restrictions (for example web-only, no download for guests), and Conditional
  Access app control via Defender for Cloud Apps.

Because a policy can target "all users" and "all cloud apps," it is powerful enough to lock everyone —
including admins — out of the tenant in one save. The whole method below exists to prevent that.

## Personas — designing the baseline by who the user is
The clean way to build a baseline is by **persona**, not one giant policy. Each persona gets policies
appropriate to its risk:

- **Admins** — the highest-value accounts. Require phishing-resistant MFA, tighter session controls
  (sign-in frequency, no persistent browser), and no legacy authentication.
- **Internal staff** — the workforce. Require MFA and a compliant or hybrid-joined device; block
  legacy auth.
- **External / guest users** — require MFA and app-enforced session restrictions; limit what they can
  do and download.
- **Service accounts / workload identities** — non-interactive accounts that break under interactive
  MFA. They are scoped out of interactive policies and, where licensed, governed by dedicated
  workload-identity Conditional Access instead; each one is documented and exception-tracked.

Personas map to security groups, and policies target those groups — so the baseline is legible,
auditable, and rolled out group by group.

## Report-only mode and the What-If tool — validate before you enforce
Two Entra features make a safe rollout possible:

- **Report-only mode** — a policy set to `Report-only` is fully evaluated on every sign-in and logged
  ("would have granted / would have blocked / would have required MFA") **without actually enforcing**
  anything. You read the impact in `Conditional Access -> Insights and reporting` (a Log Analytics
  workbook) and confirm the policy does what you intend, and does not catch break-glass or service
  accounts, before you turn it on.
- **What-If** — a simulator (`Conditional Access -> What If`) where you pick a user, app, device
  state, and conditions and see exactly which policies would apply and which controls would fire —
  without any real sign-in. It is how you sanity-check a policy against each persona before enabling
  it.

The rule for the whole baseline: **every policy is created in report-only, validated with
report-only data and What-If, and only then enforced** — in waves.

## Break-glass and exclusions — the anti-lockout discipline
Two cloud-only emergency access (break-glass) accounts are **excluded from every policy** so a bad
policy can never lock all admins out (global requirement G4). Beyond break-glass, exclusions are kept
deliberate and minimal — each exclusion is a documented exception (a service account, a specific
legacy app, a temporary carve-out), not a convenience, because every exclusion is a hole in the
baseline.

## Licensing note (be honest)
- MFA, device compliance, and session controls are available with Entra ID P1.
- **Sign-in risk and user risk conditions** (Identity Protection) require **Entra ID P2** — *verify
  your licensing*. If you are P1-only, substitute equivalent non-risk policies (for example require
  compliant device + MFA everywhere) and note the gap.
- **Require compliant device** depends on **Intune** device compliance; **require hybrid Entra-joined
  device** depends on Entra hybrid join. *Verify these are in place* or use the control the tenant
  supports.

## What you can control
- Personas and their group mappings.
- A numbered baseline: MFA, phishing-resistant MFA for admins, compliant/hybrid device, sign-in and
  user risk (P2), app-enforced restrictions for guests, block legacy auth, and admin session
  controls.
- The rollout state of each policy: report-only -> enforce, wave by wave.
- Exclusions and break-glass — deliberate and documented.

## Benefits
- Security — least-privilege access enforced at every sign-in; legacy auth and un-managed devices
  shut out; risk-based step-up where licensed.
- Safety — report-only + What-If + break-glass mean the baseline is deployed without lock-outs.
- Legibility — a numbered, persona-based set of policies anyone can read and audit, not a tangle.
- Repeatability — a wave pattern you re-run for each group and each new policy.

## Limitations (be honest with buyers)
- Risk-based policies need Entra ID P2; some device controls need Intune / hybrid join — *verify
  licensing* and substitute where needed.
- A CA baseline governs access; it is not a full Zero Trust program on its own (device management,
  data protection, and network controls are separate, adjacent solutions).
- Which apps are "sensitive," which staff are "privileged," and how strict guest access must be are
  business/security decisions the customer owns — the guide provides the controls, not the
  determinations.

## The standard deployment model
> Assess current CA policies and personas -> Configure the numbered baseline in report-only, scoped
> to persona groups, with break-glass excluded -> Pilot on a pilot ring and validate with report-only
> data + What-If -> Validate against pass/fail gates -> Expand by enforcing wave by wave with
> rollback ready. repeatable pattern: Assess -> Configure -> Pilot -> Validate -> Expand.

## Authentication and connections used
- Microsoft Entra admin center (`https://entra.microsoft.com`) for Conditional Access policies,
  report-only insights, and What-If.
- Microsoft Graph PowerShell SDK for read-only discovery/validation/reporting and the safe,
  preview-by-default baseline-policy creation (scopes named in each script header).
