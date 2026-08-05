# Executive Summary — Intune Managed App Configuration Policies (iOS & Android)

Most mobile-app friction is not a licensing problem — it is a *first-launch* problem. A user
installs a line-of-business app, then is asked to type a server hostname, a tenant or realm, an
environment name, and an account. They guess, they mistype, they call the help desk, and the app
never routes cleanly to your identity provider. Multiply that across a fleet and the cost is real.

**App Configuration Policies** in Microsoft Intune remove that friction. They push the app's own
settings — server hostname, tenant/realm, environment, feature flags, and sign-in routing — *to the
app* so it configures itself the moment it opens. The user launches the app and lands on the right
sign-in screen, already pointed at your Microsoft Entra ID tenant and covered by Conditional Access.
Zero-touch setup, fewer tickets, and a consistent, auditable configuration everywhere.

This solution delivers the repeatable way to build those policies across **both platforms**:

- **iOS/iPadOS** — managed-device app configuration authored as a proper Apple **property list
  (plist)**, plus the managed-app (MAM) channel for unenrolled devices.
- **Android Enterprise** — **managed configurations** read from the app's own schema in managed
  Google Play, via the configuration designer or the JSON channel.
- **The two delivery channels explained** — *managed devices* (enrolled/MDM) versus *managed apps*
  (MAM) — so you always pick the channel that will actually reach your users.
- **A full worked example — SAP Ariba Procurement** — an App Configuration Policy that pre-fills the
  Ariba site/realm/environment, sets the user's role option, and routes sign-in to Entra ID and
  Conditional Access, built click-by-click in the Intune admin center with every object named.
- **Identity/SSO routing** — how the app trusts Entra single sign-on and how a Conditional Access
  policy scoped to that app enforces access (the deep CA build is handled by the dedicated
  Conditional Access solution; here we wire the app to route to it).
- **Five Microsoft Graph PowerShell tools** — read-only by default, cloud-aware (Commercial and US
  Gov) — to pre-flight scopes, export existing policies and assignments, validate delivery to a
  device, report configuration coverage, and stage guarded remediation.

Delivered as self-guided, click-by-click documentation and tested scripts — buy once, reuse across
unlimited apps and devices. The outcome: apps that set themselves up correctly on first launch and
route every sign-in to your identity provider, with the configuration proven on a pilot device
before you expand.
