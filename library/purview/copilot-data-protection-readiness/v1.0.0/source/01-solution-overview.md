# 1. Solution Overview — Microsoft 365 Copilot Data-Protection Readiness (Microsoft Purview)

## What this solution is
Microsoft 365 Copilot surfaces whatever a user can already access. The moment Copilot is switched on,
every file, message, and site that user *technically* has access to — including content that was
over-shared and never actively found — becomes one prompt away. This solution is the **remediation
playbook that makes your data safe *before* Copilot sees it**: a repeatable, self-guided way to
**discover oversharing and then remediate it** with Microsoft Purview sensitivity labels, Data Loss
Prevention (DLP), and SharePoint access controls, so Copilot only surfaces appropriate data.

It is delivered end to end in the **Microsoft Purview portal** (`https://purview.microsoft.com`), the
**Microsoft 365 admin center**, **Security & Compliance PowerShell** (`Connect-IPPSSession`), and
**Microsoft Graph** — with no third-party tooling. Every high-impact change (a new label policy, a DLP
policy, an auto-labeling policy, a sharing restriction) is **piloted in simulation / test / disabled
mode first**, validated against pass/fail gates, and only then enforced and expanded.

> **How this differs from "DSPM for AI."** Data Security Posture Management for AI is the **telemetry and
> posture surface** — it *shows* what AI can reach and recommends fixes. **This solution is the
> hands-on remediation playbook** you run against that signal: the ordered work of discovering the
> oversharing, standing up the labels/DLP/access controls that shrink it, piloting and validating each
> control, and producing a defensible **go / no-go readiness decision** before broad Copilot rollout. Use
> DSPM for AI to *see*; use this solution to *fix and evidence*. Where DSPM for AI is present in your
> tenant, this solution reads it as one input; where it is not, the discovery scripts and portal steps
> here still give you the oversharing picture.

## Why this matters
- **Copilot inherits access, not intent.** It respects existing permissions exactly — so a document
  shared with "Everyone except external users," or a site open to a broad group, is fair game for
  Copilot to summarize and cite. Access that was harmless-by-obscurity becomes discoverable.
- **Copilot honors sensitivity-label protection.** If content carries a sensitivity label whose
  encryption denies the user usage rights, Copilot will not surface or summarize it, and cited content
  inherits the highest-priority label of its sources. Labeling is therefore a *direct* Copilot control,
  not just a classification exercise — which is exactly why getting labels right before rollout matters.
- **Oversharing remediation is high-impact.** Broad sharing changes, new DLP, and auto-labeling can
  disrupt legitimate collaboration if enforced blindly — so every reduction here is piloted in
  simulation/test and validated before enforcement.
- **"Ready" must be evidenced, not asserted.** Leadership needs a defensible answer to "is our data safe
  for Copilot?" This solution produces that evidence: a before-state, the controls applied, the
  validation results, and a recorded go/no-go.

## The remediation levers (what actually reduces Copilot exposure)
- **Sensitivity labels — coverage & protection.** Default and (where policy requires) mandatory labeling
  so content is classified; **encryption/usage rights** on protected labels so Copilot honors "who may
  read this"; **container labeling** on SharePoint sites, Teams, and Microsoft 365 Groups to control
  privacy, external sharing, and the default sharing link. *(Availability of container labeling and
  mandatory labeling is licensing-dependent — verify in your tenant.)*
- **Auto-labeling (simulation first).** Service-side auto-labeling policies that classify sensitive
  content at rest across SharePoint/OneDrive/Exchange, run in **simulation** so you see what *would* be
  labeled before anything is applied.
- **DLP for Microsoft 365 Copilot.** A DLP policy scoped to the **Microsoft 365 Copilot** location that
  prevents Copilot from processing/summarizing content carrying specified sensitivity labels — keeping
  the most sensitive material out of AI responses. *(Feature availability is evolving/licensing-gated —
  verify the Copilot DLP location exists in your tenant.)*
- **SharePoint access remediation.** Reducing the actual access surface: removing broad "Everyone Except
  External Users" (EEEU) grants, tightening site/sharing scope, and — as documented interim controls —
  **Restricted SharePoint Search** and **Restricted Content Discovery** to fence off not-yet-remediated
  sites from Copilot and org-wide search while you do the real cleanup. *(These SharePoint controls are
  delivered via SharePoint admin / SharePoint Advanced Management and are licensing-dependent — verify.)*

## The scope of "outcomes" (what this solution does and does not decide)
This solution delivers the **technical method and the evidence** — how to discover oversharing and
configure labels, DLP, and access controls, piloted and validated. It does **not** make **regulatory,
records, or legal determinations**: which data is "sensitive," what an acceptable Copilot-exposure level
is, what must be retained or restricted, and any records/legal-hold obligations are **deferred to your
compliance, records, privacy, and legal functions**. You provide the configuration and the evidence;
they own the determination and the final go/no-go sign-off.

## Naming convention (used in every doc and script)
Every artifact this solution creates or exports is named `<Purpose> – <Scope> – <Stage>` and reused
verbatim across the docs, scripts, and portal so a reader can trace one artifact end to end.

| Artifact | Name |
|---|---|
| Readiness scope & connection-health export | `Copilot Readiness – Tenant – Scope` |
| SharePoint/OneDrive oversharing discovery export | `Oversharing – Estate – Discovery` |
| Unlabeled sensitive-content assessment export | `Unlabeled Sensitive – Estate – Assess` |
| Pilot default-labeling policy | `Default Labeling – Users – Pilot` |
| Pilot auto-labeling (simulation) policy | `Auto-Label Sensitive – Pilot – Simulation` |
| Pilot DLP-for-Copilot (test) policy | `DLP for Copilot – Pilot – Test` |
| Prioritized SharePoint access-reduction list | `Site Access Reduction – Sites – Pilot` |
| Readiness go/no-go decision record | `Copilot Readiness – Tenant – GoNoGo` |
| Recurring readiness-review cadence tag | `Copilot Readiness Review – Tenant – Recurring` |

## The standard deployment model
> Confirm scope/licensing/roles → discover oversharing and unlabeled sensitive content → design the
> label/DLP/access controls with stakeholders → configure and **pilot every control in
> simulation/test/disabled** → validate against gates → **expand to enforce**, record the go/no-go, and
> review on a recurring cadence.
> Pattern: **Assess → Design → Configure → Pilot (simulate/test) → Validate → Expand (enforce).**
