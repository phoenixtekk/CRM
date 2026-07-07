# Solution Overview

## What this solution is

Every time a user clicks **"Allow"** on a third-party application's consent screen, they grant that
app an OAuth token that can read, write, or delete Google Workspace data on their behalf — mail,
Drive files, calendars, contacts, and more. Across an enterprise of 80,000–150,000+ users, this
produces thousands of standing grants to hundreds of external applications, most of them never
reviewed. It is one of the largest and least visible attack surfaces in a Google Workspace estate:
a single over-scoped or malicious app, or a compromised vendor, can exfiltrate data at scale using
tokens that survive password changes and are invisible to most endpoint controls.

This solution establishes **OAuth & third-party app-access governance** for Google Workspace. It
brings the invisible consent surface under explicit control by:

- **Inventorying connected third-party apps and their OAuth scopes** — who has granted what to which
  app, and how sensitive each scope is.
- **Configuring API access control** — the Google Admin console's **trusted / limited / blocked**
  model for OAuth apps, **Google Workspace Marketplace allowlisting**, and **blocking of
  unverified (unconfigured) apps** and their sensitive-scope access.
- **Reviewing high-risk scopes and tokens** — surfacing the grants that carry restricted or
  sensitive scopes (full Gmail, Drive, admin, directory) and the tokens that should be revoked.
- **Standing up an app-vetting / approval workflow** — a repeatable process (risk criteria,
  reviewers, decision record) so new third-party apps are assessed *before* they are trusted, not
  discovered after an incident.

The result: only trusted, vetted applications reach the organization's Google data, and every
standing grant is inventoried, risk-scored, and governed.

## How it works

The solution operates against the **Google Admin console** (admin.google.com) and the **Admin SDK**
(the **Reports API** for OAuth-token activity and the **Directory API** for token/domain-app
inventory), driven by **Python** automation (the `google-api-python-client` client library and, where
useful, `gcloud` subprocess wrappers) authenticated with **Application Default Credentials (ADC)** or
a delegated service account — never hardcoded keys.

Control is exercised through **Google's native API access control model**, configured under
**Admin console → Security → Access and data control → API controls**:

- **App access control** classifies each OAuth/OIDC app as **Trusted**, **Limited**, or **Blocked**.
  "Trusted" apps may access **all** scopes (including restricted/sensitive ones); "Limited" apps may
  access only non-sensitive/basic scopes; "Blocked" apps get no access.
- **Unconfigured (unverified) third-party apps** can be governed globally: you can **block** their
  access to Google services entirely, or restrict them from **sensitive and restricted scopes**,
  so a newly encountered app cannot silently obtain high-risk access.
- **Google Workspace Marketplace settings** control whether users can install Marketplace apps
  freely, only from an **allowlist**, or not at all.
- **Domain-wide OAuth token inventory** (Directory API `tokens` resource) and **OAuth-token log
  events** (Reports API) provide the connected-app + scope inventory and the revocation surface.

The four capabilities are layered: **inventory** feeds **risk classification**, which drives **access
control configuration** and **token revocation**, and the **vetting workflow** governs everything new
going forward. Every change is applied **pilot-first** with explicit pass/fail gates and a documented
rollback.

## Reference design

The governance model is organized around named artifacts (reused verbatim throughout implementation,
testing, and the scripts):

| Artifact | Name convention | Purpose |
|---|---|---|
| App inventory | `App Inventory – Org-Wide – v1` | Connected apps + scopes + grant counts, risk-scored |
| Trusted-app list | `Trusted Apps – Org-Wide – v1` | Vetted apps allowed all/restricted scopes |
| Limited-app list | `Limited Apps – Org-Wide – v1` | Apps allowed basic/non-sensitive scopes only |
| Blocked-app list | `Blocked Apps – Org-Wide – v1` | Apps denied all Google access |
| Unverified-app policy | `Unverified-App Block – Org-Wide – Pilot` | Global block/limit of unconfigured apps' sensitive scopes |
| Marketplace policy | `Marketplace Allowlist – Org-Wide – v1` | Allowlist-only Marketplace install setting |
| Pilot scope | `App-Access Pilot – Pilot-OU – v1` | OU/group the controls are validated on first |
| Vetting workflow | `App-Vetting Workflow – Org-Wide – v1` | Risk criteria + reviewers + decision record for new apps |
| Revocation runbook | `Token Revocation – Risky-Grants – Runbook` | Steps + evidence to revoke high-risk grants |

The **risk score** for a connected app is derived from the sensitivity of the scopes it holds
(restricted > sensitive > basic), the number of users who granted it, whether it is verified by
Google, and whether it appears on the Trusted list. Scope-sensitivity tiers follow Google's own
classification (restricted and sensitive scopes are enumerated in Google's OAuth API scopes
documentation — *verify the current list for your tenant*, as Google updates it).

## Benefits

- **Visibility:** a complete, risk-scored inventory of every third-party app and OAuth scope touching
  Google data — replacing an unknown surface with a governed one.
- **Containment:** unverified apps and high-risk scopes are blocked by default; only vetted apps are
  trusted.
- **Least privilege for apps:** the trusted/limited/blocked model enforces that apps get only the
  scope tier they were vetted for.
- **Repeatability:** a documented vetting workflow means new-app risk is assessed before access is
  granted, not after.
- **Auditability:** every configuration and revocation is named, evidenced, and reproducible via the
  included Python tools.

## Limitations & boundaries

- **Native Google controls only.** This solution uses Google's built-in API access control,
  Marketplace, and Admin SDK capabilities. A dedicated SaaS-security / SSPM product (or Google's
  own advanced app-governance tooling where licensed) may add deeper behavioral detection; that is
  complementary, not replaced here. *Verify which capabilities your Workspace edition includes.*
- **Edition-dependent features.** Some app-access and security-center capabilities depend on the
  Workspace edition (e.g. Enterprise tiers). Where a control's availability is edition- or
  rollout-dependent, this guide flags "verify in your tenant" rather than asserting it.
- **Scope classification evolves.** Google's list of sensitive/restricted scopes changes; the risk
  model reads the current classification and flags unknown scopes for manual review rather than
  assuming a fixed list.
- **Legal/compliance determinations deferred.** Whether a given app or data flow is *permitted* under
  the organization's policy or regulatory regime is a decision for security/legal/data-governance
  stakeholders; this solution provides the technical inventory, controls, and evidence.
- **User-consent behavior.** Blocking apps changes what users can install; expansion beyond the pilot
  must be communicated (see change management) to avoid support load.

## Deployment model

This solution follows the house model: **Assess → (Design →) Configure → Pilot → Validate →
Expand**, pilot-first, with explicit pass/fail gates and a documented rollback for every org-wide
change:

1. **Assess** — inventory connected apps + scopes with the read-only discovery tool; risk-score them.
2. **Design** — classify apps into Trusted / Limited / Blocked; define unverified-app and Marketplace
   policy; define the vetting workflow and risk criteria.
3. **Configure** — apply API access control, Marketplace allowlist, and unverified-app block in the
   Admin console (dry-run/preview first).
4. **Pilot** — apply to `App-Access Pilot – Pilot-OU – v1` first; validate no legitimate app is
   broken.
5. **Validate** — run the validation tool against the pass/fail gates (high-risk scopes controlled,
   unverified apps blocked, approvals enforced).
6. **Expand** — roll out org-wide under change control; operationalize the vetting workflow and
   periodic token review.
