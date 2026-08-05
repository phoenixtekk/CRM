# 7. Best Practices

## Design
- **Pick the channel first, deliberately.** Decide *managed devices* vs *managed apps* per app before
  you build anything — it determines whether the policy will ever apply. Enrolled + OS payload =
  managed devices; unenrolled/BYOD or App-SDK apps = managed apps.
- **Never invent keys.** Key names are vendor-defined. Take iOS keys from the vendor's MDM/app-config
  documentation and Android keys from the app's managed-configuration **schema** in managed Google
  Play. A key the app did not publish is silently ignored.
- **Prefer the configuration designer over raw XML/JSON.** The designer prevents malformed payloads.
  Use "Enter XML data" (iOS plist) or raw JSON (Android) only when the vendor supplies content that
  way.
- **Author iOS XML as a real plist.** Lowercase `<dict>` root, `<key>`/`<string>` pairs only, **no**
  `xmlns`/`xsi` attributes, **no** vendor profile header. A full vendor profile document, if
  supported, is a **string value under a key**, not the plist structure.
- **Every "server/host" value is a hostname, not a URL.** No `https://`, no trailing path/slash — a
  path is sent to DNS as one string and fails. Region-specific hosts (e.g. `s1-eu.ariba.com`) matter;
  confirm the correct one.

## Naming & hygiene
- **Name everything consistently:** `<Purpose> - <App> - <Platform> - <Stage>` — e.g.
  `APPCFG - Ariba - iOS - Pilot`, `APPCFG - Ariba - Android - Prod`. Reuse the exact names in testing,
  troubleshooting, and scripts.
- **One app per policy** for clarity and clean assignment; use separate pilot/prod policies rather
  than editing a live production policy in place.
- **Use Intune token variables** (`{{userprincipalname}}`, `{{mail}}`, `{{tenantid}}`) to pre-fill
  per-user values instead of hardcoding — cleaner and reusable across users.

## Identity & SSO
- **Deploy the Entra SSO plumbing before relying on routing:** Microsoft Authenticator + the iOS
  **Enterprise SSO app extension** (Microsoft Entra ID type), or the Android broker. App config points
  the app at the tenant; the SSO extension makes the landing silent.
- **Keep Conditional Access where it belongs.** This solution routes sign-in to Entra; build and own
  the CA policies in the dedicated **Conditional Access Integration** solution. Pilot CA in
  **Report-only** and keep **break-glass** accounts excluded.

## Rollout & change control
- **Pilot first, always.** Prove the app opens pre-configured and routes to Entra on a small
  `- Pilot` group before creating the `- Prod` copy and expanding in waves.
- **Change keys in pilot, then promote.** A wrong key just doesn't apply — but a wrong *host* can send
  users to the wrong environment. Validate changes in pilot.
- **Mind supersedence.** App configuration does **not** automatically follow an app through
  supersedence. After replacing an app package, confirm the App Configuration Policy still targets the
  current app or the new app installs unconfigured.
- **Coexist with App Protection intentionally.** Assign App Configuration (settings) and App
  Protection (data controls) as separate, complementary policies; test that both apply.

## Operations
- **Baseline and monitor with the scripts.** Run `APPCFG-Get-AppConfigPolicies.ps1` to export
  policies+assignments into source control, `APPCFG-Report-AppConfig.ps1` to spot apps missing config,
  and `APPCFG-Validate-Assignment.ps1` after every change.
- **Re-run pre-flight after tenant changes.** `APPCFG-Preflight.ps1` confirms scopes/roles and the
  correct cloud (Commercial vs USGov) before you make changes.
- **US Government:** use `https://intune.microsoft.us` and `Connect-MgGraph -Environment USGov`; the
  feature and steps are identical, only the endpoints change. Flag any app-specific GCC High parity
  question **"verify for GCC High."**
