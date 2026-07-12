# Executive Summary — Entra Identity Protection & Advanced Conditional Access

White-label · Entra ID Solutions

A static Conditional Access baseline cannot react to a compromise in progress. It decides once, at
sign-in, on fixed conditions — it has no idea that a user's password just appeared on a leak list,
that a session token was replayed from another country, or that an action about to happen is more
sensitive than the sign-in that authorised it. This solution adds the layer a baseline is missing:
the risk-and-context layer that turns your access decisions from a fixed gate into an adaptive
perimeter.

It does two things together. First, it turns on **Microsoft Entra ID Protection** so the tenant has a
live risk engine — risky users and risky sign-ins are detected, scored, and (once you enforce)
challenged or blocked by risk-based Conditional Access. Second, it deploys **advanced Conditional
Access**: authentication contexts for step-up on sensitive apps and actions, token protection (token
binding) and Continuous Access Evaluation so stolen tokens stop working mid-session, authentication
strengths to demand phishing-resistant methods where it matters, and named-location policy. Every
policy is piloted **report-only first**, so you see exactly who each change would have affected before
a single user is blocked.

This is a complete, deploy-it-today package written for an administrator with no prior identity-risk
experience. It is deliberately the **risk/advanced layer** — it assumes you already have (or will
add) a Conditional Access baseline (see the Conditional Access baseline solution) and does not
re-teach that ground.

## What you get
- A plain-language Solution Overview of Entra ID Protection (risk detections, risky users/sign-ins, risk-based policies) and advanced Conditional Access (authentication contexts, token protection, CAE, authentication strengths, named locations).
- A Requirements Guide with verify / implement-if-missing for every solution-specific prerequisite (P2 licensing flagged for you to verify).
- An Implementation Guide of precise, ordered steps in the Entra admin center — report-only first, then staged enforcement, with break-glass kept safe throughout.
- Five PowerShell scripts (Microsoft Graph / Az) plus KQL for risk discovery, pilot validation, a risk-and-coverage report, safe policy-state changes, and risk hunting.
- Testing and Troubleshooting guides for a confident rollout.

## What this delivers
An adaptive identity perimeter: risky sign-ins and risky users are detected and (after validation)
challenged with MFA or blocked; sensitive apps and actions demand a fresh, phishing-resistant step-up
via authentication context; tokens are bound to their device and revoked in near-real-time by
Continuous Access Evaluation; and every one of these controls is proven in report-only mode against
real traffic before it enforces. Break-glass emergency accounts are excluded from every risk and
enforcement policy so a misconfiguration can never lock all administrators out.

## The standard deployment model
Assess -> Configure -> Pilot -> Validate -> Expand.

## Outcome
Access decisions that react to risk in real time — risk-based challenges, step-up on sensitive
actions, and token protection layered over your Conditional Access baseline — proven on a pilot in
report-only before you enforce.
