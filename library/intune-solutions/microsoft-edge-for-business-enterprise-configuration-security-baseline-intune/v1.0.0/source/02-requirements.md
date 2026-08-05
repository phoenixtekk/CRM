# 2. Requirements — Microsoft Edge for Business: Enterprise Configuration & Security Baseline (Intune)

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide prerequisites
(tenant, Intune licensing, admin roles, device enrollment, pilot group, supported Windows baseline,
network) are covered once in the **Global Requirements — Intune Solutions** document; the items here are
specific to configuring and hardening **Microsoft Edge for Business on Windows** via Intune.

> **Scope reminder.** These requirements are for **Microsoft Edge on Windows** managed by Intune —
> Settings Catalog (Microsoft Edge ADMX-backed) configuration plus the Microsoft Edge security baseline,
> default-browser enforcement, and IE mode. macOS/iOS/Android Edge management is out of scope.

## R1. Microsoft Edge (Chromium) installed on target Windows devices
**Description:** A current channel of **Microsoft Edge for Business** (the Chromium-based Edge) is
installed on the target Windows devices.
**Why:** Policies and the security baseline apply to the installed browser; ADMX-backed settings only take
effect where Edge is present.
**Verify:** On a device, open `edge://version` (shows the version and channel); or Intune →
**Apps → Windows** to confirm any managed Edge deployment. On Windows 11 and current Windows 10, Edge is
in-box.
**Implement:** Edge ships in-box with supported Windows. If you manage the channel explicitly, deploy
**Microsoft Edge for Business (Stable)** from Intune → **Apps → Windows → Add → Microsoft Edge for
Business**, or rely on the in-box browser and manage its channel with the **Microsoft Edge Update**
policies (Implementation, Step 8).

## R2. Edge policies visible in the Intune Settings Catalog
**Description:** The **Microsoft Edge** ADMX-backed policy category is available in Intune's **Settings
Catalog**.
**Why:** This solution configures Edge through the Settings Catalog (not a legacy custom ADMX import).
**Verify:** Intune (`https://intune.microsoft.com`) → **Devices → Configuration → Create → New policy** →
Platform **Windows 10 and later**, Profile type **Settings catalog** → **Add settings** → search
**Microsoft Edge**; you should see the **Microsoft Edge** and **Microsoft Edge Update** setting groups.
**Implement:** The Edge settings are built in; no import is needed. If a specific setting is missing, your
Edge/Settings-Catalog version may predate it — **verify the exact policy name** for your version and use
the equivalent, or import the Edge ADMX as a fallback.

## R3. Enterprise password solution in place (for the password-manager finding)
**Description:** A sanctioned enterprise password solution (corporate password manager / vault) users can
use instead of the Edge built-in password manager.
**Why:** Turning off `PasswordManagerEnabled` steers users **to** the enterprise solution; disabling the
browser manager without an alternative causes support tickets.
**Verify:** Confirm the organization's approved password manager is deployed/available to the pilot users.
**Implement:** Deploy or confirm the enterprise password solution and brief users before enabling the
policy. (Selecting or deploying that product is out of scope for this solution.)

## R4. Enterprise Mode Site List authored (for IE mode)
**Description:** An **Enterprise Mode Site List** XML (`EdgeForBusiness-EMSiteList.xml`) listing the
legacy line-of-business URLs that must render in **IE mode**.
**Why:** IE mode only applies to sites in this list; without it, `InternetExplorerIntegrationLevel` has
nothing to act on.
**Verify:** You have a valid site-list XML (schema version 2), and it is (or will be) reachable at an
internal URL the devices can reach.
**Implement:** Author it with the free **Enterprise Mode Site List Manager** (add each legacy site with
open-in = **IE11** / engine = IE mode), export the XML as `EdgeForBusiness-EMSiteList.xml`, and host it at
an internal HTTPS URL (or a `file://` share) reachable by the pilot devices. Only the sites you list use
IE mode. **Start with a short, verified list.**

## R5. Default application associations XML (for default-browser enforcement)
**Description:** A Windows **default associations** XML that maps `http`, `https`, `.htm`, `.html` (and
optionally `.pdf`, `.svg`) to Microsoft Edge.
**Why:** Fleet-wide default-browser enforcement on Windows via Intune uses the
`ApplicationDefaults/DefaultAssociationsConfiguration` policy CSP, which takes this XML.
**Verify:** You have an `AppAssociations.xml` produced from a reference device where Edge is already the
default for the relevant types.
**Implement:** On a reference Windows device with Edge set as default, run (elevated)
`dism /online /Export-DefaultAppAssociations:C:\AppAssociations.xml`, then keep only the http/https/html
(and any additional) entries you want to enforce. This XML is deployed in
`Edge for Business - Default Browser - Pilot` (Implementation, Phase 2).

## R6. Microsoft Edge security baseline available in Endpoint security
**Description:** The **Microsoft Edge security baseline** is available under **Endpoint security →
Security baselines**.
**Why:** It is the enforced hardening floor applied as `Edge for Business - Security Baseline - Pilot`.
**Verify:** Intune → **Endpoint security → Security baselines**; a **Microsoft Edge Baseline** entry with a
version is listed.
**Implement:** It is provided by Intune; no import needed. Note the **baseline version** shown — you will
reference it in change control (Best Practices).

## R7. Windows devices enrolled and in scope
**Description:** The target Windows devices are Intune-enrolled and manageable (Global Requirement G4).
**Why:** Configuration profiles and baselines only reach enrolled devices.
**Verify:** Intune → **Devices → Windows → Windows devices**; the pilot device is listed and **compliant**.
**Implement:** Enroll via Entra join + automatic enrollment, or Autopilot (covered by the enrollment
solutions).

## R8. Pilot target group
**Description:** An Entra security group named **`Edge for Business - Pilot Devices`** containing the pilot
device(s) or user(s).
**Why:** Every solution is piloted before fleet rollout; all four objects assign to this group first.
**Why:** Consistent naming keeps the assignment, testing, and reporting steps unambiguous.
**Verify:** Entra → **Groups**; `Edge for Business - Pilot Devices` exists and contains the pilot members.
**Implement:** Entra → **Groups → New group → Security**, name it **`Edge for Business - Pilot Devices`**,
add the pilot device(s)/user(s). (This is the solution-specific instance of Global Requirement G5.)

## R9. Internal hosting reachable for the site list (IE mode)
**Description:** The devices can reach the URL that hosts `EdgeForBusiness-EMSiteList.xml`.
**Why:** Edge fetches the site list from `InternetExplorerIntegrationSiteList`; an unreachable URL means
IE mode never applies.
**Verify:** From a pilot device, browse to the site-list URL and confirm the XML loads.
**Implement:** Host the XML on an internal web server / SharePoint / file share reachable by the fleet, and
allow it through any proxy. Use HTTPS where possible.

## R10. Change-control awareness for browser policy
**Description:** Acknowledgement that browser policy changes affect every user's daily tool, and a plan to
communicate them.
**Why:** Disabling the password manager, forcing a default browser, and controlling extensions are
user-visible; unannounced changes generate tickets.
**Verify:** You have a comms plan and a rollback owner for the pilot.
**Implement:** Draft a short user notice (what changes, when, why, where to store passwords now), and keep
the rollback plan (unassign the profiles) documented before you pilot.
