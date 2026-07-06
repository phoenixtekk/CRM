# 6. Troubleshooting — Google Workspace Security Baseline, DLP & Context-Aware Access (CAA)

Symptom → likely cause → fix, for the common issues across the three layers. Work on the **pilot OU
first**, and remember every enforcement has a **rollback** (relax session, re-widen sharing,
DLP→audit, CAA→monitor). Edition-gated notes are flagged **"verify in your tenant."**

## Hardening baseline (Layer 1)

**Users not prompted for 2SV after enforcement.**
- *Cause:* enforcement scoped to the wrong OU, or users still inside the **new-user enrollment
  grace period**; or they never enrolled a factor.
- *Fix:* Admin console → **Security → Authentication → 2-step verification**; confirm the setting is
  scoped to the intended OU and the grace period has elapsed; verify enrollment in the user's
  security settings.

**Admins locked out after enforcing 2SV.**
- *Cause:* super-admin enrolled no factor / has no backup codes before enforcement.
- *Fix:* use the **break-glass** super-admin and pre-generated **backup codes**; if none exist,
  another super-admin generates backup codes (Security → Authentication) for the affected admin.
  *Always enroll admins and generate backup codes before org-wide enforcement.*

**Sessions never expire / users are never asked to reauthenticate.**
- *Cause:* Google session control not set for the OU, or the value governs only the web session
  while the complaint is about a native/mobile app (which behaves differently).
- *Fix:* **Security → Access and data control → Google session control**; set the web-session
  duration for the OU. Note native-app session behavior differs — verify in your tenant.

**External sharing still silent / "anyone with the link" still available.**
- *Cause:* sharing settings scoped to the root OU but not the target OU, or child OU inheriting a
  looser override.
- *Fix:* **Apps → Google Workspace → Drive and Docs → Sharing settings** scoped to the OU; disable
  anyone-with-link, enable outside-org warnings, set default link scope to restricted.

**Legacy mail client still connects.**
- *Cause:* less-secure-app / legacy-auth access still permitted, or an app-password in use.
- *Fix:* **Security → Access and data control** → restrict legacy/basic-auth; review app passwords.

## Data Loss Prevention (Layer 2) — *edition-gated*

**DLP rule fires no incidents even on obvious test content.**
- *Cause:* rule scoped to the wrong OU, trigger mismatch (e.g. rule triggers on *external* share but
  the test was internal), detector/threshold too strict, or the rule is inactive.
- *Fix:* **Security → Access and data control → Data protection**; confirm the rule is **active**,
  scoped to the pilot OU, the **trigger** matches the test action, and the **detector likelihood /
  minimum count** are not set too high. Test with the standard synthetic values.

**DLP blocks legitimate, benign content (false positives).**
- *Cause:* detector too broad or threshold too low (single incidental match fires).
- *Fix:* raise detector **likelihood** and **minimum count**, narrow a custom word-list/regex
  detector, and re-run in **audit** before returning to block.

**DLP "block" doesn't block — content still shares/sends.**
- *Cause:* rule still in **Audit only**, or scoped to an OU the user is not in.
- *Fix:* promote the action to **Block external sharing** (Drive) / **Block delivery / Quarantine**
  (Gmail) and confirm OU scope.

**Custom detector not matching expected data.**
- *Cause:* regex/word-list error, or data format differs from the pattern.
- *Fix:* **Manage detectors**; correct the regex/word list and re-test with representative synthetic
  samples.

## Context-Aware Access (Layer 3) — *edition-gated*

**Compliant users blocked by CAA.**
- *Cause:* access-level signal wrong — corporate **CIDR range** missing/incorrect, or a required
  **device attribute** (encryption / screen lock / company-owned) not flowing because endpoint
  verification / device management isn't deployed to those users.
- *Fix:* **Security → Access and data control → Context-Aware Access → Access levels**; correct the
  IP ranges; confirm device signals in **Devices**. Roll device signals out **before** requiring
  them. Verify in your tenant.

**Non-compliant users are NOT blocked (enforcement not taking effect).**
- *Cause:* the assignment is still in **monitor mode** (simulate only), or the access level isn't
  assigned to that app/OU.
- *Fix:* **Assign access levels**; switch the assignment from **monitor** to **enforce** for the OU
  and confirm it is bound to the app (Drive/Gmail/Admin console).

**Access works in the browser but not in a native/mobile app (or vice-versa).**
- *Cause:* CAA behaves differently for non-web clients; some signals aren't available to native apps.
- *Fix:* test each client path explicitly; adjust the access level or app assignment; verify the
  specific client's supported signals in your tenant.

**Admin console reachable from off-network despite a corp-network level.**
- *Cause:* the access level was assigned to apps but **not to the Admin console** for that OU.
- *Fix:* **Assign access levels** → include the **Admin console** assignment for the privileged OU.

## Scripts

**A `GWSEC-*` script errors on the API call / returns nothing.**
- *Cause:* missing or expired OAuth token, insufficient scope, or wrong OU path.
- *Fix:* set `GOOGLE_OAUTH_TOKEN` to a valid super-admin access token with the read-only scopes each
  script's header lists; pass the exact OU path (e.g. `/Security Baseline - Pilot`). Discovery /
  Validation / Report are read-only; Remediation and Set-ScopeTargeting default to `-WhatIf` — pass
  `-Apply` only after previewing.

**Not sure whether an edition-gated feature exists in your tenant.**
- *Fix:* **Billing → Subscriptions** for the edition, then confirm the **Data protection** and
  **Context-Aware Access** pages are present. If absent, the layer requires a higher tier — deploy
  the hardening baseline (edition-independent) and document the deferred layer.
