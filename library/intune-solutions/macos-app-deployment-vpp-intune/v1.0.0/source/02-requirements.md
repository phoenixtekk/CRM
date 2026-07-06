# 2. Requirements — macOS App Deployment & Apple VPP with Microsoft Intune

Confirm **every** requirement below before you begin. Each entry follows the same pattern:
**Description · Why required · How to verify · How to implement if missing.** Category-wide
prerequisites (tenant, Intune licensing, admin roles, pilot group, network) are covered once in the
**Global Requirements — Intune Solutions** document; the items here are specific to Apple VPP and
macOS app deployment.

## R1. Apple Business Manager (or Apple School Manager) account
**Description:** A verified Apple Business Manager (ABM) organization.
**Why:** VPP lives inside ABM; app licenses are acquired there against a location, and the VPP token
is exported from there. Without ABM there is no VPP.
**Verify:** Sign in to `https://business.apple.com` with an ABM Administrator (or Content Manager)
account; the organization status is **active**.
**Implement:** Enroll at `https://business.apple.com/enroll` using your **D-U-N-S** number; complete
Apple's verification (a phone callback to a verifiable company contact). Allow 1–5 business days.

## R2. An ABM location with acquired app licenses
**Description:** At least one ABM **location**, with the target apps **acquired** (free or paid) under
it. This solution names the working location **Location A**.
**Why:** VPP licenses are held **per location**, and each location has **its own** token. Intune can
only sync and install apps that have been acquired in that location.
**Verify:** ABM → **Apps** (or **Content → Apps**); confirm the app appears with a license count under
your location. ABM → **Locations** shows the location exists.
**Implement:** ABM → **Apps**, search the App Store app, choose the **location**, set a quantity, and
**Get** it (free apps: quantity is effectively unlimited but the app must still be acquired). Create
a location under ABM → **Locations** if none exists.

## R3. VPP token for the location (the ABM ↔ Intune license link)
**Description:** The location's downloaded **VPP server token** (`.vpptoken`), connected in Intune.
**Why:** This token is the trust link that lets Intune sync that location's licenses and install its
App Store apps.
**Verify:** Intune → **Tenant administration → Connectors and tokens → Apple VPP tokens** (also
reachable via **Apps → macOS → … VPP**); a token is listed as **Active/Valid** with a future
expiration. This solution names it **`VPP – Corporate (Location A)`**.
**Implement:** In ABM → **Preferences → Payments and Billings** (or the location's **Apps** area),
**Download** the location's VPP token; in Intune, **Add** an Apple VPP token, sign in with the ABM
managed Apple ID that owns the token, upload the `.vpptoken`, and give it the name above. **Renew
annually.**

## R4. Managed Apple ID / token owner recorded
**Description:** The **managed Apple ID** used to download and own the VPP token, documented.
**Why:** The token is tied to that Apple ID; renewals must use the **same** identity, and losing track
of it makes renewal painful.
**Verify:** Intune → the VPP token shows the **Apple ID** it was uploaded with; you have that Apple ID
recorded in your runbook.
**Implement:** Record the managed Apple ID (and the ABM location it belongs to) in your operations
runbook the first time you connect the token.

## R5. Target Macs enrolled and managed in Intune
**Description:** The Macs that will receive apps are **enrolled** in Intune and manageable.
**Why:** Managed apps and VPP **device licensing** only reach enrolled, managed devices. Device
licensing further expects a **supervised / company-owned** Mac.
**Verify:** Intune → **Devices → macOS**; the target device appears, is **managed**, and (for device
licensing) shows **Supervised = Yes / Corporate-owned**.
**Implement:** Enroll Macs (Automated Device Enrollment or Company Portal). A separate solution covers
zero-touch macOS enrollment; company-owned + supervised is required for silent device-licensed VPP.

## R6. Entra pilot group for app targeting
**Description:** A Microsoft Entra security group for the pilot — this solution names it
**`PILOT – macOS App Deployment`**.
**Why:** Every app assignment targets a group; piloting to a small, named group first is the model.
**Verify:** Entra → **Groups**; the group `PILOT – macOS App Deployment` exists and contains your
pilot device(s) or user(s).
**Implement:** Entra → **Groups → New group → Security**, name it exactly as above, add the pilot
members. The included **`MACVPP-Set-ScopeTargeting.ps1`** can create/populate it.

## R7. Signed package(s) for enterprise (LOB) apps
**Description:** For any in-house/vendor app you deploy as LOB, a **signed** `.pkg` (or vendor
**signed `.dmg`**); notarized where Apple requires it.
**Why:** Modern macOS (Gatekeeper) blocks unsigned/unnotarized installers; Intune's managed `.pkg`
type expects a **component/distribution PKG** signed with a Developer ID Installer certificate.
**Verify:** On a Mac, `pkgutil --check-signature <pkg>` (or `spctl -a -vv <app>` for a `.dmg`'s app)
reports a valid Developer ID signature.
**Implement:** Obtain the signed installer from the vendor, or sign your own with a **Developer ID
Installer** certificate (`productsign`) and **notarize** it. For installers that can't be made into a
managed `.pkg`, use the **unmanaged PKG** app type (install-once, no license/uninstall management).

## R8. Decide the licensing model per app (device vs. user)
**Description:** For each VPP app, a decision: **device** licensing (default) or **user** licensing.
**Why:** It changes the user experience and prerequisites — device licensing is silent and needs no
Apple ID; user licensing needs the user invited, accepting VPP terms, and signed in to the App Store.
**Verify:** You have, per app, a documented choice and (for user licensing) a plan to invite users.
**Implement:** Default to **device** licensing for company Macs. Only choose **user** licensing when
an app specifically requires it; then plan the VPP user invitation flow.

## R9. Network access to Apple app & VPP endpoints
**Description:** Outbound HTTPS to Apple's VPP, App Store, and content endpoints.
**Why:** License sync, App Store app delivery, and content downloads all depend on Apple endpoints; a
block silently stalls installs.
**Verify:** From the device network, reach `https://vpp.itunes.apple.com`, `https://buy.itunes.apple.com`,
Apple's content/CDN ranges, and the Apple push range `*.push.apple.com` (TCP 443 and 5223).
**Implement:** Allow Apple's published network ranges (Apple support article HT210060) plus the
Microsoft Intune/Entra endpoints through proxy/firewall. Do **not** TLS-inspect Apple push/VPP.

## R10. macOS enrollment/app deployment allowed in Intune
**Description:** macOS platform is permitted by enrollment restrictions, so managed devices can
receive apps.
**Why:** A restriction that blocks macOS stops devices from enrolling and thus from receiving apps.
**Verify:** Intune → **Devices → Enrollment → Enrollment device platform restrictions → macOS** shows
platform **Allowed**.
**Implement:** Edit the default (or a targeted) restriction to **Allow** macOS for the pilot group.
