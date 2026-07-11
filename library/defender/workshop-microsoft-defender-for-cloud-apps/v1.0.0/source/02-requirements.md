# 2. Requirements — Workshop: Microsoft Defender for Cloud Apps

The **category-level prerequisites** (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics, response governance) are covered once in **`global-requirements-defender.md`** — read that first. This section lists only the **workshop-specific** prerequisites. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Defender for Cloud Apps licensed and active
**Description:** MDA is licensed (standalone or via E5 Security / E5 Compliance bundles) and the **Cloud apps** area is reachable in the Defender portal.
**Why required:** Every lab uses the MDA console. Without the license the Cloud apps blades, connectors, and policies are unavailable.
**How to verify:** In `https://security.microsoft.com`, confirm the **Cloud apps** section is present and opens. `WSMCA-Validate.ps1` checks that Graph returns cloud-app data. *Confirm the exact plan in Admin center → Billing → Licenses — verify current availability.*
**How to implement if missing:** Assign the MDA plan (often bundled in E5 Security) before running the workshop.

## R2. A Cloud Discovery data source
**Description:** A source of traffic for **Cloud Discovery** — a continuous feed from **Defender for Endpoint**, a network appliance log, or a manually uploaded traffic log (snapshot report).
**Why required:** Lab 1 reads a discovery report. With no data source there are no discovered apps to rank.
**How to verify:** In **Cloud apps → Cloud Discovery**, confirm a dashboard with discovered apps exists, or that the Defender for Endpoint integration is on. `WSMCA-Discovery.ps1` reports whether discovery data is present.
**How to implement if missing:** Turn on the **Defender for Endpoint → MDA** integration (fastest), or upload a sample traffic log to produce a **snapshot report** for the lab. *Verify current integration steps in your tenant.*

## R3. At least one connected app (API connector)
**Description:** At least one **app connector** (e.g. Microsoft 365, or another supported SaaS app) is connected via API.
**Why required:** Lab 2 explores a connected app's activity and app-governance signal. Without a connector there is no in-app activity to examine.
**How to verify:** In **Cloud apps → Connected apps** (App connectors), confirm at least one connected app with recent activity. `WSMCA-Validate.ps1` flags connector presence via available signal.
**How to implement if missing:** Connect the **Microsoft 365** connector at minimum (native, quick). Additional SaaS connectors can be added later per the Cloud App DLP solution.

## R4. App governance enabled (for the OAuth/app-behavior labs)
**Description:** **App governance** (the app-behavior monitoring capability within MDA) is turned on.
**Why required:** Labs 2 and 3 use app governance and the OAuth app inventory to review third-party app behavior and risk.
**How to verify:** In **Cloud apps → App governance**, confirm it is enabled and shows app data. *App governance availability/plan — verify current in your tenant.*
**How to implement if missing:** Enable app governance in the MDA settings (may require the appropriate plan). If it cannot be enabled for the workshop, Lab 3 can still use the **OAuth apps** inventory (Enterprise applications / MDA OAuth apps) read-only.

## R5. Advanced hunting access (CloudAppEvents)
**Description:** Attendees can open **Advanced hunting** and query the `CloudAppEvents` table.
**Why required:** Labs 2 and 5 run the KQL pack (`WSMCA-LabQueries.kql`) against `CloudAppEvents` and related tables.
**How to verify:** Open **Hunting → Advanced hunting**; run `CloudAppEvents | take 5`; confirm rows return.
**How to implement if missing:** Grant attendees a role including advanced-hunting read (e.g. **Security Reader** plus hunting). *Confirm role mapping in your tenant.*

## R6. Read-only Graph permissions for the lab helpers
**Description:** The PowerShell lab helpers authenticate to Microsoft Graph with **read-only** scopes.
**Why required:** `WSMCA-Discovery.ps1`, `WSMCA-Validate.ps1`, `WSMCA-Report.ps1`, and `WSMCA-OAuthApp-Lab.ps1` read alerts, service principals, and OAuth grants.
**How to verify:** `Connect-MgGraph -Scopes "SecurityAlert.Read.All","Application.Read.All","Directory.Read.All"` consents successfully.
**How to implement if missing:** Have a Global Administrator consent the delegated read scopes once, or register a read-only workshop app. Never grant write/consent-management scopes for the labs.

## R7. Facilitator with the right role, attendees read-only
**Description:** One **facilitator** with an MDA administrative role (to create the report-only policy); **attendees** with **Security Reader** (plus hunting) to follow along read-only.
**Why required:** Least privilege — only the facilitator authors the single **report-only** session policy; everyone else learns read-only and rehearses enforce/disable in **simulate** mode.
**How to verify:** Confirm the facilitator holds the MDA admin / Security Administrator role and attendees hold Security Reader.
**How to implement if missing:** Assign roles before the session; reserve enforce/disable actions for the approval-gated rehearsal only.
