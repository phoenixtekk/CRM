# Executive Summary — AWS Data-Source Governance (S3/RDS): Microsoft Purview

Most data-governance efforts stop at Microsoft 365, and the AWS estate — customer data in S3 buckets,
application databases on Amazon RDS — sits outside the map, unclassified and ungoverned. You cannot
protect, retain, or grant access to data you cannot see. This solution closes that blind spot: it
**registers, scans, and classifies your AWS S3 and RDS sources into the Microsoft Purview Data Map**,
so AWS data becomes a mapped, classified, owned part of the same governed estate as the rest of your
data.

This is a complete, do-it-today package written for an engineer bringing AWS into Purview for the
first time. It delivers the AWS connector workflow end-to-end — the safe **role-based trust** for S3, a
**Key Vault** credential for RDS, a bounded pilot scan, classification review, and ownership — with
every artifact named once and reused everywhere, and every scan proven on a bounded pilot before the
AWS estate is touched. Because the Purview multicloud connectors are evolving and consumption-billed,
the guide cites the method and flags every capability "verify your licensing/tenant" rather than
asserting a connector, an AWS account ID, or a price as permanent.

## What you get
- A plain-language Solution Overview of the two AWS sources — Amazon S3 (cross-account IAM role +
  external ID, read-only + KMS decrypt) and Amazon RDS (Key Vault credential over a network path) — how
  they scan and classify, and how they complement Microsoft 365 Purview.
- A Requirements Guide with verify / implement-if-missing for every prerequisite: the Purview account,
  connector availability, least-privilege collection roles, the AWS inventory with owners, the S3 trust
  path, the RDS Key Vault credential, the integration-runtime network path, a classification approach,
  and the pilot scope.
- An Implementation Guide of precise, ordered steps: design the collection/role model, establish the S3
  trust and RDS credential safely, register the AWS sources, **pilot-scan** a bounded set, review
  classifications, assign ownership, validate against the gate, then expand with scheduled scans.
- Five PowerShell tools for readiness/role discovery, pilot-scope capture, AWS source registration and
  scan configuration (`-WhatIf` by default), a scan-and-classification coverage report, and a
  consolidated readiness-gate check — authentic Purview data-plane REST automation with **no
  credentials in code** (S3 role ARN and RDS secret referenced by name only).
- Testing and Troubleshooting guides with explicit pass/fail gates, plus field-proven Best Practices.

## What this delivers
AWS data governed from Purview: S3 buckets and RDS databases registered into the Data Map, scanned and
classified, and owned — validated on a pilot before you scale.

## The deployment model
Assess → Design → Configure → **Pilot (bounded scan)** → Validate → Expand — with a pilot gate before
any AWS-wide scanning.

## Outcome
The AWS blind spot closed — S3 and RDS discoverable, classified, owned, and governed in the same
Purview Data Map as the rest of the estate — with regulatory, records, and access determinations left
to the owners who make them.
