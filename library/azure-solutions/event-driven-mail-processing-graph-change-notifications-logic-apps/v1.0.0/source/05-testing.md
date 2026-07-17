# 5. Testing Guide — Event-Driven Mail Processing with Microsoft Graph Change Notifications

Run after the receiver and subscription are built (Implementation Steps 5–6), again after the renewal workflow (Step 7), and after each expansion. Objects are referenced by their names — `wf-NotificationReceiver`, `wf-SubscriptionRenewal`, `svc-mailevents@contoso.com`, `MailEvents-ClientState`. Each test is **PASS/FAIL**.

## Test 1 — Validation handshake succeeds (subscription creates)
**Do:** Create the subscription (Implementation Step 6) with `New-MgSubscription`, or re-run it. Watch `wf-NotificationReceiver` run history.
**Expected — PASS:** Graph calls the endpoint with a `validationToken`, the receiver echoes it back as `text/plain`/200, and `New-MgSubscription` **returns a subscription id and expirationDateTime**.
**FAIL:** Creation errors (e.g. "endpoint validation failed") — the handshake branch did not answer correctly or fast enough. See Troubleshooting A/B.

## Test 2 — A new message fires a notification
**Do:** Send an email to `svc-mailevents@contoso.com`. Watch `wf-NotificationReceiver` run history.
**Expected — PASS:** Within seconds a run is triggered by a Graph POST; the workflow reads the message via the managed identity and completes its processing for that message id.
**FAIL:** No run appears (subscription inactive/expired, notificationUrl wrong, or scoping/permission blocking the read) — run `GRAPHSUB-Validate.ps1` and see Troubleshooting C/D.

## Test 3 — clientState rejects a forged call
**Do:** From an external tool, POST a fake notification body to the `notificationUrl` with a **wrong or missing** `clientState`.
**Expected — PASS:** The receiver **discards** the call (no message read, no downstream processing); the run shows the clientState check failed and the notification was dropped.
**FAIL:** The workflow processes the forged call — the `clientState` comparison (Implementation Step 5.4) is missing or wrong. See Troubleshooting F.

## Test 4 — Renewal extends the subscription
**Do:** Run `wf-SubscriptionRenewal` manually (or wait for a scheduled run). Compare `expirationDateTime` before and after with `GRAPHSUB-Report.ps1`.
**Expected — PASS:** The subscription's `expirationDateTime` moves **forward** (extended within Graph's allowed window); the subscription id is unchanged. If it had already expired, a new subscription is created and re-validated.
**FAIL:** Expiration does not advance, or the run errors — check the identity's permission and the renewal cadence vs the current max lifetime (verify with Microsoft). See Troubleshooting C.

## Test 5 — Dedup prevents double-processing
**Do:** Cause the same message to be delivered twice (send during a brief receiver retry, or re-POST the same valid notification body), or run the catch-up read over a message already processed by a live notification.
**Expected — PASS:** The message is processed **once**; the second delivery is recognised by its message id in the dedup store and **skipped** (visible in run history).
**FAIL:** The message is processed twice — the idempotency check (Implementation Step 5.6 / Step 8.1) is missing or the dedup key is wrong.

## Test 6 — Catch-up recovers a missed event
**Do:** Temporarily delete the subscription (`Remove-MgSubscription`), send a message to `svc-mailevents@contoso.com` while there is no subscription, then run `wf-SubscriptionRenewal` (which recreates the subscription and runs the reconcile read).
**Expected — PASS:** The message sent during the gap is picked up by the **catch-up read** and processed once; the subscription is recreated and validated; the watermark advances.
**FAIL:** The gap message is never processed — the reconcile/watermark logic (Implementation Step 7.3) is missing or the watermark did not cover the gap.

## Test 7 — Least-privilege scoping holds
**Do:** `Test-ApplicationAccessPolicy -AppId '<mi app id>' -Identity svc-mailevents@contoso.com` and `-Identity someone-else@contoso.com`.
**Expected — PASS:** **Granted** for the target mailbox, **Denied** for the control mailbox — the app cannot read other mailboxes. (Depth in product #4.)
**FAIL:** The control mailbox returns Granted — scoping is not applied. See product #4.

---
## Pass/fail gate
| Gate | Requirement |
|---|---|
| **Receiver pass** | Tests 1–3 pass — handshake creates the subscription, a real message fires and is read, a forged call is rejected |
| **Durability pass** | Tests 4–6 pass — renewal extends, dedup blocks doubles, catch-up recovers a gap |
| **Security pass** | Test 7 passes — access is scoped to the one mailbox before expanding |
| **Expand pass** | Tests 1–2, 4, 7 pass for each additional mailbox before the next expansion |
