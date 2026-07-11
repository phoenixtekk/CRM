# Troubleshooting — Workshop: Microsoft Defender for Endpoint

The common failure modes, each as **symptom → cause → fix**. Most workshop issues are onboarding /
plan gaps, table freshness, or a feature that needs enabling — not a broken platform.

---

## 1. No devices listed / endpoint tables empty

- **Symptom:** **Assets → Devices** is empty, or hunting tables return 0 rows.
- **Cause:** No devices onboarded, sensors unhealthy, or ingestion hasn’t caught up.
- **Fix:** Onboard devices (the **MDE onboarding accelerator** solution) and confirm health; allow
  ingestion time; check with `WSMDE-Discovery.ps1`. Run available labs on whatever data exists (**R1**).

## 2. Advanced hunting / Live Response / custom detections are missing

- **Symptom:** One of these blades is absent or greyed out.
- **Cause:** The tenant/user is on **Defender for Endpoint Plan 1** (these are P2 features), the
  feature isn’t enabled, or the role is insufficient.
- **Fix:** Confirm **Plan 2** (R2); enable **Live Response** under **Settings → Endpoints → Advanced
  features**; confirm the role (R4). *Verify current plan-to-feature mapping in your tenant.*

## 3. "Unknown table/column" in a hunting query

- **Symptom:** A Lab 4/5 query fails to resolve a table or column (e.g. `DeviceProcessEvents`,
  `RemoteIPType`).
- **Cause:** **Schema drift** — the pack uses representative names that evolve and can differ by cloud.
- **Fix:** Open **Advanced hunting → schema** and correct the name to your tenant’s current schema.
  *Verify current schema.*

## 4. ASR audit events don’t appear

- **Symptom:** The Lab 5 hunt over `DeviceEvents` returns no ASR audit entries.
- **Cause:** The rule isn’t in **audit**, it’s scoped to the wrong devices, nothing has triggered it
  yet, or the rule GUID differs.
- **Fix:** Confirm `ASR-Lab-AuditOnly-Pilot` is **audit** on `Grp-MDE-LabDevices-Pilot`; generate a
  benign triggering action on a lab device; verify the current ASR rule GUIDs. *Verify ASR rules for
  your tenant.*

## 5. An ASR rule is blocking legitimate software

- **Symptom:** A lab device can’t run an expected app after an ASR change.
- **Cause:** A rule was set to **block** instead of **audit** during the lab.
- **Fix:** Set the rule back to **audit** (the workshop never blocks — R5); if a real enforcement is
  needed later, add a **specific** exclusion and roll out by ring as an operations decision.

## 6. Live Response won’t connect to the lab device

- **Symptom:** The Live Response session fails to start.
- **Cause:** Live Response not enabled in Advanced features, the device is offline/unhealthy, or the
  account lacks the Live Response permission.
- **Fix:** Enable **Live Response** (Settings → Endpoints → Advanced features); confirm the device is
  online and healthy; grant the instructor the Live Response role (R4). Use only read-only commands
  (R5).

## 7. A learner ran a change command in Live Response

- **Symptom:** A `run` / `remediate` / `putfile` appears in the transcript.
- **Cause:** The read-only posture wasn’t enforced.
- **Fix:** Reaffirm the posture (R5); restrict Live Response to the instructor; change commands are
  out of scope for the workshop and belong to real incident response under approvals.

## 8. "Create detection rule" is greyed out

- **Symptom:** In Lab 8 you cannot create the custom detection.
- **Cause:** The account lacks the authoring role, or the query doesn’t project the required entity
  columns.
- **Fix:** Have the **instructor** author `Detect-MDELab-Pilot`; ensure the query projects
  `DeviceId`/`DeviceName`/`AccountName` so the rule can map entities. Keep it **alert-only**.

## 9. The custom detection is noisy

- **Symptom:** `Detect-MDELab-Pilot` floods with alerts.
- **Cause:** The underlying hunt wasn’t tuned to a small, explainable result before promotion.
- **Fix:** Disable it, tighten the Lab 4 query (more selective filters / thresholds), then recreate the
  alert-only rule. Never promote a noisy hunt.

## 10. Graph connection or permission errors

- **Symptom:** `Connect-MgGraph` fails, or a call returns 403.
- **Cause:** Missing modules, wrong cloud endpoint, unconsented scopes, or insufficient role.
- **Fix:** `Install-Module Microsoft.Graph`; connect with the correct `-Environment` for Government
  cloud; consent the read/hunt scopes in each script header; confirm the account holds a read/hunt
  role (R4). *Verify the correct endpoints for your cloud.*
