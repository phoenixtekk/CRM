# 5. Testing & Validation — BeyondCorp Enterprise: Zero-Trust Access

Each test states the procedure and the **expected pass/fail**. The zero-trust principle is validated
only when access is **granted on identity + context** and **denied otherwise** — every test below maps
to one of the implementation gates. Run them against the named pilot artifacts (`IAP App – Pilot`,
`IAP VM – Pilot`, `Pilot Group – ZeroTrust`, `Access Level – Corp-Managed – v1`) before expanding or
retiring any VPN path. The `bce_zerotrust_validation_report.py` tool automates the allow/deny matrix
and gathers the log evidence.

---

## T1 — Access levels exist and are well-formed (Gate 1)
- **Procedure:** `gcloud access-context-manager levels list --policy $POLICY_ID`; open each level and
  confirm its conditions match the intended identity/device/network design.
- **Pass:** both `Access Level – Trusted-Network – v1` and `Access Level – Corp-Managed – v1` exist,
  and the corp-managed level includes a **device** condition (not identity/IP only).
- **Fail:** a level is missing, or the corp-managed level has no device/context condition (the
  guardrail check flags this) — return to Implementation Stage 1.

## T2 — Allowed path: corp-managed device, allowed region (Gate 4)
- **Procedure:** As a **member of `Pilot Group – ZeroTrust`** on a **corporate-managed device** in an
  **allowed region**, open the pilot app URL and SSH via `gcloud compute ssh $PILOT_VM
  --tunnel-through-iap`.
- **Pass:** both the app loads and the SSH session connects; IAP logs show an **allow** for that user
  with the access level satisfied.
- **Fail:** access is denied for a user who should pass — inspect the access-level condition and the
  device signal (T6); the binding condition may not match the level.

## T3 — Denied path: unmanaged device or disallowed region (Gate 4)
- **Procedure:** As the **same pilot user** but from an **unmanaged device** (or a disallowed region /
  outside the trusted network), retry the app and the SSH tunnel.
- **Pass:** access is **denied** — the request fails the access level even though the identity is
  authorized; IAP/audit logs show a **deny** attributed to the access-level condition.
- **Fail:** access is granted from an unmanaged/disallowed context — the access level is not being
  enforced on the binding. Confirm the `--condition` is present on the IAP binding; re-check Stage 2/3.

## T4 — Denied path: unauthorized identity (Gate 4)
- **Procedure:** As a user **not** in `Pilot Group – ZeroTrust`, attempt the pilot app and the SSH
  tunnel from an otherwise-compliant device.
- **Pass:** access is **denied** by IAM (no `roles/iap.*ResourceAccessor` grant); logs show the deny.
- **Fail:** a non-member reaches the resource — an over-broad IAM binding exists (e.g. a grant to
  `allAuthenticatedUsers` or a wider group). Remove it; the guardrail check flags broad principals.

## T5 — Direct-bypass attempt is refused (Gate 2/3/5)
- **Procedure:** Attempt to reach the app backend directly (not through the load balancer/IAP) and SSH
  to the VM **without** `--tunnel-through-iap`, from both the internet and the (pre-retirement) VPN.
- **Pass:** the direct attempt **fails** — the backend only accepts IAP-signed requests and SSH is only
  permitted from `35.235.240.0/20`. After Stage 5, the retired VPN path also cannot reach the VM.
- **Fail:** direct or VPN access still works — a firewall rule still exposes the backend/SSH. Lock it
  down (the guardrail check flags SSH not restricted to the IAP range) and re-test.

## T6 — Device-trust signal is actually evaluated
- **Procedure:** Toggle the device out of compliance in the signal source (e.g. remove endpoint
  enrollment / mark unmanaged) — **verify the exact toggle for your signal source** — and retry.
- **Pass:** access flips from allowed to **denied** when the device signal changes, proving the signal
  drives the decision (not just IP/identity).
- **Fail:** the decision does not change with device state — the access level is testing only
  identity/network. Add/repair the device condition (requirement 2.4, Stage 1).

## T7 — Guardrail / posture check is clean (Gate 4)
- **Procedure:** `python bce_policy_guardrail_check.py --project $PILOT_PROJECT --policy $POLICY_ID`.
- **Pass:** no high-severity findings — every IAP binding carries an access-level condition, no
  over-broad principals, access levels include device/context conditions, and SSH firewall is scoped to
  the IAP range.
- **Fail:** any high-severity finding — remediate before proceeding to VPN retirement (Stage 5).

## T8 — VPN retirement verified (Gate 5)
- **Procedure:** After Stage 5, from the retired VPN path attempt the app/VM; then confirm IAP access
  still works from a compliant device.
- **Pass:** the retired path **cannot** reach the app/VM, **and** IAP access from a compliant pilot user
  still succeeds.
- **Fail:** the old path still reaches the resource, or IAP access broke — roll back per the
  Implementation rollback and re-plan.

---

### Evidence to retain
Export the IAP allow/deny logs and the validation-report output for T2–T5 and T8, plus the guardrail
report for T7, as the audit evidence that zero-trust enforcement is live for each resource.
