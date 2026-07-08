# 3. Implementation Guide — Browser & Network DLP (Microsoft Purview)

Follow these steps **in order**. Work is done in the **Microsoft Purview portal**
(purview.microsoft.com), **Security & Compliance PowerShell** (`Connect-IPPSSession`), and **Microsoft
Graph**. The DLP policy is authored in **simulation/test mode** and previewed with `-WhatIf` before any
`-Commit`/enforce. Artifact names follow the `<Purpose> – Purview – <Stage>` convention from the Overview
and are reused verbatim.

> **Model:** Assess the tenant → design the in-scope data, destinations, and action ladder → configure
> onboarding, extension, domain group, and the policy in simulation → pilot on a ring and tune → confirm
> every gate → expand to enforce. Pattern: **Assess → Design → Configure → Pilot (simulate) → Validate →
> Expand (enforce).**
>
> **Portal paths are cited as of authoring and the Purview portal / Endpoint DLP settings are evolving —
> verify each path in your own tenant.** Capability availability is licensing-dependent — verify against
> your plan (Requirement 2.1). The upload restriction is **high-impact**: it is piloted in
> **simulation/test** and tuned before Warn/Block enforcement.

## Step 1 — Assess the tenant (Assess)
1. Run `DLPBROWSER-Assess-Readiness.ps1 -CsvPath .\DlpBrowserReadiness.csv`. Read-only, it captures:
   whether an **Endpoint DLP–bearing SKU** is present (E5 / E5 Compliance / E5 IP&G), existing
   **Devices-scoped DLP policies** and their **mode** (enabled vs test/simulation), and S&C
   PowerShell + Graph connectivity. It writes `Browser & Network DLP – Egress – Assess`.
2. Run `DLPBROWSER-Get-EndpointHealth.ps1 -CsvPath .\EndpointHealth.csv` to record **device onboarding**
   readiness and the **browser-extension** checklist for the pilot ring.
3. **Pass/fail:** you can state that Endpoint DLP is available on the plan, how many devices are
   onboard-ready, and whether any Devices DLP policy already exists (to avoid conflicts).

## Step 2 — Design the in-scope data, destinations, and action ladder (Design)
1. Confirm the **policy condition**: the sensitivity labels and/or sensitive information types that make
   an upload "sensitive" (Requirement 2.7). Record them.
2. Compile the **destination list** for `Unsanctioned & Personal Cloud – Domain Group` — personal cloud
   storage and unsanctioned file-sharing/SaaS domains (Requirement 2.8). Use
   `DLPBROWSER-Report-Activity.ps1` to see where uploads actually go today.
