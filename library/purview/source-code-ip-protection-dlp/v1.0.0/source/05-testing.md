# 5. Testing Guide — Source-Code & IP Protection DLP (Microsoft Purview)

Run after each configuration step. Every test is safe (read-only or a `-WhatIf` preview) except where it
asks you to generate representative egress on a pilot user/device — and the policy is in **test mode**, so
no real egress is blocked. Validate on `Source-Code DLP – Pilot Ring – Stage1` before enforcing or
expanding.

## Test 1 — Prerequisites and enablement are in place
**Do:** Run `DLPCODE-Check-Prereqs.ps1`.
**Expected:** ExchangeOnlineManagement present and connected; the DLP/compliance role reported; the DLP
capability signal reported; existing policies listed. Every gap (e.g. Endpoint DLP / Source Code classifier
unavailable → deferred) is **recorded, not guessed**.

## Test 2 — Discovery inventory is complete
**Do:** Run `DLPCODE-Discover.ps1`.
**Expected:** Every DLP policy and rule is listed with which **channels** it covers
(Exchange/SharePoint/OneDrive/Teams/Endpoint) and its **mode**; available **sensitive information types**
are sampled; the reminder to confirm the **Source Code** classifier and **Endpoint DLP** onboarding is
shown.

## Test 3 — Create dry-run makes no changes
**Do:** Run `DLPCODE-Set-DlpPolicy.ps1 -Action CreatePolicy -PilotUsers "codedlp-pilot@contoso.com" -UseSourceCodeClassifier -WhatIf`.
**Expected:** It states the policy/rule/channels it *would* create (test mode) plus the reverse action and
changes nothing; a follow-up `Get-DlpCompliancePolicy` shows no new policy until `-Commit`.

## Test 4 — Policy exists in test mode across the intended channels
**Do:** After `-Commit`, run `Get-DlpCompliancePolicy -Identity "Source-Code & IP DLP - Policy"` and
`Get-DlpComplianceRule`.
**Expected:** The policy exists, covers the intended channels (email, SharePoint/OneDrive, Teams, and —
where licensed — Endpoint), its rule matches the Source Code classifier (+ custom IP types), and the mode
is **test** — enforcing nothing.

## Test 5 — The rule detects source code
**Do:** Create test content that the Source Code classifier should match (a representative code file) and
route it through an in-scope channel (e.g. attach to an internal email or upload to a pilot site).
**Expected:** The DLP reports / Activity Explorer show a **match** in test mode — the policy detects source
code. (Trainable-classifier matching is probabilistic; verify behavior against current Microsoft guidance.)

## Test 6 — Endpoint egress is evaluated (where licensed)
**Do:** On an **onboarded** pilot device, attempt to copy a matching code file to **USB/removable media**
and to upload it via an unmanaged browser.
**Expected:** In test mode the policy records what it **would** restrict for the USB-copy and upload
activities (and where a **policy tip** would appear) — without blocking. If Endpoint DLP is out of plan,
this test is recorded **deferred**.

## Test 7 — External email egress is evaluated
**Do:** Email a matching code file to an **external** recipient from a pilot user.
**Expected:** In test mode the policy records what it **would** restrict for the external-email condition —
without blocking the send.

## Test 8 — Validation gate passes on the pilot (test mode)
**Do:** Run `DLPCODE-Validate.ps1`.
**Expected:** PASS for each gate — the policy exists, covers the intended channels, the rule matches the
source-code/IP detection, and the policy is in **test mode** (not prematurely enforcing). Any FAIL names
the specific issue.

## Test 9 — False positives are tuned out
**Do:** Review test-mode matches for legitimate developer activity (build tools, approved-repo pushes,
partner sharing) that shouldn't match; add an **exception** or adjust the classifier confidence/conditions;
re-review.
**Expected:** After tuning, legitimate developer workflow no longer matches while real source-code/IP
egress still does — an acceptable false-positive rate before enforcement.

## Test 10 — Enforcement blocks as designed (deliberate, after approval)
**Do:** Only after validation and approval: enforce with `-Commit`, then attempt a matching egress
(external email / USB copy / upload) as a normal pilot user/device.
**Expected:** The egress is **restricted/blocked** per the rule, the user sees the **policy tip**, and an
**admin alert** fires. An approved/excepted path still works. (Verify against your configuration.)

## Test 11 — Reporting evidence is produced
**Do:** Run `DLPCODE-Report.ps1 -CsvPath .\CodeDlpReport.csv`.
**Expected:** `Source-Code DLP – Coverage Report` lists each policy/rule, its channels, mode, and match
conditions — usable as the management evidence artifact and re-runnable on a schedule.

---
### Pass/fail summary
All gates green on `Source-Code DLP – Pilot Ring – Stage1` — policy present in test mode, detecting source
code / IP across the intended channels with false positives tuned out, policy tips and alerts behaving as
designed — before moving to enforce or expanding. Enforcement is enabled only as a deliberate, approved
step; any deferred (Endpoint-DLP/classifier/licensing-gated) capability is recorded explicitly, not
silently skipped.
