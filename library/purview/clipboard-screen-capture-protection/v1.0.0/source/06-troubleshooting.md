# Troubleshooting — Clipboard & Screen-Capture Protection (Microsoft Purview)

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most "the
restriction isn't working" reports trace back to onboarding, screen-capture availability, condition
matching, allowed-app coverage, or simulation-vs-enforce confusion — not the rule itself.** Where a portal
path or cmdlet parameter is named, **verify it against your tenant** — the Purview portal and the endpoint
restriction options evolve, and **screen-capture restriction is newer / may be in preview**.

---

## 1. A device shows no clipboard/screen-capture activity at all

**Symptoms:** Copy or screenshot a matching file on a device and **nothing** appears in Activity explorer
(Devices); the policy never fires.

**Likely causes & fixes**
- **Device isn't onboarded.** The #1 cause. Confirm the device appears under **Purview → Settings → Device
  onboarding → Devices**. If not, re-run your onboarding method (Intune/GPO/local script/ConfigMgr). There
  is **no** S&C PowerShell cmdlet to onboard — it is a portal/management-tool action.
- **Unsupported / unpatched OS build.** Clipboard and screen-capture sensing need a supported minimum
  Windows/macOS build and a current agent. Patch and retest.
- **Onboarding still propagating.** After onboarding, allow time for the device to register and for activity
  to surface — endpoint telemetry is **not** instant. Wait and retry.
- **Check the readiness signals:** `DLPCLIP-ScopeHealth.ps1` reports managed-device counts (Graph) and
  Endpoint-DLP-settings readability — but remember the device count is a **proxy**; the authoritative check
  is the **Devices** list in the portal.

---

## 2. Clipboard is caught, but screen capture is not (or the activity isn't selectable)

**Symptoms:** Copy-to-clipboard is audited/blocked, but a screenshot of the same content does nothing — or
**screen capture** isn't even offered when you author the rule.

**Fix**
- **Screen-capture restriction is newer / may be in preview**, gated on licensing, supported apps/browsers,
  and minimum OS builds. **Verify your licensing/tenant** — if it is unavailable, **deliver clipboard
  restriction first** and revisit screen capture when the capability is enabled. `DLPCLIP-Validate.ps1`
  marks the screen-capture check **VERIFY** (not FAIL) when it can't read the restriction.
- Confirm target devices meet the **minimum OS build** documented by Microsoft for the screen-capture
  activity, and that the capture tool in use is a **supported** one.
- Do **not** treat a missing screen-capture activity as a bug in the policy — it is a capability/availability
  question. Flag it, don't force it.

---

## 3. The restriction fires on the wrong things (false positives)

**Symptoms:** Legitimate work is flagged/blocked — copy-paste between two sanctioned internal apps, or a
screenshot of a normal page.

**Likely causes & fixes**
- **Allowed apps/browsers not configured (or stale).** Add the sanctioned apps/browsers to the **Endpoint
  DLP settings** (Data loss prevention → Endpoint DLP settings) so they aren't caught alongside real
  exfiltration. A missing exception is the most common false-positive driver on endpoints.
- **Condition too broad.** If the rule keys on "all content" instead of a **sensitivity label / SIT**, it
  matches everything. Tighten the condition — prefer a **sensitivity-label condition** where content is
  labelled. `DLPCLIP-Validate.ps1` gate **A6** flags a rule with no readable content condition.
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- Tune **in simulation** — never tune by loosening an already-enforcing block in production. Re-measure with
  `DLPCLIP-Report.ps1` after each change (Gate B in `05-testing.md`).

---

## 4. The restriction doesn't fire on content it should

