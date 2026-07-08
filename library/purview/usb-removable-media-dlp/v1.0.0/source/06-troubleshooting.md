# Troubleshooting — USB & Removable-Media DLP

The failures you will actually hit, with the most likely cause and the fix. Work top-down: **most
"the policy isn't working" reports trace back to onboarding, device-group membership, condition
matching, or simulation-vs-enforce confusion — not the rule itself.** Where a portal path or cmdlet
parameter is named, **verify it against your tenant** — the Purview portal and the removable-media /
device-control options evolve.

---

## 1. A device shows no removable-media activity at all

**Symptoms:** Copy a matching file to a USB stick on a device and **nothing** appears in Activity
explorer (Devices); the policy never fires.

**Likely causes & fixes**
- **Device isn't onboarded.** The #1 cause. Confirm the device appears under **Purview → Devices**
  (Settings → Device onboarding). If not, re-run your onboarding method (Intune/GPO/local script/
  ConfigMgr). There is **no** S&C PowerShell cmdlet to onboard — it is a portal/management-tool action.
- **Unsupported / unpatched build.** Endpoint sensing needs a supported build (Windows 10 1809+ /
  Windows 11, or a supported macOS) and a current antimalware client (R3). Patch and retest.
- **Onboarding still propagating.** After onboarding, allow time for the device to register and for
  activity to surface — endpoint telemetry is **not** instant. Wait and retry.
- **Check the proxy signal:** `DLPUSB-ScopeHealth.ps1` reports managed-device counts (Graph) — but
  remember that is a **proxy**; the authoritative check is the **Devices** list in the portal.

---

## 2. Endpoint DLP (content) sees the copy, but device control does nothing (or vice-versa)

**Symptoms:** Only one of the two layers is acting.

**Fix**
- **They are configured in different places.** Endpoint DLP (content) is the Purview **DLP policy**;
  device control (device) is deployed through your **management tooling** (Intune / GPO / OMA-URI).
  Confirm **both** exist: `DLPUSB-Validate.ps1` covers the DLP policy; check
  `DC-RemovableStorage-Pilot` in your management tool for the device-control layer.
- **Device control not assigned to the pilot ring.** Verify the device-control policy targets
  `DG-USB-Pilot` and reached the device (management-tool reporting).
- **Remember what each layer does:** content DLP only fires on **sensitive** content; device control
  fires on the **device** regardless of content. A plain (non-sensitive) file copy to an unapproved
  USB is a *device-control* event, not a content-DLP event — that is by design.

---

## 3. The control fires on the wrong things (false positives)

**Symptoms:** Legitimate work is flagged/blocked — a corporate USB, or a non-sensitive file copy.

**Likely causes & fixes**
- **Approved device not in `USBG-Corporate`.** Add the corporate device to the removable-storage
  device group (Endpoint DLP settings) and make sure the DLP rule **and** the device-control policy
  reference it as the approved exception.
- **Content condition too broad.** If the Endpoint DLP rule keys on "all content" instead of a
  **sensitivity label / SIT**, it matches everything copied to USB. Tighten the condition (R5).
  `DLPUSB-Validate.ps1` gate **A6** flags a rule with no readable content condition. (If you actually
  want to stop *all* USB use, that belongs in the **device-control** layer, not a content rule keyed
  to "all content.")
- **SIT confidence/count too loose.** Raise the confidence level or instance count on the sensitive
  information type to cut noise, then re-test.
- Tune **in simulation/audit** — never tune by loosening an already-enforcing block in production.

---

## 4. The rule doesn't fire on content it should

**Symptoms:** A file you expect to match is copied to USB with no policy match.

**Likely causes & fixes**
- **Content doesn't carry the label/SIT.** The test file must actually carry the **sensitivity
  label** or contain the **sensitive information type** the rule keys on. Seed a known match.
- **Label not published / SIT not in scope.** Confirm the label is published to the user (Information
  Protection → Label policies) and the SIT exists (Data classification). `DLPUSB-Discovery.ps1`
  inventories both.
- **Rule disabled.** `DLPUSB-Validate.ps1` gate **A5b** flags a disabled rule.

---

## 5. Simulation/audit looks fine but enforcement doesn't block

**Symptoms:** In simulation/audit the activity is recorded; after "turning it on" the block/warn/
read-only still doesn't happen.

**Likely causes & fixes**
- **DLP policy still in a Test mode.** Simulation records but does **not** block. To enforce, move the
  policy out of simulation: portal → turn the policy **On**; PowerShell → `Set-DlpCompliancePolicy
  -Identity EDLP-USB-Pilot -Mode Enable`. `DLPUSB-Validate.ps1` gate **A3** shows the current mode.
