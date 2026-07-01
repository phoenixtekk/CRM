# 5. Testing Guide — Endpoint Privilege Management (EPM)

Run these validations after the pilot is deployed (Implementation Steps 8–11) and again after each
production wave. Each test states **what to do** and the **expected result**. Do not expand the
rollout until every test passes for the pilot group.

## Test 1 — The EPM client installed
**Do:** On a pilot device run **`EPM-Discovery.ps1`**, or check `Get-Service EPMAgent` and the folder
`C:\Program Files\Microsoft EPM Agent\`.
**Expected:** The **Microsoft EPM Agent** service is present and **Running**; the agent folder exists.

## Test 2 — The base policy applied
**Do:** Intune admin center → **Endpoint security → Endpoint Privilege Management → `EPM - Base - Pilot` → Device/User check-in status.**
**Expected:** Pilot devices/users show **Succeeded**. No **Error** or **Conflict**.

## Test 3 — An approved app elevates with the correct type
**Do:** As a **standard user** on a pilot device, right-click an approved application → **Run with elevated access**.
**Expected:** The **User confirmed** prompt appears (justification/authentication if configured); after confirming, the app runs **elevated**.

## Test 4 — A non-approved app does NOT elevate
**Do:** As a standard user, attempt **Run with elevated access** on an application that has **no** rule.
**Expected:** It is **denied** (no elevation), falling back to the standard Windows UAC admin-credential prompt the user cannot satisfy. The default response is **Deny all**.

## Test 5 — User-confirmed justification is captured
**Do:** Perform an approved elevation that requires a business justification; enter text.
**Expected:** The elevation proceeds and the justification is recorded in the EPM report (Test 7).

## Test 6 — Support-approved flow (if used)
**Do:** Trigger an elevation for an app configured as **Support approved**; approve it in Intune → **Endpoint Privilege Management** → the elevation request.
**Expected:** The request appears for approval; after admin approval the user can elevate; before approval it is blocked.

## Test 7 — Tenant-wide elevation reporting
**Do:** Run **`EPM-ElevationReport.ps1`** (Microsoft Graph), and review **Endpoint security → Endpoint Privilege Management → Reports**.
**Expected:** Pilot elevations appear (managed elevations, plus unmanaged/denied attempts) with user, file, and elevation type.

## Test 8 — Standard-user posture (after Step 10)
**Do:** On a pilot device after local-admin removal, run `net localgroup administrators`.
**Expected:** Pilot users are **no longer** members; day-to-day work continues, and only rule-approved apps elevate.

## Test 9 — Compliance remains intact
**Do:** Intune → **Devices → Compliance**; review pilot devices after EPM deployment.
**Expected:** Devices remain **Compliant**; no new compliance failures were introduced.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–5, 7, 9 pass for **100%** of the pilot group (Test 6 if support-approved is used; Test 8 after local-admin removal) |
| **Wave pass** | Tests 1–4, 7, 9 pass for the wave before starting the next |

Record results in your change log. If any test fails, use the **Troubleshooting Guide** (Section 6)
and the **`EPM-Remediation.ps1`** script before proceeding.
