# Implementation — Pre-Logon VPN: Choose the Approach & Validate the Two Scenarios

This is the ordered procedure. Follow the phases in order:
**Assess → Configure → Pilot → Validate → Expand.** Because this product is the **decision +
scenario + validation** layer, the phases are framed around **choosing an approach** and **proving
the two scenarios**, not around building VPN profiles (those builds live in the companion products).
Use the **exact object names** shown — the tests, troubleshooting, and scripts reference them verbatim.

> **Scope boundary:** the device-tunnel build (`AOVPN – Device Tunnel – ProfileXML – Windows`) and
> the SBL/PLAP build (`Cisco Secure Client – Pre-Logon (SBL) – Win32`) are **created in their
> companion products** and are **deferred to those products and the vendor's official documentation**.
> This guide chooses between them and validates the outcome; it does not re-create them.

> **Government / GCC High note:** the portal URLs below are Commercial. In US sovereign clouds use the
> `*.us` equivalents — Intune/Endpoint at `https://endpoint.microsoft.us`, Entra at
> `https://entra.microsoft.us`, and sign-in at `login.microsoftonline.us` — and **verify each step for
> GCC High**, as feature availability and portal paths can differ. Do not assume Commercial steps map
> one-to-one; confirm against Microsoft US Gov documentation.

## Object naming convention (use verbatim)

| Object | Name | Created where |
|---|---|---|
| Pilot group | `PILOT – Pre-Logon First-Logon Users` | This product (`PREVPN-Set-ScopeTargeting.ps1`) |
| Production group | `PROD – Pre-Logon First-Logon Users` | This product (`PREVPN-Set-ScopeTargeting.ps1`) |
| Device-tunnel profile (referenced) | `AOVPN – Device Tunnel – ProfileXML – Windows` | Companion device-tunnel product |
| SBL/PLAP app (referenced) | `Cisco Secure Client – Pre-Logon (SBL) – Win32` | Companion SBL/PLAP product |

---

# Phase 1 — Assess

1. Confirm every item in `02-requirements.md` passes.
2. Build the **join-type inventory** and pre-logon readiness baseline:
   `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Discovery.ps1`
   Review the readiness table: counts by join type (hybrid / domain-joined / Entra-joined), whether a
   device-tunnel profile **or** the SBL/PLAP app is present, and pilot/prod group membership.
3. Note which devices are **hybrid/domain-joined** (the ones the two scenarios apply to) versus
   **Entra-joined** (which usually need neither approach).

**Gate A (Assess):** You have the join-type mix, you know which devices are in scope for pre-logon,
and all requirements pass. If the fleet is overwhelmingly Entra-joined, confirm you actually need
pre-logon at all before proceeding.

---

# Phase 2 — Configure (choose the approach)

## 2.0 Create the segmentation groups

Use the script (recommended) or the portal.

- **Script:** `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Set-ScopeTargeting.ps1`
  (creates `PILOT – Pre-Logon First-Logon Users` and, with `-CreateProd`,
  `PROD – Pre-Logon First-Logon Users`, and adds the members you supply).
- **Portal:** Entra admin center → **Groups > New group > Security** → name
  `PILOT – Pre-Logon First-Logon Users` → add pilot members → **Create**. Repeat for the prod group.

## 2.1 Run the decision matrix — pick device tunnel or SBL/PLAP

Work down the matrix. The **first row that forces a choice wins**; use the later rows to confirm.

| # | Question | If this is true → | Approach |
|---|---|---|---|
| 1 | Are the in-scope devices **Entra-joined (cloud-only)**? | They authenticate against Entra in the cloud; a first logon and password change work without an on-prem DC. **Do not deploy a pre-logon tunnel** — use SSPR/TAP for the cloud paths. | **Neither** |
| 2 | Are devices **domain-joined / hybrid-joined**? | The scenarios apply — continue to row 3. | (continue) |
| 3 | Are all in-scope devices **Windows Enterprise / Education** with a **machine-cert PKI** and an **IKEv2** gateway? | You can run a **silent, no-user-action** machine tunnel at boot. | **Device tunnel (A)** |
| 4 | Do you **already run Cisco Secure Client**, or **cannot** meet the Enterprise/Education + machine-cert + IKEv2 bar? | Use the **logon-screen** VPN the user brings up before signing in. | **SBL / PLAP (B)** |
| 5 | Do you want the **user to choose** the network before logon, or need a manual fallback? | SBL/PLAP is user-initiated at the logon screen. | **SBL / PLAP (B)** |
| 6 | Support model: fully hands-off vs. help-desk-guided first connect? | Hands-off → device tunnel (A); guided/manual → SBL/PLAP (B). | (tie-break) |

