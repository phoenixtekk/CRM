# 5. Testing & Validation Guide — Android Enterprise Connection & Managed Google Play Setup

Validate the foundation with explicit **pass/fail gates**. Do **not** expand past the pilot until every
gate passes. Run the read-only scripts (`ANDROIDENT-Discovery.ps1`, `ANDROIDENT-Report.ps1`) to gather
evidence; confirm the device-side behavior by hand on the pilot devices.

> **Pilot-first rule.** Every gate is measured on the **pilot scope** (`Android AE - Pilot - Stage` and the
> per-model pilot groups) before any production expansion.

---

## Gate A — Managed Google Play binding is healthy
**What good looks like:** the connection is **bound / connected**, owned by the **organization Google
account** (not a personal Gmail), and the **app catalog sync** succeeded recently.

| Check | How | Pass |
| --- | --- | --- |
| Connection bound | `ANDROIDENT-Discovery.ps1` → bind status | Status is **bound** |
| Owner is org account | Intune → Android enterprise → owner account | Organization-owned account (Req 2.2) |
| App sync succeeded | `ANDROIDENT-Discovery.ps1` → last app sync | **Success**, recent timestamp |

**Fail →** see Troubleshooting (binding not bound / app sync failing — usually endpoint reachability or the
owner account).

---

## Gate B — Enrollment restrictions enforce the intended models
**What good looks like:** the `Android Enterprise - Platform Restrictions - Pilot` restriction **allows**
the models this pilot needs (incl. personally-owned work profile for BYOD), **blocks** unwanted models
(and legacy device administrator unless required), and is **assigned to the pilot scope only**.

| Check | How | Pass |
| --- | --- | --- |
| Allowed models correct | `ANDROIDENT-Discovery.ps1` → Android restriction | Matches the Req 2.4 plan |
| BYOD enabled (if in scope) | Restriction allows personally-owned work profile | Allowed |
| Legacy DA blocked | Restriction → Android device administrator | **Blocked** (unless justified) |
| Scoped to pilot | Restriction assignment | `Android AE - Pilot - Stage` only |

**Fail →** re-run `ANDROIDENT-Set-EnrollmentRestrictions.ps1` (preview first) and re-assign.

---

## Gate C — Each enrollment model enrolls correctly
**What good looks like:** one device of **each** model in scope enrolls the right way.

| Model | How | Pass |
| --- | --- | --- |
| **BYOD work profile** | Company Portal enrollment on a personal phone | A **work profile** is created; personal space untouched |
| **Fully managed** | QR/token enroll a reset company device (`Android FM - Enroll - Pilot`) | Whole device managed, **no** personal space |
| **Corporate-owned work profile** | Enroll with `Android COPE - Enroll - Pilot` | Managed **work profile + personal space** on a company device |
| **Dedicated / COSU** | Enroll with `Android COSU - Enroll - Pilot` | Device enrols **no user affinity** (kiosk-ready) |

Confirm in Intune → **Devices** that each pilot device shows the expected **ownership** (corporate /
personal) and **management** state. `ANDROIDENT-Report.ps1` summarizes this per model.

**Fail →** see Troubleshooting (per-model enrollment failures; "can't add a Google account").

---

## Gate D — Reporting reconciles and the profiles exist
**What good looks like:** the corporate-owned enrollment profiles exist and the report reconciles enrolled
devices to the expected models.

| Check | How | Pass |
| --- | --- | --- |
| Profiles present | `ANDROIDENT-Discovery.ps1` → enrollment profiles | `Android FM/COPE/COSU - Enroll - Pilot` present |
| Per-model coverage | `ANDROIDENT-Report.ps1` | Each in-scope model shows ≥1 enrolled pilot device |
| No unexpected models | `ANDROIDENT-Report.ps1` | No devices enrolled via a blocked model |

---

## Regression / periodic checks
- **Token / connection expiry** — corporate-owned enrollment tokens and the managed Google Play connection
  have lifecycles; `ANDROIDENT-Discovery.ps1` surfaces token expiry. Schedule a periodic
  `ANDROIDENT-Report.ps1`.
- **AMAPI transition watch** — because AMAPI, web/account-driven enrollment, and re-enrollment behavior are
  **evolving**, re-validate Gates B and C after any Microsoft-announced Android enrollment change, and
  **verify re-enrollment behavior on your own tenant** before assuming.

> **Expansion gate:** expand past the pilot only when **A, B, C, and D all pass** on the pilot scope.
