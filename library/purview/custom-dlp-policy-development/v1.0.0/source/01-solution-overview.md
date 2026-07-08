# 1. Solution Overview — Custom DLP Policy Development (Microsoft Purview)

## What this solution is
Microsoft Purview ships with a large set of **built-in / templated DLP policies** (financial, medical,
privacy, regional PII, and more). They are a reasonable starting point, but they rarely fit *your* data:
your organisation has its own document types, its own identifiers, its own approved sharing paths, and
its own tolerance for friction. Run a template unchanged and you get noise — false positives that train
users to click through warnings, and false negatives that miss the data you actually care about.

This solution builds **custom Data Loss Prevention policies in Microsoft Purview** that are tuned to your
exact data. It delivers, end to end:

- **Custom DLP policies** authored against the workloads you choose — Exchange Online, SharePoint Online,
  OneDrive, Teams, and endpoint devices — rather than a one-size template.
- **Tailored conditions and rules** — the right combination of **sensitive information types (SITs)**,
  confidence levels, instance counts, sensitivity labels, and content/recipient conditions that match how
  your data really looks.
- **Deliberate exceptions** — the allowed business flows (approved recipients/domains, service mailboxes,
  specific sites) encoded as rule exceptions so legitimate work is not blocked.
- **A tuning loop** — the policy is piloted in **simulation / test mode first**, matches are reviewed,
  false positives and negatives are driven down, and only then is the policy moved to enforcement.

Everything is done with the **Microsoft Purview portal** (purview.microsoft.com) and **Security &
Compliance PowerShell** (`Connect-IPPSSession`) — no third-party tooling. The five included scripts author,
validate, and report on the policies **safe-by-default** (read-only, or `-WhatIf` until you pass `-Commit`).

> **This is custom policy *development*, not the DLP platform build-out.** It assumes the Purview
> foundation and DLP prerequisites are in place (licensing, roles, the S&C PowerShell toolchain, the
> in-scope workloads, and — for endpoints — device onboarding). It focuses squarely on **designing,
> configuring, simulating, tuning, and enforcing custom DLP policies**. Where a prerequisite belongs to
> another solution (endpoint onboarding, custom sensitive info types, Exact Data Match, sensitivity
> labels), this guide points to it rather than duplicating it.

## Why this matters
- **Templates don't know your data.** A built-in "U.S. PII" policy fires on any SSN-shaped string
  anywhere; it doesn't know that your finance shared mailbox legitimately handles them, or that your
  real exposure is a bespoke customer-ID format the template has never heard of. Custom policies encode
  *your* reality.
- **False positives are a security risk, not just an annoyance.** Every over-firing rule trains users to
  dismiss DLP warnings — so the one that matters gets dismissed too. Tuning is what makes DLP credible.
- **Un-piloted DLP breaks work.** A block action shipped straight to enforcement can stop legitimate
  business email or file sharing on day one. Piloting in **simulation/test** first is the difference
  between a controlled rollout and an outage.
- **Defensibility.** A policy that was designed to a documented data-protection intent, piloted, tuned
  against evidence, and enforced under change control is one you can stand behind in an audit — not a
  guess.

## How it works
1. **Assess.** Read the tenant read-only: existing DLP policies and rules, which sensitive info types are
   available, the in-scope workloads, and the DLP licensing. Establish what's already firing (or over-
   firing) before adding anything.
2. **Design.** Decide, per data type, the **conditions** (which SITs, confidence, instance count, labels,
   recipients), the **actions** (audit only, notify/policy tip, restrict access, block, encrypt), and the
   **exceptions** (approved flows) — mapped to the data-protection intent your stakeholders provide.
3. **Configure.** Author the custom policy and its rules **in simulation / test mode** — the policy is
   created with `TestWithoutNotifications` (or `TestWithNotifications`) so it evaluates content and records
   matches **without blocking anything or notifying users**. Changes are previewed with `-WhatIf` first.
4. **Pilot (simulate).** Let the policy run in simulation over the pilot scope, generating match data with
   no user impact. This is the mandatory high-impact-change gate for the Purview category.
5. **Validate & tune.** Review the simulation matches: drive down false positives (tighten conditions, add
   exceptions, raise confidence/instance thresholds) and false negatives (broaden or add SITs). Re-simulate
   until the match quality passes the gate.
