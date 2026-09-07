# Requirements

Confirm every prerequisite before you begin. Each lists **why** it is required, **how to verify**,
and **how to implement** if missing. Do not assume a prerequisite exists.

## 1. Intune (Endpoint Manager) administrator rights + licensing

- **Description:** **Intune Administrator** in the Microsoft Intune admin center, and Intune licenses
  (Intune Plan 1 / Microsoft 365 E3/E5 or equivalent) for the migrating users/devices.
- **Why required:** You will connect Apple enrollment, build ADE profiles, configuration/compliance
  policies, and app assignments.
- **How to verify:** Open **Intune admin center** (`intune.microsoft.com`; GCC High:
  `intune.microsoft.us`) → **Devices → Enrollment → Apple**; confirm it loads.
- **How to implement if missing:** Assign the role and licenses.

## 2. Apple Business Manager (ABM) administrator access

- **Description:** ABM administrator (or Device Enrollment Manager) able to view **Devices** and
  **re-assign** them between MDM servers, and to manage **Apps and Books (VPP)**.
- **Why required:** ABM is the pivot — you re-assign devices from the Jamf MDM server to the Intune
  MDM server, and move the VPP token.
- **How to verify:** Sign in to **business.apple.com** → **Devices** and **Apps and Books**; confirm
  you can see the current MDM-server assignment.
- **How to implement if missing:** Have an ABM administrator grant access.

## 3. Jamf Pro administrator access + API credentials

- **Description:** Jamf Pro admin to review PreStage enrollments, configuration profiles, smart
  groups, policies, and app scoping — plus **Jamf Pro API** credentials (an API client / bearer token)
  for the inventory export script.
- **Why required:** You must inventory what Jamf manages to translate it into Intune, and un-scope /
  unenroll devices as they migrate.
- **How to verify:** Sign in to Jamf Pro; under **Settings → API Roles and Clients**, confirm an API
  client with read scope exists (or create one).
- **How to implement if missing:** Create a Jamf Pro API client with read privileges for the export.

## 4. Intune Apple enrollment connected — MDM push cert, ADE token, VPP token

- **Description:** Intune's **Apple MDM push certificate**, at least one **Automated Device Enrollment
  (enrollment program) token**, and the **Apple VPP (Apps and Books) token** connected in Intune.
- **Why required:** Devices cannot enroll into Intune, and apps cannot deploy, without these.
- **How to verify:** Run **`JAMFMIG-Get-IntuneReadiness.ps1`** to report the push-cert expiry, ADE
  tokens, and VPP tokens; or check **Intune → Devices → Enrollment → Apple**.
- **How to implement if missing:** Add the Apple MDM push certificate, download an ADE token from ABM
  and upload it to Intune, and connect the VPP token. (Watch expiries — a lapsed push cert
  unenrolls the whole Apple fleet.)

## 5. A complete Jamf inventory and mapping worksheet

- **Description:** An export of Jamf computers, mobile devices, PreStage enrollments, configuration
  profiles, smart groups, and scoped apps, mapped to their Intune equivalents.
- **Why required:** Configuration and app scoping do not transfer; you rebuild them from this map.
- **How to verify:** Run **`JAMFMIG-Export-JamfInventory.ps1`** and confirm the CSV worksheet is
  populated.
- **How to implement if missing:** Run the export first; complete the mapping columns before Phase 2.

## 6. Entra ID groups for waves and platforms

- **Description:** Entra security groups for the migration waves and platform targets, e.g.
  `PILOT – Jamf Migration – Wave1`, `MIG – macOS – Corp`, `MIG – iPadOS – Shared`, `MIG – iOS – Users`.
- **Why required:** ADE profiles, configuration, compliance, and apps are assigned to these groups.
- **How to verify:** The groups exist with the right members.
- **How to implement if missing:** In **Entra admin center → Groups → New group**, create them.

## 7. A wipe window and end-user communications for supervised devices

- **Description:** A scheduled maintenance window to erase supervised devices, and comms so users back
  up and expect the reset.
- **Why required:** Supervised/ADE devices must be erased to change MDM; this is disruptive and must be
  planned.
- **How to verify:** Windows scheduled per wave; comms sent.
- **How to implement if missing:** Schedule the wipe window and notify users before each supervised
  wave.

## 8. Change approval and rollback plan

- **Description:** Approved change record per wave, with rollback defined (re-assign ABM to Jamf; note
  that supervised rollback needs another wipe).
- **Why required:** Migration changes management authority for the fleet; rollback is costly for
  supervised devices, so waves must be validated.
- **How to verify:** Change ticket approved per wave.
- **How to implement if missing:** Raise the change with this program's wave plan and rollback.

> **Category-wide prerequisites** common to every Migrations solution are listed in
> `global-requirements-migrations.md`. For a formal pre-migration readiness assessment and wave
> sizing, see the companion **MDM Migration Readiness Assessment & Wave Planning** solution.