- **Rule action still Audit.** The removable-media restriction may be **Audit** even though the policy
  is enforcing. Set it to **Warn/Block** per the R8 decision.
- **Device-control policy still in audit.** In your management tool, move `DC-RemovableStorage-Pilot`
  from **audit** to **read-only / Block** for unapproved media.
- **Device out of scope.** Enforcement only applies to devices in scope. Confirm with
  `DLPUSB-ScopeHealth.ps1` / gate **A4** and the device-control assignment.
- **Propagation delay.** Policy/action changes take time to reach endpoints. Wait, then retest.

---

## 6. `New-DlpComplianceRule` fails on the removable-media restriction

**Symptoms:** `DLPUSB-Configure.ps1 -Commit` (or manual scripting) errors when setting the endpoint
restriction, e.g. an invalid Setting name or value.

**Fix**
- **Verify the exact Setting name and value for your tenant.** The removable-media endpoint-restriction
  Setting name and permitted values (`Audit` / `Warn` / `Block` / `Ignore`) **evolve**. Run
  `Get-Help New-DlpComplianceRule -Full` and check current Microsoft docs, then adjust the hashtable.
  The script deliberately **prints the planned Setting name** so you can verify before `-Commit`.
- **Prefer the portal for the first build** if PowerShell parameter names are uncertain, then read the
  result back with `DLPUSB-Discovery.ps1` to learn the exact shape in your tenant.

---

## 7. `-EndpointDlpLocation` / scope errors

**Symptoms:** Creating the policy errors on the location/scope value.

**Fix**
- The **Devices** location is scoped by user/group (or `All`). Confirm the pilot group
  (`SG-USB-Pilot`) exists and the identifier is one your tenant accepts. `DLPUSB-ScopeHealth.ps1`
  reports the group and the current scope.
- Avoid `All` during the pilot — scope to the pilot group first (gate **A4**).

---

## 8. The device-control policy won't deploy / doesn't reach devices

**Symptoms:** `DC-RemovableStorage-Pilot` shows as failed/not-applied in your management tool.

**Likely causes & fixes**
- **This is a management-tool issue, not a Purview one.** Device control is deployed via **Intune /
  GPO / OMA-URI** — troubleshoot in that console (assignment, targeting, sync, per-OS support). The
  provided scripts do **not** deploy or read the device-control policy.
- **OS / surface mismatch.** The removable-storage/device-control settings and their availability
  **differ by platform** and evolve — verify the exact surface for your tenant/OS.
- **Device not onboarded/managed.** The device must be managed by the tool pushing the policy; confirm
  enrollment/management state.

---

## 9. Activity report is empty or export fails

**Symptoms:** `DLPUSB-Report.ps1` returns no activity, or the Activity Explorer export warns and skips.

**Likely causes & fixes**
- **Licensing/permission.** `Export-ActivityExplorerData` is licensing-dependent; the script **warns
  and degrades to policy-modes only** rather than failing. Fall back to **Purview → Activity explorer**
  (filter to **Devices**) in the portal.
- **Quiet pilot window.** A small pilot may simply have no activity in the window — widen `-Days` or
  perform the sanctioned test actions from `05-testing.md` first.
- **Role.** Ensure the connected account holds a role that can read Activity Explorer.
- **Device-control audit lives elsewhere.** Device-control audit events are in your **management
  tool**, not Activity Explorer — check both.

---

## 10. "It blocked an admin / broke a workflow" — emergency rollback

**Do this immediately, then diagnose:**
- Return the DLP policy to **simulation** or **off**: `Set-DlpCompliancePolicy -Identity EDLP-USB-Pilot
  -Mode TestWithoutNotifications` (simulation) or `-Mode Disable` (off). Either **stops enforcement at
  once.**
- Set the device-control policy back to **audit** (or remove its assignment) in your management tool.
- Or add the affected device to `USBG-Corporate` if it should have been approved.
- Then work the relevant section above (usually §3 false positives or §5 scope), fix **in
  simulation/audit**, re-validate with `DLPUSB-Validate.ps1`, and only then re-enforce.

---

## When to escalate to the determination owners (not a technical fix)

Some questions are **not** troubleshooting — they are **determinations** that belong to compliance /
security / records / HR-legal (see `global-requirements-purview.md` §5):

- *Should* removable media be **blocked**, **read-only**, or only **audited**? → the **R8** decision
  owners.
- Is *this device* actually approved corporate media? → the **device/security owners**.
- Is a user's action a **violation**, and what is the consequence? → **HR / legal**.

Provide them the **evidence** (`DLPUSB-Report.ps1`, Activity explorer, device-control audit, the
validation output) — not a verdict.
