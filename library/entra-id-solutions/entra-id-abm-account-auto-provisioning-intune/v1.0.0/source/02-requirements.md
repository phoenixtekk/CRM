# 2. Requirements Guide — Entra ID + ABM Federation & Account Auto-Provisioning

Verify **every** requirement before configuring. Each entry: **Description · Why required · How to
verify · How to implement if missing.** Category-wide identity prerequisites are in
`global-requirements-entra-id-solutions.md` (tenant, licensing, admin roles, break-glass accounts,
UPN/domain hygiene, network) — confirm those first.

> **Object names used throughout (use verbatim):**
> Entra provisioning app `Apple Business Manager – Federation – Prod`;
> provisioning job `ABM SCIM Provisioning – Corp – Prod`;
> provisioning pilot group `Managed Apple ID Provisioning – Pilot – Stage`;
> provisioning production group `Managed Apple ID Provisioning – Corp – Prod`;
> per-scenario groups `iOS COD – Devices – Pilot`, `iOS BYOD – Users – Pilot`,
> `iOS Shared – Devices – Pilot` (and `… – Prod` variants);
> ADE profiles `iOS COD – ADE – Pilot`, `iOS Shared – ADE – Pilot`;
> compliance `iOS COD – Compliance – Pilot`, `iOS BYOD – Compliance – Pilot`,
> `iOS Shared – Compliance – Pilot`.

## 2.1 Microsoft Intune (and Entra ID P1+)
**Description:** Intune (Plan 1) for iPhone enrollment and policy; Entra ID P1+ for the federation
and provisioning features (see global G2).
**Why required:** Intune delivers the ADE / User Enrollment / no-affinity enrollment and compliance;
Entra delivers federation and SCIM provisioning.
**How to verify:** M365 admin center → **Billing → Licenses**; confirm Intune and Entra ID P1/P2.
**How to implement if missing:** Assign M365 E3/E5 / Business Premium (Intune + Entra P1 included).

## 2.2 Apple Business Manager (ABM) account
**Description:** An organization **Apple Business Manager** account (not Apple School Manager) with
an administrator who can configure identity/federation and manage devices and Managed Apple IDs.
**Why required:** ABM is where federation is linked, Managed Apple IDs live, and devices are assigned
to your MDM (Intune).
**How to verify:** Sign in to `https://business.apple.com` as an ABM Administrator.
**How to implement if missing:** Enroll the organization in Apple Business Manager (Apple docs);
verify the organization and assign an ABM Administrator.

## 2.3 Verified domain(s) for federation
**Description:** The email domain(s) your Managed Apple IDs will use, **verified in Entra** and ready
to be added in ABM for federation.
**Why required:** Federation is keyed on a domain; Apple must confirm the org owns the domain, and the
Managed Apple ID local part comes from the user's verified-domain email.
**How to verify:** Entra → **Identity → Settings → Domain names** shows the domain **Verified**.
**How to implement if missing:** Add and verify the public domain in Entra (DNS TXT record), then add
it on the ABM side per Apple docs.

## 2.4 The Entra "Apple Business Manager" provisioning application
**Description:** The gallery **Apple Business Manager** enterprise application used to provision
Managed Apple IDs by SCIM, added to your tenant as `Apple Business Manager – Federation – Prod`.
**Why required:** It is the supported automatic provisioning path from Entra to ABM (scoped to
groups, recurring sync, de-provision on removal).
**How to verify:** Entra → **Identity → Applications → Enterprise applications**; confirm the app
exists; run **`ABMPROV-Discovery.ps1`**.
**How to implement if missing:** Add it from the gallery (Implementation Step 2) and name it
`Apple Business Manager – Federation – Prod`.

## 2.5 Apple MDM Push (APNs) certificate
**Description:** A valid **Apple MDM Push certificate** connecting Intune to Apple for iOS management.
**Why required:** No iPhone can be managed by Intune without an active APNs certificate; it underpins
all three enrollment models.
**How to verify:** Intune → **Devices → Enrollment → Apple → Apple MDM Push certificate**; status
**Active**; run **`ABMPROV-Discovery.ps1`** (reports expiry).
**How to implement if missing:** Create/renew it (Implementation Step 6) with a **company** Apple ID
you record and reuse yearly.

## 2.6 ADE enrollment program token (for Corporate-Owned)
**Description:** An **Automated Device Enrollment** token linking an ABM **MDM server** entry to
Intune, so company-owned devices enroll zero-touch.
**Why required:** COD enrollment is driven by the ADE token; devices assigned to the Intune MDM server
in ABM flow to Intune and receive an ADE profile.
**How to verify:** Intune → **Devices → Enrollment → Apple → Enrollment program tokens**; a valid,
non-expired token exists; run **`ABMPROV-Discovery.ps1`**.
**How to implement if missing:** Create it (Implementation Step 7): download Intune's public key,
create the MDM server in ABM, upload the token back to Intune.

## 2.7 Supported iOS versions for modern enrollment
**Description:** iPhones on an iOS version that supports **account-driven User Enrollment** (BYOD) and
**account-driven device enrollment** (COD).
**Why required:** The modern, Managed-Apple-ID-based flows require recent iOS; older devices fall back
to legacy enrollment.
**How to verify:** Check device iOS versions in Intune → **Devices → All devices**; confirm against
Apple's stated minimums for account-driven enrollment.
**How to implement if missing:** Update target iPhones to a supported iOS version before enrolling.

## 2.8 User/group scoping and a pilot group
**Description:** Entra security groups that scope provisioning and each enrollment model, plus a small
**pilot** group, all created with the naming convention above.
**Why required:** Federation and provisioning must be **piloted on a scoped group first** — you do not
federate/provision the whole tenant at once. Per-scenario groups keep COD, BYOD, and Shared cleanly
separated.
**How to verify:** Entra → **Groups**; confirm the provisioning + per-scenario groups exist; run
**`ABMPROV-Report.ps1`**.
**How to implement if missing:** Create them with **`ABMPROV-Set-ScopeTargeting.ps1`** (Implementation
Step 1).

## 2.9 Existing-Apple-ID conflict review readiness
**Description:** A plan and access to detect personal Apple IDs that use your verified-domain email
(domain capture conflicts) and resolve them before widening federation.
**Why required:** Conflicted users fail Managed Apple ID provisioning and cannot complete account-
driven enrollment until resolved.
**How to verify:** ABM provides the conflict / domain-capture report on the federation/identity screen
(deferred to Apple docs); plan user communications for the change window.
**How to implement if missing:** Run the conflict review in ABM (Implementation Step 4), notify
affected users to change their personal Apple ID email, then re-check before expanding.

---
## Checklist
- [ ] Intune + Entra ID P1+ licensing assigned (2.1)
- [ ] Apple Business Manager account with an Administrator (2.2)
- [ ] Verified domain(s) for federation (2.3)
- [ ] Entra `Apple Business Manager – Federation – Prod` provisioning app added (2.4)
- [ ] Apple MDM Push (APNs) certificate Active (2.5)
- [ ] ADE enrollment program token valid (2.6) — for Corporate-Owned
- [ ] Target iPhones on a supported iOS version (2.7)
- [ ] Provisioning + per-scenario scope groups created, incl. pilot (2.8)
- [ ] Existing-Apple-ID conflict review planned (2.9)