Record the decision (approach, and why) in your runbook. If devices split across categories, you may
run **both** (device tunnel for the Enterprise/Education + PKI cohort, SBL/PLAP for the rest) — segment
each cohort with the pilot/prod groups.

## 2.2 Confirm the chosen approach's objects exist

You do **not** build the tunnel here — you confirm the companion product deployed it.

- **If you chose the device tunnel (A):** confirm `AOVPN – Device Tunnel – ProfileXML – Windows`
  exists and is assigned (deploy it via the companion device-tunnel product if not).
  `PREVPN-Discovery.ps1` flags whether a device-tunnel profile is present.
- **If you chose SBL/PLAP (B):** confirm `Cisco Secure Client – Pre-Logon (SBL) – Win32` exists and is
  assigned (deploy it via the companion SBL/PLAP product if not). `PREVPN-Discovery.ps1` flags whether
  the SBL app is present.

**Gate B (Configure):** The approach is chosen and recorded, the segmentation groups exist, and the
chosen approach's object is present and assigned. Re-run `PREVPN-Discovery.ps1` — the fleet should now
show a pre-logon path for the in-scope devices.

---

# Phase 3 — Pilot

1. Put a **representative** cohort into `PILOT – Pre-Logon First-Logon Users`:
   - at least one **hybrid-joined** device,
   - at least one **domain-joined** device (if you have any),
   - and one **Entra-joined** device as a **control** (to confirm it does *not* need pre-logon).
2. Ensure the chosen approach's object (device-tunnel profile or SBL app) is assigned so the pilot
   devices actually have the pre-logon capability.
3. On a pilot device, confirm the capability landed:
   `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Validation.ps1`
   It reports the join type, whether a pre-logon tunnel exists, the machine cert (if device tunnel),
   and a best-effort DC reachability check.

**Gate C (Pilot):** Every in-scope pilot device shows a pre-logon path present and a DC reachable
through it (`PREVPN-Validation.ps1` = PASS). The Entra-joined control shows *no* pre-logon path and
still signs in — confirming it did not need one. If a pilot device fails, go to `06-troubleshooting.md`.

---

# Phase 4 — Validate (the two decisive scenarios)

These are the tests this product exists for. Run both on the pilot before expanding. Full pass/fail
detail is in `05-testing.md` (T1 and T2).

1. **Scenario 1 — First-time off-network logon.** Take a **freshly provisioned** hybrid/domain-joined
   device with a **user who has never logged on to it**, keep it **off the corporate network**, and
   confirm the **first interactive logon succeeds** because the pre-logon tunnel brought a DC into
   reach (device tunnel auto-up at the logon screen, or the user brings up SBL/PLAP first).
2. **Scenario 2 — Off-network password change.** Take a user whose **password is expired** (or force a
   change), off-network, and confirm they can **change the password at the logon/lock screen** and
   sign in — because the tunnel carried the AD password change to a DC.
3. Run the fleet readiness roll-up to see pilot coverage:
   `powershell -ExecutionPolicy Bypass -File .\scripts\PREVPN-Report.ps1`

**Gate D (Validate):** On the pilot, **both** scenarios PASS on every in-scope join type, and the
Entra-joined control confirms the cloud paths (ordinary logon; SSPR/TAP for password). All Testing
gates are green. Only then expand.

---

# Phase 5 — Expand

1. Add `PROD – Pre-Logon First-Logon Users` to the chosen approach's assignment (via the companion
   product), keeping the pilot group assigned. Ensure only **hybrid/domain-joined** devices are
   targeted — do not push a pre-logon tunnel to Entra-joined devices that don't need it.
2. Expand in waves for large fleets; watch `PREVPN-Report.ps1` between waves for coverage of the
   pre-logon path across in-scope devices.
3. Remediate stragglers with `PREVPN-Remediation.ps1` (defaults to **-WhatIf** preview — it adds
   devices/users lacking a pre-logon path to the pilot group for the chosen approach and prints
   guidance; it does **not** create VPN profiles — that is the companion products' job).
4. Keep the **break-glass fallback** (R8: local admin, TAP, on-network onboarding) documented and
   ready for any device where pre-logon VPN fails.

**Rollback (any phase):** Exclude the target group from the chosen approach's assignment (in the
companion product) and fall back to on-network first onboarding / SSPR / TAP per R8. No VPN profile is
created by this product, so rollback here is purely a targeting/segmentation change.

**Gate E (Expand):** In-scope coverage meets your target (e.g. ≥ 95% of hybrid/domain-joined devices
have a validated pre-logon path); Entra-joined devices are correctly excluded; both scenarios remain
green on spot-checks. The decision is implemented and validated.
