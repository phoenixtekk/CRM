# Requirements — Cisco Secure Client (AnyConnect) VPN Deployment via Microsoft Intune

Confirm **every** requirement below before you build. Each entry follows the same shape:
**Description / Why required / How to verify / How to implement if missing.** The category-level
prerequisites (Entra tenant, Intune, admin roles, pilot group, change control) are in
`global-requirements-network.md`; the items here are specific to deploying the Cisco Secure Client
and its VPN profiles.

> **Vendor boundary:** the **Cisco Secure Client console, the VPN Profile Editor / XML internals, and
> the VPN head-end (ASA / Firepower FTD / ISE) configuration are deferred to Cisco's official
> documentation.** Below, "obtain from Cisco" means *get the artifact/value from your Cisco admin or
> Cisco docs* — this guide does not fabricate Cisco menu paths.

---

## R1. Microsoft Intune licensing and enrolled devices
**Description:** An Intune-bearing license plan (e.g. Microsoft 365 E3/E5, EMS, or Intune standalone)
and the target Windows/macOS/iOS/Android devices already enrolled and shown in Intune.
**Why required:** Intune is the delivery plane for both the app and the VPN profile. Nothing deploys
to a device that is not enrolled and licensed.
**How to verify:** In the **Microsoft Intune admin center** (`https://intune.microsoft.com`), go to
**Devices > All devices** and confirm the target devices are present and *Compliant/Managed*. Under
**Tenant administration > Licenses**, confirm Intune licenses are assigned to the pilot users.
**How to implement if missing:** Assign an Intune-bearing license to the pilot users (Microsoft 365
admin center → **Users** → assign licenses). Enroll devices: Windows via Autopilot / Company Portal;
macOS via Company Portal / Automated Device Enrollment; iOS via Company Portal or ADE; Android via
the work-profile / fully-managed enrollment flow.

## R2. Entra ID security groups (pilot and production)
**Description:** A pilot group `PILOT – Cisco VPN Users` and one or more production target groups
(e.g. `PROD – Cisco VPN Users`), containing users or devices to receive the client.
**Why required:** Intune assignments target Entra groups. The pilot-first model requires a small,
named pilot group distinct from the eventual production audience.
**How to verify:** In the **Microsoft Entra admin center** (`https://entra.microsoft.com`), go to
**Groups > All groups** and confirm `PILOT – Cisco VPN Users` exists with the intended members.
**How to implement if missing:** Entra → **Groups > New group > Security**; name it exactly
`PILOT – Cisco VPN Users`; add 3–10 representative pilot members (ideally covering each platform).
The included `CSCVPN-Set-ScopeTargeting.ps1` script creates and populates these groups for you.

## R3. A Cisco VPN head-end (ASA / Firepower FTD) — with ISE where used
**Description:** A reachable Cisco VPN termination point (ASA or Firepower Threat Defense) with a
configured **tunnel group / connection profile**, plus **Cisco ISE** if you use posture or
identity-based authorization.
**Why required:** The deployed client needs something to connect *to*. The gateway FQDN,
tunnel-group/connection-profile name, and accepted authentication method are inputs to the Intune
VPN profile.
**How to verify:** Obtain from your Cisco/network team: the **gateway FQDN** (e.g.
`vpn.your-company.com`), the **tunnel-group / connection-profile name**, and the **auth method**
(certificate, SAML/Entra, or RADIUS). Confirm a test user can already connect manually with a
Cisco-supplied client to that gateway.
**How to implement if missing:** Stand up / configure the ASA or FTD head-end and (optionally) ISE
**per Cisco's official documentation** — this is Cisco-side work outside this solution's scope.
Record the FQDN, connection-profile name, and auth method for use in R6/Implementation.

## R4. Cisco Secure Client installers (per platform)
**Description:** The official Cisco Secure Client installers for each platform you are deploying:
Windows (MSI predeploy package / modules), macOS (signed `.pkg`), and the App Store / Managed Google
Play listings for iOS and Android.
**Why required:** These are the exact binaries Intune will package and deploy. Version and module set
must match what your head-end supports.
**How to verify:** Download the installers from your **Cisco Software Download** entitlement and
confirm the version against what your head-end/Cisco admin specifies. Confirm the macOS PKG is
**signed** (needed for Intune detection and macOS Gatekeeper).
**How to implement if missing:** Obtain the correct entitled version from Cisco (Software Download,
per your support contract). Do not repackage or re-sign Cisco binaries; use the vendor-provided ones.

## R5. Cisco VPN client profile (XML) — where used
**Description:** The Cisco **VPN client profile** (an XML file authored in Cisco's **VPN Profile
Editor** or delivered from the head-end) that encodes gateway lists, connect behavior, and client
options for Windows/macOS.
**Why required:** For Windows/macOS, bundling this XML with the app package gives the client its
connection defaults immediately on install (for iOS/Android the equivalent lives in the Intune VPN
profile).
**How to verify:** Obtain the `.xml` profile from your Cisco admin and confirm it references the
correct gateway FQDN and connect settings. (iOS/Android do **not** consume this XML — they use the
Intune VPN profile.)
**How to implement if missing:** Have your Cisco admin author/export the VPN client profile XML
**per Cisco's VPN Profile Editor documentation** (deferred to Cisco). Store it with your Win32/PKG
packaging inputs.

