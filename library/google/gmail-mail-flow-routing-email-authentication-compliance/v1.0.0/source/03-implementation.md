# Implementation

Configure the Gmail mail plane following the house model — **Assess → Design → Configure → Pilot →
Validate → Expand** — **pilot-first**, with a **pass/fail gate** and a **documented rollback** at
every production change. All console paths are under **admin.google.com**. Every artifact is named
`<Purpose> – <Scope> – <Stage>` and that exact name is reused in testing, troubleshooting, and the
scripts.

> **High-impact warning.** Routing, MX/DNS, DMARC advancement, and cutover can break mail for the
> whole organization. Do each in the **pilot** OU first, lower DNS **TTLs** ahead of any record
> change, and never advance a stage until its gate passes.

---

## Stage A — Assess (read-only)

1. **Baseline the current mail flow.** Run the discovery script for every domain:
   `python mailplane_dns_audit.py --domains-file domains.txt --out baseline` — it records current
   **MX, SPF, DKIM (`google._domainkey` and any legacy selectors), and DMARC** and flags the SPF
   10-lookup limit. Save the output as the **`Mailplane Baseline – All Domains – Assess`** artifact.
2. **Enumerate routing surface.** Run `mailplane_config_export.py --section routing --out routing`
   (read-only Admin SDK) to export existing **Hosts, Routes, and default routing** so nothing is
   overwritten blindly.
3. **Start DMARC monitoring if not already present.** If any domain lacks DMARC, publish a
   monitor-only record now so evidence starts accruing while you design (see Stage C, step C1 — begin
   at `p=none`). Name it `DMARC – <domain> – Monitor`.
4. **Gate A (Assess → Design):** baseline captured for **every** domain; RUA reports arriving at the
   monitored mailbox; legitimate-sender inventory started. **Fail →** resolve DNS/monitoring access
   before proceeding.

## Stage B — Design

1. **Choose the coexistence pattern per domain** — **split** or **dual** delivery — the
   **authoritative** system, and the **retirement trigger** for dual delivery. Record as
   **`Coexistence Design – <domain> – Design`**.
2. **Design routing & hosts.** Define each **Host** (legacy inbound smart host, archive/journal
   connector, partner relay) and each **Route** with its name, match, and action. Reserve names now:
   e.g. `Host – Legacy Smart Host – Prod`, `Route – Archive Connector – Prod`,
   `Route – Split Delivery to Legacy – Prod`.
3. **Design authentication targets.** For each domain define the intended **SPF** record (all
   legitimate senders within the 10-lookup limit), confirm **DKIM** will use the Google
   2048-bit key with selector `google`, and set the **DMARC end-state** (`p=reject`, `rua=`, optional
   `ruf=`, `pct=` ramp). Record as `SPF – <domain> – Target`, `DKIM – <domain> – Target`,
   `DMARC – <domain> – Enforce`.
4. **Design compliance/routing rules** from the policy definitions: name, scope (OU/domain), match,
   and action (route/modify/quarantine/reject) — e.g. `Content Compliance – Outbound Disclaimer – Pilot`,
   `Content Compliance – TLS Required Partner – Pilot`, `Content Compliance – Attachment Quarantine – Pilot`.
   Reconcile any overlap with existing DLP rules.
5. **Gate B (Design → Configure):** every route/host/record/rule is named and approved; rollbacks and
   TTL reductions are written into the change ticket.

## Stage C — Configure (in the pilot OU / pilot domain first)

### C1 — Email authentication

1. **DKIM.** **Apps → Google Workspace → Gmail → Authenticate email** → select the domain →
   **Generate new record** (2048-bit, selector `google`) → publish the provided
   `google._domainkey.<domain>` TXT (CNAME/TXT per your DNS) → return and **Start authentication**.
   Confirm with `mailauth_validate.py --domain <domain> --check dkim`. Artifact: `DKIM – <domain> – Prod`.
