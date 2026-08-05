# 3. Implementation Guide — Application Retirement, Offboarding & Decommissioning

Follow these steps **in order**. Nearly everything is in the **Microsoft Intune admin center**
(`https://intune.microsoft.com`) and the **Microsoft Entra admin center**
(`https://entra.microsoft.com`). *(US Gov: sign in at `https://portal.azure.us`; substitute the
sovereign endpoints from the Solution Overview table throughout.)*

> **Model:** Decide → analyse impact → communicate → protect data → uninstall Wave 0 (pilot) →
> validate → expand wave by wave → handle stragglers → clean up every artefact → reclaim licences →
> produce the evidence pack → monitor. **You cannot un-remove an app**, so no wave advances until the
> prior wave's gate passes, and the data checkpoint (Step 6) is a hard go/no-go.

## Named objects (create with these EXACT names and reuse them verbatim everywhere)

We use the `APPRET-<code> – <App> – <Purpose> – <Stage>` convention so every object created for one
retirement sorts and cleans up together. For the worked example (`LegacyTrack Client`, code
`APPRET-LGT`):

| Object | Name to create |
|---|---|
| Pilot wave group (Wave 0) | `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 0 Pilot` |
| Early wave group (Wave 1) | `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 1 Early` |
| Broad wave group (Wave 2) | `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 2 Broad` |
| Exemption / exclusion group | `APPRET-LGT – LegacyTrack Client – Retain – Exempt (expires 2026-09-30)` |
| Uninstall shim app (only if no app object exists) | `APPRET-LGT – LegacyTrack Client – Uninstall Shim` |
| Retirement notice (proactive remediation, optional) | `APPRET-LGT – LegacyTrack Client – Retirement Notice` |
| The decision record document | `APPRET-LGT – LegacyTrack Client – Decision Record` |

## Step 1 — Name the trigger and open the decision record
1. Identify which of the five triggers applies (EOL/EOS, security risk, redundancy, low utilisation,
   licence cost). Write it down — it sets urgency and approver.
2. Create the decision-record document `APPRET-LGT – LegacyTrack Client – Decision Record` (a
   controlled doc/wiki page — content, not an Intune object). It will collect: trigger, evidence,
   named owner, approver + sign-off date, replacement app (if any), data determination, planned wave
   dates, and the licence/renewal deadline. You fill it in as you go; it becomes the front page of the
   evidence pack.

## Step 2 — Capture the install base and usage evidence
1. Run `APPRET-Discovery.ps1 -AppName "LegacyTrack Client"`. It reports the app's Intune object,
   assignment intents and target groups, dependency/supersedence links, and the **per-device install
   list** (device name, primary user, last check-in). Save the CSV — it is your wave-planning source
   and evidence exhibit A.
2. Obtain the **usage** signal (Requirement 2.5) and attach it to the decision record. Install base
   (from Intune) and utilisation (from the vendor/SSO/telemetry) are two different numbers; the gap
   between them is your retirement justification.
3. **Gate 1 — Decision:** the owner and approver sign the decision record. Do not proceed without it.

## Step 3 — Run the impact analysis
1. Run `APPRET-ImpactAnalyzer.ps1 -AppName "LegacyTrack Client"`. It surfaces, from Graph:
   - devices/users that still have the app (who is affected),
   - **dependencies** — other Intune apps that declare this app as a dependency (removing it breaks
     them),
   - **supersedence chains** the app sits in (is it superseding, or superseded by, something?),
   - the **Entra groups** used to assign it, and their membership counts,
   - Win32 apps that share the same detection/requirement **script** (shared scripts are a cleanup
     hazard).
2. Review the report with the owner. Anything the app is a **dependency for** must be resolved first
   (re-point or retire the dependent app too) — otherwise the dependent app will try to reinstall
   `LegacyTrack Client` and fight your Uninstall intent.
3. Record the affected-user count and any dependency findings in the decision record.

## Step 4 — Build and communicate the plan and grace period
1. Decide the grace period from the trigger: security = short or none; EOL/redundancy/cost = a stated
   window (commonly 2–4 weeks) with a hard removal date tied to the vendor EOS or the licence renewal.
2. Draft the user communication: what is being removed, why, the replacement (if any), the removal
   date, what the user must do (save/export anything they need), and the support contact. Send it to
   the affected users identified in Step 3.
3. *(Optional but recommended)* Deploy the notice **on the device** as an Intune **proactive
   remediation** named `APPRET-LGT – LegacyTrack Client – Retirement Notice` (Intune → **Devices →
   Scripts and remediations → Remediations → Create**), scoped to the install-base group, that shows
   a toast/notification. This reaches users who ignore email. Keep it detection-only (no destructive
   action).
4. Record the comms date and grace-period end in the decision record.

