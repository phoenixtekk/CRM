# 5. Testing Guide — Exchange Online Mailbox Automation with Logic Apps Managed Identity (Graph)

Run after Implementation Step 4 (the Graph read is built) and re-run after any change to the app role, the mailbox scope, or the workflow. Objects are referenced by their names from `03-implementation.md` (`la-mailbox-automation-pilot`, `automation-inbox@contoso.com`, `Mail.Read`, `sg-MailboxAutomation-Scope-Pilot`).

> The two gates that matter most: **(1)** the identity holds **only** the least-privilege permission, and **(2)** the identity can read the **in-scope** mailbox but is **denied** an **out-of-scope** mailbox. A deployment that fails gate 2 has tenant-wide read and must not go live.

## Test 1 — The managed identity exists and authenticates
**Do:** `portal.azure.com` → `la-mailbox-automation-pilot` → **Identity** → confirm **System assigned** = **On** (or the user-assigned `id-mailbox-automation-pilot` is attached); run `LAMIMAIL-Discovery.ps1`.
**Expected:** The identity's service principal is listed with an Object ID and AppId.
**PASS/FAIL:** PASS if the identity resolves; FAIL if no service principal is found.

## Test 2 — Least privilege: Mail.Read and nothing broader
**Do:** Run `LAMIMAIL-Validate.ps1`.
**Expected:** `Mail.Read` (application) is granted, and **no** broader Graph application permission is present.
**PASS/FAIL:** PASS only if both checks pass; FAIL if `Mail.Read` is missing **or** any broader permission is granted.

## Test 3 — The identity reads the IN-scope mailbox
**Do:** Run `LAMIMAIL-Test-MailboxAccess.ps1` with `-InScopeMailbox automation-inbox@contoso.com`.
**Expected:** The in-scope read returns messages (READ OK).
**PASS/FAIL:** PASS if the in-scope read succeeds; FAIL if it is denied (check the app-role grant/consent and the scope group membership).

## Test 4 — An OUT-of-scope mailbox is DENIED (the security boundary)
**Do:** Run `LAMIMAIL-Test-MailboxAccess.ps1` with `-OutOfScopeMailbox ceo@contoso.com` (any mailbox NOT in `sg-MailboxAutomation-Scope-Pilot`).
**Expected:** The out-of-scope read is **refused** (Access Denied / 403 / ErrorAccessDenied).
**PASS/FAIL:** PASS **only** if the out-of-scope read is denied. If it **succeeds**, the mailbox scope is not in place — the identity still has tenant-wide read; **FAIL** and apply the scope (Implementation Step 3 / scoping sibling product).

## Test 5 — The workflow processes a test message end to end
**Do:** Send a test email to `automation-inbox@contoso.com`. Trigger `la-mailbox-automation-pilot` (recurrence, or your chosen webhook/polling trigger). Open **Run history**.
**Expected:** A run executes, the Graph HTTP action returns **200** with the message in the body, and the workflow's downstream steps act on it.
**PASS/FAIL:** PASS if the run succeeds and the test message is read; FAIL on a 401 (auth), 403 (scope/permission), or a token/audience error (see Troubleshooting).

## Test 6 — No stored credential remains
**Do:** Inspect `la-mailbox-automation-pilot` for any **Office 365 Outlook** API connection or service-account credential.
**Expected:** There is **no** Office 365 Outlook connector connection and **no** stored mailbox credential — authentication is the managed identity only.
**PASS/FAIL:** PASS if no connector connection/credential exists; FAIL if a service-account OAuth connection is still present (remove it — it is the pattern this solution replaces).

## Test 7 — Evidence report
**Do:** Run `LAMIMAIL-Report.ps1 -OutCsv .\LAMIMAIL-permissions.csv`.
**Expected:** A table + CSV of the application permission(s) on the identity and the mailbox-scope binding.
**PASS/FAIL:** PASS if the report shows `Mail.Read` as the only application permission and the scope binding lists only the target mailbox.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Least-privilege pass** | Tests 1–2 pass — the identity exists and holds only `Mail.Read` |
| **Boundary pass (must hold before go-live)** | Tests 3–4 pass — in-scope readable, **out-of-scope denied** |
| **End-to-end pass** | Test 5 passes — a test message is read by the workflow with managed-identity auth |
| **Hygiene pass** | Tests 6–7 pass — no stored credential remains; evidence report is clean |
