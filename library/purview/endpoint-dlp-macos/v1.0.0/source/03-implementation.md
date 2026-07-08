# 3. Implementation Guide — Endpoint DLP for macOS (Microsoft Purview)

Follow these steps **in order**. The **Microsoft Purview portal**, the **Intune** onboarding path, and
the **Security & Compliance PowerShell** automation are given click-by-click / cmdlet-exact. **Jamf
Pro** onboarding is named and deferred to Jamf's documentation for its console specifics. Category
Purview prerequisites (licensing, roles, toolchain, classification intent, stakeholders, pilot/change
control) are assumed confirmed (Requirements + `global-requirements-purview.md`).

Consoles used:
- **Microsoft Purview portal** — `https://purview.microsoft.com` (Device onboarding, Endpoint DLP
  settings, Data Loss Prevention → Policies)
- **Microsoft Intune admin center** — `https://intune.microsoft.com` (macOS onboarding + extension /
  Full Disk Access profiles)
- **Jamf Pro** — deferred to Jamf documentation for the equivalent profiles
- **Security & Compliance PowerShell** — `Connect-IPPSSession`

> **Model:** Onboard the Macs, configure the endpoint settings, create the DLP policy **in
> test/simulation (Audit)**, pilot on a few onboarded Macs, validate in Activity Explorer, then move
> rules to **Block (enforce)** in waves. **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**

> **Artifact names (use verbatim):** onboarding config (Intune) `Purview DLP - macOS Onboarding`; DLP
> policy `Endpoint DLP - macOS - Pilot` (later `Endpoint DLP - macOS - Prod`); DLP rule
> `macOS Egress - Sensitive Content`; restricted app group `macOS - Restricted Apps`.

> **Risk + rollback (read first):** Endpoint DLP **Block** actions can interrupt legitimate work
> (blocked USB copy, blocked upload, blocked print). This solution therefore creates the policy in
> **`TestWithoutNotifications`** (silent simulation / Audit) and only advances to `Enable` after
> validation. **Rollback:** set the policy **Mode** back to `TestWithoutNotifications` (or `Disable`)
> to stop enforcing immediately (`Set-DlpCompliancePolicy -Mode`); un-scope by removing the **Devices**
> location; fully stop by disabling the policy. Onboarding is reversible by **off-boarding** the device
> in Purview / removing the MDM profiles. Regulatory/records/legal determinations remain with the
> relevant governance functions — this guide configures the technical control.

---

## Phase 1 — Onboard macOS devices to Microsoft Purview

### Step 1 — Get the macOS onboarding package from Purview
1. Purview portal → **Settings → Device onboarding** *(verify the exact path for your tenant; the
   onboarding blade has moved between the compliance portal and the new Purview portal)*.
2. Choose **macOS** and the **deployment method** — **Intune** or **Jamf** — and **download the
   onboarding package** (a configuration payload / `.mobileconfig` / onboarding blob).
3. Note that onboarding for Endpoint DLP on macOS uses the same device-onboarding pipeline as Microsoft
   Defender for Endpoint; if MDE is already deployed on the Mac, the extensions may be shared —
   **verify against current Microsoft guidance for your tenant**.

### Step 2 — Deploy onboarding + required profiles via Intune
Create these in Intune → **Devices → macOS → Configuration** (name the onboarding one
`Purview DLP - macOS Onboarding`) and assign to the **pilot Mac group**:
1. **Onboarding package** — upload the payload from Step 1 as a **configuration profile** (custom /
   `.mobileconfig`).