2. **SPF.** Publish the designed SPF TXT for the domain (typically `v=spf1 include:_spf.google.com
   ~all` plus each legitimate sender's include, kept **≤10 lookups**). Verify with
   `mailauth_validate.py --domain <domain> --check spf`. Artifact: `SPF – <domain> – Prod`.
3. **DMARC — monitor.** Publish `_dmarc.<domain>` TXT `v=DMARC1; p=none; rua=mailto:<rua>; adkim=r;
   aspf=r` (start relaxed). Artifact: `DMARC – <domain> – Monitor`. **Do not advance yet** — collect
   at least one to two weeks of aggregate reports and reconcile senders with `dmarc_rua_analyzer.py`.

### C2 — Routing & hosts (coexistence)

4. **Add hosts.** **Gmail → Hosts → Add route** → create each designed **Host** (legacy smart host,
   archive connector, partner relay). Name each exactly as designed (`Host – Legacy Smart Host – Prod`).
5. **Configure inbound gateway** (if a gateway/relay fronts Google): **Gmail → Spam, phishing, and
   malware → Inbound gateway** → add the gateway IPs so Gmail trusts and correctly evaluates SPF for
   relayed mail.
6. **Configure split or dual delivery.** **Gmail → Routing → Routing** → add the rule for the chosen
   pattern:
   - **Split:** route mail for legacy-hosted mailboxes to `Host – Legacy Smart Host – Prod`
     (`Route – Split Delivery to Legacy – Prod`), Google authoritative for its own mailboxes.
   - **Dual:** deliver to Google **and** add a copy/recipient to the legacy host
     (`Route – Dual Delivery Copy – Prod`) — mark it **temporary**, tie it to the retirement trigger.
7. **Outbound gateway / smart host** (if outbound must egress via a relay): **Gmail → Routing →
   Outbound gateway** → set the smart host. Artifact: `Host – Outbound Smart Host – Prod`.

### C3 — Content compliance & safety

8. **Content-compliance & routing rules.** **Gmail → Compliance → Content compliance** (and
   **Routing** / **Objectionable content** as needed) → create each designed rule scoped to the
   **pilot OU** first, using the exact names (`Content Compliance – Outbound Disclaimer – Pilot`,
   `Content Compliance – TLS Required Partner – Pilot`, `Content Compliance – Attachment Quarantine – Pilot`).
   For TLS-required, set **Require secure transport (TLS)** on the route.
9. **Spam, phishing & attachments.** **Gmail → Spam, phishing, and malware** → enable enhanced
   pre-delivery scanning and the attachment/anti-phishing/anti-malware safety toggles for the pilot
   OU; add any **approved/blocked senders** lists. Artifact: `Safety – Pilot OU – Pilot`.
10. **Export the configured state** for the change record: `mailplane_config_export.py --section all
    --out configured` — the export is the reviewable artifact and the rollback reference.

## Stage D — Pilot & Validate (gate before Expand)

1. Send the **validation test matrix** (see `05-testing.md`) from and to the pilot OU: internal,
   inbound external, outbound external, a disclaimer-triggering message, a TLS-partner message, and a
   quarantine-triggering attachment.
2. Confirm authentication with `mailauth_validate.py --domain <domain> --check all` and inspect
   delivery with **Email Log Search**.
3. **Advance DMARC to quarantine — only if** `dmarc_rua_analyzer.py` shows **≥ ~98% of legitimate
   volume aligned** and every source is accounted for: update `_dmarc.<domain>` to
   `p=quarantine; pct=100` (optionally ramp `pct=25→50→100`). Artifact: `DMARC – <domain> – Quarantine`.
4. **Gate D (pilot pass/fail):**
   - **PASS:** all six test flows behave as designed; authentication passes; rules route/modify/
     quarantine correctly; no legitimate mail lost; DMARC aggregate alignment ≥ target.
   - **FAIL / ROLLBACK:** revert the offending route/rule to its exported prior state; roll DMARC
     back to the previous `p=` value (DNS TTL was pre-lowered); do **not** expand.

## Stage E — Expand

1. Widen each validated route, rule, and safety setting from the pilot OU to the **remaining OUs /
   fleet**, renaming the stage token `Pilot → Prod` (e.g. `Content Compliance – Outbound Disclaimer – Prod`).
2. **Advance DMARC to reject** once fleet-wide alignment holds at the quarantine target with no
   collateral: `_dmarc.<domain>` → `p=reject; pct=100`. Artifact: `DMARC – <domain> – Enforce`.
3. **Retire dual delivery** at the recorded trigger (cutover complete): remove
   `Route – Dual Delivery Copy – Prod` and update MX to the final authoritative path. Re-run
   `mailplane_dns_audit.py` to confirm the final state.
4. **Restore DNS TTLs** to normal values and archive the final `mailplane_config_export.py` output as
   the steady-state baseline.

## Rollback (any production change)

- **DNS/DMARC/MX:** re-publish the exact prior record captured in the Stage A/C exports; because TTLs
  were lowered pre-change, propagation is fast. DMARC steps down one policy level at a time
  (`reject → quarantine → none`).
- **Routing/compliance rule:** disable or restore the rule to its exported prior state
  (`configured`/`baseline` export). Rules are scoped to OUs, so a rollback is limited to that OU.
- **Cutover:** if a wave's cutover fails, re-point the affected mailboxes' delivery back to the
  authoritative legacy host per the recorded split/dual design and re-validate before retrying.
