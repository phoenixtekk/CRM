# 2. Requirements — Security Optimization Assessment: Defender for Identity

The category-wide prerequisites (target tenant, least-privilege read-only access, Graph/management API access, licensing awareness, defined scope and point-in-time baseline, the best-practice reference, secure output handling, and remediation ownership) are in the separate **Global Requirements — Assessments** file — read it first and do not repeat those here. Below are only the prerequisites **specific to assessing Defender for Identity**. Each item: **Description / Why required / How to verify / How to implement if missing.**

## R1. Defender for Identity is provisioned (even partially)
**Description:** MDI is enabled in the tenant with at least one sensor installed, so there is a configuration and sensor list to read.
**Why required:** The assessment scores an existing MDI setup; a tenant with no MDI at all is a deployment engagement, not an assessment (though the AD-inventory / coverage-gap view still has value).
**How to verify:** In `security.microsoft.com` → **Settings → Identities**, confirm the MDI workspace and at least one sensor appear.
**How to implement if missing:** If MDI is not provisioned, use the **DEFXDR** onboarding path first. Partial sensor coverage is expected — measuring the gap is the point.

## R2. Read-only Active Directory access to enumerate the identity inventory
**Description:** The ability to read the AD forest/domains to list **all domain controllers** and locate **AD FS** and **AD CS** roles — the denominator for sensor coverage.
**Why required:** Sensor coverage is only meaningful against the true count of DCs/AD FS/AD CS; MDI's own sensor list cannot reveal servers that have **no** sensor.
**How to verify:** From a domain-joined host with RSAT, `Get-ADDomainController -Filter *` returns all DCs and `Get-ADForest` returns the forest. A normal domain user can read this.
**How to implement if missing:** Install RSAT / the `ActiveDirectory` module; run from a domain-joined host as a read-only domain account. No elevated AD rights are needed for enumeration.

## R3. Graph read access for identity Secure Score and advanced hunting
**Description:** Microsoft Graph read scopes for **Secure Score** (`SecurityEvents.Read.All`) and **advanced hunting** (`AdvancedHunting.Read.All`) over `IdentityInfo`, `IdentityDirectoryEvents`, `IdentityLogonEvents`.
**Why required:** ISPM ranking and detection-activity signals come from these; identity Secure Score provides the posture-recommendation signal.
**How to verify:** In `security.microsoft.com` → **Advanced hunting**, run `IdentityInfo | take 1`. `Connect-MgGraph` with the read scopes succeeds.
**How to implement if missing:** Assign **Security Reader** / **Global Reader** and consent the read scopes. *Verify current scope names and hunting retention.*

## R4. Portal read access to MDI sensor health, DSA, and honeytoken configuration
**Description:** Read access to **Settings → Identities** for sensor health, the **directory-service account** configuration, **honeytoken (tagged) entities**, and detection exclusions — some of which have no public read API today.
**Why required:** Sensor health, DSA, and honeytoken posture are core checks; where no API exists, the script collects what it can and flags the rest for portal confirmation.
**How to verify:** You can open **Settings → Identities → Sensors / Directory service accounts / Entity tags** in the Defender portal as the assessor.
**How to implement if missing:** Assign a read-only Defender role that can view Identities settings. Record portal-confirmed values against the script's `verify` flags. *Verify current MDI settings layout and any new read APIs.*

## R5. The expected server inventory is defined
**Description:** A documented, authoritative count/list of domain controllers (and AD FS / AD CS / Entra Connect servers) in scope.
**Why required:** Coverage percentages need the real denominator; unmanaged or newly-promoted DCs are exactly the blind spots the assessment must surface.
**How to verify:** You have the DC/AD FS/AD CS list from AD (R2) and can confirm it matches operational reality with the AD team.
**How to implement if missing:** Reconcile the AD-derived list with the AD team before scoring so no DC is missed; `SOAMDI-Coverage.ps1` uses this as the denominator.

## R6. A named best-practice baseline for scoring
**Description:** The reference the score is measured against — Microsoft's **Defender for Identity** deployment/best-practice guidance and the **identity Secure Score** recommendations, and/or the org standard.
**Why required:** A score is only meaningful against a stated reference; the report names it so results are defensible and comparable.
**How to verify:** The baseline is documented in scope and echoed in the report header. *MDI guidance evolves — verify against current Microsoft guidance at run time.*
**How to implement if missing:** Adopt Microsoft's MDI guidance + identity Secure Score as the default reference; note deliberate deviations as accepted exceptions.

## R7. Secure destination for the findings report
**Description:** A restricted location for the HTML/CSV output, which names exactly which domain controllers are un-sensored.
**Why required:** A list of your identity blind spots is extremely sensitive; it must be handled on a need-to-know basis.
**How to verify:** A restricted location exists and access is limited to the security owners.
**How to implement if missing:** Provision a restricted location before the run; treat output as confidential. *Risk-acceptance of any finding is the customer's decision.*
