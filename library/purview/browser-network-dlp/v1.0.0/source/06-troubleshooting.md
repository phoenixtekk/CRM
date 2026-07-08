# Troubleshooting — Browser & Network DLP (Microsoft Purview)

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most "the
upload isn't being caught" reports trace back to onboarding, the browser extension, condition matching,
the sensitive service domain group, or simulation-vs-enforce confusion — not the rule itself.** Where a
portal path or cmdlet parameter is named, **verify it against your tenant** — the Purview portal and the
Endpoint DLP browser/domain settings evolve.

---

## 1. A device shows no upload/egress activity at all

**Symptoms:** Upload a matching file to a restricted domain on a device and **nothing** appears in
Activity explorer (Devices); the policy never fires.

**Likely causes & fixes**
- **Device isn't onboarded.** The #1 cause. Confirm the device appears under **Purview → Devices**
  (Settings → Device onboarding). If not, re-run your onboarding method (Intune/GPO/local script/
  ConfigMgr). There is **no** S&C PowerShell cmdlet to onboard — it is a portal/management-tool action.
- **Browser not covered.** In Chrome/Firefox, no Microsoft Purview browser extension means no visibility
  (see §2). In Edge, confirm native integration applies.
- **Onboarding still propagating.** After onboarding, allow time for the device to register and for
  activity to surface — endpoint telemetry is **not** instant. Wait and retry.
- **Check the readiness signals:** `DLPBROWSER-ScopeHealth.ps1` reports managed-device counts (Graph),
  the licensing flag, and the coverage checklist — but remember the device count is a **proxy**; the
  authoritative check is the **Devices** list in the portal.

---

## 2. Uploads are caught in Edge but Chrome/Firefox are invisible

**Symptoms:** Cloud-egress/upload is caught in **Edge** but not in **Chrome** or **Firefox**.

**Fix**
- **Deploy the Microsoft Purview browser extension** to Chrome/Firefox (Requirement 2.6). Edge is
  native; Chrome/Firefox **cannot** see upload/cloud-egress activity without the extension.
- Until the extension is deployed, treat those browsers as **unallowed browsers** in the Endpoint DLP
  settings so uploads through them are controlled rather than silently uncovered.
- Verify the extension is actually installed and enabled on a sample device (via your browser enterprise
  policy). `DLPBROWSER-ScopeHealth.ps1` lists this as a checklist item — deployment itself is
  enterprise-managed, not scriptable here.

---

## 3. The rule fires on the wrong things (false positives)

**Symptoms:** Legitimate work is flagged/blocked — an upload to a **sanctioned** destination, or
non-sensitive content.

**Likely causes & fixes**
- **Sanctioned destination in the restricted group.** Remove corporate OneDrive/SharePoint and approved
  SaaS from `Unsanctioned & Personal Cloud – Domain Group`; that group should hold only the destinations
  you intend to control.
- **Condition too broad.** If the rule keys on "all content" instead of a **sensitivity label / SIT**,
  it will match everything. Tighten the condition (Requirement 2.7). `DLPBROWSER-Validate.ps1` gate
  **A6** flags a rule with no readable content condition.
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- Tune **in simulation** — never tune by loosening an already-enforcing block in production.

---

## 4. The rule doesn't fire on an upload it should

**Symptoms:** A file you expect to match is uploaded to a restricted domain with no policy match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test file must actually carry the **sensitivity label**
  or contain the **sensitive information type** the rule keys on. Seed a known match and confirm the
  label is applied / the SIT pattern is present.
