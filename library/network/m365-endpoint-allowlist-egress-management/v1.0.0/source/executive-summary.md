# Executive Summary

## The situation

Tight egress filtering — denying outbound internet traffic by default and allowing only explicit
destinations — is a required control in regulated and security-conscious environments. But Microsoft
365, Intune, Windows Autopilot, Microsoft Defender, and Microsoft Entra ID are cloud services: a
managed device must reach a **specific, Microsoft-published set of endpoints** to enroll, sync policy,
receive updates, and stay protected. When the allow-list misses even one required endpoint, the result
is not a clear error — it is **enrollment that stalls, policies that never sync, and updates that fail
silently**, with no obvious network cause. And because Microsoft changes the endpoint list regularly,
a list that was correct last quarter drifts out of date on its own.

## The solution

A repeatable operating method — plus five PowerShell scripts — to **administer the IP/Port/URL
allow-lists and proxy/firewall exceptions** for Microsoft's required endpoints, built around one
principle: **derive the required set live from Microsoft's published source, never hardcode it.**

The method runs as a lifecycle: **derive** the current required IP/Port/URL set from the Microsoft 365
IP/URL web service (for your tenant's instance) plus the documented Intune, Autopilot, and Defender
endpoints; **build** named allow-list entries and proxy exceptions; **validate** that every required
destination is actually reachable and that real workflows (enrollment, sync, update) succeed on a
**pilot**; **expand** to the fleet; and **keep current** with a scheduled drift check that flags added
or retired endpoints before they cause failures. It follows a staged model —
**Assess → Configure → Pilot → Validate → Expand** — with a pass/fail gate at every step.

## What is included

- **Solution, Requirements, and Implementation guides** — the why, the prerequisites (each with how to
  verify and how to implement if missing), and the exact ordered steps.
- **Five PowerShell scripts** — required-endpoint + filter-state discovery (with drift detection),
  per-endpoint reachability validation, an allow-list coverage/gap report, safe allow-list update
  generation (preview first), and a pilot target-group builder. The read-only scripts change nothing;
  the change-generating scripts preview by default.
- **Testing and Troubleshooting guides** — pass/fail gates (endpoint reachable; enrollment, sync, and
  update succeed) and a symptom-to-missing-endpoint map.
- **Best Practices** — change control and drift review to keep the list healthy.

## The outcome

Cloud management that works reliably through strict egress filtering: the correct IP/Port/URL
allow-lists and proxy exceptions, derived from Microsoft's live published set, validated on a pilot,
and kept current — delivered as a repeatable method and scripts you keep and reuse, at a fraction of
the cost of an outside engagement.

## Important notes

- **Vendor-neutral on the proxy/firewall device** — the method specifies what to allow and how to name
  it; the specific console steps are deferred to that vendor's documentation.
- **No hardcoded Microsoft IP addresses** — the required set is always derived live, because
  Microsoft's endpoints change over time.
