# Testing & Validation — Windows Autopilot (Government / GCC High)

This is the **Validate** gate. Every test has an explicit **pass/fail** condition. Do not
**Expand** to more groups until all gates pass. Read-only scripts (`WAPG-Validation.ps1`,
`WAPG-Discovery.ps1`, `WAPG-Report.ps1`) automate much of this against **US Gov Graph**
(`-Environment USGov`).

> **GCC High reminder:** All portal checks use the `*.us` admin centers
> (`https://intune.microsoft.us`, `https://entra.microsoft.us` *(verify for GCC High)*).

---

## T1 — Configuration objects exist and are correct (pre-pilot)

**Run:** `WAPG-Validation.ps1` (read-only).

| Check | Pass |
| --- | --- |
| Groups `WAPG-Provisioning-Users`, `WAPG-Pilot`, `WAPG-Autopilot-Devices` exist | All three present |
| `WAPG-Autopilot-Devices` is **Assigned** (not Dynamic) | membershipType = Assigned |
| **Intune Provisioning Client** (`f1346770-…`) is an **owner** of `WAPG-Autopilot-Devices` | Owner present |
| Device preparation profile `WAPG-DevicePrep-UserDriven-EntraJoin` exists, **User-driven**, **Entra join** | Confirmed |
| ESP `WAPG-ESP-Provisioning` assigned to `WAPG-Pilot` | Assigned |
| Update ring `WAPG-UpdateRing-Pilot` + compliance `WAPG-Compliance-Win11` assigned | Assigned |

**Fail →** fix the missing/incorrect object in `03-implementation.md` before piloting. The
owner check is the highest-value gate.

## T2 — Tenant is genuinely GCC High (not Commercial)

**Check:** Signed into `https://intune.microsoft.us` you can see the **Windows Autopilot
device preparation** tile, and you do **not** see a classic "Windows Autopilot" / "Deployment
Profiles" import. `WAPG-Discovery.ps1` reports the connected Graph environment as **USGov**.
**Pass:** Graph environment = USGov; device-preparation tile present.
**Fail:** If you see classic Autopilot blades or Graph reports Global/Commercial, you are on
the wrong tenant/cloud — stop and re-confirm R1.

## T3 — Endpoint reachability from the provisioning network

**Check:** From the network a pilot device will use, resolve and reach:
`login.microsoftonline.us`, `portal.manage.microsoft.us`, `graph.microsoft.us`,
`enterpriseregistration.microsoftonline.us`, `login.live.com`, and NTP `time.windows.com`
(UDP 123). Confirm **no SSL inspection** on `*.manage.microsoft.us`.
**Pass:** All resolve and connect; `*.manage.microsoft.us` is inspection-exempt.
**Fail:** Any blocked/inspected → fix per R9 before piloting.

## T4 — End-to-end pilot provisioning (the core test)

**Run:** provision one factory-fresh/reset supported Windows 11 device with a pilot user (per
`03-implementation.md` Phase B).

| Gate | Pass |
| --- | --- |
| Device Entra-joins during OOBE | Joined (visible later in Entra → Devices) |
| Device auto-enrolls into Intune | Appears in Intune → Devices → All devices |
| Device is added to `WAPG-Autopilot-Devices` at enrollment | Member appears automatically |
| ESP `WAPG-ESP-Provisioning` shows progress percentage | Percentage UI shown |
| Selected OOBE apps/scripts install | Status = installed/succeeded |
| User reaches desktop without technician touch | Zero-touch achieved |
| Device shows **compliant** against `WAPG-Compliance-Win11` | Compliant (allow grace period) |

**Fail on empty group / no installs →** Intune Provisioning Client owner missing
(`06-troubleshooting.md`, symptom #1).

## T5 — Deployment monitoring reflects the run

**Check:** `https://intune.microsoft.us` → **Devices → Windows → Enrollment → Windows
Autopilot device preparation → Monitor** (deployment report). The pilot device appears with
profile name/version, deployment status, per-app and per-script status. `WAPG-Report.ps1`
produces the same summary from US Gov Graph.
**Pass:** The device and its app/script statuses are visible.
**Fail:** No record → device likely never matched the profile (user not in
`WAPG-Provisioning-Users`, or device pre-registered as classic Autopilot — which takes
precedence).

## T6 — Servicing and policy land (post-provisioning)

**Check:** After provisioning, `WAPG-UpdateRing-Pilot` and any post-OOBE apps assigned to
`WAPG-Autopilot-Devices` apply within a normal sync window.
**Pass:** Update ring shows assigned/applied; post-OOBE apps install.
**Fail:** Confirm assignments target the device group and the device is a member.

> **GCC High reminder:** Do not test for Autopatch/feature-update-policy behavior — those are
> **not available in GCC High**. Servicing is validated only via the **update ring**.

---

## Validate gate (pass/fail summary)

Proceed to **Expand** only when **all** are TRUE:

- [ ] T1 — All objects correct; **Intune Provisioning Client owns the device group.**
- [ ] T2 — Confirmed **GCC High** (Graph USGov; device-preparation tile present).
- [ ] T3 — Sovereign endpoints reachable; **no SSL inspection** on `*.manage.microsoft.us`.
- [ ] T4 — One device provisioned **zero-touch** end to end and is compliant.
- [ ] T5 — Deployment **monitoring** shows the device with app/script status.
- [ ] T6 — Update ring + post-OOBE policy/apps applied.

Then run `WAPG-Set-ScopeTargeting.ps1` (default **`-WhatIf`**) to preview widening scope,
review, and re-run with `-WhatIf:$false` to apply.

## Sources

- Microsoft, *Windows Autopilot device preparation — overview, requirements, reporting and
  monitoring.*
- Microsoft, *Intune Government Service overview* (GCC High feature availability).
- Microsoft, *Network endpoints for US government deployments.*
