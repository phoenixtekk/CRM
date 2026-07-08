# 2. Requirements Guide — Financial / FINRA Communications Compliance (Microsoft Purview)

Confirm each item **before** starting the Implementation steps. These are **in addition to** the six
shared prerequisites in `global-requirements-purview.md` (tenant/licensing, least-privilege Purview
roles, Security & Compliance PowerShell + Graph toolchain, in-scope data sources, compliance/records/
legal stakeholders, and a pilot scope + change control) — that file is the baseline and is **not**
repeated here. The requirements below are the ones **specific to a FINRA/SEC communications-supervision
program**.

Each requirement is stated as **Description · Why required · How to verify · How to implement**.
Purview features are **licensing-/plan-dependent and some are in preview**, and the portal evolves —
where noted, **verify availability against your own tenant and Microsoft licensing; do not assume.**

---

## 2.1 Communication Compliance entitlement (E5 / E5 Compliance)
- **Description:** The **Communication Compliance** capability must be licensed and visible in the
  Purview portal. It is part of **Microsoft 365 E5** / the **E5 Compliance** add-on (or equivalent);
  several **regulated-conduct trainable classifiers** are separately gated and **some are in preview**.
- **Why required:** Without the entitlement, the supervisory-review area and the regulated-conduct
  classifiers this program relies on are unavailable.
- **How to verify:** Purview portal → **Communication Compliance** is present and openable; in
  `Settings` the policy/classifier options load. **Confirm the exact entitlement with Microsoft
  licensing — do not assume from portal visibility alone.**
- **How to implement if missing:** Assign/purchase the required licensing (GR §1) before configuring;
  flag any classifier shown as *preview* for a licensing/risk check with Compliance.

## 2.2 Designated supervisory principals and role separation
- **Description:** The people who will **review** supervised communications must be **designated
  supervisory principals** (per the firm's WSPs), placed in the **Communication Compliance Analysts**
  role, and **separated** from the **Admin** (policy builders), **Investigators** (escalation), and
  **Viewers** (oversight, reports-only) — and separated from the population they supervise.
- **Why required:** FINRA supervision requires review **by an appropriately qualified person who is not
  supervising themselves**; collapsing builder/reviewer/subject into one identity undermines both the
  control and its defensibility.
- **How to verify:** Purview portal → `Settings → Roles & scopes → Permissions` — confirm the four role
  groups exist and membership is separated; `CCFIN-Discovery.ps1` prints the separation snapshot.
- **How to implement if missing:** With Compliance/Legal, assign designated principals to **Analysts**,
  keep IT config staff in **Admin**, and record who may **not** review whom. Avoid the combined
  **Communication Compliance** role group except for a tiny pilot (it collapses separation).

## 2.3 Approved supervised population and exclusions (registered persons)
- **Description:** The **supervised population** must be the **approved registered/covered persons**
  (typically registered representatives, principals, and associated persons the firm's WSPs place under
  communications supervision), expressed as a group, with an explicit **exclusion** set for anyone who
  must not be monitored.
- **Why required:** Supervision scope is a **compliance determination**, not "everyone"; over-scoping is
  a privacy and works-council/employment risk, under-scoping is a supervision gap.
- **How to verify:** Confirm the named supervised group and exclusion group with Compliance;
  `CCFIN-EvidenceCheck.ps1` reports the policy's supervised/excluded scope.
- **How to implement if missing:** Have Compliance define the registered/covered population; create the
  supervised group (`FINRA Supervised – Pilot` for the pilot) and the exclusion group
  (`FINRA Excluded – Privacy`).

## 2.4 Firm conduct lexicons and Written Supervisory Procedures (WSPs)
- **Description:** The firm's **prohibited-conduct language** (guarantees, misrepresentation, selling
  away, unregistered activity, undisclosed outside business, complaint language, etc.) as **keyword
  dictionaries ("lexicons")**, plus the **WSPs** that define what is supervised, at what sampling rate,
  and by whom.
- **Why required:** Detection is only as good as the firm's own lexicon; the WSPs are the authority for
  scope, sampling, and reviewer assignment — the tool implements them, it does not invent them.
- **How to verify:** Compliance provides the lexicon term lists and the current WSP supervision section;
  confirm the sampling rate and reviewer mapping are documented.
