# Troubleshooting — Egress Filtering for M365/Intune Endpoints (Government / GCC High)

GCC High–specific symptoms, root causes, and fixes. The most common root cause by far is **querying or
allow-listing the wrong cloud** (`Worldwide`/`.com` instead of `USGovGCCHigh`/`.us`). Work top-down;
each entry gives **Symptom → Likely cause → Fix**.

---

## A. Wrong cloud / wrong instance

**Symptom:** Discovery output shows `.com` M365 endpoints (`outlook.office.com`, `*.manage.microsoft.com`),
or sign-in redirects to `login.microsoftonline.com`.
**Likely cause:** You queried the **`Worldwide`** instance, or the egress device allows Commercial
FQDNs instead of Gov.
**Fix:** Re-run against **`USGOVGCCHigh`**:
`https://endpoints.office.com/version/USGOVGCCHigh?clientrequestid=your-guid` — confirm the returned
`instance` is `USGOVGCCHigh`. Rebuild `EGRESSG-M365-GCCHigh-Allow` / `EGRESSG-M365-GCCHigh-URLs` from
the corrected export. In GCC High, identity is `login.microsoftonline.us` — allow the `.us` name.

**Symptom:** Portals load at `.com` and everything "looks normal," but Gov services misbehave.
**Likely cause:** You may not actually be on a GCC High tenant.
**Fix:** Confirm tenant type (R1): sign in at `portal.office365.us` / `intune.microsoft.us`. If you can
only sign in at `.com`, you are not on GCC High — do not apply this solution.

---

## B. Sign-in / authentication fails behind the proxy

**Symptom:** Users cannot authenticate; token or portal errors.
**Likely cause:** `login.microsoftonline.us`, `*.auth.microsoft.us`, or `*.gov.us.microsoftonline.com`
is blocked, or the Commercial `login.microsoftonline.com` was allowed instead.
**Fix:** Allow the Gov identity FQDNs (R8) on TCP 443. Confirm with
`EGRESSG-Validation.ps1` (Identity row must PASS).

---

## C. Intune enrollment / check-in stalls

**Symptom:** Devices don't enroll, Company Portal won't check in, or software updates fail to download.
**Likely cause 1:** `*.manage.microsoft.us` is **being SSL-inspected** (not supported).
**Fix:** Add `*.manage.microsoft.us` and `has.spserv.microsoft.com` to `EGRESSG-NoInspect-GCCHigh` and
exclude them from inspection.
**Likely cause 2:** Proxy requires **authentication** to `manage.microsoft.us`.
**Fix:** Some Intune tasks require **unauthenticated** proxy access to `manage.microsoft.us` — allow it
unauthenticated.
**Likely cause 3:** `enterpriseregistration.microsoftonline.us` blocked.
**Fix:** Allow it on TCP 443.

---

## D. Defender for Endpoint / EPM devices never onboard

**Symptom:** Devices don't appear in `security.microsoft.us`, or EPM elevation rules never apply.
**Likely cause:** `*.dm.microsoft.us` is blocked or **SSL-inspected** (inspection not supported).
**Fix:** Allow `*.dm.microsoft.us` and add it to `EGRESSG-NoInspect-GCCHigh`. Confirm the Defender/EPM
row in `EGRESSG-Validation.ps1` is PASS. If onboarding still fails, **verify for GCC High** whether
your OS versions require the standard vs streamlined Gov connectivity URL set.

---

## E. Teams calls drop or have no audio/video

**Symptom:** Teams connects to chat but calls fail or media is one-way.
**Likely cause:** Teams media UDP ports (**3478–3481**) or `*.gov.teams.microsoft.us` are blocked.
**Fix:** Allow UDP 3478–3481 to the derived Teams IP ranges and `*.gov.teams.microsoft.us` on 443.
Remember GCC High Teams media routes only through **USGov Arizona / USGov Texas** datacenters.

---

## F. Exchange / SharePoint access issues

**Symptom:** Outlook or SharePoint/OneDrive fails behind the proxy.
**Likely cause:** Gov FQDNs blocked — Exchange is `outlook.office365.us` (not `outlook.office.com`);
SharePoint is `*.sharepoint.us` (not `*.sharepoint.com`).
**Fix:** Allow the Gov FQDNs and their derived IP ranges/ports (Exchange mail ports 25/143/587/993/995
where used).

---

## G. Web service returns HTTP 429 (Too Many Requests)

**Symptom:** Discovery/Validation fails with 429 from `endpoints.office.com`.
**Likely cause:** The endpoints/changes web methods are rate-limited per client IP.
**Fix:** Wait 1 hour, or generate a new ClientRequestId GUID. As designed, the scripts only call the
**endpoints** method when the **version** method shows a new version — don't disable that check, and
don't run more than once an hour.

---

## H. Allow-list keeps going stale (periodic outages after month-start)

**Symptom:** Connectivity breaks around the start of a month.
**Likely cause:** Microsoft updated the GCC High set and your allow-list wasn't refreshed within the
30-day advance window; or someone hardcoded IPs.
**Fix:** Schedule `EGRESSG-Discovery.ps1` (weekly), review the emitted diff, and apply additions before
their effective date. Convert any hardcoded ranges to machine-maintained objects fed from the export.

---

## I. Graph script fails to connect

**Symptom:** `EGRESSG-Set-ScopeTargeting.ps1` cannot connect or targets the wrong tenant.
**Likely cause:** Graph defaulted to the **Commercial** environment.
**Fix:** Connect with **`Connect-MgGraph -Environment USGov`**. Confirm `graph.microsoft.us` is
reachable and allowed on the script host.

---

## J. SSL-inspected endpoint breaks after enabling inspection

**Symptom:** Everything worked until SSL inspection was turned on near M365 traffic; now Intune/Defender
break.
**Likely cause:** A no-inspect endpoint (`*.manage.microsoft.us`, `has.spserv.microsoft.com`,
`*.dm.microsoft.us`) is being inspected.
**Fix:** Ensure `EGRESSG-NoInspect-GCCHigh` is applied **and excluded from inspection**, then re-test.
Microsoft does not support inspecting these endpoints.

---

## Escalation checklist (before opening a ticket)

1. Confirm the instance is **`USGovGCCHigh`** (not `Worldwide`).
2. Confirm portals are `.us` and identity is `login.microsoftonline.us`.
3. Confirm `EGRESSG-NoInspect-GCCHigh` is applied and excluded from inspection.
4. Run `EGRESSG-Validation.ps1` from a real pilot endpoint and capture the PASS/FAIL table.
5. Run `EGRESSG-Discovery.ps1` and confirm "up to date" (or apply the diff).
6. If a capability's Gov behavior is unclear, treat it as **"verify for GCC High"** and check current
   Microsoft Gov documentation (see `gcc-high-parity-notes.md`) before escalating.
