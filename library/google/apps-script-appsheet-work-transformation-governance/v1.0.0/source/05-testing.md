# Testing

Testing here means **guardrail-conformance gates**: objective pass/fail checks that prove the
governance is real, that builders can still ship, and that the pilot is safe to expand. Run these in
the **Pilot** scope first; every gate must pass before expanding org-wide. Re-run after expansion to
confirm the estate.

Use **`GWAUTO-Validation.ps1`** for the automated conformance checks and **`GWAUTO-Report.ps1`** for
the coverage/risk view. Manual gates are verified in the Admin console / AppSheet Admin Console.

---

## Gate 1 — App access control posture (Apps Script data access)

- **Check:** Unconfigured apps are set to the agreed governed posture (not the open default);
  approved apps are explicitly **trusted**; internal-app trust is set deliberately.
- **Pass:** Unconfigured apps cannot obtain restricted-service access; only trusted apps can.
- **Fail:** Unconfigured apps still reach restricted services, or the posture is still the open
  default.
- **How:** Validation script flags the posture; confirm in **Security → Access and data control →
  API controls → App access control**.

## Gate 2 — High-risk OAuth scope restriction (edition-gated)

- **Check:** For Gmail and Drive, high-risk scopes are **restricted** to trusted apps; non-high-risk
  scopes remain grantable.
- **Pass:** A new untrusted Apps Script project cannot obtain a high-risk Gmail/Drive scope.
- **Fail:** An untrusted project can still authorize a high-risk scope.
- **How:** Attempt authorization with a test project in the pilot OU; confirm it is blocked.
  (Skip with a documented note if your edition lacks this control.)

## Gate 3 — AppSheet external sharing blocked

- **Check:** Apps cannot be shared to external users / outside approved domain(s) — via the Core
  security setting or an Enterprise Plus sharing policy.
- **Pass:** An attempt to share a pilot app externally is blocked (or the policy raises an Error).
- **Fail:** External sharing succeeds.
- **How:** Validation script flags AppSheet sharing config; confirm by test-sharing a pilot app.

## Gate 4 — AppSheet external data sources / webhooks / external API restricted

- **Check:** External data-source connections, external automation email, external API, and webhooks
  are governed (Core security on, or Enterprise Plus policy).
- **Pass:** A pilot app cannot connect a disallowed external source or fire a disallowed webhook.
- **Fail:** A disallowed external connection succeeds.
- **How:** Validation script reports the AppSheet security/policy state; spot-check with a pilot app.

## Gate 5 — Require sign-in

- **Check:** Deployed AppSheet apps require user sign-in (`[AuthRequired] = true`), enforced at
  deploy as an **Error** policy (Enterprise Plus) or per standard.
- **Pass:** An app without sign-in cannot be marked deployed.
- **Fail:** An anonymous-access app deploys.
- **How:** Attempt to deploy a no-sign-in pilot app; confirm it is blocked.

## Gate 6 — Deploy control (review model is enforceable)

- **Check:** Only designated people can **mark an app as deployed** (AppSheet policy), and Apps
  Script Tier 1/2 deployments went through the review checklist.
- **Pass:** A non-reviewer cannot mark a pilot app deployed; reviewed Apps Script deployments have a
  recorded review.
- **Fail:** Any builder can self-deploy a Tier 1/2 artifact.
- **How:** Test with a non-reviewer account; check the review record for sampled deployments.

## Gate 7 — Owner of record and environment discipline

- **Check:** Every deployed automation has an **owner of record**; nothing shipped from Build
  straight to Production without passing Pilot.
- **Pass:** Discovery/Report shows an owner for every deployed artifact; no ownerless production
  automation.
- **Fail:** Ownerless or un-piloted production automations exist.
- **How:** `GWAUTO-Report.ps1` ownership/coverage section.

## Gate 8 — Builders can still ship (guardrails aren't a lockdown)

- **Check:** A pilot citizen developer can build and deploy a compliant Tier 0/1 automation
  end-to-end within the guardrails.
- **Pass:** A compliant automation ships without an exception request.
- **Fail:** Compliant work is blocked, indicating over-tight guardrails.
- **How:** Have a pilot builder complete a real, compliant workflow build.

---

## Conformance summary

Record each gate as **Pass / Fail / N-A (edition)** with evidence (screenshot, Validation output,
Report section). The pilot **expands only when Gates 1, 3–7 pass** and Gate 8 confirms builders can
still ship; Gate 2 is *Pass or documented N-A*. Re-run the full set after org-wide expansion, then on
the recurring Discovery cadence.
