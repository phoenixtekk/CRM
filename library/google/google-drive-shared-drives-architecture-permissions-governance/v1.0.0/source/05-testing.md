# 5. Testing & Validation

Each test below has an **expected pass/fail** result. Run them against the **pilot scope** first
(`Pilot OU – Drive – Finance`), then per OU as you Expand. Tests map to the gates in the
Implementation Guide. The Python tools referenced are all **read-only** for validation.

---

## Test 1 — Sharing exposure reduced to policy (Gate G2 / Validate)
- **Procedure:** Re-run `python drive_sharing_exposure_assessment.py --domain corp.example --ou "/Finance" --json`
  and compare to the G0 baseline (`baseline-finance.json`).
- **Expected PASS:** External-shared and "Anyone with the link" counts drop to the design's allowed
  set (only shares to the approved `Audience – …`); orphaned-owner count is **0**; business content in
  My Drive count is **0** for pilot users.
- **FAIL:** Any un-scoped external / link share, or any orphaned-owner or My-Drive business file
  remains → remediate or **rollback** (§3.6).

## Test 2 — External-sharing policy conformance (go/no-go gate)
- **Procedure:** Run `python external_sharing_policy_validator.py --domain corp.example --ou "/Finance" --catalog drive-catalog.csv`.
- **Expected PASS:** Exit code **0** — configured sharing (OU sharing settings, target audiences, trust
  rules) matches the `Sharing Profile – Finance – Restricted` design; no partner domain outside the
  allow-list is reachable.
- **FAIL:** Non-zero exit listing the specific violation (e.g. external sharing still ON where design
  says allow-listed only).

## Test 3 — Link-sharing default is restricted
- **Procedure:** As a pilot user, create a new Doc in a pilot Shared Drive and open **Share** — observe
  the default access. Also confirm via the assessment's link-sharing count.
- **Expected PASS:** Default is **"Only added people"** (restricted), not "Anyone with the link";
  sharing outside the domain shows the outside-domain **warning**.
- **FAIL:** New files default to "Anyone with the link" or external sharing proceeds with no warning.

## Test 4 — Target audience is the default suggestion
- **Procedure:** In a pilot Shared Drive file, open **Share → "Add people and groups"** and check the
  suggested audience.
- **Expected PASS:** `Audience – Internal – All Staff` (the governed audience) is offered as the
  default, replacing the generic "Anyone with the link."
- **FAIL:** The generic public-link option is the default (target audience not applied to the OU).
  *(Edition-gated — if target audiences are unavailable on your edition, this test is N/A; rely on
  Tests 2/3 and the OU sharing settings.)*

## Test 5 — DLP blocks/warns on sensitive external sharing
- **Procedure:** As a pilot user, place a **synthetic** sensitive value that matches a `DLP –
  <Detector> – …` rule (e.g. a test national-ID pattern) into a Doc in a pilot Shared Drive and attempt
  to share it **externally**.
- **Expected PASS:** The `DLP – <Detector> – Block-External` rule **blocks** the external share (or
  **warns**, per the rule action); the event appears in **Security → Data protection** / the security
  investigation tool.
- **FAIL:** The external share of matching sensitive content succeeds silently. *(Use only synthetic
  test data — never real regulated content.)*

## Test 6 — Membership is group-based, roles are least-privilege
- **Procedure:** In **Manage Shared Drives**, open a pilot Shared Drive's membership; or run the
  governance report and inspect the membership section.
- **Expected PASS:** Members are **Google Groups** (`grp-…`), not individual users; the **Manager**
  role is held only by the owner group `grp-<function>-drive-owners@…`; other groups are Contributor/
  Viewer per the role model.
- **FAIL:** Individual users are direct members, or a non-owner group holds **Manager**.

## Test 7 — No orphaned ownership
- **Procedure:** Run the assessment (or the governance report) and inspect the orphaned-owner section
  (files owned by suspended/deleted users).
- **Expected PASS:** Orphaned-owner count is **0** for the scope — business content lives in
  organization-owned Shared Drives, so no file is stranded on a departed user.
- **FAIL:** Any file still owned by a suspended/deleted user → transfer to a Shared Drive.

## Test 8 — Governance reporting is in place
- **Procedure:** Run `python drive_governance_report.py --catalog drive-catalog.csv --exposure post-finance.json --out finance-governance.html`
  and open the report.
- **Expected PASS:** The report lists each `Shared Drive – …` with its owner group, member groups +
  roles, external-share and orphaned-owner counts, and flags stale/empty Drives and any Drive lacking
  a Manager group — i.e. the artifacts a quarterly `Access Review – <Drive> – <Quarter>` needs.
- **FAIL:** The report cannot enumerate owners/members or omits the exposure/lifecycle sections.

## Test 9 — Rollback restores the baseline
- **Procedure:** In a change window, execute the §3.6 rollback for one setting (e.g. revert
  `Sharing Profile – Finance – Restricted` to the G0 value) and re-run Test 1/2.
- **Expected PASS:** The pre-change posture is restored and validation reflects the baseline — proving
  the change is reversible before production expansion.
- **FAIL:** The setting cannot be cleanly reverted → do not expand until rollback is proven.
