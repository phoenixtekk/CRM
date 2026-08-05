# 6. Troubleshooting — Application Retirement (campaign-level)

This section covers **campaign-level** problems — the removal not progressing across the fleet as a
whole. For a **single device whose uninstall genuinely errors at the installer level** (a bad
uninstall string, `0x80070643`, a hung MSI, a corrupt product cache), that is deep Win32 uninstall
failure remediation: record the device with `APPRET-WaveReporter.ps1 -Action Stragglers`, hand it to
that discipline, and keep the wave moving. Do not stall the campaign on one machine.

Worked example throughout: `LegacyTrack Client`, code `APPRET-LGT`.

## "I assigned Uninstall but nothing is being removed"
**Most common cause — Required beats Uninstall.** A device still in a group assigned **Required**
(or **Available** and installed) will not uninstall while that assignment exists.
- Run `APPRET-Discovery.ps1 -AppName "LegacyTrack Client"` and read every assignment intent.
- Remove the old **Required/Available** assignment for the devices you are retiring (Implementation
  Step 7.2). Adding an Uninstall on top is not enough.
- `APPRET-ArtifactFinder.ps1` shows which group still carries the winning intent.

**Second cause — the device hasn't checked in.** The Uninstall only runs when the IME evaluates the
app on check-in. Force a sync (**Settings → Accounts → Access work or school → Info → Sync**) or wait
a cycle. See "partial fleet removal" below.

**Third cause — wrong target.** Confirm the Wave 0 group actually contains the pilot devices (device
objects, not user objects, for a device-targeted app), and that those devices are members *now*
(group membership changes also take a sync to apply).

## "Some devices removed it, most didn't" (partial fleet removal)
This is normal and expected — completion is bounded by check-in.
- Run `APPRET-WaveReporter.ps1 -Action Status` to see the split, then `-Action Stragglers` to
  classify the remainder.
- **Offline / never checked in:** the IME never ran. Chase the device — is it powered off, off the
  network, re-imaged, or decommissioned? Genuinely dead devices go to the decommissioned/exempt group
  and are recorded; they must not hold the campaign open.
- **Checked in but still installed:** almost always a winning Required assignment (see above).
- Set a **completion threshold on reachable devices** in the decision record; don't chase 100% of a
  fleet that includes dead hardware.

## "The app uninstalled, then came back"
Something is re-deploying it.
- **A dependent app:** another Intune app declares `LegacyTrack Client` as a dependency with
  auto-install, so it reinstalls after removal. `APPRET-ImpactAnalyzer.ps1` section [1] lists
  dependents — resolve them first (re-point or retire the dependent app).
- **A lingering SCCM/ConfigMgr deployment:** if the app was co-managed, a ConfigMgr deployment can
  reinstall it. Retire that deployment (Implementation Step 13.6).
- **An old image / task sequence:** a re-imaged device gets the app from a stale build. Update the
  image or add the device to the next Uninstall wave.
- **A user reinstalled it manually:** remove the installer's availability (Company Portal
  "Available" assignment) and communicate.

## "Detection still shows it installed after a successful uninstall"
- The **detection rule is wrong** — it is matching something the uninstall didn't remove (a leftover
  folder, a registry key the uninstaller leaves). Verify the rule (Requirement 2.4) points at a value
  that truly disappears on uninstall (MSI product code is the most reliable).
- Or the device simply hasn't re-reported yet; force a sync and re-check next cycle.

## "Deleting the app object didn't uninstall it"
Correct — it never will. Deleting the app object only stops Intune managing and reporting it; the
software stays on every device, now invisible to you. If you deleted it too early, **recreate the app
object** (or an uninstall shim, Requirement 2.3) so you can target and report on removal again, then
delete it as the final step.

## "The Uninstall shim I created isn't detecting the existing install"
The shim's **detection rule** must match the *already-installed* software, not the placeholder you
packaged. Point the detection rule at the real app's MSI product code / file+version / registry key
so Intune sees the app as present (then absent after the shim's uninstall command runs).

## "Supersedence isn't removing the old app"
- Confirm **Uninstall the previous version = Yes** on the *replacement* app's Supersedence tab
  (Implementation Step 8), and that the replacement is actually deploying to the device (supersedence
  acts as the replacement installs).
- Supersedence changes can take **up to a day** plus a couple of check-ins to fully evaluate. Give it
  time before assuming failure.
- Deeply nested supersedence chains (A supersedes B supersedes C) evaluate one hop at a time — don't
  skip levels.

## "The reports don't match what's on the devices" (reporting gaps)
- Intune app install reports lag device reality by a check-in cycle (and up to several hours for the
  aggregated install summary). Use `deviceStatuses` (per device, which the scripts read) rather than
  the summary tile for the freshest picture, and allow a cycle before trusting counts.
- A device that is uninstalled but hasn't checked in still shows its **last** state. This is why the
  evidence pack (`APPRET-EvidenceExport.ps1`) lists residuals *with last check-in* — a "residual"
  that hasn't synced in 40 days is an offline device, not a failed uninstall.

## Script / access problems
- **`Connect-MgGraph` fails or scopes are denied:** a Global Administrator must grant admin consent
  for the read scopes in Requirement 2.2. Re-run after consent.
- **US Gov tenant returns 401/empty:** you connected to the wrong cloud. Add `-Environment USGov`
  (GCC High) or `-Environment USGovDoD` (DoD) so the scripts hit `graph.microsoft.us` /
  `dod-graph.microsoft.us`. If a specific object type still returns nothing, **verify for GCC High**
  that the feature is available in your sovereign tenant.
- **`APPRET-ArtifactFinder.ps1` can't read CA policies:** it needs `Policy.Read.All`; enterprise-app
  and CA sections are skipped without it — grant the scope or review those artefacts manually.
- **Group member `$count` shows `?`:** the `ConsistencyLevel: eventual` header/advanced-query wasn't
  honored (older tenant/SDK). The count is informational; membership is still correct.
