# Implementation

This guide sets the Apps Script and AppSheet governance in the order that keeps production safe:
**Assess → Configure → Pilot → Validate → Expand**. Configure the platform admin guardrails first
(they are the floor), then define the review pattern and environments, then pilot on a scoped OU
before expanding. Every org-wide change runs under change control with a rollback noted.

> **Verify paths in your tenant.** Admin console and AppSheet console labels change over time. The
> paths below are current from Google's public documentation; confirm before clicking, and stage
> settings changes (they can take up to 24 hours to fully propagate, though usually faster).

---

## Phase 0 — Assess (inventory the estate)

Before changing any setting, know what exists.

1. Run **`GWAUTO-Discovery.ps1`** to inventory Apps Script projects and AppSheet apps — owners,
   OAuth scopes, connected data sources, and sharing exposure — into a baseline inventory.
2. Map each discovered automation to your data-classification scheme (Requirement 3): which touch
   confidential/regulated data, which are shared externally, which use broad OAuth scopes.
3. Record an **owner of record** for each artifact. Anything with no owner is the first governance
   backlog item.

**Gate:** you have a written inventory with owner, scope breadth, data sensitivity, and sharing for
every discovered automation.

---

## Phase 1 — Configure the admin guardrails (platform floor)

### 1a. Apps Script app access control (OAuth / data access)

Control which apps — including internal Apps Script projects — can access Workspace data.

1. In the Google Admin console, go to **Security → Access and data control → API controls**.
2. Open **App access control** (also labelled *Manage third-party app access*). Apps you have not
   configured as **Trusted**, **Limited**, **Specific Google data**, or **Blocked** are treated as
   **unconfigured**.
3. Set the **unconfigured apps** posture deliberately. Options, from most open to most closed:
   - *Allow users to access any third-party apps* (default — too open for a governed estate).
   - *Allow only apps that request basic Sign-in-with-Google profile info.*
   - *Don't allow users to access any third-party apps until configured.*
   Choose the most closed posture the business can tolerate; a common governed default is to block
   unconfigured apps and explicitly **trust** approved ones.
4. For **internal apps** (your own Apps Script projects), decide whether to check **Trust internal
   apps**. Untrusted internal apps can access only *unrestricted* services — a useful default that
   forces broad-scope internal automations through review before they are trusted.
5. **Restrict high-risk OAuth scopes** (edition-gated — Enterprise / Education Standard/Plus). For
   **Gmail** and **Drive**, set access so users can grant *non-high-risk* scopes but **high-risk
   scopes are restricted** unless the app is explicitly trusted. This is the tightest data-access
   guardrail for Apps Script.

**Rollback:** app access control settings are reversible — record the prior posture per service
before changing so you can restore it.

### 1b. AppSheet governance (sharing / external data / sign-in / deploy control)

Pick the lever that matches your edition.

**All editions — the Core security setting (all-or-nothing):**

1. In the Google Admin console, go to **Apps → Google Workspace**.
2. Select **AppSheet Core license security settings**.
3. Set **Turn on AppSheet Core security**. When on, it disables, for all users: app sharing with
   **external** users, **external** data-source connections, automation emails to **external**
   recipients, **external** API integration, and **webhooks**. This is a fast, blunt floor when you
   don't have Enterprise Plus.

**AppSheet Enterprise Plus — granular governance policies:**

1. Open the **AppSheet Admin Console** (from **Apps → Google Workspace → AppSheet**, or the
   **Admin → Policies** area of the AppSheet editor).
2. Define **governance policies** as *condition + severity (Error/Warning) + stage (edit / deploy /
   always)*. Start with these:
   - **Require sign-in** — every app must require users to sign in (condition on `[AuthRequired] =
     true`), severity **Error** at deploy.
   - **Restrict external sharing** — apps can only be shared to your domain(s); block external
     sharing, severity **Error**.
   - **Restrict external data sources** — constrain which connected sources are permitted.
   - **Control who can deploy** — *only certain people can mark apps as deployed* (this is what makes
     the review model enforceable).
   - **Data protection** — for example, data cannot be deleted through an app where that is a rule.
