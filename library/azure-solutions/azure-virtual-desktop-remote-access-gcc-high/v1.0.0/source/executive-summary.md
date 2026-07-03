# Executive Summary — Azure Virtual Desktop Remote Access (Government / Azure Government · GCC High)

## The problem
Azure Virtual Desktop (AVD) on a **GCC High / Azure Government** tenant is **not** the Commercial portal with a different sign-in. The admin portals, the client feed URLs, the sign-in endpoint, and the session-host service endpoints are all **different** in the US sovereign cloud — and some capabilities **lag, are limited, or are absent** versus Commercial. Teams that follow a Commercial runbook verbatim typically end up with clients subscribed to the wrong feed and session hosts that fail to register because a `.us` endpoint is blocked. The failures are quiet, and they surface late.

## The solution
This is the **Government (Azure Government / GCC High) edition** of the AVD Remote Access solution: AVD authored end to end for the US sovereign cloud. It uses the correct portals (**`portal.azure.us`**), the correct client feed (**`rdweb.wvd.azure.us`**), the correct Government service endpoints (`*.wvd.azure.us`, `*.usgovcloudapi.net`), and the identity model a Gov tenant actually supports — with **Commercial-vs-Azure-Government parity gaps called out** so nothing silently fails.

## What's inside
- **Solution Overview** with an explicit *Commercial vs Azure Government — what's different* table.
- **Requirements Guide** — ten verifiable prerequisites (tenant, Government licensing, roles, resource provider, identity model, image, networking + the Gov endpoint allow-list, clients, pilot group, change control).
- **Implementation Guide** — ordered, click-to-implement steps in the Gov portals, following **Assess → Configure → Pilot → Validate → Expand** with a gate at every stage and GCC-High caveats inline.
- **Testing & Troubleshooting** — twelve pass/fail test cases and a symptom→fix guide for the common sovereign-cloud failures.
- **Five PowerShell scripts** — Discovery, Validation, Report, Remediation (`-WhatIf`), and Set-ScopeTargeting — all on **US Gov** Azure/Graph endpoints.
- **GCC High parity reference** — cited, so you verify feature availability before you depend on it.

## The outcome
AVD deployed **correctly on GCC High** — right portals, right endpoints, parity gaps handled — proven on a small pilot before you scale, expanded in controlled waves, with a documented rollback. Self-guided and tested, at a fraction of the cost of a bespoke consulting engagement.

## Who it's for
Government, defense, and regulated organizations — and the MSPs and integrators serving them — deploying or correcting AVD on an Azure Government / GCC High tenant, who need the sovereign-cloud specifics up front rather than learned the hard way.
