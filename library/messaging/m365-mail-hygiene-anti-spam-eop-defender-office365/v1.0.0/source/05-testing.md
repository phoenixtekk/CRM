# Testing & Validation

Run these against the **pilot scope** before expanding (Stage 5). Each test states the procedure and
the **expected pass/fail** result. Use only safe test artifacts (GTUBE, EICAR) — **never real
malware**. Send from a controlled external address into a test mailbox inside `Hygiene-Pilot`.

> The provided **`Test-MailHygienePolicy.ps1`** validation script automates the read-side checks
> (policy presence/scope, quarantine action, TABL entries, authentication posture) and summarizes
> pass/fail. Message-injection tests below are performed by actually sending mail.

---

## T1 — Anti-spam verdict (GTUBE)

- **Procedure:** Send a message from the external test sender to a pilot mailbox with the standard
  **GTUBE** spam-test string as the body.
- **Expected pass:** The message is treated as **high-confidence spam** — quarantined (or moved to
  Junk, per your anti-spam action). It appears in quarantine and/or the message trace shows the spam
  verdict.
- **Fail:** Message lands in the Inbox untouched → check the anti-spam policy scope, priority, and
  any lingering `SCL -1` transport rule (Troubleshooting T-A).

## T2 — Anti-malware (EICAR)

- **Procedure:** Send a message with the **EICAR** anti-malware test file attached (a benign
  industry-standard test file — not malware) to a pilot mailbox.
- **Expected pass:** The attachment/message is caught by anti-malware and **quarantined**; message
  trace shows the malware verdict. Recipient does not receive the file.
- **Fail:** File delivered → verify the anti-malware policy (or Standard preset) is scoped to the
  pilot and the common-attachments filter is enabled.

## T3 — Spoof / anti-phishing (unauthenticated spoof of your domain)

- **Procedure:** From the controlled external sender, send a message with a **From** address that
  spoofs one of your own accepted domains (unauthenticated), to a pilot mailbox.
- **Expected pass:** Spoof intelligence / anti-phishing marks it as spoof — quarantined or Junk with
  the composite-authentication (`compauth`) failure visible in headers. With DMARC `p=reject/quarantine`
  the honoring behavior applies.
- **Fail:** Delivered as legitimate → confirm SPF/DKIM/DMARC (Requirement #2), spoof intelligence is
  on, and no TABL allow or transport rule is whitelisting the sender.

## T4 — Bulk mail threshold (BCL)

- **Procedure:** Send/receive from a known bulk sender (e.g. a marketing newsletter you control) and
  observe the **bulk complaint level (BCL)** verdict.
- **Expected pass:** Legitimate bulk you want is **delivered**; unwanted bulk above the threshold is
  filtered. The BCL in headers matches your configured threshold behavior.
- **Fail:** Wanted bulk quarantined → tune the BCL threshold **up** from data, or add a specific TABL
  allow — do not disable bulk filtering.

## T5 — Safe Attachments (Defender for Office 365 only)

> **Skip if EOP-only.** Requires Defender for Office 365.

- **Procedure:** Send a message with a benign attachment to a pilot mailbox and observe detonation
  behavior; use Microsoft's documented Safe Attachments test guidance / a known test file.
- **Expected pass:** Safe Attachments processes the attachment (Dynamic Delivery: body arrives, then
  the attachment after scan). Detonation events are visible in the Defender portal.
- **Fail:** No Safe Attachments processing → confirm the license, the `Safe-Attach – Standard – Pilot`
  policy/preset scope, and the global ATP setting.

## T6 — Safe Links (Defender for Office 365 only)

> **Skip if EOP-only.** Requires Defender for Office 365.

- **Procedure:** Send a message containing a URL to a pilot mailbox; inspect the received message.
- **Expected pass:** The URL is **rewritten/wrapped** (Safe Links) and is checked at time of click;
  a known-malicious test URL is blocked at click.
- **Fail:** URL not rewritten → confirm the license and the `Safe-Links – Standard – Pilot`
  policy/preset scope and that URL rewrite is enabled.

## T7 — Quarantine notification & release

- **Procedure:** For a message quarantined in T1/T3, confirm the recipient receives a **quarantine
  notification** and can **request release** (per `Quarantine – Notify – Prod`). As admin, release a
  message.
- **Expected pass:** Notification delivered; recipient can request release; admin release delivers
  the message to the Inbox.
- **Fail:** No notification → verify quarantine notifications are enabled on the quarantine policy
  and the policy is assigned to the verdict's action.

## T8 — Tenant Allow/Block List behaves

- **Procedure:** Add a test **allow** for a specific sender and a test **block** for another in the
  TABL; send from each into a pilot mailbox.
- **Expected pass:** The allowed sender is delivered even if otherwise borderline; the blocked sender
  is blocked/quarantined. Remove the test entries after.
- **Fail:** Entry not honored → check the TABL entry type/scope and expiration.

## T9 — No legitimate mail lost (false-positive gate)

- **Procedure:** Over the pilot window, review the quarantine and the reporting script's
  false-positive analysis for any **legitimate business mail** that was quarantined.
- **Expected pass:** No legitimate business mail lost; any borderline case resolved by a specific
  TABL allow or a data-driven threshold tune — **not** by downgrading a filter.
- **Fail:** Legitimate mail quarantined and unresolved → treat as a Gate 4/5 failure; tune and
  re-validate before expanding.

---

**Overall validation gate:** T1–T4 and T7–T9 pass on every tenant; T5–T6 additionally pass where
Defender for Office 365 is licensed. Only then proceed to **Expand**.
