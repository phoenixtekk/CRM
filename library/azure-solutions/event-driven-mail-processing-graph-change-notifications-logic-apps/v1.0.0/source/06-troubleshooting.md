# 6. Troubleshooting Guide — Event-Driven Mail Processing with Microsoft Graph Change Notifications

Use `GRAPHSUB-Discovery.ps1` / `GRAPHSUB-Validate.ps1` for readiness, `GRAPHSUB-Report.ps1` for the subscription inventory + expiry, `GRAPHSUB-Test-Notification.ps1` for coverage evidence, and `GRAPHSUB-Renew.ps1` (defaults to `-WhatIf`) to extend or recreate a subscription. Objects are referenced by their names — `wf-NotificationReceiver`, `wf-SubscriptionRenewal`, `svc-mailevents@contoso.com`, `MailEvents-ClientState`. **Every Graph limit/name below is version-specific — verify against current Microsoft documentation before relying on it.**

## A. Subscription creation fails
| Symptom | Cause | Remediation |
|---|---|---|
| `New-MgSubscription` returns "subscription validation request failed" / "endpoint validation failed" | The receiver did not echo the `validationToken` correctly or in time | See section B — fix the handshake branch, then recreate |
| "expirationDateTime is too far in the future" (or similar) | Requested lifetime exceeds Graph's current max for a mail resource | Lower `expirationDateTime` to within the allowed window (verify the current max with Microsoft); `GRAPHSUB-Renew.ps1` uses a conservative default |
| "resource is invalid / not supported" | The `resource` string is malformed or that resource/`changeType` is not supported | Use `users/svc-mailevents@contoso.com/messages` with `changeType=created`; verify supported resources/changeTypes with Microsoft |
| 403 / insufficient privileges creating the subscription | The identity creating the subscription lacks the required permission, or mailbox scoping denies it | Confirm the app permission is granted + consented (Step 2) and scoping grants the target mailbox (Step 3 / product #4); re-run `GRAPHSUB-Validate.ps1` |

## B. Validation handshake fails
- **The handshake must be first and fast.** `wf-NotificationReceiver` must, before anything else, detect the `validationToken` query parameter and return it as the response body with `Content-Type: text/plain` and HTTP 200, within Graph's timeout (verify the exact timeout with Microsoft).
- **Common mistakes:** returning JSON instead of `text/plain`; not URL-decoding the token; the workflow doing slow work (Key Vault reads, loops) *before* responding; the endpoint not publicly reachable.
- **Check:** from an external network, `curl -i "https://<wf-NotificationReceiver URL>&validationToken=test123"` should return `200` with body `test123` and `Content-Type: text/plain`.
- **Fix:** move the validation branch to the very top of the workflow; return the raw token; then recreate the subscription.

## C. Notifications stop arriving (expired subscription)
| Symptom | Cause | Remediation |
|---|---|---|
| Mail arrives but `wf-NotificationReceiver` no longer runs | The subscription **expired** and was not renewed | Run `GRAPHSUB-Report.ps1` (state = EXPIRED) → `GRAPHSUB-Renew.ps1 -Mailbox svc-mailevents@contoso.com -Execute` (or `-RecreateIfMissing`); then run the catch-up read to recover the gap |
| Renewal workflow errors | `wf-SubscriptionRenewal` cadence too close to expiry, or the identity lost permission | Shorten the recurrence to well within the max lifetime (verify); confirm the MI still holds the permission (`GRAPHSUB-Validate.ps1`) |
| Subscription silently disappears | Deleted, tenant policy, or lifecycle event | Have `wf-SubscriptionRenewal` **recreate** on missing (falls through to `New-MgSubscription`); subscribe to lifecycle notifications if supported (verify) |
| Mail was missed during the gap | No subscription while messages arrived | Run `GRAPHSUB-Test-Notification.ps1` to see messages that arrived while lapsed; the **catch-up read** (from the watermark) reprocesses them once |

## D. 403 when reading the changed message
- **Symptom:** the notification fires and `wf-NotificationReceiver` runs, but the `GET /users/svc-mailevents@contoso.com/messages/{id}` returns **403 Forbidden**.
- **Cause 1 — permission not granted/consented:** the managed identity does not hold the application permission (e.g. `Mail.Read`), or admin consent was not applied. **Check:** `GRAPHSUB-Validate.ps1`. **Fix:** Implementation Step 2.
- **Cause 2 — scoping denies the mailbox:** the Application Access Policy / Graph RBAC scope excludes `svc-mailevents@contoso.com`. **Check:** `Test-ApplicationAccessPolicy -AppId '<mi app id>' -Identity svc-mailevents@contoso.com` should return **Granted**. **Fix:** correct the scope group / RBAC assignment (product #4). Access-policy changes can take time to propagate.
- **Cause 3 — wrong identity/audience:** the HTTP action is not authenticating as the managed identity, or the token audience is not `https://graph.microsoft.com` (or the national-cloud equivalent). **Fix:** set Authentication = Managed identity with the correct audience.

## E. Duplicate processing
| Symptom | Cause | Remediation |
|---|---|---|
| The same message is processed more than once | Notifications are at-least-once; retries and overlapping catch-up reads re-deliver | Enforce idempotency: key on the message **id** (+ `changeKey`/internet message id), check the dedup store before processing, skip if seen (Implementation Step 5.6 / 8.1) |
| Duplicates spike after failures | Receiver returned non-2xx, so Graph retried | Acknowledge with **202 quickly**, then process asynchronously; make downstream actions safe to repeat |
| Catch-up read reprocesses live-notified messages | Watermark overlaps already-processed items | The dedup store must be shared between the receiver and the catch-up read so both consult the same seen-ids |

## F. clientState mismatch
- **Symptom (legitimate):** `wf-NotificationReceiver` logs "clientState mismatch — dropped" for real notifications. **Cause:** the value in `MailEvents-ClientState` no longer matches the `clientState` set on the subscription (e.g. the secret was rotated but the subscription was not recreated). **Fix:** align them — recreate the subscription with the current secret value (`GRAPHSUB-Renew.ps1 -RecreateIfMissing …`) or update the stored secret to match.
- **Symptom (expected/good):** a forged or stray POST is dropped for clientState mismatch. **This is correct** — the public endpoint is doing its job. Do not disable the check.
- **Never** process a notification whose `clientState` does not match; that is the only thing standing between your public URL and an attacker driving the workflow.

## G. Scripts — Microsoft.Graph connection and matching
- **Connect with the right scopes.** Interactive runs need delegated scopes: `Subscription.Read.All` (discovery/report), `Application.Read.All` + `Directory.Read.All` (permission checks), `Subscription.ReadWrite` (renew), `Mail.Read` (notification-evidence). Each script's header lists its scopes. **Verify the exact scope names against current Microsoft documentation** — they can change.
- **Subscriptions are owned by their creator.** `Get-MgSubscription` returns subscriptions owned by the **identity you authenticate as**. Subscriptions created by the **managed identity** may **not** appear in an interactive delegated session — cross-check the Logic App run history, or authenticate as the MI. The scripts flag this rather than assume "no subscription = broken."
- **Exact-name matching.** Scripts resolve the managed identity by **display name** (`logic-mailevents-receiver-pilot`) or **Object ID**; pass `-ManagedIdentityObjectId` when display names are ambiguous. The Graph resource SP is matched by the stable AppId `00000003-0000-0000-c000-000000000000`, not a display name.
- **`-WhatIf` is the default state-changer safety.** Only `GRAPHSUB-Renew.ps1` changes state, and it **defaults to `-WhatIf`** — it prints what it would do and changes nothing until you pass `-Execute`. Preview first, always.
- **National clouds.** Pass `-Environment USGov` / `USGovDoD` for sovereign tenants — the default `Global` targets commercial endpoints. **Verify the correct environment value and endpoints against current Microsoft documentation.**

## H. When to escalate
If the subscription creates and validates, the identity holds the scoped permission (`GRAPHSUB-Validate.ps1` all PASS), `clientState` matches, and notifications still do not arrive for new mail after confirming an active subscription with `GRAPHSUB-Report.ps1`, collect the `wf-NotificationReceiver` run history, the subscription id/expiry, and the `GRAPHSUB-Report.ps1` CSV, and open a Microsoft support case.
