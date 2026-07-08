# 6. Troubleshooting — CMMC / CUI DLP Pack (Microsoft Purview)

Symptom-first fixes for the failures you actually hit implementing CUI DLP across email, cloud, Teams, and
endpoint. Most problems are one of: a policy not matching CUI, the CUI label/marking not detected, the
marking keyword over-firing, the endpoint location unavailable, GCC High path differences, or matches that
raise no alert.

---

## CUI detection (label & marking)

**A CUI DLP policy matches nothing even though the file is clearly marked/labeled CUI.**
- Confirm the policy is **enabled and in a mode that evaluates** — a *disabled* policy does nothing; a
  **simulation** policy evaluates and logs but does not block. Check with `DLPCMMC-Discovery.ps1` (Mode
  column) or `DLPCMMC-Validate.ps1`.
- Confirm the rule actually references the **`CUI` sensitivity label** and/or the marking SIT — run
  `DLPCMMC-Validate.ps1` (the `CUISignalOk` column). A policy with no CUI condition matches nothing relevant.
- **Policy propagation takes time** — newly created/changed DLP policies can take **up to ~1 hour (longer for
  some locations)** to take effect. Wait before concluding it's broken.
- Confirm the **location scope** includes where you're testing and the test identity isn't in an
  **exclusion** (the enclave scope may exclude your test user).

**The `CUI` sensitivity label condition isn't available or doesn't match.**
- **Label must be published** to the user who applies it (Req 2.1) — confirm in **Purview → Information
  protection → Sensitivity labels → label policies**. An unpublished label can't be applied, so DLP never
  sees it. `DLPCMMC-Discovery.ps1` reports label presence.
- **Label-based DLP conditions are licensing-gated** — confirm the *"content contains sensitivity label"*
  condition is available for your plan/tenant (Req 2.2). On **GCC High**, verify availability specifically.
- Content must actually **carry** the label — a file that is marked in text but not labeled won't match the
  label condition (that's what the marking SIT backstop is for; test A2 in Testing).

**The CUI marking keyword SIT never matches.**
- Test the SIT's **keywords/regex + proximity** in the SIT wizard's **Test** step with known CUI-marked
  text. A too-strict pattern, wrong **character proximity**, or a required keyword that isn't present will
  suppress all matches. Loosen and re-test incrementally.
- Confirm you built it from the **exact markings** compliance supplied (Req 2.6) — an invented or
  approximate banner string won't match your real documents.

**The marking SIT fires on documents that merely mention "CUI".**
- This is the classic over-fire. **Prefer the label condition** as primary and demote the marking SIT to a
  backstop; add **proximity/context keywords** so a stray "CUI" mention doesn't trigger; add a targeted
  **exception** for known discussion libraries (e.g. compliance training). Re-simulate after each change.

## Enforcement / simulation confusion

**Matches appear in simulation but nothing is blocked.**
- That is **correct** — simulation logs what *would* happen without enforcing. To block, move the policy to
  **enforce** for the pilot ring (Implementation Phase 4). If you expected blocking, you're still in
  simulation.

## Endpoint DLP

**The Devices/Endpoint location isn't available when creating a policy.**
- **Licensing:** Endpoint DLP requires the appropriate plan (E5 / E5 Compliance) — verify in the admin
  center; `DLPCMMC-Discovery.ps1` reports the endpoint-policy signal.
- **Onboarding:** the Devices location depends on **onboarded devices** — confirm in **Purview → Settings →
  Device onboarding**. No onboarded devices → the location does nothing even if selectable.

**Endpoint policy is enforced but CUI activities (USB/print/upload) aren't caught.**
- Confirm the specific **device is onboarded and reporting** (portal device list), meets the **minimum OS
  build**, and any required agent/AV prerequisites per Microsoft docs are met.
- Confirm the **activity is in scope** of the rule (e.g. "copy to USB" enabled) and the app/browser or
  network path isn't on an **allowed/exception** list.
- Allow for **reporting latency** — endpoint events can take time to surface in Activity Explorer.

## GCC High / tenant differences

**A documented portal path or capability isn't where the guide says.**
- **Confirm the tenant type** (Commercial / GCC / **GCC High**) (Req 2.3). GCC High uses different portal
  endpoints and some features/preview capabilities differ or are absent — **verify against Microsoft's GCC
  High documentation** for your environment. The guides flag rather than assert; treat every path as
  "verify in your tenant."

## Alerts / incident handling & evidence

**CUI matches occur but no alert appears / no one is notified.**
- Confirm **alerts are configured** on the rule (alert on match, threshold) and check **Purview → Data loss
  prevention → Alerts**. Some low-severity matches aggregate rather than alert per event.
- Confirm **unified audit logging is enabled** in the tenant — the report script and Activity Explorer rely
  on it.
- Confirm the **triage owner/queue** (`CUI DLP Alerts – Triage – Operations`) exists and, if forwarding to
  SIEM/Sentinel, that the connector is healthy (Req 2.8).

**`DLPCMMC-Report.ps1` returns no matches.**
- **Audit log latency:** DLP events can take time to appear; widen `-Days` and re-run.
- Freshly created policies need **dwell time** — there may simply be no matches yet.
- Confirm **audit logging is on** and your account has the **View-Only DLP / audit** role.

## Connectivity / tooling

**`Connect-IPPSSession` or a DLP cmdlet fails.**
- Ensure the **ExchangeOnlineManagement** module is installed/updated and you're using a **modern-auth /
  MFA-capable** admin. On **GCC High**, use the environment-specific connection parameters.
- Confirm the account holds the required **DLP role** (Compliance Administrator / Compliance Data
  Administrator / DLP Compliance Management) — a missing role surfaces as "cmdlet not recognized" or access
  denied.

**A script made an unexpected change.**
- The delivered scripts are **read-only or `-WhatIf` by default**; writes require `-Commit`. The config
  helper never leaves a policy in **enforce**, and the scope helper never changes **mode** — so the safe
  recovery is always to set the policy back to **simulation** in the portal (one setting, no data change).

---

### Fast triage table

| Symptom | First check |
|---|---|
| Policy matches no CUI | Mode (disabled/sim), rule references `CUI` label/SIT (`DLPCMMC-Validate`), propagation time, scope/exclusion |
| Label condition unavailable/no match | Label published? licensing for label-based DLP? content actually labeled? (GCC High: verify) |
| Marking SIT never fires | Test keywords+proximity in the SIT wizard; built from real markings? |
| Marking SIT over-fires on "CUI" mentions | Label-first, add proximity/context, add exception, re-simulate |
| Nothing blocked | Still in **simulation** — that's expected; enforce the ring to block |
| Devices location missing | Licensing (E5/E5 Compliance) + device **onboarding** |
| Endpoint activity not caught | Device onboarded/reporting, activity in scope, allowed-app/network exceptions |
| Portal path not as documented | Confirm tenant type (GCC High differs) — verify against Microsoft docs |
| No alert on match | Alert config on rule, audit logging on, triage owner, SIEM connector |
| Report returns nothing | Audit latency/dwell time, audit logging on, role |
| Cmdlet/connect fails | Module updated, modern auth (GCC High params), correct DLP role |
