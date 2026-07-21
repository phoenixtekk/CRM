# 2. Requirements — Anomaly Detection & Application Reliability with Endpoint Analytics

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, enrollment, supported OS, network) are covered
once in the **Global Requirements — Intune Solutions** document; the items here are specific to
**reading Endpoint Analytics reliability signals and anomaly detection and acting on them**.

> **Verify feature and licensing specifics against Microsoft.** Endpoint Analytics reliability reports,
> anomaly detection, licensing entitlements, minimum device populations, data latency, and the exact
> OS builds that report each signal **change over time and can differ by cloud**. Every requirement
> below that names a specific portal path, licensing SKU, threshold, or feature-availability claim is
> flagged **"verify against current Microsoft documentation"** — do that for your own tenant rather
> than trusting a snapshot.

## R1. Endpoint Analytics enabled and reliability data flowing (see the parent product)
**Description:** Endpoint Analytics is **already turned on**, the data-collection policy is deployed,
and enrolled devices are reporting — specifically the **reliability** data (application reliability and
device/restart analytics), not only startup performance.
**Why:** This solution reads and acts on reliability signals; it does **not** enable Endpoint
Analytics. Enabling it, deploying data collection, and onboarding devices are the job of the **parent**
solution, *"Endpoint Analytics Deployment & Optimization in Microsoft Intune."*
**Verify:** In the Intune admin center (`https://intune.microsoft.com`), open **Endpoint analytics**
and confirm the reliability reports show data (not "collecting"/empty). *(Exact report location and
names — verify against current Microsoft documentation.)* Run `ENDPTREL-Discovery.ps1` for a scripted
readiness read.
**Implement:** Deploy the **parent** solution first (enable Endpoint Analytics + the data-collection
policy + onboard devices), then return here once reliability data is populating.

## R2. Licensing / entitlement for Endpoint Analytics
**Description:** The licensing/entitlement that includes Endpoint Analytics for your managed devices.
**Why:** Endpoint Analytics (and its reliability reports) are gated by entitlement; without it the
reports are unavailable regardless of enrollment.
**Verify:** Endpoint Analytics loads and reports render for your managed population. *(Exact licensing
requirements and which SKUs include Endpoint Analytics and anomaly detection — **verify against current
Microsoft documentation**; do not assume from this guide.)*
**Implement:** Assign the licensing your tenant requires per Microsoft's current documentation; the
parent solution covers this at the tenant level.

## R3. Anomaly detection available in your tenant/cloud
**Description:** The **anomaly detection** capability of Endpoint Analytics is present and active for
your tenant.
**Why:** The anomaly-detection portion of this practice depends on the feature being available; it may
be in preview, may vary by cloud (Commercial vs. GCC / GCC High / DoD), and may require a minimum
device population.
**Verify:** The anomaly view/report appears in Endpoint Analytics and shows either anomalies or "no
anomalies." *(Whether anomaly detection is GA or preview, its exact location, and its minimum-
population/latency requirements — **verify against current Microsoft documentation** for your cloud.)*
**Implement:** If it is unavailable, proceed with the application- and device-reliability portions of
this solution (which do not require it) and enable/adopt anomaly detection when it is available for
your tenant; flag it as a follow-up.

## R4. Sufficient device population reporting reliability data
**Description:** Enough managed devices are reporting reliability telemetry for the signals (and any
anomaly cohorts) to be statistically meaningful.
**Why:** Reliability scores and anomalies are **aggregate** signals; too few devices, or a brand-new
tenant, produces empty or noisy output and false anomalies.
**Verify:** The reliability reports show a device count consistent with your fleet, not a handful of
devices. *(Minimum device counts and per-cohort thresholds — **verify against current Microsoft
documentation.**)*
**Implement:** Broaden the Endpoint Analytics data-collection scope (via the parent solution) and allow
the reporting window to fill before drawing conclusions.

## R5. Device scope and data-collection scope defined
**Description:** A clear understanding of **which devices** are in scope for the reliability practice
(and therefore appear in the reports), driven by the Endpoint Analytics data-collection assignment.
**Why:** You triage what you can see; a signal you act on must map to a real, in-scope population, and
the review scope group in this solution must align with what Endpoint Analytics is collecting.
**Verify:** The Endpoint Analytics data-collection policy's assignment matches the population you intend
to review; the pilot group `Reliability – Pilot` (Implementation §2) is a subset of it.
**Implement:** Align the data-collection assignment (parent solution) with your intended scope, then
create `Reliability – Pilot` and later `Reliability – Review Scope` as subsets/aligned groups
(Implementation §2 and §8).

## R6. Reader access to Endpoint Analytics reports
**Description:** The operator has a role that can **read** Endpoint Analytics reports and device data.
**Why:** Reading application reliability, restart analytics, and anomalies requires appropriate Intune/
Endpoint Analytics read permissions.
**Verify:** Entra → **Roles and administrators**; the operator holds a role that grants Endpoint
Analytics read access (e.g. an Intune reader/administrator role). *(Exact role names and the least-
privilege role for Endpoint Analytics — **verify against current Microsoft documentation.**)*
**Implement:** Assign the appropriate read role; reserve higher privilege for the group-creating step
(R7).

## R7. Permission to create the review-scope group (state-changing step only)
**Description:** Rights to create and assign an Entra security group for the review cadence.
**Why:** The one state-changing script in this solution (`ENDPTREL-Set-ReviewScope.ps1`) creates/assigns
the `Reliability – Review Scope` group; that requires group-write permission (`Group.ReadWrite.All`).
**Verify:** The operator can create a security group in Entra → **Groups**.
**Implement:** Grant the operator group-creation rights (or have an identity admin run the state-
changer). All other scripts in this solution are **read-only**.

## R8. The parent and automated-fix companion solutions available (recommended)
**Description:** Access to the **parent** Endpoint Analytics solution and the **automated-fix
companion** (Proactive Remediations at Scale).
**Why:** This solution **points to** the parent for enablement and **hands scriptable fixes to** the
companion; the loop closes fastest when both are on hand. Neither is technically required to *read* the
signals, but the practice assumes them.
**Verify:** You have the parent solution deployed (R1) and the companion available for building
detection/remediation script packs.
**Implement:** Deploy the parent first; adopt the companion for the remediation side. This product does
**not** reproduce either — it references them.