3. Apply policies at the right **level** — **organization** (highest precedence, org-wide), **team**,
   or **individual**. Where org and team policies overlap, AppSheet applies the **most restrictive**.
4. **Data region** (Enterprise Plus) — if you have data-residency requirements, set the AppSheet
   **app creation region** so data is stored/processed in the required geography.

**Rollback:** governance policies can be set to **Warning** (surface, don't block) during pilot, then
raised to **Error** once builders have adapted — a built-in soft rollback.

### 1c. Apps Script sharing & deployment standard

Apps Script has no single "sharing" admin toggle equivalent to AppSheet's; sharing is governed
through app access control (1a) plus a standard builders follow:

- **Web apps / add-ons** default to **execute-as the deploying user, access limited to the domain**
  — never "anyone, even anonymous" unless explicitly approved and reviewed.
- **Trusted deployments** (add-ons published org-wide) go through review and are added to the
  **trusted** app list in app access control, not left unconfigured.

---

## Phase 2 — Define the approval/review pattern and environments

### 2a. Review pattern (tiered)

Tier automations by risk so speed is preserved where it's safe:

- **Tier 0 — self-serve:** personal-scope, internal-only, no confidential data → builder ships, no
  review, but still appears in Discovery/inventory.
- **Tier 1 — reviewed:** shared beyond the builder, or moderate scope, or internal-confidential data
  → one named reviewer checks the checklist before it is **marked deployed**.
- **Tier 2 — reviewed + stakeholder sign-off:** broad OAuth scopes, external sharing, or
  regulated data → reviewer plus data-governance/security sign-off.

The checklist (see Best Practices) covers: scope breadth, connected-source sensitivity, sharing
posture, owner-of-record, and rollback. AppSheet's deploy-control policy and Apps Script deployment
control make "marked deployed" a real gate for Tiers 1–2.

### 2b. Environments

Standardize three environments so nothing ships straight from a builder's draft to production:

- **Build** — draft/dev; personal or team scope; no production data unless masked.
- **Pilot** — the named pilot OU/group; real guardrails applied; the review model exercised.
- **Production** — org-wide (or the approved audience); guardrails at **Error**; owner-of-record and
  rollback recorded.

### 2c. Reuse baseline

Give builders a governed starting point so they don't reinvent risk:

- **Apps Script:** shared libraries and vetted script templates (auth patterns, least-scope helpers).
- **AppSheet:** a small set of blessed app templates and approved connected-source patterns.

---

## Phase 3 — Pilot

1. Apply the admin guardrails (Phase 1) scoped to the **pilot OU/group** where possible (app access
   control and AppSheet policies can target OUs/teams).
2. Have pilot builders build and deploy through the review pattern and environments.
3. Run **`GWAUTO-Validation.ps1`** to confirm guardrail conformance, and **`GWAUTO-Report.ps1`** for
   coverage/risk in the pilot scope.
4. Keep AppSheet policies at **Warning** initially if builders need time to adapt; raise to **Error**
   once conformance is clean.

**Gate (must pass to expand):** builders can still ship; no unconfigured broad-scope app reaches
production; external sharing is blocked (or explicitly approved); every deployed artifact has an
owner and passed its tier's review. See the Testing guide for the exact gates.

---

## Phase 4 — Validate and Expand

1. Confirm all **Validation** gates pass in the pilot (Testing guide).
2. Expand the guardrails from the pilot OU/group to the wider organization under change control,
   raising any Warning-stage AppSheet policies to **Error**.
3. Re-run **Discovery → Validation → Report** at the org scope to confirm the estate conforms and to
   establish the ongoing baseline.
4. Schedule a recurring Discovery + Report (for example monthly) so new automations are caught and
   reviewed rather than accumulating as shadow IT.

**Rollback (any phase):** restore the recorded prior app-access-control posture per service; set
AppSheet policies back to **Warning** or off; revert the AppSheet Core security setting. Because the
guardrails are configuration (not data changes), rollback is a settings restore, not a data
recovery.