- **Destination not in the domain group.** Confirm the target domain is a member of
  `Unsanctioned & Personal Cloud – Domain Group` (a missing destination is uncontrolled). Use
  `DLPBROWSER-Report.ps1` to see where uploads actually go and refine the list.
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPBROWSER-Discovery.ps1`
  inventories both.
- **Rule disabled.** `DLPBROWSER-Validate.ps1` gate **A5b** flags a disabled rule.

---

## 5. Simulation looks fine but enforcement doesn't block

**Symptoms:** In simulation the upload is recorded; after "turning it on" the block/warn still doesn't
happen.

**Likely causes & fixes**
- **Policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the policy
  out of simulation: portal → turn the policy **On**; PowerShell →
  `Set-DlpCompliancePolicy -Identity 'Browser & Network DLP - Devices - Pilot' -Mode Enable`.
  `DLPBROWSER-Validate.ps1` gate **A3** shows the current mode.
- **Domain-group action still Audit.** The sensitive service domain group's action for "upload to a
  restricted domain" may still be **Audit** even though the policy is enforcing. Escalate it to
  **Warn/Block** in Endpoint DLP settings per the approved design.
- **Device out of scope.** Enforcement only applies to devices in the policy's Devices scope. Confirm
  with `DLPBROWSER-ScopeHealth.ps1` / gate **A4**.
- **Propagation delay.** Policy/action changes take time to reach endpoints. Wait, then retest.

---

## 6. `New-DlpComplianceRule` fails on the endpoint upload restriction

**Symptoms:** `DLPBROWSER-Configure.ps1 -Commit` (or manual scripting) errors when setting the endpoint
upload restriction, e.g. an invalid Setting name or value.

**Fix**
- **Verify the exact Setting name and values for your tenant.** The endpoint-restriction Setting name for
  the upload/cloud-egress activity and its permitted values (`Audit` / `Warn` / `Block` / `Ignore`)
  **evolve**. Run `Get-Help New-DlpComplianceRule -Full` and check current Microsoft docs, then adjust
  the hashtable. `DLPBROWSER-Configure.ps1` deliberately **prints the planned Setting name** so you can
  verify before `-Commit`.
- **Remember the destination side is portal-managed.** The sensitive service domain group and the
  unallowed-browsers list are configured in **Endpoint DLP settings** (portal), not by the script —
  build them there first, then key the policy/rule to your content condition.
- **Prefer the portal for the first build** if PowerShell parameter names are uncertain, then read the
  result back with `DLPBROWSER-Discovery.ps1` to learn the exact shape in your tenant.

---

## 7. `-EndpointDlpLocation` / scope errors

**Symptoms:** Creating the policy errors on the location/scope value.

**Fix**
- The **Devices** location is scoped by user/group (or `All`). Confirm the pilot group
  (`SG-DLPBROWSER-Pilot`) exists and the identifier is one your tenant accepts. `DLPBROWSER-ScopeHealth.ps1`
  reports the group and the current scope.
- Avoid `All` during the pilot — scope to the pilot group first (gate **A4**).

---

## 8. Upload-activity report is empty or export fails

**Symptoms:** `DLPBROWSER-Report.ps1` returns no upload activity, or the Activity Explorer export warns
and skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns and
  degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer**
  (filter to **Devices** + upload/egress activities) in the portal.
- **Keyword filter missed the activity-type name.** Endpoint activity-type names evolve; the script falls
  back to exporting **all** rows for manual review when its upload/egress keywords match nothing — open
  the CSV and look for the upload/cloud-egress events directly.
- **Quiet pilot window.** A small pilot may simply have no activity in the window — widen `-Days` or
  perform the sanctioned test upload from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.

---

## 9. `Get-PolicyConfig` can't read the domain group / unallowed browsers

**Symptoms:** `DLPBROWSER-Discovery.ps1` / `DLPBROWSER-Validate.ps1` report the sensitive service domain
group or unallowed-browsers list as not readable (gate **A7 / A7b** = UNKNOWN).

**Fix**
- **This is expected on some tenants.** The Endpoint DLP browser/domain **settings** surface and the
  `Get-PolicyConfig` property shape **evolve**, and these settings are **portal-managed**. UNKNOWN is not
  a failure — **confirm the domain group and unallowed-browsers list in the portal**: Data Loss
  Prevention → Endpoint DLP settings → **Browser and domain restrictions to sensitive data** (verify
  path).
- Do not attempt to script settings Microsoft manages in the portal — the scripts deliberately read and
  report them, and configure only the policy/rule that has a supported PowerShell surface.

---

## 10. "It blocked an admin / broke a workflow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the policy to **simulation** or **off**:
  `Set-DlpCompliancePolicy -Identity 'Browser & Network DLP - Devices - Pilot' -Mode TestWithoutNotifications`
  (simulation) or `-Mode Disable` (off). Either **stops enforcement at once.**
- Or return the sensitive service domain group's upload action to **Audit** in Endpoint DLP settings.
- Then work the relevant section above (usually §3 false positives or §5 scope/action), fix **in
  simulation**, re-validate with `DLPBROWSER-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* this destination be **blocked** or only **audited**? → the action-ladder decision owners.
- Is *this destination* actually "unsanctioned," and is *this content* in scope? → **compliance / data
  owners**.
- Is a user's upload a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPBROWSER-Report.ps1`, Activity explorer, the validation output) — not
a verdict.