2. **System extension** — a **System Extensions** profile that **allows** the DLP/Defender extension
   (team identifier / bundle IDs per Microsoft's macOS deployment docs).
3. **Network extension** — a **content-filter / network extension** profile so egress can be inspected.
4. **Full Disk Access (PPPC/TCC)** — a **Privacy Preferences Policy Control** profile granting **Full
   Disk Access** to the agent so it can see file activity.
5. **(Optional) Background/Notifications** profiles per Microsoft's macOS guidance.
6. Assign all profiles to the **pilot Mac group** and let them apply.

> **Jamf path (deferred):** deploy the same four payloads — onboarding package, **System Extensions**
> allow, **Content Filter / network** extension, and **PPPC (Full Disk Access)** — via Jamf **Configuration
> Profiles**. The payload contents are Microsoft's; the Jamf console steps are deferred to Jamf's docs.

### Step 3 — Confirm the Macs are onboarded
1. Purview portal → **Settings → Device onboarding → Devices** — the pilot Macs appear as
   **onboarded/active** *(verify path)*.
2. On a pilot Mac, **System Settings → Privacy & Security** shows the extension **allowed** and **Full
   Disk Access** granted.
3. Run **`DLPMac-Onboarding-Check.ps1`** — it reports managed macOS devices, OS versions, and whether
   the onboarding/extension configuration profiles are present in Intune.
4. **Pass/fail gate:** at least the pilot Macs are onboarded and show the extension + Full Disk Access.
   Do **not** proceed until Macs report — a policy on an un-onboarded Mac does nothing.

---

## Phase 2 — Configure Endpoint DLP settings (shared, tenant-wide)

### Step 4 — Set the Endpoint DLP settings baseline
Purview portal → **Data Loss Prevention → Endpoint DLP settings**. Review/set (to the pilot intent
agreed with data owners — determinations remain theirs):
1. **Restricted apps and app groups** — create the app group `macOS - Restricted Apps` listing the
   macOS apps you want to restrict access to sensitive files (e.g. personal cloud-sync / messaging
   apps, by bundle ID/name). The DLP rule references this group.
2. **Browser and domain restrictions to sensitive data** — set **unallowed browsers** (so sensitive
   files can't upload via non-approved browsers) and confirm **Microsoft Edge** is the approved browser;
   deploy the **Purview browser extension** for Chrome/Firefox (Requirement 2.8).
3. **Sensitive service domains** — define the **service domain groups** (approved vs sensitive) that
   the cloud-egress control acts on.
4. **File path exclusions (macOS)** — add any macOS paths to exclude from monitoring (to cut noise),
   being careful not to exclude paths that would create a gap.

> These settings are **shared by every endpoint DLP policy** — change them under change control.
> **`DLPMac-Validation.ps1`** flags a rule that references the `macOS - Restricted Apps` group if the
> group is absent.

---

## Phase 3 — Create the DLP policy in simulation/test (Audit) mode

### Step 5 — Create the endpoint-scoped DLP policy (test mode)
1. **Portal path:** Purview → **Data Loss Prevention → Policies → Create policy** → choose the data
   categories/custom, name it **`Endpoint DLP - macOS - Pilot`**, and select the **Devices** location
   **only** (turn off Exchange/SharePoint/OneDrive/Teams for this Mac-focused pilot).
2. On **Policy mode**, choose **Run the policy in simulation mode** (optionally with policy tips off) —
   this is the **`TestWithoutNotifications`** mode: it **audits/simulates** without user-visible tips or
   blocks.
3. **Automation (preferred, safe):** run **`DLPMac-Set-Policy.ps1`** — default **-WhatIf** (previews the
   `New-DlpCompliancePolicy` / `New-DlpComplianceRule` it would run); add **-Commit** to create the
   policy **in `TestWithoutNotifications`** and the rule with **Audit** endpoint restrictions:
   ```
   New-DlpCompliancePolicy -Name 'Endpoint DLP - macOS - Pilot' -EndpointDlpLocation All -Mode TestWithoutNotifications
   ```
   The script never creates the policy in `Enable` mode — enforcement is a deliberate later step.

### Step 6 — Add the egress rule (Audit actions first)
1. In the policy, **Create rule** `macOS Egress - Sensitive Content`.
2. **Conditions:** content is sensitive — the agreed **SIT(s) / sensitivity label(s) / conditions**
   (Requirement 2.9).
3. **Endpoint restrictions (start at Audit):** set each in-scope channel to **Audit** for the pilot:
   - **Upload to a cloud service / access by unallowed browser** → **Audit**
   - **Copy to a USB removable device** → **Audit**
   - **Copy to a network share** → **Audit**
   - **Copy to clipboard** → **Audit**
   - **Print** → **Audit**
   - **Access by restricted apps** (`macOS - Restricted Apps`) → **Audit**
   *(Only include channels supported on your macOS version — verify current support.)*
4. Save the rule. **`DLPMac-Set-Policy.ps1 -Commit`** creates this rule with **Audit** restrictions via
   `New-DlpComplianceRule -EndpointDlpRestrictions` — never Block on first creation.

### Step 7 — Confirm the policy is scoped and in test mode
1. Run **`DLPMac-Discovery.ps1`** — it lists the endpoint-scoped policy, confirms **Mode =
   TestWithoutNotifications** (flags anything in `Enable`), and lists the rule's egress restrictions.
2. Run **`DLPMac-Validation.ps1`** — confirms the policy targets **Devices**, is in a **test** mode, and
   the rule includes the intended channels + references a present restricted-app group.
3. **Pass/fail gate:** policy exists, **Devices**-scoped, **Mode = TestWithoutNotifications**, rule
   present with **Audit** actions. Do not advance until this passes.

---

## Phase 4 — Pilot, validate, then enforce

### Step 8 — Drive test activities on a pilot Mac and validate
1. On an onboarded pilot Mac, perform benign test egress with **non-production test content that
   matches the SIT** (e.g. a file with dummy test data): copy to USB, copy to a network share, upload
   from a browser, copy to clipboard, print, open with a restricted app.
2. Purview portal → **Activity Explorer** (or run **`DLPMac-Report.ps1`**, which uses
   `Export-ActivityExplorerData`) — the simulated/audited **Endpoint DLP** events for the Mac appear
   with the activity, app, and matched rule.
3. **Pass/fail gate (simulation):** every driven channel produces an **audited** event attributed to
   `Endpoint DLP - macOS - Pilot` / `macOS Egress - Sensitive Content`, and no unexpected volume of
   false positives. If a channel produces nothing, revisit onboarding/extensions (Phase 1) or the
   channel's macOS support before enforcing.

### Step 9 — Advance to notifications, then enforce (Block) — deliberately, in scope
Only after Step 8 passes and **compliance/records/legal sign off** the enforcement intent:
1. **`TestWithNotifications`** — move the policy to test **with** policy tips so pilot users see
   warnings (still no block): `Set-DlpCompliancePolicy -Identity 'Endpoint DLP - macOS - Pilot' -Mode
   TestWithNotifications`. Confirm tips appear on the Mac; gather user feedback.
2. **Enforce selectively** — change the rule's chosen channels from **Audit** to **Block** (or
   **Block with override / Warn**) for the channels compliance approved, and set the policy to
   **`Enable`**: `Set-DlpCompliancePolicy -Identity 'Endpoint DLP - macOS - Pilot' -Mode Enable`.
   Start with the **highest-risk, lowest-friction** channel (often USB) rather than all at once.
3. Re-run **`DLPMac-Report.ps1`** — confirm blocks/overrides are recorded as intended.
4. **Rollback if needed:** `Set-DlpCompliancePolicy -Mode TestWithoutNotifications` (back to silent
   simulation) reverts enforcement immediately on next sync.

### Step 10 — Expand to production in waves
1. Create the production twin **`Endpoint DLP - macOS - Prod`** (or widen the pilot policy's onboarded
   scope), starting again in **`TestWithoutNotifications`** for the newly onboarded Macs.
2. Onboard production Macs in **waves** (Phase 1) so each wave is validated in simulation before it is
   enforced.
3. Re-run **`DLPMac-Validation.ps1`** and **`DLPMac-Report.ps1`** after each wave; only advance the mode
   once the wave passes.

---
### Order of operations
`Onboard Macs (Intune/Jamf: package + system/network extension + Full Disk Access) → confirm onboarded →
Endpoint DLP settings (restricted apps, domains, exclusions) → create DLP policy Devices-scoped in
TestWithoutNotifications → add egress rule with Audit actions → discovery/validation confirm test mode →
drive test activities + validate in Activity Explorer → TestWithNotifications → enforce (Block) selected
channels on Enable → expand in waves (each starting in simulation)`
