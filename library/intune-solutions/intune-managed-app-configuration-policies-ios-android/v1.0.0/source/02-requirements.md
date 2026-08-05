# 2. Requirements

Each requirement below lists **Description · Why required · How to verify · How to implement if
missing.** Do not assume any prerequisite already exists — check each one. (Requirements common to
every Intune solution — tenant, licensing, admin roles, MDM authority — are in
`global-requirements-intune-solutions.md`; this file covers what is specific to App Configuration
Policies.)

## 2.1 Microsoft Intune plan and Entra ID licensing
- **Description:** Intune (standalone or via Microsoft 365 E3/E5, EMS E3/E5, or Business Premium) for
  every targeted user/device, and **Microsoft Entra ID P1** where you will enforce Conditional
  Access on the app's sign-in.
- **Why required:** App Configuration Policies are an Intune feature. The SSO-routing outcome is only
  *enforced* when a Conditional Access policy (Entra ID P1) is scoped to the app.
- **How to verify:** In the Microsoft 365 admin center → **Billing → Licenses**, confirm Intune and
  Entra ID P1 are assigned. In the Intune admin center → **Apps → Monitor**, confirm you can open
  **App configuration policies**.
- **How to implement if missing:** Assign the Intune and Entra ID P1 licenses to the pilot users/devices.

## 2.2 Enrollment posture matched to the delivery channel
- **Description:** Decide, per app, whether you will use the **managed-device** channel (enrolled
  devices) or the **managed-app** channel (MAM). Have the matching posture in place.
- **Why required:** A managed-device App Configuration Policy applies **only** to enrolled devices; a
  managed-app policy applies **only** to apps that integrate the Intune App SDK. Mismatched posture =
  the policy silently never applies.
- **How to verify:**
  - Managed-device iOS/iPadOS: **Devices → iOS/iPadOS** shows the target device as **enrolled** and
    **managed**.
  - Managed-device Android: **Devices → Android** shows the device under an **Android Enterprise**
    enrollment (work profile / fully managed / dedicated), and managed Google Play is connected.
  - Managed-app (MAM): the app is one of the **Intune App SDK-enabled** apps and the user is
    licensed; enrollment is optional.
- **How to implement if missing:** Enroll the pilot device (see the relevant enrollment solution), or
  confirm the app supports the App SDK (managed-app) channel.

## 2.3 Apple MDM push certificate (iOS/iPadOS managed-device channel)
- **Description:** A current **Apple Push Notification service (APNs)** certificate connecting Intune
  to Apple for iOS/iPadOS management.
- **Why required:** iOS Managed App Configuration (the plist payload) is delivered over the Apple MDM
  channel, which requires a valid APNs certificate.
- **How to verify:** **Devices → Enrollment → Apple → Apple MDM Push certificate** shows **Active**
  and a future expiry.
- **How to implement if missing:** Create/renew the APNs certificate (Devices → Enrollment → Apple →
  Apple MDM Push certificate → follow the download-CSR / Apple Push Portal steps). **Always renew the
  *same* certificate** (using the same Apple ID) — a new certificate re-enrolls every device.

## 2.4 Managed Google Play connection (Android Enterprise managed-device channel)
- **Description:** Intune bound to **managed Google Play** so Android Enterprise apps and their
  **managed-configuration schemas** are available.
- **Why required:** Android managed configurations are read from the app's schema in managed Google
  Play; without the binding, the app and its schema do not appear in Intune.
- **How to verify:** **Devices → Enrollment → Android → Managed Google Play** shows the account as
  **Connected**, and the target app appears under **Apps → Android**.
- **How to implement if missing:** Connect managed Google Play (Devices → Enrollment → Android →
  Managed Google Play → follow the bind flow with a corporate Google account, not a personal Gmail).

## 2.5 The target app added to Intune, identified by exact publisher + bundle/package ID
- **Description:** The app you will configure is already added to Intune as a managed app, selected by
  its **exact store publisher** and **bundle ID (iOS)** / **package ID (Android)**.
- **Why required:** An App Configuration Policy is bound to a specific app object. Store search
  returns near-identical results; the exact publisher + ID guarantees you configure the right app.
  For the worked example, **SAP Ariba Procurement**:
  - **iOS/iPadOS:** publisher **SAP SE**, bundle ID **`com.sap.ariba.procurement`** — *verify the
    exact bundle ID in the App Store listing / SAP documentation before use* (App Store item id
    `1451570638`).
  - **Android:** SAP states the Ariba Procurement app is **not certified with MDM on Android** as of
    current documentation — **verify against SAP Ariba documentation**; the Android managed-config
    worked example is therefore shown with clearly-labeled placeholders.
- **How to verify:** **Apps → iOS/iPadOS** (or **Android**) lists the app with the expected publisher
  and bundle/package ID.
- **How to implement if missing:** Add the app: **Apps → iOS/iPadOS → Add → iOS store app** (or
  **Android → Add → Managed Google Play app**), search by the exact publisher, confirm the
  bundle/package ID, and save.