## Step 5 — Create the wave groups (assigned) and the exclusion group
1. Entra → **Groups → New group** → **Group type: Security** → **Membership type: Assigned** → name
   `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 0 Pilot` → **Create**. Add 5–15 pilot devices
   (owners who agreed to be first) as members.
2. Repeat to create `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 1 Early` and
   `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 2 Broad`. Leave their membership empty for now;
   you will populate them from the install-base CSV as each wave opens.
3. Create the exclusion group `APPRET-LGT – LegacyTrack Client – Retain – Exempt (expires 2026-09-30)`
   → **Assigned** security group → add only devices with a **documented, dated** exemption. The expiry
   date is in the name so an audit sees when the exemption lapses.
4. *(Optional)* Use `APPRET-WaveReporter.ps1 -Action Plan` to split the install-base CSV into balanced
   wave membership lists (spread across departments and device types), then add members accordingly.

## Step 6 — Protect data (the irreversibility checkpoint)
1. Confirm the data determination from Requirement 2.7: does the uninstall destroy data you must keep?
2. If **yes**, complete the export **now**, before any uninstall assignment exists:
   - perform or script the export (vendor export tool, copy of the local database/config, licence-key
     capture), store it in your retention location, and
   - record the export location, date, and operator in the decision record.
3. Capture the licence/entitlement state now too (see Step 11) — some products deactivate the licence
   on uninstall, and you want the seat count *before* removal.
4. **Gate 2 — Data go/no-go:** the owner confirms in writing that either (a) the uninstall destroys
   nothing that must be kept, or (b) all required data has been exported and verified. **Do not create
   any Uninstall assignment until this gate passes.** This is the one-way door.

## Step 7 — Point the app's assignment at Wave 0 with the Uninstall intent
1. Intune → **Apps → All apps** → open `LegacyTrack Client` → **Properties → Assignments → Edit**.
2. **Remove the existing install assignment** that keeps the app on pilot devices. Under **Required**
   (and **Available for enrolled devices**), remove any group whose membership overlaps Wave 0.
   > **Critical:** the **Required** intent beats **Uninstall**. If a Wave 0 device is still in a group
   > assigned Required, it will **not** uninstall. Removing the old install assignment for those
   > devices is mandatory, not optional.
3. Under the **Uninstall** intent → **Add group** → select
   `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 0 Pilot`.
4. Under the **Uninstall** intent's **Excluded groups** (or as a global exclusion) → add
   `APPRET-LGT – LegacyTrack Client – Retain – Exempt (expires 2026-09-30)`.
5. **Review + Save.**

## Step 8 — (Replacement/migration retirements only) use supersedence instead
If retirement means migrating to a successor app, prefer supersedence over a bare Uninstall so no
device is ever left with neither app:
1. Open the **replacement** app (e.g. `LegacyTrack Cloud Agent`) → **Properties → Supersedence →
   Edit → Add**.
2. Select the retiring app `LegacyTrack Client` → set **Uninstall the previous version = Yes**.
3. **Review + Save.** As the replacement deploys to a wave, Intune removes `LegacyTrack Client` on the
   same device. You still drive the rollout wave by wave via the replacement app's assignment groups,
   and you still run the same validation gates.

## Step 9 — Validate Wave 0
1. On a pilot device, sync policy (**Settings → Accounts → Access work or school → Info → Sync**), or
   wait a check-in cycle.
2. Run `APPRET-WaveReporter.ps1 -AppName "LegacyTrack Client" -Action Status`. Confirm Wave 0 devices
   move to **Uninstalled / Not installed** and detection reports the app **absent**.
3. Complete the **Testing Guide** Wave-0 gates (uninstalled, detection absent, no collateral breakage,
   data preserved).
4. **Gate 3 — Pilot pass:** every reachable Wave 0 device is confirmed uninstalled and clean, with no
   dependency fallout. Investigate any device still showing installed (Step 12) before expanding.

## Step 10 — Expand wave by wave
1. Only after Gate 3 passes, populate `APPRET-LGT – LegacyTrack Client – Uninstall – Wave 1 Early`
   from the install-base CSV (~10%), then add it under the app's **Uninstall** intent (Step 7.3).
   **Save.**
2. Let it run a check-in cycle; re-run `APPRET-WaveReporter.ps1 -Action Status`; clear stragglers
   (Step 12). When Wave 1 meets the completion threshold, open **Wave 2 Broad** the same way.
3. Continue until every non-exempt device in the install base has been targeted and reported.
4. Track the **residual installed count** every cycle. "Done enough to proceed to cleanup" is a number
   you set in the decision record (e.g. ≥98% of reachable devices uninstalled, with all remaining
   devices accounted for as offline/decommissioned/exempt).

