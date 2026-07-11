# 2. Requirements — Workshop: Microsoft Defender for Identity

The **category-level prerequisites** (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics, response governance) are covered once in **`global-requirements-defender.md`** — read that first. This section lists only the **workshop-specific** prerequisites. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Defender for Identity deployed with at least one healthy sensor
**Description:** MDI is active in the tenant and at least one sensor (on a domain controller / AD CS / AD FS) is reporting **Healthy**.
**Why required:** The labs read real identity telemetry, alerts, and entity timelines. Without a reporting sensor there is nothing to investigate and the entity pages/hunting tables are empty.
**How to verify:** In `https://security.microsoft.com` go to **Settings → Identities → Sensors**; confirm at least one sensor with health status **Healthy** and recent activity. Or run **`WSMDI-Discovery.ps1`** / **`WSMDI-Validate.ps1`**.
**How to implement if missing:** Onboard MDI sensors using the catalog **Defender XDR Deployment / Unified Onboarding** solution before running the workshop. Sensor onboarding is out of scope here.

## R2. A pilot/lab scope for the labs
**Description:** A defined **lab or pilot ring** — a small set of test users, a test domain controller environment, or a documented pilot slice of production — against which the labs are performed.
**Why required:** The workshop is delivered pilot-first (per the deployment model). Honeytoken tagging and investigation practice should not target live privileged production identities on the first pass.
**How to verify:** Confirm a named pilot group in Entra/Intune, or an isolated lab domain, exists and the facilitator has access to it.
**How to implement if missing:** Create a pilot ring (see the global requirements) or stand up a small AD lab. A non-production lab is the safest venue for the honeytoken and response-rehearsal labs.

## R3. ISPM assessment data populated
**Description:** Identity Security Posture Management assessments have run and produced recommendations.
**Why required:** Lab 4 reads the ISPM recommendations. Assessments populate over time after the sensors report; an empty ISPM view has nothing to work.
**How to verify:** In the portal, open **Secure Score** (or **Exposure management → Recommendations**) and filter to **Identity** recommendations; confirm items are listed. `WSMDI-Validate.ps1` reports whether posture data is present.
**How to implement if missing:** Allow a warm-up window (typically hours to a few days) after sensor onboarding for assessments to populate. *Warm-up timing varies — verify in your tenant.*

## R4. A candidate account for the honeytoken lab
**Description:** A **dormant, unused** directory account that can be designated the workshop honeytoken (created for the lab or an existing never-used account).
**Why required:** A honeytoken must be an account that legitimately should **never** authenticate, so any activity is high-fidelity. Using an active account produces false positives.
**How to verify:** Identify an account with no recent sign-ins. `WSMDI-Discovery.ps1` lists candidate low-/no-activity accounts (read-only) for the facilitator to choose from — it does **not** tag anything.
**How to implement if missing:** Create a decoy account in the lab (e.g. `svc-legacy-backup` in `contoso.com`) with a strong password, no group memberships beyond default, and never sign in with it.

## R5. Advanced hunting access (identity tables)
**Description:** Attendees can open **Advanced hunting** in the Defender portal and query the `Identity*` tables.
**Why required:** Labs 2 and 5 run the KQL pack (`WSMDI-LabQueries.kql`) against `IdentityLogonEvents`, `IdentityQueryEvents`, `IdentityDirectoryEvents`, and `IdentityInfo`.
**How to verify:** Open **Hunting → Advanced hunting**; run `IdentityInfo | take 5`; confirm rows return.
**How to implement if missing:** Grant attendees a role that includes advanced-hunting read (e.g. **Security Reader** plus hunting permissions, or a Defender XDR custom role). *Confirm role mapping in your tenant.*

## R6. Read-only Graph app or delegated permissions for the lab helpers
**Description:** The PowerShell lab helpers authenticate to Microsoft Graph with **read-only** security scopes.
**Why required:** `WSMDI-Discovery.ps1`, `WSMDI-Validate.ps1`, and `WSMDI-Report.ps1` pull alerts, secure-score, and account data for the labs.
**How to verify:** Run `Connect-MgGraph -Scopes "SecurityAlert.Read.All","SecurityEvents.Read.All"` and confirm consent succeeds. `WSMDI-Validate.ps1` checks scope availability.
**How to implement if missing:** Have a Global Administrator consent the delegated read scopes once, or register a read-only app registration for the workshop. Never grant write/response scopes for the labs.

## R7. Facilitator with the right role, attendees with reader access
**Description:** One **facilitator** (Security Administrator) to drive configuration steps (honeytoken tag); **attendees** with **Security Reader** (plus hunting) to follow along read-only.
**Why required:** Least privilege — only the facilitator needs the single configuration action (tagging the honeytoken); everyone else learns read-only and rehearses response in **simulate** mode.
**How to verify:** Entra → **Roles and administrators**; confirm the facilitator holds Security Administrator and attendees hold Security Reader.
**How to implement if missing:** Assign the roles before the session; keep response/write roles reserved for the approval-gated response rehearsal only.
