# 5. Testing Guide — Microsoft Purview for Manufacturing

Run after publishing to `Purview - Manufacturing Pilot` (Implementation Step 3 onward), before the DLP
audit gate (Step 7), and again after each expansion.

## Test 1 — Labels published and visible
**Do:** In Outlook / Word (web or desktop) as a pilot user, open the **Sensitivity** button. Or run
`PURVIEW-MFG-Validation.ps1`.
**Expected:** All five taxonomy labels appear (`Sensitivity Label - MFG-Public` through
`Sensitivity Label - MFG-CUI-Export-Controlled`) via `Label Policy - Manufacturing Taxonomy - All
Users`.

## Test 2 — IP label protection travels externally
**Do:** Apply `Sensitivity Label - MFG-Confidential-IP` to a test drawing and share it to (a) a listed
trusted partner domain and (b) a non-listed external address.
**Expected:** The file is encrypted/marked; the trusted partner can open per the label's permissions;
the non-listed external recipient is denied.

## Test 3 — CUI / export-control label restricts
**Do:** Apply `Sensitivity Label - MFG-CUI` (and separately `MFG-CUI-Export-Controlled`) to a test
item and attempt to open it as an out-of-scope/unauthorized user.
**Expected:** The item is encrypted and shows the CUI / export-control marking; the unauthorized user
is denied per the label's permissions.

## Test 4 — Custom SIT detects a part/drawing number
**Do:** Purview → **Data classification → Sensitive info types →** open `SIT - MFG Part/Drawing Number`
→ **Test**, using sample content containing a real-format part number and some decoy text.
**Expected:** The SIT matches the part/drawing number at the configured confidence and does **not**
match the decoys.

## Test 5 — Auto-labeling simulation matches
**Do:** Purview → **Information Protection → Auto-labeling →** open
`Auto-Label - CUI and Export-Controlled - Pilot` → **Simulation**.
**Expected:** The simulation lists items containing part/drawing numbers or CUI markers and proposes
the correct label — and does not flag routine, non-sensitive content.

## Test 6 — DLP is auditing (before the gate)
**Do:** As a pilot user, email a test message containing a labelled IP/CUI file (or a part number) to
an external address; check Purview → **Data Loss Prevention → Alerts** and **Activity explorer**. Or
run `PURVIEW-MFG-Report.ps1`.
**Expected:** `DLP Policy - Manufacturing IP and CUI - Audit` records the match (policy tip shown, no
block) — the audit gate has data to review.

## Test 7 — DLP enforces (after the gate)
**Do:** After Step 8, repeat Test 6 against `DLP Policy - Manufacturing IP and CUI - Enforce`; also try
to send an export-controlled item to an unauthorized recipient, and (endpoint) copy a labelled drawing
to a USB drive.
**Expected:** The action now blocks (or blocks-with-override for internal); the export-control send is
hard-blocked; the USB copy is blocked/audited per the endpoint rule; each event is logged.

## Test 8 — Retention label applied and honored
**Do:** Apply `Retention Label - Quality and Contract Records - 7 Year` to a test item and attempt to
delete it.
**Expected:** The item is retained for the period (or declared a record and blocked from deletion) per
the label.

## Test 9 — Retention policy scoped
**Do:** Confirm `Retention Policy - Manufacturing Baseline - 5 Year` is applied to the pilot locations
(Purview → **Data Lifecycle Management → Retention policies →** open the policy). Or run
`PURVIEW-MFG-Validation.ps1`.
**Expected:** The policy shows **On** and scoped to the pilot mailboxes/sites/OneDrive/Teams.

## Test 10 — CMMC / 800-171 evidence + coverage report
**Do:** In **Compliance Manager**, open `Assessment - CMMC / NIST 800-171 - Manufacturing` and confirm
the configured controls show progress/evidence. Run `PURVIEW-MFG-Report.ps1`.
**Expected:** The mapped improvement actions reflect the labels/DLP/retention/audit you deployed; the
report summarizes classification and DLP events across the enabled services so coverage and gaps are
visible.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Pilot pass** | Tests 1–6, 8–9 pass on `Purview - Manufacturing Pilot`; the DLP audit shows real IP/CUI matches and acceptable noise |
| **Audit gate** | DLP audit reviewed and tuned; auto-labeling simulation clean; only then is Test 7 (enforce) run |
| **Expand pass** | Tests 1, 6/7, 9, 10 pass after widening scope beyond the pilot |
