# Testing & Validation

Run these in the **pilot OU** before Gate D and again after **Expand**. Each procedure states the
**expected pass** and the **fail signal**. Use the exact artifact names from `03-implementation.md`.
The included Python tools are read-only/report-only and are safe to run repeatedly.

---

## T1 — DNS & authentication records present and correct

- **How:** `python mailplane_dns_audit.py --domains-file domains.txt --out validate`
- **Pass:** every domain shows the intended **MX**, an **SPF** record within the **10-lookup** limit,
  a resolving **DKIM** `google._domainkey` record, and a **DMARC** record at the expected policy
  level for the current stage.
- **Fail:** missing/duplicate SPF, SPF > 10 lookups, DKIM not resolving, or DMARC policy not at the
  stage's expected value. Fix in DNS / Admin console before advancing.

## T2 — SPF / DKIM / DMARC evaluation on real mail

- **How:** `python mailauth_validate.py --domain <domain> --check all`, then send a test message from
  the domain to an external address you control and inspect **Authentication-Results** /
  original-message headers.
- **Pass:** headers show `spf=pass`, `dkim=pass`, and `dmarc=pass` with **alignment** (the DKIM `d=`
  and/or SPF domain aligns with the From domain).
- **Fail:** any of `spf/dkim/dmarc=fail` or `dmarc=... (p=none)` misalignment. Reconcile the sending
  host against the SPF include list and DKIM signing before advancing DMARC.

## T3 — DMARC aggregate reports show legitimate senders aligned

- **How:** collect RUA reports at the monitored mailbox for the monitoring window, then
  `python dmarc_rua_analyzer.py --input reports/ --out rua-summary`
- **Pass:** **≥ ~98%** of legitimate volume passes DMARC (aligned), and **every** sending source in
  the report is a known, approved sender from the inventory.
- **Fail:** legitimate sources failing alignment, or an **unknown** source sending volume. Do **not**
  advance to `quarantine`/`reject` until resolved (add the sender to SPF/DKIM or investigate spoofing).

## T4 — Inbound & outbound routing behaves as designed

- **How:** send the six-flow matrix — internal, inbound external, outbound external, disclaimer
  trigger, TLS-partner, quarantine-attachment — and trace each in **Gmail → Email Log Search**.
- **Pass:** each message follows the **named route** (`Route – …`), reaches the correct system under
  the chosen split/dual pattern, and no message loops or double-delivers unexpectedly.
- **Fail:** mail delivered to the wrong system, dropped, or duplicated (beyond intended dual
  delivery). Correct the route ordering/match and re-test.

## T5 — Content-compliance rules fire correctly

- **How:** send messages that should and should **not** trigger each rule
  (`Content Compliance – Outbound Disclaimer – Pilot`, `… – TLS Required Partner – Pilot`,
  `… – Attachment Quarantine – Pilot`).
- **Pass:** triggering messages are modified/routed/quarantined as designed; non-triggering messages
  pass untouched; the TLS-partner message is delivered only over TLS.
- **Fail:** false positives (legitimate mail quarantined/rejected) or false negatives (policy mail
  not caught). Tighten/loosen the match; verify rule order; reconcile with DLP overlap.

## T6 — Spam / attachment safety settings active

- **How:** send an EICAR-style test attachment and a known-benign attachment to a pilot mailbox;
  confirm approved/blocked sender behavior.
- **Pass:** malicious/blocked content is caught per the `Safety – Pilot OU – Pilot` settings; benign
  mail from approved senders is delivered.
- **Fail:** malicious content delivered or benign approved-sender mail blocked. Adjust the safety
  toggles and lists for the OU.

## T7 — Config export matches intended state (change evidence)

- **How:** `python mailplane_config_export.py --section all --out validate` and diff against the
  approved design.
- **Pass:** exported routes, hosts, and rules match the named, approved artifacts exactly.
- **Fail:** drift (an unnamed or unexpected route/rule). Investigate the change and reconcile before
  declaring the gate passed.

## T8 — Rollback rehearsal

- **How:** in the pilot OU, disable a test rule / step DMARC down one level, confirm reversion, then
  restore.
- **Pass:** the prior state is restored quickly (TTLs were pre-lowered) and mail flow returns to
  baseline. This proves the rollback documented in the change ticket actually works.
- **Fail:** reversion does not restore prior behavior — fix the rollback procedure **before** any
  fleet-wide change.

---

**Gate D summary:** T1–T6 pass in the pilot OU and T3 shows alignment ≥ target **before** advancing
DMARC or expanding fleet-wide. After Expand, re-run T1–T3 and T7 to confirm the steady state.
