# 7. Best Practices — Source-Code & IP Protection DLP (Microsoft Purview)

- **Test mode first; enforce deliberately.** The single most important discipline: create the policy in
  **test mode**, review what it *would* match and block across channels on real developer activity, tune
  it, and enforce only after approval. Enforcing an untuned code/IP policy blocks legitimate development
  and erodes trust fast.
- **Detect on content, not extension.** Renaming a file or pasting a snippet defeats extension rules. Lead
  with the **Source Code trainable classifier** and custom IP types so detection follows what the content
  *is*, wherever it goes.
- **What is protected IP is a security/legal determination.** The classifier plus custom IP types come from
  security/IP/legal — which code-names, markings, and identifiers matter. Configure the conditions they
  specify; capture the determinations and approvers in `Source-Code DLP – Map`.
- **Close the endpoint gap where you can.** Email and SharePoint DLP don't see a USB copy or a browser
  upload — Endpoint DLP does. Where E5/onboarding allows, include the endpoint channel; where it doesn't,
  scope to email/collaboration and record endpoint coverage as **deferred** rather than pretending it's
  covered.
- **Except approved developer egress explicitly.** Build systems, approved repositories, CI/CD, and
  sanctioned partner sharing are legitimate egress. Except them deliberately so protection lands on
  unsanctioned exfiltration, not on the daily workflow.
- **Tune the classifier confidence to your false-positive tolerance.** Trainable classifiers are
  probabilistic. Use the test-mode pilot to find the confidence and conditions that catch real code/IP
  without flagging comments, config, or documentation.
- **Pilot on a developer ring first.** Prove the policy on `Source-Code DLP – Pilot Ring – Stage1` — real
  developers/devices — before scoping to all engineering. Match behavior across channels is easier to
  reason about on a bounded ring.
- **Use policy tips to teach.** A tip at the moment of egress ("this looks like source code — external
  sharing is restricted") prevents mistakes and trains developers. Design the tip text deliberately; it's
  the most visible part of the policy.
- **Coordinate with, don't replace, developer-platform security.** DLP governs egress through M365 and
  endpoints; it doesn't secure the Git server or scan repos for secrets. Deploy them together and keep each
  doing its own job.
- **Keep automation safe-by-default and secret-free.** Run discovery, validation, and reporting read-only;
  gate every write behind `-WhatIf` → `-Commit`; enforcement behind its own explicit `-Action Enforce`.
  Sign in interactively; no credentials or secrets in a script or a document.
- **Re-report and re-tune on a schedule.** New projects, code-names, and egress patterns appear constantly.
  Re-run `DLPCODE-Report.ps1` and review matches periodically so `Source-Code DLP – Coverage Report` stays
  a live evidence artifact and the policy stays accurate.
- **Keep determinations with their owners.** The solution configures and evidences code/IP DLP; what is
  protected IP, which egress is acceptable, and any legal obligation are determinations for security, IP,
  and legal. Keep that separation explicit.