## R6. VPN connection parameters recorded
**Description:** A recorded set of connection values: **gateway FQDN**, **tunnel-group / connection
profile**, **authentication method**, tunnel mode (**split** vs **full**), any **Per-App VPN** app
list, and **On-Demand / trusted-network** rules.
**Why required:** These are the exact fields you type into the Intune VPN device-configuration
profiles for each platform. Consistency here is what makes every device identical.
**How to verify:** You have a single sheet listing each value; a manual client connect using those
values succeeds against the head-end.
**How to implement if missing:** Collect the values from R3/R5 and your security requirements. Decide
split vs full tunnel and Per-App scope with the network/security owner before building profiles.

## R7. Certificate infrastructure (if using certificate authentication)
**Description:** A working PKI path for Intune to deliver client/device certificates — an on-prem
**NDES/SCEP** connector, **Intune Cloud PKI**, or a supported third-party CA connector — and a
**SCEP or PKCS certificate profile** in Intune.
**Why required:** Certificate-based VPN auth (the recommended silent-connect pattern) requires each
device to receive a certificate the head-end trusts, delivered by Intune.
**How to verify:** Intune → **Devices > Configuration**; a certificate profile named
`Cisco Secure Client – VPN – Device Cert (SCEP)` deploys successfully to a test device, and the
issued cert chains to a CA the Cisco head-end trusts.
**How to implement if missing:** Stand up the SCEP/PKCS path (NDES + Intune Certificate Connector,
or enable Intune Cloud PKI), publish the trusted root/intermediate CA profile, then create the SCEP
certificate profile. Ensure the **issuing CA is trusted by the Cisco head-end** (Cisco-side trust
config is deferred to Cisco docs). Skip R7 only if you authenticate by SAML/Entra SSO or
username/password.

## R8. iOS enrollment prerequisite — Apple Push Notification service (APNs)
**Description:** A valid **Apple MDM Push certificate (APNs)** configured in Intune, enabling iOS/
iPadOS management.
**Why required:** No iOS device can be managed (and thus receive the store app or VPN profile)
without a current APNs certificate.
**How to verify:** Intune → **Tenant administration > Connectors and tokens > Apple MDM Push
certificate**; status is *Active* and not expired.
**How to implement if missing:** Create/renew the APNs certificate: download the CSR from Intune,
upload it at `https://identity.apple.com` (Apple Push Certificates Portal) with a **corporate** Apple
ID, and upload the resulting certificate back into Intune. **Renew annually with the same Apple ID.**

## R9. Android enrollment prerequisite — Managed Google Play
**Description:** Intune connected to **Managed Google Play** (Android Enterprise) so the Cisco Secure
Client app can be approved and pushed.
**Why required:** Android Enterprise app deployment (work profile / fully managed) flows through the
Managed Google Play connection.
**How to verify:** Intune → **Devices > Android > Android enrollment > Managed Google Play**; the
connection shows as configured/connected.
**How to implement if missing:** Complete the Managed Google Play bind in Intune (**Android
enrollment > Managed Google Play**) using a corporate Google account, then approve the Cisco Secure
Client app.

## R10. macOS PKG signing / app detection readiness
**Description:** The macOS Cisco Secure Client **`.pkg` is signed**, and you know its **primary bundle
ID and version** for Intune's install-detection.
**Why required:** Intune's macOS PKG deployment relies on the package being signed and on bundle-ID/
version metadata to detect a successful install; unsigned packages fail Gatekeeper.
**How to verify:** Inspect the vendor PKG (e.g. it is a Developer ID–signed installer) and record the
bundle identifier/version Cisco documents for the release.
**How to implement if missing:** Use Cisco's official signed PKG (do not re-sign). If your workflow
needs the bundle-ID list, obtain it from Cisco's release notes / documentation.

## R11. Administrative roles for building the deployment
**Description:** Intune admin rights to create apps and configuration profiles, and Entra rights to
create/populate groups (Groups Administrator or better).
**Why required:** Packaging apps, creating VPN/cert profiles, and assigning groups all require
elevated roles.
**How to verify:** In Intune, you can reach **Apps > Add** and **Devices > Configuration > Create**;
in Entra you can create groups.
**How to implement if missing:** Have a Global Administrator assign **Intune Administrator** and
**Groups Administrator** (least-privilege) to the operator.

## R12. Microsoft Graph PowerShell SDK (to run the included scripts)
**Description:** The **Microsoft.Graph** PowerShell SDK installed on the operator workstation, used by
the five discovery/validation/report/remediation/targeting scripts.
**Why required:** The scripts call Microsoft Graph (Intune/Entra) to inventory apps, profiles,
assignments, and group membership.
**How to verify:** In PowerShell, `Get-Module Microsoft.Graph -ListAvailable` returns a version.
**How to implement if missing:** Run `Install-Module Microsoft.Graph -Scope CurrentUser`. The scripts
call `Connect-MgGraph` with the specific delegated scopes each one documents in its header.

## R13. Change control and rollback (category requirement, restated)
**Description:** An approved change window and a written rollback (exclude the group / uninstall the
app / remove the profile).
**Why required:** Pushing a VPN client and profile touches remote-access for real users; changes must
be reversible.
**How to verify:** A rollback procedure exists and is approved; you know how to exclude
`PILOT – Cisco VPN Users` and how to flip the Win32 app to **Uninstall** if needed.
**How to implement if missing:** Document the rollback (Intune assignment exclusion, app Uninstall
intent, profile removal) and the comms plan before you assign anything.

---

When all requirements pass, proceed to `03-implementation.md`.
