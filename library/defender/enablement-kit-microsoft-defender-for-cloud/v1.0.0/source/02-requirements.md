# 2. Requirements — Enablement Kit: Microsoft Defender for Cloud

The **category-level prerequisites** (tenant, Defender licensing, admin roles, onboarding reach, network access, pilot ring, Log Analytics, response governance) are covered once in **`global-requirements-defender.md`** — read that first. This section lists only the **enablement-kit-specific** prerequisites. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. A pilot Azure subscription with Defender for Cloud reachable
**Description:** An Azure subscription designated as the **pilot** for the enablement kit, with **Microsoft Defender for Cloud** visible in the Azure portal.
**Why required:** Every lab reads posture and alerts for a subscription. The enablement kit is delivered pilot-first so nothing production is changed.
**How to verify:** In the Azure portal, open **Microsoft Defender for Cloud → Overview** for the pilot subscription; confirm it loads. `WSMDC-Discovery.ps1` reports the subscription and its plan tiers.
**How to implement if missing:** Nominate a non-production subscription as the pilot (see the global pilot-ring requirement). Foundational CSPM is on by default for Azure subscriptions.

## R2. Secure Score data populated
**Description:** Secure Score and recommendations have populated for the pilot subscription.
**Why required:** Labs 1 and 5 read Secure Score and recommendations. Assessments take time to populate after a subscription is onboarded.
**How to verify:** Open **Defender for Cloud → Secure Score** / **Recommendations**; confirm a score and recommendation list appear. `WSMDC-Validate.ps1` reports whether Secure Score data is present.
**How to implement if missing:** Allow a warm-up window after the subscription is assessed (*timing varies — verify in your tenant*). Ensure `Microsoft.Security` is registered on the subscription.

## R3. At least one Defender (CWPP) plan enabled — for the alerts lab
**Description:** At least one **Defender plan** (e.g. Defender for Servers, Storage, or Resource Manager) is enabled on the pilot subscription, ideally with some sample alerts.
**Why required:** Lab 2 triages workload-protection alerts. With no plan on, no CWPP alerts are generated.
**How to verify:** **Defender for Cloud → Environment settings → [subscription] → Defender plans**; confirm at least one plan is **On**. Check **Security alerts** for existing alerts. `WSMDC-Discovery.ps1` lists plan tiers.
**How to implement if missing:** Enable an inexpensive plan on the pilot (e.g. **Defender for Resource Manager** or **Storage**) — *several plans are paid; verify current pricing/availability*. Microsoft provides a **sample-alerts** action in the portal to generate benign alerts for training. Keep plan changes on the **pilot** subscription only.

## R4. Reader access to the pilot subscription (attendees) / contributor for the facilitator
**Description:** Attendees hold **Security Reader** or **Reader** on the pilot; the facilitator holds a role that can toggle a plan (e.g. **Security Admin** / **Owner** on the pilot) for the `-WhatIf` rehearsal.
**Why required:** Least privilege — attendees learn read-only; only the facilitator demonstrates a change, and only in `-WhatIf` / with approval.
**How to verify:** Azure portal → subscription → **Access control (IAM)**; confirm role assignments.
**How to implement if missing:** Assign **Reader/Security Reader** to attendees and the change-capable role to the facilitator on the **pilot** subscription only.

## R5. Az PowerShell modules for the lab helpers
**Description:** The Az modules `Az.Accounts`, `Az.Security`, `Az.ResourceGraph` are available on the facilitator/attendee workstations.
**Why required:** `WSMDC-Discovery.ps1`, `WSMDC-Validate.ps1`, `WSMDC-Report.ps1`, and `WSMDC-SecureScore-Lab.ps1` use them for read-only posture/alert queries.
**How to verify:** `Get-Module -ListAvailable Az.Security, Az.ResourceGraph`. The scripts auto-offer to install Az if missing.
**How to implement if missing:** `Install-Module Az -Scope CurrentUser`. Run `Connect-AzAccount` before the labs.

## R6. Advanced hunting / Azure Resource Graph access
**Description:** Attendees can run **Azure Resource Graph** queries (Azure portal → Resource Graph Explorer) and/or **Advanced hunting** in Defender XDR for posture/alert data.
**Why required:** Labs 1, 2, and 5 use the ARG/KQL pack (`WSMDC-LabQueries.kql`) against the `securityresources` ARG tables and Defender alert tables.
**How to verify:** In **Resource Graph Explorer**, run `securityresources | take 5`; confirm rows return.
**How to implement if missing:** Grant **Reader** on the subscription (ARG honors resource RBAC) and, for Defender XDR hunting, an advanced-hunting-read role. *Confirm role mapping in your tenant.*

## R7. (Optional) A multicloud connector for Lab 4
**Description:** An existing **AWS or GCP connector** in Defender for Cloud, if the customer wants a live multicloud lab.
**Why required:** Lab 4 is richer with a real connector; without one it is taught as a concept walk-through.
**How to verify:** **Defender for Cloud → Environment settings**; look for AWS/GCP accounts. `WSMDC-Discovery.ps1` lists connectors.
**How to implement if missing:** Not required — Lab 4 can run as a concept lab. Standing up a connector is part of the CSPM/Secure-Score program solution, not this enablement kit.
