# 6. Troubleshooting — BeyondCorp Enterprise: Zero-Trust Access

Common failure modes and resolutions. Symptoms reference the named artifacts (`IAP App – Pilot`,
`IAP VM – Pilot`, `Pilot Group – ZeroTrust`, `Access Level – Corp-Managed – v1`) and the gates from
Implementation and Testing. Where a fix depends on a version- or preview-dependent surface, it is
flagged **verify** — confirm the current path in your organization.

---

## Access levels won't create / "no access policy"
- **Symptom:** `gcloud access-context-manager levels create ...` fails, or `policies list` returns
  nothing.
- **Cause:** The Access Context Manager API is not enabled, or no organization-scoped access policy
  exists (requirement 2.1).
- **Resolution:** Enable the API (`gcloud services enable accesscontextmanager.googleapis.com`) and
  confirm/create the org access policy. Only **one scoped access policy** applies to the whole
  organization — if one already exists (often from the Landing Zone or VPC-SC solution), reuse its
  policy ID rather than creating a second.

## IAP page won't enable for the web app / OAuth consent error
- **Symptom:** Turning on IAP for the backend service errors, or users hit an OAuth consent problem.
- **Cause:** `iap.googleapis.com` not enabled, or the project's OAuth brand/consent screen isn't
  configured (required the first time IAP for web is used).
- **Resolution:** `gcloud services enable iap.googleapis.com`; configure the OAuth brand/consent as the
  console prompts. This first-run flow is **version-dependent** — follow the in-console prompt / current
  IAP docs. Re-run `bce_iap_enable_helper.py --resource-type web --dry-run` to re-check prerequisites.

## Access is granted from an unmanaged device or wrong region (T3 fails)
- **Symptom:** A pilot user reaches the app/VM even from a non-compliant context.
- **Cause:** The IAP binding has **no access-level condition** — it enforces identity (IAM) but not
  context — or the condition references the wrong access level.
- **Resolution:** Confirm the binding carries a `--condition` referencing `Access Level – Corp-Managed –
  v1`. Re-add the binding with the condition (Implementation Stage 2/3). `bce_policy_guardrail_check.py`
  flags this as `IAP_NO_CONDITION` (HIGH). **Verify** the exact condition-expression syntax for your
  `gcloud` version.

## Device state changes but the decision doesn't (T6 fails)
- **Symptom:** Marking a device unmanaged/non-compliant doesn't flip access from allow to deny.
- **Cause:** The access level tests only identity/network, not a device signal; or the device-trust
  signal source isn't enrolled/licensed for the pilot devices (requirement 2.4).
- **Resolution:** Add a **device condition** to the access level and confirm the signal source is live
  and licensed. Richer device signals may require **Chrome Enterprise Premium / endpoint-verification
  enrollment** — **verify the exact signal source and license in your organization.** Rebuild the level
  with `bce_scope_config_helper.py build --require-corp-device`.

## A user who should have access is denied (T2 fails)
- **Symptom:** A compliant member of `Pilot Group – ZeroTrust` is denied.
- **Cause:** The user isn't in the group; the group lacks `roles/iap.httpsResourceAccessor` /
  `roles/iap.tunnelResourceAccessor`; the access-level condition is stricter than intended (e.g. region
  or IP mismatch); or the device signal isn't reporting for that device.
- **Resolution:** Verify group membership and the IAM binding; inspect the access-level condition
  against the user's actual context (IP/region/device). Loosen or correct the level, then re-test.
  IAP/audit logs show which condition produced the deny.

## SSH via `--tunnel-through-iap` fails
- **Symptom:** `gcloud compute ssh <vm> --tunnel-through-iap` times out or is refused.
- **Cause:** The firewall doesn't allow SSH from the IAP range; the user lacks
  `roles/iap.tunnelResourceAccessor` (optionally conditioned); or `iap.googleapis.com` isn't enabled.
- **Resolution:** Ensure an ingress rule allows `tcp:22` **from `35.235.240.0/20`** (and not from the
  internet/VPN); grant the tunnel accessor role to `Pilot Group – ZeroTrust`; enable the IAP API.
  `bce_iap_enable_helper.py --resource-type ssh --dry-run` prints and checks all three.

## Direct access to the backend/VM still works (T5 fails)
- **Symptom:** The app backend is reachable without IAP, or SSH works without the IAP tunnel.
- **Cause:** A firewall rule still exposes the backend/SSH directly (often a broad `0.0.0.0/0` rule or a
  leftover VPN-range rule).
- **Resolution:** Remove the broad rule; scope SSH to `35.235.240.0/20` and the web backend to accept
  only IAP-signed traffic. `bce_policy_guardrail_check.py` flags `SSH_BROAD` (HIGH);
  `bce_access_assessment.py` tags such rules `FLAT-TRUST`.

## An unauthorized user reaches the resource (T4 fails)
- **Symptom:** Someone not in `Pilot Group – ZeroTrust` gets in.
- **Cause:** An over-broad IAM binding — e.g. a grant to `allAuthenticatedUsers`/`allUsers` or a wider
  group.
- **Resolution:** Remove the broad binding; bind only the pilot group. The guardrail check flags
  `IAP_BROAD_PRINCIPAL` (HIGH).

## VPN retirement locked users out (Stage 5)
- **Symptom:** After removing a VPN route/firewall rule, users can no longer reach the app/VM.
- **Cause:** The app/VM wasn't fully reachable through IAP before the path was retired (Gate 4 not truly
  passed), or an internal dependency still relied on the retired path.
- **Resolution:** **Roll back** — re-apply the removed route/firewall rule from the Stage 0 baseline to
  restore access. Confirm IAP access works for a compliant pilot user (Gate 4) *before* retiring again.
  Retire per-resource, not in bulk.

## `gcloud` access-level / IAP flags differ from the guide
- **Symptom:** A flag (`--basic-level-spec`, `--custom-level-spec`, condition syntax, tunnel binding
  scoping) is rejected or behaves differently.
- **Cause:** These surfaces are **version-dependent** and evolve.
- **Resolution:** Run `gcloud <command> --help` for your installed version and confirm the current flag
  shape; the guide flags these as **verify**. Update `gcloud` if it is significantly out of date.

## Guardrail check can't read policies/logs
- **Symptom:** `bce_policy_guardrail_check.py` or the validation report prints `*_UNREADABLE` / no log
  entries.
- **Cause:** The running identity lacks read roles (`roles/accesscontextmanager.policyReader`,
  IAP policy read, `roles/logging.viewer`) or Cloud Audit Logging for IAP isn't enabled.
- **Resolution:** Grant the read roles to the operator/service identity via ADC; enable Data Access
  audit logs for IAP so allow/deny evidence is captured. The tools are read-only and safe to re-run.