6. **Expand (enforce).** Move the tuned policy to **enforcement** (`Enable`) — first with policy tips /
   notifications, then with the restrictive action — under change control, keeping the rollback path ready.

## Where custom DLP conditions come from
A custom DLP rule is a combination of building blocks. The design step chooses from:

| Building block | What it does | Example |
|---|---|---|
| **Sensitive information type (SIT)** | Pattern/keyword/checksum match for a data class | Built-in "Credit Card Number"; a **custom SIT** for your customer-ID format |
| **Confidence level** | How strict the SIT match must be (low/medium/high) | Require *high* confidence to cut false positives |
| **Instance count (min/max)** | How many matches trigger the rule | 1–9 for a tip, 10+ for a block |
| **Sensitivity label** | Content carrying a specific label | Trigger on the "Highly Confidential" label |
| **Content/recipient conditions** | Where content is going / who to | Sent **outside the organisation**; to a non-approved domain |
| **Exceptions (`ExceptIf…`)** | Approved flows that must *not* trigger | Except when recipient is an approved partner domain |
| **Actions** | What happens on a match | Audit → policy tip/notify → restrict/block → encrypt |

> **Custom SITs, Exact Data Match, document fingerprinting, and sensitivity labels are inputs, not this
> solution's build.** If a condition needs a data class Purview doesn't have out of the box, that SIT is
> built in its own dedicated solution and then *consumed* here as a condition. This solution develops the
> **policies and rules**; it names the building blocks it uses.

## What you can control
- Which **workloads** the policy applies to (Exchange, SharePoint, OneDrive, Teams, endpoints) and its
  scope (all users vs a pilot group).
- The **conditions**: which SITs, at which confidence, at which instance counts, plus labels and
  content/recipient conditions.
- The **exceptions** that keep approved business flows working.
- The **actions** and their staging: audit-only → policy tip/notify → restrict/block → encrypt.
- The **mode**: simulation/test (no impact) → enforcement — and the pace at which you move between them.

## Limitations (be honest with buyers)
- **DLP is licensing-dependent.** Baseline DLP for Exchange/SharePoint/OneDrive/Teams is broadly
  available; **Endpoint DLP** and some advanced classification (trainable classifiers, EDM) require
  **Microsoft 365 E5** or the **E5 Compliance** add-on. Capability availability is **flagged "verify your
  licensing/tenant"**, never assumed. (Global Requirement 1.)
- **The portal is evolving.** Purview DLP portal paths and the simulation experience change over time.
  Paths here are cited as of authoring and marked **"verify in your tenant."**
- **This solution builds policies, not the data classes underneath.** Custom sensitive info types, Exact
  Data Match, document fingerprinting, and the sensitivity-label taxonomy are prerequisites developed in
  their own solutions and consumed here as conditions.
- **Endpoint and cloud-app coverage have their own onboarding.** Endpoint DLP needs devices onboarded to
  Purview; cloud-app DLP needs Defender for Cloud Apps — those roll-outs are separate solutions; this one
  authors the policy that targets them once they're in place.
- **What data is sensitive, and which regulations apply, is not ours to decide.** The data-protection
  intent, retention/records implications, and regulatory applicability are **deferred to compliance,
  privacy, and legal**; this solution provides the technical configuration and the match evidence.

## Naming convention (used in every doc and script)
Artifacts this solution creates or captures follow `Custom DLP – <Purpose> – <Stage>` and are reused
verbatim across the docs, scripts, and portal. The placeholder data type `Sensitive Data` stands in for
your real class (e.g. `Financial PII`, `Customer ID`) — rename consistently.

| Artifact | Name |
|---|---|
| Environment / existing-DLP discovery export | `Custom DLP – Discovery – Assess` |
| Policy design (conditions/actions/exceptions matrix) | `Custom DLP – Sensitive Data – Design` |
| The custom DLP policy (piloted in simulation) | `Custom DLP – Sensitive Data – Pilot` |
| The rule inside the policy | `Custom DLP Rule – Sensitive Data – R1` |
| Simulation validation snapshot | `Custom DLP – Simulation – Validate` |
| Match / incident report | `Custom DLP – Matches – Report` |
| Workload & SIT scope map | `Custom DLP – Scope – Map` |

## The standard deployment model
> Assess the environment → design conditions/actions/exceptions → configure the policy in simulation/test
> → pilot (simulate, no user impact) → validate & tune against the match evidence → expand to enforcement
> under change control. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate → Expand
> (enforce).**
