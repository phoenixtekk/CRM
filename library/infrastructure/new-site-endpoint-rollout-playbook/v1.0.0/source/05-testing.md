# 5. Testing Guide — New-Site Endpoint Rollout Playbook

Run these after the site's devices are provisioned (Implementation Step 7) and again before the
go-live gate (Step 8). The first site is the pilot; it must pass every gate before you expand.

## Test 1 — Network / identity reachable at the site
Do: From a device on the site network, run `NEWSITE-Discovery.ps1`.
Expected: Microsoft login and enrollment endpoints reachable; DNS resolves; time is in sync.

## Test 2 — Devices enrolled and in the site group
Do: Intune → **Devices → All devices**; filter to the site, and check Entra → **Groups →**
`New Site – Site A – Pilot` → **Members**.
Expected: Every site device appears, is managed by Intune, and is a member of the site group.

## Test 3 — Baseline applied and compliant
Do: Intune → **Devices → Compliance → Device compliance**, scoped to the site; and **Endpoint
security → Security baselines →** your baseline **→ Device status**.
Expected: All site devices show **Compliant** and the security baseline shows **Succeeded**.

## Test 4 — Site apps installed
Do: On a site device run `NEWSITE-Validation.ps1`; or Intune → **Apps → Monitor → App install
status** scoped to the site app.
Expected: Each app in the site app set is **Installed** on every site device.

## Test 5 — Site printers present and printing
Do: On a site device, confirm the site printers appear under **Settings → Bluetooth & devices →
Printers & scanners**, then print a test page.
Expected: The site's printers are present and a test page prints successfully.

## Test 6 — Per-device go-live validation
Do: Run `NEWSITE-Validation.ps1` on each site device.
Expected: Each device reports PASS for enrollment, compliance, apps, and printers.

## Test 7 — Site rollout status report
Do: Run `NEWSITE-Report.ps1`.
Expected: The site shows expected counts for devices provisioned, baselined, app-ready, and
validated — with no devices stuck in an earlier stage.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| Pilot pass | Tests 1–6 pass on every pilot-site device; a user can sign in, open apps, and print |
| Go-live | Test 7 shows full coverage and the Step 8 go-live checklist is fully ticked |
| Expand | Each subsequent site passes Tests 1–7 before it opens |
