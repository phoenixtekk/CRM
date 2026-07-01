# 1. Solution Overview — CASB & Cloud App Control with Netskope

## What CASB is
A Cloud Access Security Broker (CASB) sits between your users and the cloud apps they use and gives
you three things you cannot get from a firewall alone: visibility into which cloud apps are used,
a risk score for each app, and granular control over what users can do inside those apps. Netskope
delivers CASB in two complementary modes — inline (proxying live traffic) and API (connecting
directly to the management plane of a sanctioned app) — so you can govern both data in motion and
data already at rest in the cloud.

## Why this matters
Most cloud usage is invisible to IT. Employees adopt apps on their own (shadow IT), and corporate
data flows into them with no policy, no logging, and no way to retract it. The traditional response —
block the category at the firewall — fails because it is all-or-nothing: it blocks the sanctioned app
alongside the risky one, drives users to workarounds, and still misses data movement inside an
allowed app. CASB replaces that blunt instrument with graduated control: allow the safe, restrict the
risky activity, coach the user toward the sanctioned alternative, and block only what truly warrants
it. The goal is to govern cloud usage without blocking the business.

## How Netskope CASB works
1. Inline CASB steers live web/cloud traffic through Netskope (via the SWG/steering already in place),
   so policy can see and act on the activity in real time — uploads, downloads, posts, shares.
2. API CASB connects out-of-band to a sanctioned app's API (for example a sanctioned file-storage or
   collaboration suite) to inspect and govern data already resident there — exposed shares, risky
   files, external collaborators — without being in the traffic path.
3. Cloud app discovery analyzes traffic and logs to surface every app in use, sanctioned or not, and
   assigns each a risk score (the Cloud Confidence Index / app risk rating).
4. Policy applies control levers per app and per activity, scoped to identity (users and groups from
   Entra ID).
5. Activity is logged and reported, feeding the app risk register and the usage/risk reports.

## Cloud app discovery and risk scoring (sanctioned vs shadow IT)
- Discovery distinguishes sanctioned apps (IT-approved, often API-connected) from unsanctioned /
  shadow-IT apps (in use but not approved).
- Each discovered app carries a risk score derived from its security, compliance, and data-handling
  attributes. The score drives the policy decision: sanction it, restrict it, coach away from it, or
  block it.
- The named output is the app risk register — All cloud apps – Discovery stage — a living inventory
  of discovered apps, their risk score, and the disposition decision.

## The control levers
- Allow — permit the app/activity (typically the sanctioned app).
- Restrict — permit the app but constrain specific activities (for example allow download, restrict
  upload of sensitive data).
- Coach — let the user proceed but present guidance steering them to the sanctioned alternative, or
  require a justification.
- Block — deny the app or activity outright (reserved for genuinely unacceptable risk).
- Activity controls — act on what the user does (upload, download, share, post, edit, login).
- Data-movement controls — act on the content being moved (used with DLP-style profiles to catch
  sensitive data leaving for an unsanctioned destination).

## Govern without blocking
The operating principle is least-disruption: prefer restrict and coach over block, scope every new
control to a pilot group first, and reserve hard blocks for the highest-risk apps on the register.
This keeps users productive on sanctioned apps while closing the data-loss path through shadow IT.

## Limitations (be honest with buyers)
- Inline control requires traffic steering / SWG already in place (a category prerequisite).
- API control requires a supported, sanctioned app and an authorized API connection to it; coverage
  depends on what each app's API exposes.
- Discovery and risk scores are a decision aid, not a verdict — disposition is a human policy choice.
- Exact Netskope console screens, menu paths, and tenant options change over time and are deferred to
  the official Netskope documentation and your tenant.

## The standard deployment model
> Discover and risk-score apps -> define sanctioned/unsanctioned policy -> apply inline activity and
> API controls -> validate -> pilot, validate, expand. Model: Assess -> Configure -> Pilot ->
> Validate -> Expand.