- **How to implement if missing:** Have Compliance supply the lexicon(s) and the WSP supervision
  requirements before building any rule; capture them as the `FINRA Lexicon – Conduct` dictionary and
  the policy sampling/reviewer design.

## 2.5 Channels and connected communication sources in scope
- **Description:** The **communication channels** to supervise — Teams chat/channels, Exchange email,
  Viva Engage, and any **third-party sources** (e.g. text/IM, social, or trading-desk chat) ingested via
  **Microsoft 365 data connectors** — and confirmation each in-scope source is actually flowing.
- **Why required:** A supervision program that omits a channel registered persons use (e.g. text/IM) is
  a known examination finding; connectors must be **configured and verified**, not assumed.
- **How to verify:** Purview portal → **Data connectors** shows the required connectors healthy; confirm
  Teams/Exchange/Viva Engage coverage with the messaging owners.
- **How to implement if missing:** Stand up and validate the required data connectors (a prerequisite
  project where third-party sources are in scope), then include those sources in the policy.

## 2.6 Records-retention schedule and immutability decision (evidence layer)
- **Description:** The **retention period** for supervised communications and review activity, and
  whether **immutability/Preservation Lock** is required — the firm's **books-&-records** decision
  (SEC Rule 17a-4 / FINRA Rule 4511 territory), owned by **Compliance/Records**.
- **Why required:** The evidence pillar preserves communications and review activity; the **period and
  the lock are a records determination**. **Preservation Lock is irreversible** — it must be an
  approved, deliberate decision, not a technical default.
- **How to verify:** Compliance/Records provides the retention period and states whether immutability is
  required; `CCFIN-EvidenceCheck.ps1` reports current retention/immutability coverage.
- **How to implement if missing:** Do **not** apply any lock until Compliance/Records has approved the
  schedule and the immutability decision in writing; configure retention accordingly (Implementation
  Step 7).

## 2.7 Privacy configuration and legal basis
- **Description:** The agreed **privacy option** for the review experience (e.g. **pseudonymized
  usernames** where the firm's privacy/works-council posture requires it) and a documented **lawful
  basis / notice** for supervising employee communications.
- **Why required:** Supervision touches employee privacy; several jurisdictions and works councils
  require pseudonymization and/or notice, and reviewer over-reach is itself a risk.
- **How to verify:** Privacy/Legal states the required privacy option and confirms notice/lawful basis;
  the setting is checked in `Settings → Communication Compliance`.
- **How to implement if missing:** Set the agreed privacy option before any policy runs; do not go live
  without Privacy/Legal sign-off on the lawful basis.

## 2.8 Change control, pilot scope, and rollback authority
- **Description:** A named **pilot scope** (the `FINRA Supervised – Pilot` population, in
  **simulation/test**), a **change window/approval**, and clear **rollback** authority for each stage.
- **Why required:** Supervision and retention changes are high-impact; the category model mandates
  **pilot-in-simulation-first** with explicit pass/fail gates and documented rollback.
- **How to verify:** Confirm the pilot population, that simulation mode is available for the policy, the
  approval path, and who may authorize rollback.
- **How to implement if missing:** Define the pilot and change control before enforcing anything;
  agree that retention **Preservation Lock** has a separate, explicit approval (it cannot be rolled
  back).

---

### Requirements summary
| # | Requirement | Verify with |
|---|---|---|
| 2.1 | Communication Compliance entitlement (E5 / E5 Compliance; some classifiers preview) | Portal + Microsoft licensing |
| 2.2 | Designated principals + role separation | Roles & scopes; `CCFIN-Discovery.ps1` |
| 2.3 | Approved supervised population + exclusions | Compliance; `CCFIN-EvidenceCheck.ps1` |
| 2.4 | Firm conduct lexicons + WSPs | Compliance-supplied term lists / WSP |
| 2.5 | Channels + connected sources in scope | Data connectors; messaging owners |
| 2.6 | Retention schedule + immutability decision | Compliance/Records; `CCFIN-EvidenceCheck.ps1` |
| 2.7 | Privacy option + lawful basis | Privacy/Legal; portal settings |
| 2.8 | Change control, pilot scope, rollback | Change management |

*Regulatory applicability, what constitutes a violation, the retention schedule, the immutability
decision, and any supervisory/disciplinary action are **deferred to Compliance, Records, Legal, and the
firm's designated supervisory principals** — this solution provides the technical method and the
evidence, not the determination.*