**Symptoms:** A file you expect to match is copied/screenshotted with no policy match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test file must actually carry the **sensitivity label** or
  contain the **sensitive information type** the rule keys on. Confirm the label is applied / the SIT pattern
  is present (seed a known match, e.g. the Microsoft test credit-card number `4111 1111 1111 1111`).
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPCLIP-Discovery.ps1` inventories
  both and flags rules that carry a clipboard/screen-capture restriction.
- **Rule disabled.** `DLPCLIP-Validate.ps1` gate **A5a** flags a disabled rule.
- **Below-threshold content.** A single low-confidence fragment below the configured confidence/instance
  count will correctly not match — that is tuning, not a fault.

---

## 5. Simulation looks fine but enforcement doesn't block

**Symptoms:** In simulation the copy/screenshot is recorded; after "turning it on" the block/warn still
doesn't happen.

**Likely causes & fixes**
- **Policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the policy out
  of simulation: portal → turn the policy **On**; PowerShell →
  `Set-DlpCompliancePolicy -Identity 'DLP - Endpoint Clipboard+Screen - Simulation' -Mode Enable`.
  `DLPCLIP-Validate.ps1` gate **A3** shows the current mode.
- **Restriction action still Audit.** The rule's clipboard/screen-capture restriction may be **Audit** even
  though the policy is enforcing. Set the per-activity action to **Block with override** / **Block** per the
  compliance determination.
- **Device out of scope.** Enforcement only applies to devices in the policy's Devices scope. Confirm with
  `DLPCLIP-ScopeHealth.ps1` / gate **A4** — during pilot, scope is `DLP Pilot Ring - Stage1`, not `All`.
- **Propagation delay.** Policy/action changes take time to reach endpoints. Wait, then retest.

---

## 6. `New-DlpComplianceRule` fails on the clipboard/screen-capture restriction

**Symptoms:** `DLPCLIP-Configure.ps1 -Commit` (or manual scripting) errors when setting the endpoint
restriction, e.g. an invalid Setting name or value.

**Fix**
- **Verify the exact Setting names and values for your tenant.** The endpoint-restriction Setting names
  (copy to clipboard, screen capture) and permitted values (`Audit` / `Block` / `BlockWithOverride` /
  `Ignore`) **evolve**, and **screen capture may be preview**. Run `Get-Help New-DlpComplianceRule -Full`
  and check current Microsoft docs, then adjust the hashtable. `DLPCLIP-Configure.ps1` deliberately
  **prints the planned Setting names** so you can verify before `-Commit`.
- **Prefer the portal for the first build** if the PowerShell parameter names are uncertain, then read the
  result back with `DLPCLIP-Discovery.ps1` to learn the exact shape in your tenant before committing.

---

## 7. `-EndpointDlpLocation` / scope errors

**Symptoms:** Creating the policy errors on the location/scope value.

**Fix**
- The **Devices** location is scoped by user/group (or `All`). Confirm the pilot group
  (`DLP Pilot Ring - Stage1`) exists and the identifier is one your tenant accepts.
  `DLPCLIP-ScopeHealth.ps1` reports the group and the current scope.
- Avoid `All` during the pilot — scope to the pilot ring first (gate **A4**).

---

## 8. Activity report is empty or export fails

**Symptoms:** `DLPCLIP-Report.ps1` returns no clipboard/screen-capture rows, or the Activity Explorer export
warns and skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns and
  degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer** (filter
  to *copy to clipboard* / *screen capture*) and **DLP → Alerts** in the portal.
- **Field naming differs.** The script keeps rows whose serialized event mentions a clipboard/screen-capture
  token; if the tenant names fields differently, rows may be returned but not matched — check the portal
  filter directly.
- **Quiet pilot window.** A small pilot may simply have no activity — widen `-Days` or perform the sanctioned
  test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.

---

## 9. "It blocked an admin / broke a workflow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the policy to **simulation** or **off**:
  `Set-DlpCompliancePolicy -Identity 'DLP - Endpoint Clipboard+Screen - Simulation' -Mode TestWithoutNotifications`
  (simulation) or `-Mode Disable` (off). Either **stops enforcement at once**, with no data change.
- Or set the offending **restriction action back to Audit** for the clipboard/screen-capture activity.
- Then work the relevant section above (usually §3 false positives or §5 scope), fix **in simulation**,
  re-validate with `DLPCLIP-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* copy/screenshot of this content be **blocked** or only **audited**? → the **compliance** owners.
- Is *this content* actually sensitive / in scope? → **compliance / data owners**.
- Is a user's copy/screenshot a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPCLIP-Report.ps1`, Activity explorer, the `DLPCLIP-Validate.ps1` output) —
not a verdict. And stay honest about the boundary: Endpoint DLP restricts content it can **classify** at the
moment of the activity — a determined user can still **photograph a screen with a phone**. It is one
supporting control, not a guarantee.
