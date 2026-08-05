# 6. Troubleshooting

Symptom → cause → fix. Reuse the object names from Implementation.

## Portal / plist errors

### "Property list must begin and end with 'dict' tag"
- **Cause:** the pasted XML root is a capitalized `<Dict>`, or is wrapped in something other than a
  lowercase `<dict>` (e.g. a vendor `<Configuration>`/`<profile>` root).
- **Fix:** the iOS "Enter XML data" content is an **Apple plist**. Make the root a lowercase
  `<dict>` … `</dict>` containing only `<key>`/`<string>` (etc.) pairs. Paste only from `<dict>` to
  `</dict>`.

### "Remove XML headers from property list"
- **Cause:** you pasted the `<?xml …?>` declaration and/or a `<!DOCTYPE plist …>` / `<plist>` wrapper,
  or the payload carries `xmlns`/`xsi` **namespace attributes** (a vendor XML *profile* schema).
- **Fix:** delete the XML/DOCTYPE/plist headers and all namespace attributes — paste **only** the
  `<dict>…</dict>`. Managed App Configuration is **not** a transport for a vendor's namespaced XML
  profile. If the app truly needs a whole profile document, put it in as a **string value under a
  key** (CDATA), never as the plist structure.

### The portal rejects the plist but the XML "looks fine"
- **Cause:** a mismatched tag, a `<key>` with no following value element, or a smart-quote pasted from
  a Word doc.
- **Fix:** validate the plist (every `<key>` has exactly one value element; tags balanced; straight
  ASCII quotes). Prefer the **Configuration designer** to avoid hand-editing XML entirely.

## Config not applying

### App opens and still asks for server/realm (nothing pre-filled)
- **Causes & fixes (work top to bottom):**
  1. **Wrong channel.** A **managed-device** policy only applies to **enrolled** devices; on an
     unenrolled/BYOD phone it never applies. Confirm the device is enrolled, or use the **managed
     apps (MAM)** channel instead. (See "MAM vs MDM confusion" below.)
  2. **Device/user not in the assigned group.** Run
     `APPCFG-Validate-Assignment.ps1 -PolicyName "APPCFG - Ariba - iOS - Pilot" -DeviceName <name>`.
     If FAIL, add the device/user to `APPCFG - Ariba - Pilot` and re-sync.
  3. **Key name typo / wrong key.** A key the app did not publish is silently ignored, so the field
     stays empty. Re-check every key against the vendor's documentation (Ariba: the SAP MDM guide —
     **verify against SAP Ariba documentation**). On Android, only keys the **schema** exposes work.
  4. **Policy not synced yet.** Force a sync (Company Portal → **Sync**, or Intune → device → **Sync**)
     and reopen the app; some apps read config only on a fresh launch or reinstall.
  5. **App doesn't support managed configuration at all.** Confirm the app declares iOS Managed App
     Configuration / Android managed configurations / Intune App SDK. If not, app config cannot
     configure it.

### Some keys apply, others don't
- **Cause:** the ones that don't are misnamed, use the wrong value **type** (string vs integer vs
  bool), or aren't in the app's schema.
- **Fix:** match each key's name and type exactly to the vendor schema. On Android use the designer's
  control (enum/bool/bundle) rather than free text.

### The app went to the wrong environment/site
- **Cause:** a **URL in a hostname field** (e.g. `https://s1.ariba.com/Buyer`) or a region-wrong host.
- **Fix:** set the host to a **bare hostname** — no `https://`, no path (a path is sent to DNS as one
  string → NXDOMAIN / wrong routing). Confirm the region-specific host (e.g. `s1-eu.ariba.com`).

## MAM vs MDM confusion

### "I created an App Configuration Policy but it doesn't reach my BYOD users"
- **Cause:** you created a **Managed devices** policy, but the target phones are **unenrolled** — the
  OS payload channel doesn't exist there.
- **Fix:** create a **Managed apps** policy instead (Apps → App configuration policies → Create →
  **Managed apps**), scope it to the **user** group, and confirm the app is Intune App SDK-enabled
  (e.g. Outlook). Managed-app policies apply on enrolled *and* unenrolled devices.

### "My managed-app policy isn't applying to a device group"
- **Cause:** managed-app (MAM) policies target **users**, not devices.
- **Fix:** assign the policy to a **user** group; device-group assignment does not drive MAM config.

## SSO / Conditional Access routing

### App lands on a local/non-Entra login instead of Entra ID
- **Causes & fixes:**
  1. The **`authMode`/SSO** key is missing or set to a local value — set it to route to federated/SSO
     sign-in (**verify against SAP Ariba documentation** for the exact key/value).
  2. The **Microsoft Enterprise SSO extension** isn't on the device — deploy the
     `APPCFG - iOS - Enterprise SSO` profile and Microsoft Authenticator to the pilot group.
  3. The **realm/tenant isn't pre-filled**, so the app can't detect your IdP — confirm `aribaRealm`
     (or the vendor's realm/tenant key) is delivered.

### Sign-in reaches Entra but the user is blocked (or not challenged as expected)
- **Cause:** this is **Conditional Access**, which this solution routes to but does **not** build.
- **Fix:** review the CA policy targeting the app in the dedicated **Conditional Access Integration**
  solution — pilot it in **Report-only**, confirm break-glass exclusions, then enforce. Do not
  troubleshoot CA logic here.

## Supersedence & coexistence

### After replacing/superseding the app, it installs unconfigured
- **Cause:** app **supersedence** carries app *assignments* but **not** App Configuration Policies to
  the superseding app.
- **Fix:** point the App Configuration Policy's **targeted app** at the current (superseding) app, or
  create a new policy bound to it.

### App Protection seems to conflict with app config
- **Cause:** they don't conflict — but an App Protection **conditional launch** rule (e.g. min OS,
  jailbreak block) can stop the app before config is visible.
- **Fix:** confirm the app is *both* configured and protected; if the app is blocked at launch, that's
  an App Protection issue — adjust it in the App Protection solution, not here.

## Scripts / Graph

### `Connect-MgGraph` fails or the tools see the wrong tenant/cloud
- **Cause:** wrong cloud (Commercial vs US Government), or missing scope consent.
- **Fix:** run `APPCFG-Preflight.ps1` (add `-Environment USGov` for GCC/GCC High). It confirms the
  signed-in identity, tenant, cloud, and each required scope. For Government, all tools accept
  `-Environment USGov` (Graph `graph.microsoft.us`); the admin portal is `https://intune.microsoft.us`.
  Any app-specific GCC High parity question → **verify for GCC High**.

### `APPCFG-Remediation.ps1` didn't change anything
- **Cause:** it is **safe by default** — without `-Commit` it runs in preview and writes nothing.
- **Fix:** re-run with `-Commit` once you've reviewed the previewed assignment. It preserves existing
  assignments (re-sends the full set), so it won't clobber other groups.