## Step 11 — Reclaim licences and record the cost recovery
1. With the fleet uninstalled, reclaim entitlements: in the **vendor/licence console** release or
   downgrade the freed seats; if the app was licence-server based, confirm the freed check-outs.
2. If the app was assigned via an **Entra enterprise application** (SSO/app licences), remove the app
   assignment/licences there too.
3. Record **seats before vs after**, the per-seat cost, and the annualised saving in the decision
   record. This is the number finance keeps.
4. **Cancel the renewal** before its date if the trigger was cost/EOL — capture the confirmation.

## Step 12 — Handle stragglers (campaign-level, not per-installer)
A "straggler" is a device that has not uninstalled. Classify each with
`APPRET-WaveReporter.ps1 -Action Stragglers`:
- **Never checked in / offline:** the IME never ran. Chase the device (is it retired? re-imaged?
  lost?). If genuinely decommissioned, move it to the exempt/decommissioned group and record it —
  do not let it hold the campaign open forever.
- **Checked in, still installed, Required somewhere:** an install assignment is still winning
  (Step 7.2). Find and remove it — `APPRET-ArtifactFinder.ps1` shows which group/assignment.
- **Checked in, uninstall reported Failed:** the installer itself errored (bad uninstall string,
  0x80070643, hung MSI). **This is where you escalate to deep Win32 uninstall failure remediation** —
  it is a per-device installer problem, not a campaign problem. Record the device and hand it to that
  discipline; do not block the wave on it.
Keep a live straggler list in the evidence pack with each device's class and disposition.

## Step 13 — Clean up every artefact
Now, and only now, remove what the app leaves behind. Use `APPRET-ArtifactFinder.ps1` as the
checklist:
1. **Uninstall assignments & the app object:** once the residual count is accepted, remove the
   Uninstall assignments, then Intune → app → **… → Delete** to delete the app object. *(Deleting
   earlier would have stopped you targeting or reporting on it — that is why it is last.)*
2. **Wave & exempt groups:** delete the `APPRET-LGT – … – Uninstall – Wave *` groups and the
   `Retain – Exempt` group once no longer referenced.
3. **Detection / requirement scripts:** remove scripts that only this app used (Intune → **Apps** →
   the app's rules were deleted with it; check **Devices → Scripts and remediations** for standalone
   scripts named for the app). Do **not** delete a script another live app shares (the ImpactAnalyzer
   flagged shared scripts).
4. **WDAC / App Control for Business rules:** remove allow/deny rules that named the retired app's
   binaries or publisher. Orphaned app-control rules are a real hazard — a stale allow rule widens
   your attack surface; a stale deny rule blocks a future app with the same name.
5. **Conditional Access references:** Entra → **Protection → Conditional Access** → find any policy
   that targeted the app's **enterprise application**; remove the app from it or retire the policy.
   Then remove the **enterprise application / app registration** if nothing else uses it.
6. **SCCM / Configuration Manager remnants:** if the app was co-managed, retire its ConfigMgr
   application/deployment and collections so it cannot redeploy. *(Vendor-console specifics — verify in
   your ConfigMgr documentation.)*
7. **The Uninstall Shim app** (if you created one in Requirement 2.3): delete it once the fleet is
   clean.
8. Tick each removed artefact in the decision record.

## Step 14 — Produce the decommission evidence pack
1. Run `APPRET-EvidenceExport.ps1 -AppName "LegacyTrack Client" -OutFolder .\APPRET-LGT-Evidence`.
   It compiles: the final install/uninstall status, the residual-device list with dispositions, the
   artefact-cleanup confirmation (app object gone, groups gone, no CA/app-control references remain),
   the data-export record reference, and the licence-reclamation numbers.
2. Attach the decision record (Step 1) as the front page. This pack is **proof of decommission** —
   the answer to "is `LegacyTrack Client` genuinely gone?"

## Step 15 — Post-retirement monitoring
1. For a defined window (commonly **30–60 days**), re-run `APPRET-WaveReporter.ps1 -Action Status`
   and `APPRET-ArtifactFinder.ps1` weekly to catch **reappearance**: an offline device that came back
   and re-checked-in still installed, a re-imaged machine that got the app from an old task sequence,
   or a user who reinstalled it manually.
2. Any reappearance → add the device to the next Uninstall wave, or find and kill the source (a
   lingering SCCM deployment, an old image, a Required assignment you missed).
3. When two consecutive weekly checks show zero installed and zero artefacts, close the campaign.

---
### Order of operations
`Name trigger + open decision record → Discovery (install base + usage) → Impact analysis →
Comms + grace period → Wave groups + exclusion → PROTECT DATA (gate) → Uninstall→Wave 0 (or
supersedence) → Validate (gate) → Expand waves → Reclaim licences → Stragglers → Artefact cleanup →
Evidence pack → Monitor.`