3. Decide the **unallowed browsers** stance (which browsers to steer users away from where the extension
   isn't present) and the **action ladder** per destination group: **Audit** first (simulation),
   then **Warn** (block with override + business justification), then **Block** for the highest-risk
   destinations. **Which data and which destinations warrant restriction are compliance/security
   determinations** — you implement them, stakeholders decide.
4. **Pass/fail:** a one-page design names the condition (labels/SITs), the domain group members, the
   unallowed-browser stance, and the action per group.

## Step 3 — Confirm onboarding and browser coverage (Configure)
1. Ensure the pilot-ring devices are **onboarded to Purview**: Purview portal → `Settings → Device
   onboarding` (verify path). Re-run `DLPBROWSER-Get-EndpointHealth.ps1` until the ring reports onboarded.
2. Deploy the **Microsoft Purview browser extension** to **Chrome** and **Firefox** on the ring (Group
   Policy / Intune / enterprise browser management, per Microsoft's guidance). **Microsoft Edge** uses
   its **native** integration — no extension. Verify the extension is enabled on a pilot device.
3. **Pass/fail:** every pilot device is onboarded and shows the extension enabled in Chrome/Firefox;
   Edge is confirmed as natively covered.

## Step 4 — Build the sensitive service domain group + browser restrictions (Configure)
1. In Purview portal → **Data Loss Prevention → Endpoint DLP settings → Browser and domain restrictions
   to sensitive data** (verify path):
   - Create the **sensitive service domain group** `Unsanctioned & Personal Cloud – Domain Group` and add
     the destinations from Step 2. Set the per-activity action for **"Upload to a restricted cloud
     service domain"** to **Audit** for the pilot (you will escalate to Warn/Block after validation).
   - Configure the **unallowed browsers** list per the Step 2 stance.
2. These Endpoint DLP **settings** are portal-managed — record the exact group name and action so the DLP
   policy (next step) and the docs stay consistent. Do not attempt to script settings Microsoft manages
   in the portal.
3. **Pass/fail:** the domain group exists with the intended members and a starting action of **Audit**;
   the unallowed-browsers list matches the design.

## Step 5 — Author the DLP policy in simulation/test mode (Configure, pilot-first)
1. Dry-run first: `DLPBROWSER-New-DlpPolicy.ps1 -WhatIf`. With `-WhatIf` (the default) it makes **no
   changes** — it prints the exact `New-DlpCompliancePolicy` / `New-DlpComplianceRule` it *would* run,
   including the policy name `Browser & Network DLP – Devices – Pilot`, the **Devices** location scoped
   to the pilot ring, the rule `Restrict Upload to Unsanctioned Domains – Rule` conditioned on your
   labels/SITs, and the **test mode**.
2. Create in simulation: `DLPBROWSER-New-DlpPolicy.ps1 -Commit -Mode TestWithoutNotifications
   -Sits '<SIT names>'` (or `-SensitivityLabels '<label GUIDs>'`). The policy is created **in test mode**
   — it evaluates and records matches but **does not block or notify** users. The endpoint upload
   restriction is realized through the domain group's action (Step 4) once the policy scopes it; keep the
   domain-group action at **Audit** during simulation.
3. Scope the policy to `Browser & Network DLP Pilot Ring – Stage1` (a device group / user set), not the
   whole tenant.
4. **Pass/fail + rollback:** `Get-DlpCompliancePolicy -Identity 'Browser & Network DLP – Devices – Pilot'`
   shows `Mode = TestWithoutNotifications` and the Devices location. Rollback is
   `Set-DlpCompliancePolicy -Identity '<name>' -Mode Disable` or `Remove-DlpCompliancePolicy` (the script
   prints the exact reverse command).

## Step 6 — Pilot in simulation and tune (Pilot → simulate)
1. Let the policy run in **test/simulation** on the ring for a representative period. From a pilot device,
   attempt an upload of sensitive test content to a domain in the group.
2. Review what the policy **would have** acted on: Purview portal → the policy's **simulation/overview**
   (verify path) and `Data classification → Activity explorer`; run
   `DLPBROWSER-Test-Validation.ps1` to confirm the policy mode, rules, and match counts, and
   `DLPBROWSER-Report-Activity.ps1` to summarize endpoint egress events.
3. **Tune:** adjust the domain group membership, the labels/SITs condition, and the action ladder to
   remove false positives and cover missed destinations. Re-run until the simulation matches the intent.
4. **Pass/fail:** simulation shows the expected uploads matched with an acceptable false-positive rate;
   the Testing Guide gates pass on the ring.

## Step 7 — Validate on the pilot ring (Validate)
1. Complete the **Testing Guide** on `Browser & Network DLP Pilot Ring – Stage1`: extension active,
   onboarded devices covered, domain group behaving, simulation producing the expected matches, and
   evidence appearing in Activity Explorer / the audit log.
2. Confirm the **unallowed browsers** control steers users as designed, and that a covered browser
   (Edge / extension-equipped Chrome/Firefox) is what actually enforces.
3. **Pass/fail:** all Testing-Guide gates pass; stakeholders sign off on moving from simulation to
   enforcement.

## Step 8 — Expand to enforcement (Expand → enforce)
1. Escalate the action ladder: in Endpoint DLP settings, move the domain group's upload action from
   **Audit** to **Warn (block with override)**, and to **Block** for the highest-risk destinations, per
   the approved design. Move the policy from test to enforce:
   `DLPBROWSER-New-DlpPolicy.ps1 -Enforce` (wraps `Set-DlpCompliancePolicy -Mode Enable`) — dry-run
   `-WhatIf` first.
2. **Broaden device scope** from the pilot ring to the full onboarded set in stages, re-validating at
   each ring.
3. Keep evidence flowing — `DLPBROWSER-Report-Activity.ps1` on a schedule — and hand off adjacent lanes
   (USB/removable media, print, clipboard/screen capture, Exchange/SharePoint/OneDrive/Teams DLP, cloud
   apps via Defender for Cloud Apps) to their dedicated solutions.

---
### Order of operations
`Assess tenant + endpoints → Design condition/destinations/action ladder → Confirm onboarding + browser
extension → Build sensitive service domain group (Audit) + unallowed browsers → Author DLP policy in
test/simulation (dry-run then -Commit) → Pilot in simulation and tune → Validate on ring → Escalate to
Warn/Block + expand device scope (enforce)`
