# 6. Troubleshooting — Microsoft Edge for Business Enterprise Configuration & Security Baseline

Work top-down: confirm the **profiles applied** (Intune Device status + `edge://policy` on the device),
then check **conflicts** between the Settings Catalog baseline and the Edge security baseline, then the
**specific policy** in question. Most issues are an unassigned/unsynced device, a policy-name mismatch for
your Edge version, or two objects setting the same policy to different values. Each symptom below gives the
**likely cause** and the **fix**.

> **Before you start:** open **`edge://policy`** on the affected device — it shows exactly which Edge
> policies applied and their values. This is faster ground truth than Intune reporting, which can lag.

## Symptom: A profile never appears / policies not in `edge://policy`
**Likely cause:** Device not synced, not assigned, or not enrolled.
**Fix:**
1. Confirm the device is in **`Edge for Business - Pilot Devices`** and each object is **assigned**
   (`EDGEBIZ-Validation.ps1`).
2. Force a sync (**Settings → Accounts → Access work or school → Sync**, or Company Portal → **Check
   status**).
3. Check **Devices → Configuration → (profile) → Device status** (and **Endpoint security → Security
   baselines → …** for the baseline) for an error.
4. On the device, open `edge://policy` and click **Reload policies**.

## Symptom: Device status shows "Conflict"
**Likely cause:** The same Edge policy is set to **different values** by `Edge for Business - Baseline -
Pilot` and `Edge for Business - Security Baseline - Pilot` (or a duplicate profile).
**Fix:**
1. Run `EDGEBIZ-Discovery.ps1` to list the Edge configuration objects.
2. Identify the overlapping setting (e.g. SmartScreen) and make the values **agree**, or unset it in one
   object so a single owner remains (Best Practices — conflicts).
3. Remove any duplicate Edge profile targeting the same device.

## Symptom: Edge still offers to save passwords (Finding #1 not resolved)
**Likely cause:** `PasswordManagerEnabled` not applied, or set to Enabled somewhere.
**Fix:**
1. In `edge://policy`, confirm **`PasswordManagerEnabled = false`**. If absent, the baseline did not apply
   (see the first symptom).
2. Confirm no other profile / security baseline sets `PasswordManagerEnabled = true` (conflict).
3. Confirm the setting in `Edge for Business - Baseline - Pilot` is **Disabled** (Implementation Step 6),
   then re-sync.

## Symptom: Edge is not the default browser (Finding #2 not resolved)
**Likely cause:** The `DefaultAssociationsConfiguration` value is wrong/empty, or the associations XML does
not point at Edge.
**Fix:**
1. Confirm `Edge for Business - Default Browser - Pilot` shows **Succeeded** in Device status.
2. Re-check the **Base64** value in the custom OMA-URI row — decode it and confirm the XML maps
   `http`/`https`/`.htm`/`.html` to an Edge ProgId (e.g. `MSEdgeHTM`).
3. Rebuild the XML from a reference device where Edge is default (Implementation Step 4), re-encode, update
   the profile, and re-sync. Note associations apply at policy refresh / profile creation.

## Symptom: A legacy site does not open in IE mode
**Likely cause:** IE mode not enabled, the site not in the list, or the site-list URL unreachable.
**Fix:**
1. In `edge://policy`, confirm **`InternetExplorerIntegrationLevel`** = IE mode and
   **`InternetExplorerIntegrationSiteList`** points at your `EdgeForBusiness-EMSiteList.xml` URL.
2. From the device, browse to the **site-list URL** and confirm the XML loads (R9). Fix hosting/proxy if it
   does not.
3. Confirm the exact site URL is in `EdgeForBusiness-EMSiteList.xml` with **Open in = IE11**; check
   `edge://compat/enterprise` to see the parsed site list on the device.

## Symptom: An approved extension is blocked (or a bad one installs)
**Likely cause:** Allow-list missing the extension ID, or block-list not set to `*`.
**Fix:**
1. Confirm **`ExtensionInstallBlocklist`** contains **`*`** and the approved extension **ID** is in
   **`ExtensionInstallAllowlist`** (Implementation Step 7). Extension IDs are case-sensitive — copy from
   `edge://extensions`.
2. If out-of-store extensions still install, confirm **`BlockExternalExtensions = Enabled`**.
3. Re-sync and re-check `edge://policy`.

## Symptom: A policy from the guide is not in the Settings Catalog
**Likely cause:** Your Edge / Settings-Catalog version predates that policy, or Microsoft renamed it.
**Fix:**
1. Confirm the pilot device's Edge version (`edge://version`). Newer policies (e.g.
   `TyposquattingCheckerEnabled`) require a recent Edge.
2. Search the Settings Catalog for the **current** name; if renamed, use the equivalent and note it.
3. If truly unavailable, skip that single setting and document it — do not block the rest of the baseline.

## Symptom: The Microsoft Edge security baseline shows "Error"/"Not applicable"
**Likely cause:** Device not fully enrolled/compliant, or a baseline-version/setting not applicable to the
device's Edge/Windows version.
**Fix:**
1. Confirm the device is enrolled and compliant (R7, G4) and synced.
2. Check the baseline **version** — if you created it on an older version, review and consider migrating to
   the current version (Best Practices — change control).
3. Reconcile any setting the baseline reports can't apply against the device's Edge/Windows level.

## Symptom: Works for some devices, not others
**Likely cause:** Group membership, sync timing, or Edge version differences.
**Fix:**
1. Confirm affected devices are in the assigned group (`EDGEBIZ-Report.ps1`).
2. Re-sync stragglers; confirm enrollment (R7).
3. Confirm the affected devices run an Edge version that supports the missing policy (`edge://version`).

## Symptom: Coverage report shows fewer devices than the group
**Likely cause:** Some devices not synced, not enrolled, or on an unsupported Edge/Windows level.
**Fix:**
1. Run `EDGEBIZ-Report.ps1` to list which devices lack the applied baseline.
2. Run `EDGEBIZ-Remediation.ps1` **(`-WhatIf` first)** to correct assignment/scoping.
3. Re-sync stragglers and confirm enrollment (R7) and Edge version (R1).

## Escalation checklist
Before opening a Microsoft support case, collect: the `EDGEBIZ-Discovery.ps1` output, each object's Device
status export, the on-device `edge://policy` export, `edge://version` and `edge://compat/enterprise`
output, the exact policy name/value in dispute, the assignment groups, and whether the issue reproduces on
a freshly synced device (isolates policy from device state).