## 2.6 The vendor's supported configuration keys
- **Description:** The **exact key names and value formats** the app supports for managed
  configuration, taken from the vendor's documentation (and, on Android, from the managed-config
  schema surfaced in Intune).
- **Why required:** Keys are vendor-defined. A key the app did not publish is ignored; a typo is
  ignored. You cannot author a correct policy without the authoritative key list.
- **How to verify:** The vendor's admin/MDM documentation lists the keys; on Android, the Intune
  **configuration designer** displays the schema's keys automatically. For **SAP Ariba**, the
  authoritative source is the *SAP Ariba Procurement Mobile App Guide* → **"Configuring SAP Ariba
  Procurement mobile app in Mobile Device Management Tool."** Treat the Ariba keys in this guide as
  **placeholders to confirm there** — flagged **"verify against SAP Ariba documentation."**
- **How to implement if missing:** Obtain the vendor's MDM/app-config documentation before building
  the policy; do not proceed with guessed keys.

## 2.7 Microsoft Entra single sign-on plumbing (for SSO routing)
- **Description:** The identity plumbing that lets the app route sign-in to Entra ID: **MSAL**-based
  auth in the app, plus the **Microsoft Enterprise SSO plug-in** on iOS (via Microsoft Authenticator
  / Company Portal) or the Android broker, and — where the app federates — the app registered/enabled
  for SSO in Entra.
- **Why required:** App configuration can *point* the app at your tenant, but the sign-in only lands
  on Entra ID (and inherits Conditional Access) when the SSO plumbing is present.
- **How to verify:** **Devices → Configuration** shows an **iOS/iPadOS SSO app extension** (Microsoft
  Enterprise SSO) profile assigned; Microsoft Authenticator/Company Portal is deployed to the device;
  in **Entra → Enterprise applications**, the target app (e.g. Ariba) exists for SSO if it federates.
- **How to implement if missing:** Deploy Microsoft Authenticator + the iOS Enterprise SSO extension
  profile (Devices → Configuration → Create → iOS/iPadOS → **SSO app extension**, type **Microsoft
  Entra ID**), and configure the app's SSO in Entra per the vendor's federation guide.

## 2.8 A Conditional Access policy scoped to the app (enforcement — deferred)
- **Description:** A Conditional Access policy targeting the app's cloud/enterprise application, so
  the routed sign-in is actually governed (require MFA / compliant device / app protection).
- **Why required:** App configuration routes sign-in to Entra; **Conditional Access is what enforces**
  the access decision.
- **How to verify:** **Entra → Protection → Conditional Access** shows a policy targeting the app
  (e.g. Ariba) — even if in **Report-only** while piloting.
- **How to implement if missing:** Build it with the dedicated **Conditional Access Integration**
  solution (break-glass accounts, report-only piloting, baseline controls). This solution intentionally
  **does not** build the CA policy; it wires the app to route to it.

## 2.9 A pilot Entra security group
- **Description:** An Entra security group holding the pilot users (managed-app channel) or pilot
  devices (managed-device channel), named e.g. `APPCFG - Ariba - Pilot`.
- **Why required:** Every App Configuration Policy is assigned to a group; piloting first is how you
  prove the config before production.
- **How to verify:** **Entra → Groups** shows the group with the intended pilot members.
- **How to implement if missing:** Create it: **Entra → Groups → New group → Security**, name it
  `APPCFG - Ariba - Pilot`, add the pilot members.

## 2.10 An admin workstation with Microsoft Graph PowerShell (for the included scripts)
- **Description:** A workstation with the **Microsoft.Graph** PowerShell SDK to run the five included
  tools, and the delegated scopes they request.
- **Why required:** The scripts pre-flight scopes, export policies, and validate delivery via Microsoft
  Graph.
- **How to verify:** `Get-Module -ListAvailable Microsoft.Graph.Authentication` returns a version; the
  signed-in admin can consent to `DeviceManagementApps.Read.All` and `DeviceManagementConfiguration.Read.All`.
- **How to implement if missing:** `Install-Module Microsoft.Graph -Scope CurrentUser`. For **US
  Government** tenants, connect with `Connect-MgGraph -Environment USGov` (see §2.11).

## 2.11 US Government (GCC / GCC High / DoD) endpoints — if applicable
- **Description:** If your tenant is a US sovereign cloud, use the government portals and Graph
  environment, not the commercial ones.
- **Why required:** Government tenants use isolated endpoints. The App Configuration Policies **feature
  is the same**, but the admin surfaces differ.
- **How to verify / implement:**
  - Admin center: **`https://intune.microsoft.us`** (not `intune.microsoft.com`).
  - Entra: **`https://entra.microsoft.us`** / sign-in at `login.microsoftonline.us`.
  - Graph scripts: **`Connect-MgGraph -Environment USGov`** (targets `graph.microsoft.us`); device
    service endpoints use `manage.microsoft.us`.
  - The build steps, keys, plist format, and Android schema behavior are otherwise identical. No
    separate Government deliverable is required for this solution; any GCC High parity question that
    arises for a specific app should be flagged **"verify for GCC High."**
