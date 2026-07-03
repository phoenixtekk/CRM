# Troubleshooting — Entra ID + ABM Managed Apple ID Auto-Provisioning (Government / GCC High)

GCC-High-specific symptoms and fixes. Most issues fall into one of three buckets: you hit a Commercial
endpoint, you expected the unsupported federation/SCIM path, or a token/certificate expired. Always
work in the `*.us` portals and connect Graph with `-Environment USGov`.

---

## "Sign in to Apple with the Entra work account fails" / federation won't turn on
- **Cause:** This is the **expected parity gap**, not a defect. Apple states "Integration with national
  clouds isn't currently supported," and the federation is built for the Commercial global service
  `login.microsoftonline.com`, not `login.microsoftonline.us`.
- **Fix:** Do not attempt to force the Commercial federation flow against the sovereign endpoint. Use
  **ABM-native Managed Apple IDs** (manual / SFTP / ABM API) and enrol devices via **Intune
  Government ADE/User Enrollment**. See `gcc-high-parity-notes.md`. If the requirement truly depends on
  federation, escalate the parity gap — it is not solvable in a pure GCC High tenant today.

## "Apple Business Manager provisioning app isn't in my Enterprise Applications gallery"
- **Cause:** The ABM provisioning gallery app is **not offered for provisioning in the US Government
  cloud**. Its absence in `entra.microsoft.us` is expected.
- **Fix:** Do not search for a workaround gallery app. Provision Managed Apple IDs with ABM's own
  tooling per `ABM-Managed-AppleID-Standard`. (**Verify for GCC High** live — gallery availability
  changes over time.)

## `Connect-MgGraph` fails or connects to the wrong tenant
- **Cause:** You omitted `-Environment USGov`, so the SDK authenticated against the Commercial endpoint
  and rejected your GCC High credentials (looks like an auth failure), or silently used a Commercial
  context.
- **Fix:** Always run `Connect-MgGraph -Environment USGov`. Optionally set
  `$PSDefaultParameterValues['Connect-MgGraph:Environment'] = 'USGov'` in your profile. Confirm the
  connected context targets `graph.microsoft.us`.

## Portal shows nothing / "you don't have access"
- **Cause:** You opened a Commercial URL (`entra.microsoft.com`, `endpoint.microsoft.com`) instead of
  the sovereign `*.us` equivalent, or lack the Intune Administrator role.
- **Fix:** Use `entra.microsoft.us`, `endpoint.microsoft.us`, `portal.office365.us`. Confirm the
  operator holds **Intune Administrator** in `entra.microsoft.us → Roles and administrators`.

## Devices don't auto-enrol during Setup Assistant
- **Cause:** The ABM ⇄ Intune token isn't syncing, the device isn't assigned to the Intune MDM server
  in ABM, or `ABM-ADE-Profile-Gov` isn't assigned to the pilot group.
- **Fix:** In `endpoint.microsoft.us → Enrollment program tokens`, confirm the token is valid and
  synced; in `business.apple.com`, confirm the device is assigned to `Intune-Gov-MDM`; confirm
  `ABM-ADE-Profile-Gov` is assigned to `ABM-Apple-Pilot-Devices`. Run `ABMPROVG-Validation.ps1`.

## Enrolled devices get no policy
- **Cause:** The device enrolled but isn't in the scoped group, or the APNs certificate is invalid.
- **Fix:** Verify APNs validity in `endpoint.microsoft.us → Apple → MDM push certificate`; confirm
  group membership with `ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf`.

## APNs certificate or ABM token "expired"
- **Cause:** Both expire annually; a lapse breaks Apple enrollment and push.
- **Fix:** Renew before expiry. Renew the APNs certificate with the **same Apple ID** (a new Apple ID
  forces re-enrollment of all devices). Re-download and re-upload the ABM token. Calendar both
  renewals with 30-day lead time.

## `ABMPROVG-Report.ps1` disagrees with the portal
- **Cause:** Stale sync, insufficient Graph scopes, or a Commercial-context connection.
- **Fix:** Re-run after a sync; ensure you consented to the read scopes the script requests; confirm
  the connection is US Gov (`-Environment USGov`). Trust the portal until the report matches.

## Remediation changed something unexpectedly
- **Cause:** `-WhatIf` was removed before the preview was reviewed.
- **Fix:** Always run `ABMPROVG-Remediation.ps1 -WhatIf` and `ABMPROVG-Set-ScopeTargeting.ps1 -WhatIf`
  first, read the planned actions, then re-run without `-WhatIf`. If an unwanted change occurred,
  reverse it in the portal and re-validate.

## Network filtering blocks enrollment
- **Cause:** US Government Intune endpoints or Apple ABM/APNs ranges aren't allowed through the proxy.
- **Fix:** Allow the published **US Government Intune network endpoints** and Apple ABM/APNs ranges.
  Source: https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-us-government-endpoints

---

## When to escalate
- The requirement genuinely needs **Entra federation / SCIM auto-provisioning** — that is a national
  cloud limitation on Apple's side, not a configuration you can fix. Escalate with the citation from
  `gcc-high-parity-notes.md` and evaluate alternatives (ABM-native provisioning) with stakeholders.
- Any consideration of a separate Commercial/GCC tenant purely to obtain federation — route to your
  ISSO first; it may breach your CMMC/ITAR/DFARS compliance boundary.

_Re-verify the cited Apple and Microsoft pages before implementation; sovereign-cloud capabilities
change._
