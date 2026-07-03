# Executive Summary — Continuous Compliance Monitoring & Audit-Evidence Automation (Government / GCC High)

## The problem

Passing a CIS or STIG baseline **once** is not the same as **proving** you are still compliant months
later. In a **US sovereign-cloud (GCC High / DoD)** tenant this is not optional housekeeping — it is
how you *keep* an authorization. Endpoints drift — a policy is edited, an exclusion is added, a device
enrolls without the baseline — and when an assessor asks for evidence under FedRAMP continuous
monitoring, teams scramble to gather it by hand. Point-in-time compliance and manual evidence
collection are a standing audit risk.

Worse, a Gov tenant is **not the Commercial portal with a different sign-in**. The admin portals and
service endpoints are different sovereign-cloud hosts (`intune.microsoft.us`, `entra.microsoft.us`,
`graph.microsoft.us`), and several Commercial reporting/remediation conveniences are **not available**
in GCC High. Commercial runbooks silently query the wrong cloud or call features that aren't there.

## The solution

This is the **Government (GCC High)** edition: a **repeatable operational method — with PowerShell
scripts you keep** — to continuously monitor baseline **drift** and automate **audit evidence** for
Intune + Entra endpoints, using the **correct US Gov portals and endpoints**, with the
**Commercial-vs-GCC High parity gaps called out**. It follows a simple, provable cycle:

**Baseline → Measure → Detect drift → Evidence / POA&M → Remediate / track.**

The scripts read the live state of your CIS/STIG controls from **Microsoft Graph US Gov**
(`graph.microsoft.us`, read-only), compare it to your approved baseline, flag every control that has
drifted, and export **dated audit evidence** plus a **POA&M-ready gap list** — the exact artifacts
FedRAMP continuous monitoring and NIST 800-53 **CA-5** expect. Drifted settings can then be safely
re-applied (preview first) and re-measured to prove closure.

This is an **operations product**, distinct from a one-time baseline build. The build creates the
policies; this solution proves they stay true and produces the paperwork on demand — from inside your
Gov boundary.

## What is included

- A complete documentation set: Overview (with a **Commercial vs GCC High** section), Requirements,
  Implementation (Gov portals + inline parity caveats), Testing (pass/fail gates, including a
  **correct-cloud** gate), Troubleshooting (GCC-High gotchas), Best Practices, and Deliverables — plus
  a cited **GCC High parity notes** reference.
- **Five PowerShell scripts** (Microsoft Graph SDK, **US Gov endpoints**): control-state discovery,
  per-device baseline conformance, an audit-evidence + drift/gap report (POA&M-ready), safe remediation
  (preview by default), and a target-group builder (preview by default).
- A phased rollout — **Assess → Configure → Pilot → Validate → Expand** — with pass/fail gates and a
  scheduled, in-boundary continuous-monitoring cadence.

## Business value

- **Prove compliance any day**, not just deployment day — for your GCC High / DoD authorization.
- **Detect drift automatically** before an assessor does.
- **Cut audit-prep effort** — evidence and POA&M gaps export on demand, correctly formatted for
  FedRAMP continuous monitoring.
- **Avoid the sovereign-cloud traps** — correct `.us` portals and US Gov Graph, with parity gaps
  (Power BI DWH connector, ServiceNow connector, update rings, BIOS/DFCI, Remote Help) handled up front.
- **Own the capability** — a method and scripts you reuse across audit cycles, at a fraction of ongoing
  consulting cost.

## Bottom line

Continuous, provable endpoint compliance on GCC High — drift detected and audit evidence exported on
demand, POA&M-ready, in the right cloud with parity gaps handled — proven on a pilot before you scale.
The specific CIS/STIG rule content is deferred to CIS and DISA; this solution delivers the precise
monitoring and evidence method on Intune + Entra in the US sovereign cloud.
