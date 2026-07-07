# Troubleshooting

Common failure modes when operationalizing Security Command Center (SCC), with resolutions. Names
in **bold** are the reference-design artifacts.

> **Verify your edition first.** Many "it's not working" symptoms are actually "that service/detector
> isn't in my edition." Before deep debugging, confirm the active edition and enabled services in
> **Security Command Center → Settings**, and confirm the exact `gcloud scc` subcommands with
> `--help` — the API surface varies by edition/version.

---

## No findings appear for a project or folder
- **Likely cause:** the posture/threat **service isn't enabled** for that scope, the project is out
  of SCC scope, or the finding is **muted** by **Posture Baseline – Corp – v1**.
- **Resolve:** Confirm the service is enabled in Settings for that scope; confirm the project is in
  the SCC-covered hierarchy; run `scripts/scc_posture_check.py` to spot an un-approved mute. Remember
  a fresh misconfiguration only surfaces after the **next scan** — wait the scan window.

## The `gcloud scc …` command is not recognized / flags differ
- **Likely cause:** the SCC command surface is **edition- and version-dependent**; the subcommand or
  flag differs in your tenant, or the SDK is outdated.
- **Resolve:** Run `gcloud components update`, then `gcloud scc --help` (and the subcommand's
  `--help`) to get the exact form for your edition. Adjust the step/tool argument accordingly — do
  not assume the form in this guide is identical to yours.

## Notification config created but no messages on the topic
- **Likely cause:** the SCC **notification service account lacks `roles/pubsub.publisher`** on
  **Finding Export Topic – SecOps – v1**, or the config's `--filter` excludes the findings, or the
  service-account address is wrong.
- **Resolve:** Run `scripts/scc_scope_config_helper.py` to check the publisher binding; the SCC
  notification service account is **per-org** — verify its exact address in the Console before
  binding. Confirm the config filter actually matches a live finding (e.g. loosen to
  `state="ACTIVE"` to test). Pull the subscription to confirm:
  `gcloud pubsub subscriptions pull … --auto-ack`.

## Messages on the topic but the SIEM isn't ingesting
- **Likely cause:** the **consumer subscription/connector** is misconfigured, the consumer service
  account lacks `roles/pubsub.subscriber`, or the **field mapping** doesn't match the SIEM's schema.
- **Resolve:** Confirm the subscription exists and the consumer identity has subscriber rights;
  re-check the ingestion contract (Requirements §5) and the SIEM connector against the **SIEM
  vendor's current docs**. Test with a manual pull to confirm the payload shape.

## Permission denied creating configs / listing findings
- **Likely cause:** the caller lacks the SCC role (`roles/securitycenter.admin` to configure,
  finding-editor/viewer to triage) at the **Organization**.
- **Resolve:** Confirm with `gcloud organizations get-iam-policy ORG_ID`; have an Organization
  Administrator grant the correct least-privilege SCC role to the operating group (Requirements §2).
  Also confirm you are authenticated to the right account (`gcloud auth list`) and that ADC is set
  for the Python tools.

## The finding queue is overwhelming (too much noise)
- **Likely cause:** a high-volume detector or unfiltered export is flooding the queue, so responders
  stop trusting it.
- **Resolve:** Identify the top categories with `scripts/scc_coverage_assessment.py`; fix the root
  cause where possible; **mute deliberately** (documented exception + owner + review date) via the
  setup tool; and tune the **export filter** so low-value findings don't reach the SIEM while
  remaining in SCC for audit. Prefer filtering the export over disabling detectors.

## A remediated finding stays ACTIVE
- **Likely cause:** the underlying resource wasn't actually fixed, the fix hasn't been re-scanned
  yet, or a different resource still violates the same detector.
- **Resolve:** Confirm the resource is genuinely compliant; wait for the next scan; check whether
  another resource under the same category is keeping the category "hot." SCC sets state to
  `INACTIVE` on the next scan after true remediation.

## Triage/SLA report shows wrong owners or SLA math
- **Likely cause:** the **ownership matrix** or **severity→SLA table** in **Triage Runbook –
  SecOps – v1** is stale or mismatched to finding fields.
- **Resolve:** Update the runbook `owners` match rules (resource/category substrings) and `sla_hours`;
  re-run `scripts/scc_triage_sla_report.py`. Findings that map to `unassigned` mean no rule matched —
  add a rule.

## `dry-run` looked fine but `--apply` failed
- **Likely cause:** a dependency the dry-run didn't execute (topic missing, API not enabled, IAM
  binding absent) blocks the real write.
- **Resolve:** Run `scripts/scc_scope_config_helper.py` to validate APIs, topic/subscription, and the
  publisher binding **before** `--apply`. Fix any FAIL, then re-run with `--apply` under change
  control.

## Rollback needed after an org-wide change caused a noise spike or issue
- **Resolve:** Per the Implementation rollback — delete/disable **Finding Notification – Org – v1** to
  stop the export stream (findings stay in SCC), delete mute configs to reverse mutes, and re-enable
  any service you disabled. No finding data is lost by these config reversals; record each change so
  it reverts cleanly.
