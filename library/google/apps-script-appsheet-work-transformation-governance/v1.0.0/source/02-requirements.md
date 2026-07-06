# Requirements

Before configuring Apps Script and AppSheet governance, confirm each prerequisite below. These are
in addition to the shared **Global Requirements — Google Workspace & Gemini Solutions** (a
provisioned tenant with a super-admin, a pilot OU/group and change control, and engaged
security/data-governance stakeholders). Each item lists **Description**, **Why required**, **How to
verify**, and **How to implement if missing**.

> **Vendor boundary.** Google Admin console and AppSheet console paths below are authored from
> Google's public documentation and are current as of authoring; menu labels move over time, so
> **verify each path in your tenant**. Edition-gated capabilities (for example OAuth high-risk scope
> restriction and AppSheet governance policies) are flagged where they apply.

---

## 1. Super-admin (or delegated) access to the Google Admin console

- **Description:** An account with the privileges to change **Security → Access and data control →
  API controls** (app access control) and **Apps → Google Workspace → AppSheet** settings.
- **Why required:** The platform guardrails — Apps Script app access/OAuth control and the AppSheet
  security setting/governance policies — are set here.
- **How to verify:** Sign in to **admin.google.com**; confirm you can open **Security → Access and
  data control → API controls** and **Apps → Google Workspace**.
- **How to implement if missing:** Have a super-admin grant the **Services** and **Security**
  admin privileges, or perform the changes with a super-admin.

## 2. AppSheet administration access and edition awareness

- **Description:** Access to manage AppSheet for the organization — the **AppSheet Admin Console**
  (now available to any admin with sufficient privileges) and, for policy-based governance, an
  **AppSheet Enterprise Plus** account.
- **Why required:** The single **AppSheet Core security setting** (in the Google Admin console)
  disables external sharing, external data sources, external automation email, external API, and
  webhooks for all users at once. **Granular governance policies** — *require sign-in, restrict
  external sources, restrict sharing to a domain, restrict who can mark an app deployed, data
  region* — require **Enterprise Plus**. Know which lever you have.
- **How to verify:** In the Google Admin console open **Apps → Google Workspace → AppSheet**; open
  the **AppSheet Admin Console**; check the AppSheet license type on your org.
- **How to implement if missing:** For all-org lockdown, the Core security setting is sufficient. For
  per-condition governance policies, obtain Enterprise Plus for the builders/teams in scope.

## 3. A data-governance baseline (data classification + connected-source inventory)

- **Description:** A basic data-classification scheme (what is public/internal/confidential/regulated)
  and a starting inventory of the **connected data sources** automations touch (Sheets, Drive,
  Cloud SQL, third-party sources).
- **Why required:** Guardrails are meaningless without knowing which automations reach sensitive
  data. The review model tiers on data sensitivity and OAuth-scope breadth.
- **How to verify:** Confirm a classification scheme exists and that Discovery output (see the
  Implementation guide) can be mapped to it.
- **How to implement if missing:** Adopt a minimal three-tier classification and run the Discovery
  script to seed the connected-source/scope inventory before writing policy.

## 4. High-risk OAuth-scope restriction capability (edition-gated)

- **Description:** The Admin-console ability to **restrict access to high-risk OAuth scopes** (Gmail
  and Drive) while still allowing non-high-risk scopes — available on **Enterprise, Education
  Standard, or Education Plus**.
- **Why required:** This is the tightest data-access guardrail for Apps Script: it blocks apps from
  obtaining high-risk Gmail/Drive scopes unless the app is explicitly **trusted**.
- **How to verify:** In **Security → Access and data control → API controls → App access control**,
  select a Google service (for example Gmail) and confirm you can set restricted access to high-risk
  scopes.
- **How to implement if missing:** If your edition doesn't offer high-risk scope restriction, rely
  on app access control (trusted/limited/blocked) plus the review model to constrain scopes.

## 5. A named review model (roles + checklist)

- **Description:** A defined **approval/review model** — who reviews an automation before it is
  marked deployed, the risk tiers (self-serve vs reviewed), and the checklist they apply
  (scope breadth, data sensitivity, sharing, owner-of-record).
- **Why required:** Guardrails set the floor; the review model catches the medium/high-risk builds
  that clear the floor but still need a human decision. AppSheet's *"only certain people can mark an
  app as deployed"* policy and Apps Script deployment control make it enforceable.
- **How to verify:** Confirm named reviewers and a written checklist exist and are agreed with the
  business.
- **How to implement if missing:** Define two or three risk tiers and a one-page review checklist
  (see the Best Practices guide) and name at least one reviewer before the pilot.

## 6. A pilot OU/group and change control

- **Description:** A named **pilot organizational unit or group** to apply guardrails to first, and a
  **change-control** process for the org-wide settings (app access control and AppSheet security
  affect production access to data and apps).
- **Why required:** App access control and AppSheet security changes can block users from apps they
  rely on; piloting on a scoped OU proves the design before fleet-wide rollout, and change control
  protects production.
- **How to verify:** Confirm a pilot OU/group exists and a change window/approval path is available.
- **How to implement if missing:** Create a pilot OU/group and agree the change-control process with
  the owners before changing org-wide settings.

---

*Deployment across this solution follows **Assess → Configure → Pilot → Validate → Expand**, with
explicit pass/fail gates and a documented rollback for every production change.*
