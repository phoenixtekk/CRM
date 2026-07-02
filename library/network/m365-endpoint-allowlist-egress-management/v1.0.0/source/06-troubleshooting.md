# Troubleshooting Guide

Egress-filtering failures share a signature: the device behaves as if a Microsoft service is
"missing," with no firewall error shown on the device. The diagnostic method is always the same —
**map the symptom to the Microsoft service it needs, then map that service to the required endpoint,
then prove reachability of that endpoint** with `EGRESS-Validation.ps1`. This guide gives that map.

## Diagnostic method (use for every symptom)

1. **Reproduce behind the filter.** Confirm the affected device reaches the internet only through the
   proxy/firewall under management (not a secondary path). A failure that disappears off the filter
   confirms an allow-list gap.
2. **Run reachability.** From the affected device run `EGRESS-Validation.ps1` against
   `egress-required-set.json`. The FAIL rows name the exact host+port that is blocked.
3. **Confirm coverage.** Run `EGRESS-Report.ps1`; the GAP rows are the required endpoints to add.
4. **Add and re-validate.** Add the missing entry to `M365-Required-Endpoints` (regenerate the
   proposal with `EGRESS-Remediation.ps1` if helpful), then re-run validation until zero gaps.
5. **Re-test the workflow** (Testing Guide gates T4–T7).

If reachability passes for everything but a workflow still fails, suspect **SSL inspection** (a
certificate-pinned endpoint being decrypted instead of bypassed) or the **wrong instance** in the
required set.

---

## Symptom: Enrollment or Autopilot stalls / errors

**What it looks like:** A new device sits at a provisioning/enrollment screen, times out, or errors
during Autopilot; the device may register in Entra but never reach Intune, or never register at all.

**Which service/endpoint is likely missing:**
- **Entra device registration / identity** — the common/identity service area from the M365 web
  service and the device-registration host (`enterpriseregistration.windows.net`). If identity is
  blocked, nothing downstream works.
- **Intune enrollment / management** — the Intune management host (`*.manage.microsoft.com`).
- **Autopilot deployment service** — the Autopilot dependency hosts, plus (because Autopilot rides on
  them) Entra + Intune + Windows content endpoints.

**Fix:** Validate those hosts on 443; add any FAIL to the allow-list; if the proxy inspects SSL, add
the identity/enrollment hosts to the decryption-bypass list. Re-run enrollment (Gate T4).

---

## Symptom: Device shows enrolled but policies never sync / stay "pending"

**What it looks like:** Intune lists the device as enrolled, but configuration/compliance/app policies
never apply; sync appears to run but nothing lands, or check-in status is stuck pending.

**Which service/endpoint is likely missing:**
- **Intune device-management check-in** (`*.manage.microsoft.com`) on 443 — this is the sync channel.
- **The M365 common/identity area** — tokens for the sync are obtained via identity; if identity is
  intermittently blocked, sync silently fails.

**Fix:** Validate `*.manage.microsoft.com` and the common/identity endpoints; add any gap; re-run a
forced sync (Gate T5). If sync only fails from one site, the gap is site-specific — validate from a
device at that site.

---

## Symptom: Windows Update or app install fails / hangs

**What it looks like:** Update detection or download stalls, apps fail to install with content-download
errors, or delivery never completes — despite enrollment and sync working.

**Which service/endpoint is likely missing:**
- **Windows Update / content-delivery endpoints** (`*.update.microsoft.com`,
  `*.delivery.mp.microsoft.com`, `*.windowsupdate.com`) on 443 and 80. Content endpoints commonly need
  **port 80** in addition to 443 — a 443-only allow-list is a frequent cause of this exact symptom.

**Fix:** Validate the update/content hosts on **both** 443 and 80; add the missing port entries
(`M365-Required-Endpoints` must include 80 for these); re-run an update check and app install
(Gate T6).

---

## Symptom: Defender cloud protection disconnected

**What it looks like:** Defender reports cloud-delivered protection off/unreachable, or sample
submission fails, while other services work.

**Which service/endpoint is likely missing:**
- **Defender cloud endpoints** (`*.wd.microsoft.com`, `*.wdcp.microsoft.com`,
  `*.endpoint.security.microsoft.com`, and related) on 443.

**Fix:** Validate the Defender hosts; add gaps; confirm decryption bypass for any pinned Defender
endpoint; re-check cloud protection (Gate T7).

---

## Symptom: Everything intermittently breaks after "no change on our side"

**What it looks like:** Services that worked start failing across the board without a local change.

**Likely cause:** **Microsoft changed the published endpoints** and the allow-list drifted out of
date, or the required set was built from the **wrong instance**.

**Fix:**
- Run the drift check: `EGRESS-Discovery.ps1 -BaselineVersionPath ...`. If it reports **changed**,
  generate the delta with `EGRESS-Remediation.ps1 -BaselineRequiredSetPath ...`, apply the additions,
  and re-validate.
- Confirm `-Instance` matches your tenant (Worldwide vs a sovereign cloud). A wrong instance yields
  addresses your tenant never uses and omits the ones it does.

---

## Symptom: Validation passes but a workflow still fails

**Likely cause:** **SSL/TLS inspection** decrypting a certificate-pinned endpoint (the TCP connect
succeeds, so validation passes, but the pinned handshake fails inside the app), or an endpoint allowed
by IP but requested by a URL the proxy categorizes elsewhere.

**Fix:** Add the affected endpoints to the proxy's **decryption-bypass** list (not just the
allow-list); ensure URL-based allow entries exist for URL-filtering proxies, not only IP entries.
Re-run the workflow gate.

---

## Script-level issues

| Problem | Cause | Fix |
|---|---|---|
| `EGRESS-Discovery.ps1` cannot reach the web service | The management host's own egress blocks the endpoints web service | Allow the web-service host from the admin subnet (R2); the management host is itself part of the required set. |
| Wrong addresses in the required set | Wrong `-Instance` | Re-run with the instance matching your tenant. |
| `EGRESS-Validation.ps1` all-FAIL from an admin box | Tested off the filtered path | Run it **on a device behind the same proxy/firewall** as the fleet. |
| `EGRESS-Set-ScopeTargeting.ps1` cannot create the group | Not connected to Graph, or missing rights | Install Microsoft.Graph, `Connect-MgGraph` with the listed scopes, ensure a group-management admin role (R5). |
| Remediation "changed nothing on the device" | By design | The script only writes a proposal file; import it into the proxy/firewall per the vendor's documentation. |
