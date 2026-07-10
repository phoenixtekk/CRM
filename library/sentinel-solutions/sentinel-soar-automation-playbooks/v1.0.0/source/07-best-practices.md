# 7. Best Practices — Microsoft Sentinel SOAR: Automation Rules & Playbooks (Logic Apps)

Field-proven guidance for keeping the SOAR layer safe, cheap, and maintainable.

## Keep response actions simulate-first and approval-gated — always

- Every disruptive action (disable user, isolate device, block IP) stays behind **both** a human approval **and** a `SimulateMode` dry run. Move an action to enforced only for a specific, well-understood scenario, one at a time, with change approval.
- Never wire the response playbook into an automation rule that runs on incident creation during the pilot. Containment stays analyst-triggered until you have proven the scenario.
- Grant the response playbook's managed identity the enforced-action permission **only when** you enable that action — not before. A simulate-only playbook needs no containment rights.

## Least-privilege identities, no stored secrets

- Prefer a **system-assigned managed identity** on every playbook over stored connector credentials. Grant only Microsoft Sentinel Responder for incident updates, plus the single permission each enforced action needs.
- Scope role assignments at the resource group or workspace, not the subscription. Review them each quarter and remove anything unused.
- For connectors that still need an account (some Teams/Outlook/ITSM connectors), use a dedicated low-privilege service account, not a person's credentials.

## Scope automation rules narrowly, then widen

- Start with one analytics rule or one severity. A too-broad rule that runs playbooks on every incident is both a cost and a noise risk.
- Use automation-rule **order/priority** deliberately so triage (assign/tag) happens before playbooks, and so rules do not conflict.
- Add an expiration date to pilot automation rules so they cannot outlive the pilot unnoticed.

## Design playbooks to fail safe and be observable

- Put enrichment and notification in **separate** playbooks so one failing connector does not block the others.
- Add error handling (`Configure run after`) so a failed enrichment still posts a "enrichment unavailable" comment rather than silently dying.
- Always write an incident comment recording what each playbook did — enrichment, ticket number, notification sent, simulate/enforce decision, and (for response) the approver. The incident becomes its own audit trail.

## Watch cost and run volume

- Logic Apps (Consumption) bill per action execution; a chatty enrichment playbook on a high-volume rule adds up. Review `SENTSOAR-Report.ps1` run counts and trim actions or narrow scope.
- Prefer a few well-built playbooks over many overlapping ones — fewer runs, less to maintain.

## Version and back up your playbooks

- Export each Logic App's ARM/template (or keep it in source control) so a playbook can be rebuilt or promoted (Pilot → Production) cleanly.
- Rename on promotion (`... - Pilot` → `... - Production`) and keep the pilot copy until the production one is proven.

## Where to go next

- **Sentinel Analytics Rules & MITRE ATT&CK Coverage** — build the detections that create the incidents this SOAR layer acts on, and map coverage to ATT&CK.
- **SOC Onboarding — Sentinel & Defender XDR** — unify incidents across Sentinel and Defender so your playbooks act on a single queue.
- **Sentinel Cost & Data-Tier Optimization** — keep the ingestion feeding these detections lean so the whole SIEM/SOAR stack stays affordable.
- **Deploy Microsoft Sentinel — Workspace & Connectors** — if you still need to stand up or extend the underlying data sources.
