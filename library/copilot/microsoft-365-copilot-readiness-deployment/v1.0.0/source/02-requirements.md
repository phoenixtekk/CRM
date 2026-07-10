# 2. Requirements Guide — Microsoft 365 Copilot Readiness Assessment & Deployment

Verify **every** requirement before configuring. Each entry: **Description / Why / Verify / Implement-if-missing.** Category-wide prerequisites (supported M365 workloads, Copilot licensing baseline, Entra identity & MFA, data-readiness/oversharing controls, information-protection baseline, admin roles, network/client readiness, governance policy) are in `global-requirements-copilot.md`; do not repeat them — confirm them there first. This solution layers the deployment-specific readiness on top.

## 2.1 A readiness baseline captured (the scorecard)

- **Description:** A recorded starting-state assessment across the five dimensions — licensing, Entra identity, network/client, data hygiene, information protection — saved as `Copilot Readiness - Tenant - Assess`.
- **Why:** You cannot remediate blockers you have not measured, and the pilot gate compares against this baseline.
- **Verify:** Run `CPLTREADY-Discovery.ps1` and `CPLTREADY-OversharingScan.ps1`; confirm a scorecard exists.
- **Implement:** Run the discovery scripts, record the results as the baseline scorecard, and rank the blockers.

## 2.2 Copilot licenses available to assign

- **Description:** A pool of Microsoft 365 Copilot licenses sufficient for the pilot cohort, on a qualifying base plan. *Verify current base-plan prerequisites and licensing in your tenant.*
- **Why:** Copilot is a per-user add-on; a user cannot use Copilot without an assigned license on a qualifying base plan.
- **Verify:** `admin.microsoft.com` → `Billing` → `Licenses`; confirm free Copilot seats. Run `CPLTREADY-Discovery.ps1` (reports available seats).
- **Implement:** Acquire the required Copilot seats and confirm the pilot users hold a qualifying base plan. *Confirm the current prerequisite plan with Microsoft.*

## 2.3 Group-based licensing groups created

- **Description:** Two Entra groups: `Copilot License - Pilot Cohort - Pilot` (for group-based license assignment) and `Copilot Enablement - Pilot Cohort - Pilot` (the cohort roster).
- **Why:** Assigning licenses to a group (not user-by-user) makes the pilot and later waves repeatable and reversible.
- **Verify:** `entra.microsoft.com` → `Groups` → both groups exist. Run `CPLTREADY-Validate.ps1`.
- **Implement:** Create the groups; add the pilot users; use group-based licensing for the Copilot SKU.

## 2.4 Data-hygiene blockers identified

- **Description:** A list of the highest-risk oversharing conditions in scope for the pilot users' content — broad "Everyone/Everyone except external"/anonymous-link access on sites and files the cohort can reach.
- **Why:** Copilot surfaces anything the user can access; broad access is the primary AI-exposure risk and must be remediated before enablement.
- **Verify:** Run `CPLTREADY-OversharingScan.ps1`; review SharePoint sharing reports. *SharePoint Advanced Management / Restricted Content Discovery availability varies — verify in your tenant.*
- **Implement:** Remediate broad-access sites/links for the pilot scope before enabling (deep, tenant-wide remediation may be a separate oversharing engagement — see "where to go next").

## 2.5 A sensitivity-label baseline published

- **Description:** At least a minimal published sensitivity-label set in Microsoft Purview.
- **Why:** Labels are how sensitive content is kept out of AI processing where required and how Copilot use is audited.
- **Verify:** Purview portal → `Information Protection` → `Labels` shows published labels. Run `CPLTREADY-Validate.ps1`.
- **Implement:** Publish a baseline label taxonomy (see the Purview information-protection solutions) before broad enablement.

## 2.6 Client and network readiness for the cohort

- **Description:** The pilot users on a supported Microsoft 365 Apps channel/build with reachable Copilot endpoints. *Verify current client requirements.*
- **Why:** Copilot experiences in the apps require current clients and connectivity.
- **Verify:** Confirm the cohort's Apps update channel/build; run `CPLTREADY-Validate.ps1` for client/endpoint checks.
- **Implement:** Move the cohort to a supported channel/build and allow the required Microsoft 365/Copilot endpoints.

## 2.7 A pilot success-metrics definition

- **Description:** The agreed success criteria for the pilot — for example activation %, weekly active use, and a value signal (measured time saved or a self-reported impact survey).
- **Why:** The pilot gate requires demonstrated value before waves; the value dashboard reports against these metrics.
- **Verify:** The metrics and pass thresholds are written down. Run `CPLTREADY-Report.ps1` during the pilot.
- **Implement:** Define the metrics with the business sponsor before enabling the cohort.

## 2.8 An acceptable-AI-use position acknowledged

- **Description:** Acknowledgement that an acceptable-AI-use / data-handling policy will be adopted by the customer's compliance/legal function.
- **Why:** Copilot generates and surfaces content; the organization must define acceptable use and keep it auditable.
- **Verify:** A documented AI-use policy exists or is committed; Purview audit for Copilot is enabled.
- **Implement:** Adopt the policy (customer decision) and enable audit/eDiscovery for Copilot. *This is the customer's compliance/legal determination — this guide covers the technical controls only.*

---

## Checklist

- [ ] Supported M365 workloads, Copilot licensing baseline, Entra/MFA, admin roles, info-protection baseline, network/client, governance — see global requirements
- [ ] Readiness baseline scorecard captured — `CPLTREADY-Discovery.ps1`, `CPLTREADY-OversharingScan.ps1`
- [ ] Copilot seats available on a qualifying base plan — *verify*
- [ ] Group-based licensing groups created — `CPLTREADY-Validate.ps1`
- [ ] Data-hygiene blockers identified for the pilot scope
- [ ] Sensitivity-label baseline published
- [ ] Cohort client/network readiness confirmed
- [ ] Pilot success metrics and thresholds defined
- [ ] Acceptable-AI-use position acknowledged (customer)
