# Troubleshooting

Common failure modes when building and running Admin SDK / API automation, with resolutions. Reuse the
artifact names from Implementation.

## Authentication & delegation

### `unauthorized_client` / "Client is unauthorized to retrieve access tokens using this method"
- **Cause:** the service account's OAuth **client ID** is not on `DWD Grant – AdminSDK – LeastScope`, or
  a requested scope is not in the grant's scope list.
- **Resolve:** in the Admin console **API controls → Domain-wide delegation**, confirm the exact numeric
  client ID and that **every** scope the tool requests is listed (comma-separated, no typos). Scope
  changes can take a few minutes to propagate — re-run the auth validator after.

### `access_denied` / 403 `Not Authorized to access this resource/api`
- **Cause:** the **impersonation subject** (`Impersonation Subject – Reports – ReadOnly`) lacks the admin
  privilege the API requires, or you are impersonating a non-admin.
- **Resolve:** impersonate a subject with the least admin privilege the report needs (e.g. a role that
  can read users/reports). Do not escalate to super-admin as a fix — grant the specific privilege.

### `invalid_grant` / "Invalid impersonation 'sub'"
- **Cause:** the subject email is mistyped, not in the domain, or suspended.
- **Resolve:** verify the subject exists, is active, and is spelled correctly; pass it via `--subject`.

### Credentials not found / ADC error
- **Cause:** no Application Default Credentials in the runtime context (common in scheduled contexts).
- **Resolve:** run `gcloud auth application-default login` for local dev, or attach an identity /
  Workload Identity in cloud, or point `--credentials` at a secured credential. **Never** commit a key
  to fix this.

## Quota, throttling & performance

### HTTP 429 `rateLimitExceeded` / `userRateLimitExceeded`
- **Cause:** exceeding per-project or per-user API quota, often on large Directory/Drive enumerations.
- **Resolve:** the tools already retry with exponential backoff (`--max-retries`); for sustained load,
  reduce concurrency, request a quota increase for `Automation Project – Workspace – Core`, or schedule
  large reports off-peak. Keep automation in its own project so its quota is isolated.

### HTTP 500 / 503 (transient)
- **Cause:** transient Google-side errors.
- **Resolve:** covered by the built-in backoff; if persistent, retry later and check Google Workspace
  status.

### Report runs slowly / times out on a large tenant
- **Cause:** enumerating all users/files without paging efficiently.
- **Resolve:** the tools paginate (500 users / 100 files per page); scope the report (e.g. by OU or a
  narrower Drive query) for the pilot, and run full-fleet reports on a schedule rather than interactively.

## Reports API specifics

### Login/admin events are missing or delayed
- **Cause:** Reports API activity events surface with **latency that varies by application/event type**.
- **Resolve:** treat reports as point-in-time evidence; widen `--days`, and **verify the current latency
  for your event types** in Google's documentation before concluding an event "didn't happen".

### `Audit Report – Login – Validate` returns empty
- **Cause:** wrong `applicationName`, too-short look-back, or the subject lacks reports privilege.
- **Resolve:** confirm `--report login`, increase `--days`, and confirm the impersonation subject can
  read reports (see `access_denied` above).

## Drive sharing report

### `Sharing Report – External – Validate` misses shared-drive files or over-/under-reports external
- **Cause:** missing `includeItemsFromAllDrives` / `supportsAllDrives`, or the domain comparison is off.
- **Resolve:** the tool sets the all-drives flags and compares each permission's domain/address against
  `--domain`; confirm `--domain` is your **primary** domain and re-check. `anyone` links and other-domain
  users/domains are the external grants flagged.

## Provisioning

### Dry-run and apply plans differ / a NOOP user shows a change (Gate 4-B fails)
- **Cause:** the desired-state CSV has a value that never matches (whitespace, case, boolean format), so
  the tool always sees a diff.
- **Resolve:** normalize the CSV (trim, consistent `true/false`, exact `orgUnitPath`); the tool lowercases
  emails and parses common boolean spellings — align the input to those.

### `CREATE` action raised an error refusing to invent a password
- **Cause:** the desired-state CSV references a user who does not exist; the tool intentionally refuses to
  fabricate account-creation credentials.
- **Resolve:** create the account through your onboarding process (which sets the initial password per
  policy), then re-run the tool to reconcile OU/attributes idempotently.

### Applied a wrong change — need to roll back
- **Cause:** an incorrect desired-state input was applied.
- **Resolve:** run `gwsdk_provision_users.py --revert <change-log.json>` (dry-run first, then `--apply`)
  to restore prior values from the reversible change log written by the apply run.

## Scheduling

### Scheduled report produced nothing (Gate 6-A fails)
- **Cause:** the scheduled context lacks ADC, the Python path is wrong, or the output directory is not
  writable.
- **Resolve:** confirm the scheduled account resolves ADC (or a secured credential), use absolute paths
  for the interpreter and `--out`, and check the tool's exit code/log. Re-render the entry with
  `gwsdk_schedule_config_helper.py` and confirm the minimal scope is on the DWD grant.
