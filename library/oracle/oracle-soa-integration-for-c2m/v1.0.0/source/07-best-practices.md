# Best Practices — C2M SOA Integration (supportable, low-lock-in)

Production-safe practices for the C2M integration surface. They complement the implementation steps and
keep integrations **consistent, supportable, observable**, with as little lock-in as practical.

---

## Consistency (design once, reuse everywhere)

- **One naming standard, everywhere.** Reuse the same names for External Systems, Outbound Message Types,
  Message Senders, Inbound Web Services, composites, and OSB proxy/business services across every
  environment (`C2M-SOA-EXT`, `C2M-OMT-SOA`, `C2M-IWS-CustomerSync`, `C2MInboundComposite`, …). Consistent
  names make discovery/validation scripts portable and runbooks reusable.
- **Pick the mechanism by direction + timing, not by habit.** Inbound → **IWS**; synchronous outbound →
  **real-time HTTP/SOAP sender**; near-real-time outbound → **processing method SOA** (OSB) or **JMS**.
  Document the choice per interface so the pattern is obvious to the next engineer.
- **Keep transformation in the middleware tier.** Do mapping/routing/enrichment in the SOA composite or
  OSB pipeline, not inside C2M. C2M stays clean; the integration logic is externalised, versioned, and
  reusable.

## Supportability

- **Migrate off XAI to IWS.** XAI is retired in the reference release; all inbound integration must be
  IWS (SOAP/REST). Migrate any legacy XAI inbound service per MOS **Doc ID 1644914.1**.
- **Enable only the inbound services integrations actually need.** Every enabled IWS is surface to
  secure, monitor, and support; enable by inventory (Requirement 4), not by default.
- **Deploy headless and repeatably.** Deploy `spl-web-services` with `iwsdeploy` using the stored
  WebLogic user-config/key files (`$SPLEBASE/etc/.wlsuserconfig` / `.wlsuserkey`) so deploys are
  scriptable and identical across environments — no interactive passwords. Confirm the Admin Server is up
  first.
- **Version the middleware artifacts.** Keep the SOA/OSB project exports (SAR/JAR/configjar) in source
  control as the deployable + rollback unit; promote the **same** export through Test and Prod rather
  than rebuilding per environment.
- **Turn the development-environment IWS flag OFF in production.** The "deploy from browser UI" option is
  a non-production convenience; leaving it on in production is an unnecessary exposure.

## Observability

- **Instance tracking on for every composite/pipeline.** So an operator can answer "did it work, and if
  not, where?" from Enterprise Manager / the OSB console.
- **Use C2M outbound-message status as the outbound source of truth.** Alert on messages stuck in
  **error** status or **staged-but-undispatched** (a sign OSB isn't polling or a sender is
  misconfigured).
- **Log inbound (IWS) requests** and correlate them across the composite → IWS → C2M hop so an inbound
  failure can be localised.
- **Wire integrations into the environment's monitoring stack** (e.g. the APM/monitoring the site uses)
  for latency and error alerting per endpoint, not just aggregate health.

## Security (consistent authN)

- **TLS everywhere**, with certificates in the OUAF trust store (`initialSetup -i`) and the SOA/OSB
  keystores.
- **One authentication model** applied to every interface — HTTP Basic over TLS, **WS-Security/WS-Policy**
  for SOAP, OAuth where the release supports it (*verify for your version*) — rather than per-interface
  improvisation.
- **Dedicated service accounts** for each integration (least privilege), and **never** put credentials or
  keystores in scripts, composites, or committed files — source them from the environment / secret store.

## Error handling & resilience

- **Every interface has a defined failure path.** Fault policies for SOA composites, an **error
  destination** for JMS, bounded **retry/redelivery** limits, and monitored C2M outbound-message error
  status. No interface silently drops.
- **Make retries idempotent-safe.** Design inbound operations and outbound consumers so a retry cannot
  double-apply; correlate on a business key.
- **Bound backlogs.** Set JMS quotas and alert on rising pending counts so a stalled consumer is a
  bounded, visible problem — not an outage.

## Low lock-in

- **Favour open, portable mechanisms.** Standard SOAP/REST and open JCA adapters (SOAP/HTTP, JMS, DB,
  File) over bespoke or proprietary couplings, so an interface could move to a different middleware (e.g.
  Oracle Integration / OIC) without re-engineering C2M.
- **Treat the middleware as replaceable.** Because transformation and routing live in named, documented
  composites/pipelines — not in C2M — the mediation tier can be swapped with C2M's IWS/outbound contracts
  unchanged.
- **Document the contract of each interface** (endpoint, payload, authN, direction, timing) so the
  integration is understood independently of any one product's console.

## Cross-cutting

- **Non-production first, always.** Configure and validate on the pilot, then promote the *same* named
  objects, the *same* SOA/OSB exports, and the *same* scripts to Test and Prod.
- **Back up before disruptive changes** (domain `config.xml`, `$SPLEBASE` integration metadata, SOA/OSB
  project exports) and keep the restore/redeploy path as the rollback.
- **Reuse names across environments** so discovery/validation/report scripts are portable — retarget with
  `OSOAC2M-ScopeHelper` rather than re-authoring per environment.
- **Keep remediation dry-run by default.** Review `OSOAC2M-Remediation`'s planned actions before
  applying, and apply only inside a change window.
- **Retain script output as evidence** for change records and audits; a clean `OSOAC2M-Report` is the
  sign-off artifact.

## Sources

- Oracle Utilities — *Polling Outbound Messages Using OSB* (processing method SOA; OUAF Outbound Message
  transport):
  https://docs.oracle.com/en/industries/utilities/meter-solution-cloud-service/264/mscs-user-guides/Topics/F1_93XAI_Polling_Outbound_Message_Using_OSB.html
- Oracle Utilities C2M — *Inbound REST Web Services* (IWS; XAI retired):
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/2.9.0.0.0/c2m-user-guides/C2M_29000/F1_93XAI_REST_Inbound_Web_Service_Overview.html
- Oracle Utilities C2M — *Deploying Inbound Web Services (IWS)*:
  https://docs.oracle.com/en/industries/energy-water/advanced-meter/29011/c2m-installation-guide/C2M-INSTALLATION-GUIDE/C2M_Install_Postinstall.09.09.html
- Oracle® Fusion Middleware — *Understanding Technology Adapters* (JCA adapters):
  https://docs.oracle.com/en/middleware/soa-suite/integration-adapters/12.2.1.3/develop-soa-adapters/overview3.html
- My Oracle Support — *Migrating from XAI to IWS*, Doc ID 1644914.1 (entitlement-gated).
