# Requirements — Guide: Advanced KQL for SecOps

These are the **solution-specific** prerequisites for running the KQL enablement guide. The
**category baseline** — an active Microsoft 365 / Entra tenant, Defender licensing in general,
least-privilege admin roles, onboarding reach, network access to Defender endpoints, a pilot ring, a
Log Analytics workspace where required, and response governance — is covered once in
**`global-requirements-defender.md`** (**G1–G8**). Read that first; the items below layer on top of
it and are not repeated here.

Each requirement is stated as **Description / Why required / How to verify / How to implement if
missing**.

---

## R1. Advanced hunting access in Defender XDR

- **Description:** The learners can open **`security.microsoft.com → Investigation & response →
  Hunting → Advanced hunting`** and run queries against the Defender XDR schema.
- **Why required:** The core labs run KQL against the Defender advanced-hunting tables. Without
  access there is nothing to query.
- **How to verify:** Sign in and confirm the **Advanced hunting** blade loads and a trivial query
  (`DeviceInfo | take 1`) returns. Or run `WSKQL-Discovery.ps1`, which checks table reachability and
  freshness.
- **How to implement if missing:** Grant a Defender role that includes advanced hunting (e.g.
  **Security Reader** plus the hunting permission, or **Security Operator**); confirm the pillars are
  onboarded so tables have data (that onboarding is the per-pillar catalog solutions, not this one).

## R2. Telemetry actually flowing (tables have data)

- **Description:** The Defender XDR tables in scope (`DeviceProcessEvents`, `DeviceNetworkEvents`,
  `IdentityLogonEvents`, `EmailEvents`, `AlertEvidence`, …) — and, for the Sentinel labs, the
  workspace tables (`SigninLogs`, `SecurityEvent`, …) — return recent rows.
- **Why required:** Labs teach hunting on **real** data. Empty tables make the joins and aggregations
  meaningless and hide schema mistakes.
- **How to verify:** In Advanced hunting run `DeviceProcessEvents | where Timestamp > ago(24h) |
  count`; in Sentinel run `SigninLogs | where TimeGenerated > ago(24h) | count`. Both return rows. Or
  read the freshness section of `WSKQL-Discovery.ps1`.
- **How to implement if missing:** Confirm the relevant pillars are onboarded and licensed (the
  per-pillar solutions); allow ingestion time. Labs can still teach syntax on whatever tables do have
  data — the discovery script reports which are live.

## R3. A Microsoft Sentinel workspace (for the cross-tool labs)

- **Description:** A **Microsoft Sentinel**-enabled **Log Analytics workspace** with at least one
  connected data source, for the labs that contrast Defender advanced hunting with Sentinel.
- **Why required:** Part of the guide is teaching that the **same KQL** runs against **different
  tables** in the two surfaces, and when to use which. *Sentinel is a licensed/metered Azure service
  — verify current availability and cost model in your tenant.*
- **How to verify:** Open Sentinel, confirm the workspace loads and **Logs** runs a query; confirm at
  least one connector is ingesting (e.g. Entra sign-in logs).
- **How to implement if missing:** If no Sentinel workspace exists, the Defender-only labs still run
  in full; the Sentinel labs can be deferred or run in a demo/eval workspace. Standing up Sentinel is
  the **Sentinel deployment** catalog solution, not this guide.

## R4. A learner cohort and lab roles (least privilege)

- **Description:** A named group of learners — `Grp-KQLGuide-Cohort` — each holding a **read /
  hunt** role (e.g. **Security Reader** with hunting, or **Security Operator**). Authoring the lab
  **custom detection** needs a role that can create detection rules (**Security Administrator** or the
  granular equivalent), used by the instructor.
- **Why required:** Labs should run at **least privilege** — reading and hunting, not changing tenant
  security posture. Only the capstone detection-authoring step needs elevation, and only for the
  instructor.
- **How to verify:** Entra → **Roles and administrators** (or Defender **Permissions & roles**) shows
  the cohort holds read/hunt roles and the instructor holds the authoring role.
- **How to implement if missing:** Create `Grp-KQLGuide-Cohort` in Entra; assign read/hunt roles
  to learners (prefer **PIM-eligible** for any elevated role where Entra ID P2 is available — *verify
  licensing*). Reserve detection-authoring rights to the instructor.

## R5. A safe, read-only lab posture

- **Description:** An agreed rule that all labs are **read-only** — queries and (at the capstone
  only) an **alert-only** detection — with **no response actions** (isolate, delete, disable) taken
  during the guide.
- **Why required:** Learners run against **production telemetry**. Hunting is read-only by nature, but
  the posture must be explicit so no one experiments with a response action on a live host or mailbox.
- **How to verify:** Confirm the guide plan states read-only; confirm the capstone detection is
  created **alert-only** (no automatic remediation).
- **How to implement if missing:** State it in the guide kickoff; keep response actions out of
  scope and route any real finding to the SOC's normal incident process (category **G8**).

## R6. The PowerShell helper toolchain

- **Description:** A workstation with **Microsoft.Graph** (security modules) and, for the Sentinel
  labs run programmatically, the **Az** modules, signed in with an MFA-capable account holding at
  least read/hunt scopes; plus access to **Advanced hunting** in the portal for the interactive labs.
- **Why required:** The four delivered helpers check readiness, run a chosen lab query read-only,
  score the knowledge-check, and report cohort progress. The KQL lab pack itself runs in the portal
  or via the helper.
- **How to verify:** `Get-Module Microsoft.Graph -ListAvailable` returns a version; `Connect-MgGraph`
  succeeds; Advanced hunting loads in the portal.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser` (and `Az` if
  running the Sentinel labs from PowerShell); sign in. For Government cloud, connect with the matching
  environment/endpoints — *verify the correct endpoints for your cloud*.
