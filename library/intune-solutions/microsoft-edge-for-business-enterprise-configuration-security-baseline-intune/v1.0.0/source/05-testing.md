# 5. Testing & Validation — Microsoft Edge for Business Enterprise Configuration & Security Baseline

Validate against a **pilot device** in **`Edge for Business - Pilot Devices`** before expanding. Each test
has an explicit **pass/fail gate**. Use the included PowerShell scripts (Microsoft Graph) for tenant-side
checks and the on-device steps for the user experience.

> **What "pass" means here:** on a managed Windows device, Edge is the **default browser**, the built-in
> **password manager is off**, the **security/config baseline** (SmartScreen/PUA, extensions, sync/sign-in,
> typosquatting, startup) is applied, the **Microsoft Edge security baseline** reports Succeeded, and
> listed legacy sites open in **IE mode**.

## Test 1 — Tenant readiness
**Procedure:** Run `EDGEBIZ-Discovery.ps1`.
**Pass:** The **`Edge for Business - Baseline - Pilot`** Settings Catalog profile exists with
`PasswordManagerEnabled = disabled` and SmartScreen enabled; the **`Edge for Business - Default Browser -
Pilot`** custom profile exists; the **`Edge for Business - Security Baseline - Pilot`** Edge security
baseline exists.
**Fail:** Any of the three objects missing, or the baseline lacks the password-manager/SmartScreen
settings → create/fix before piloting (Implementation Steps 5–12 / `EDGEBIZ-Remediation.ps1`).

## Test 2 — Assignment
**Procedure:** Run `EDGEBIZ-Validation.ps1` (or check each object's **Assignments** tab).
**Pass:** All three objects are assigned to **`Edge for Business - Pilot Devices`** and to no unintended
broad group.
**Fail:** Not assigned, or assigned to "All devices" prematurely → correct with Implementation Step 10/11/12
or `EDGEBIZ-Set-ScopeTargeting.ps1`.

## Test 3 — Profiles applied on the device
**Procedure:** Intune → Device status for each object; and on the device open **`edge://policy`**.
**Pass:** `Edge for Business - Baseline - Pilot`, `Edge for Business - Default Browser - Pilot`, and
`Edge for Business - Security Baseline - Pilot` all show **Succeeded**; `edge://policy` lists the expected
policies.
**Fail:** Not applied / error → force a sync and re-check; if it shows **Conflict**, resolve the
overlapping setting (Troubleshooting).

## Test 4 — Password manager is off (Finding #1)
**Procedure:** On the device, open `edge://policy` and confirm **`PasswordManagerEnabled = false`**; then in
Edge go to **Settings → Profiles → Passwords** and attempt to enable "Offer to save passwords".
**Pass:** `PasswordManagerEnabled` shows **false**; the "Offer to save passwords" toggle is **managed/greyed
out (off)** and Edge does not prompt to save a password on a test sign-in.
**Fail:** Toggle still user-controllable or Edge prompts to save → confirm the setting value and that the
baseline applied (Test 3).

## Test 5 — Edge is the default browser (Finding #2)
**Procedure:** From outside a browser (e.g. a link in Notepad or an email client) open an `https://` link
and open a local `.html` file.
**Pass:** Both open in **Microsoft Edge**; **Settings → Apps → Default apps** shows Edge for the web/HTML
associations and they are **managed** (not freely changeable).
**Fail:** Opens in another browser, or the default is user-changeable → verify the Base64
`DefaultAssociationsConfiguration` value and that `Edge for Business - Default Browser - Pilot` applied.

## Test 6 — Security/config baseline behaves
**Procedure:** Confirm the hardening settings: SmartScreen blocks a known test-warning page; try to install
an extension outside the allow-list; confirm the browser opens to the configured **startup/home** page and
the **work-profile sign-in** behavior matches policy.
**Pass:** SmartScreen warns as configured (and cannot be bypassed where set); a non-allow-listed extension
is **blocked**; startup/home pages match; sign-in/work-profile behaves per `BrowserSignin`.
**Fail:** Any control not behaving → check the specific policy in `edge://policy` and its value in the
baseline profile (Implementation Step 7).

## Test 7 — IE mode renders a legacy site
**Procedure:** Browse to a site listed in `EdgeForBusiness-EMSiteList.xml`.
**Pass:** The **IE mode indicator** (IE logo) appears in the address bar and the legacy app renders/works;
a site **not** on the list uses the modern engine.
**Fail:** No IE-mode indicator → confirm `InternetExplorerIntegrationLevel = IEMode`, that the site-list URL
is reachable (R9), and that the site is actually in the list.

## Test 8 — Microsoft Edge security baseline applied
**Procedure:** Run `EDGEBIZ-Report.ps1`, and check **Endpoint security → Security baselines →
`Edge for Business - Security Baseline - Pilot` → Device status**.
**Pass:** The pilot device reports the Edge security baseline **Succeeded**; the coverage report lists it as
applied.
**Fail:** Missing/error/conflict → resolve overlapping settings between the security baseline and the
Settings Catalog baseline so they agree (Best Practices — conflicts).

## Test 9 — No unintended breakage (negative test)
**Procedure:** With a real pilot user, use Edge for a normal workday: internal apps, SSO/sign-in, an
IE-mode app, and saving a password (should route to the enterprise solution, not the browser).
**Pass:** Normal browsing works; the only *intended* changes are visible (no browser password save, Edge is
default, extensions controlled); no legacy app is broken that IE mode should cover.
**Fail:** A legacy app breaks → add it to `EdgeForBusiness-EMSiteList.xml`; unexpected block → adjust the
specific policy.

## Test 10 — Coverage report
**Procedure:** Run `EDGEBIZ-Report.ps1`.
**Pass:** The report lists the pilot device(s) as **baseline applied**; counts match the assigned group.
**Fail:** Devices missing → run `EDGEBIZ-Remediation.ps1` (`-WhatIf` first) to fix assignment/scoping and
re-sync.

## Acceptance gate
Proceed to **Expand** only when Tests 1–8 and Test 10 pass on at least one pilot device, Test 9 confirms no
unintended breakage, and a real pilot user confirms the two findings are resolved (no browser password save;
Edge is the default) and that IE-mode legacy apps still work.
