#!/usr/bin/env python3
# twin_readiness_assess.py — assess hospital-twin readiness and manage the scope/config record.
#
# PURPOSE: Profiles the declared inputs for a hospital-twin pilot (Python env, target model,
#          synthetic-source reachability, AI plug-in contract, scenarios, reference profile, and
#          acceptance gates) and writes a readiness score with any blockers. Also acts as the
#          scope/config helper (--init-config / --validate-config). Read-only; writes only reports.
# HOW TO RUN: python twin_readiness_assess.py --model fhir --use-cases sepsis-alert \
#             --output "Twin Readiness - Pilot - v1.json"   (Python 3.10+; see --help)
# EXPECTED RESULTS: A readiness report (JSON + stdout summary) with an overall score and a list of
#                   BLOCKER/WARN/OK findings. Any BLOCKER must be cleared before building the twin.
#
# Safe by default: this tool never reads or writes real PHI. It only inspects config/metadata files
# and reports; it makes no network calls to invented endpoints.

import argparse
import json
import os
import sys
from datetime import datetime, timezone

SUPPORTED_MODELS = ("fhir", "omop", "native")

# The canonical scope/config schema every twin tool reads.
CONFIG_TEMPLATE = {
    "artifact_name": "Twin Scope Config - Pilot - v1",
    "target_model": "fhir",              # fhir | omop | native
    "in_scope_domains": ["patients", "encounters", "conditions", "medications", "observations"],
    "service_line": "pilot-medsurg",
    "population": 500,
    "sim_clock": {"tick_hours": 1, "horizon_days": 7},
    "seed": 42,
    "ai_plugin_contract": "Twin AI Plug-In Contract - Pilot - v1",  # reference, not internals
    "synthetic_feed": "Synthetic Feed Binding - Pilot - v1",
    "scenario_suite": "Twin Scenario Suite - Pilot - v1",
    "reference_profile": "Twin Reference Profile - Pilot - v1.json",
    "acceptance_gates": "Twin Acceptance Gates - Pilot - v1.json",
}


def _now():
    return datetime.now(timezone.utc).isoformat()


def _finding(level, check, detail):
    return {"level": level, "check": check, "detail": detail}


def init_config(args):
    cfg = dict(CONFIG_TEMPLATE)
    if args.model:
        if args.model not in SUPPORTED_MODELS:
            print(f"ERROR: --model must be one of {SUPPORTED_MODELS}", file=sys.stderr)
            return 2
        cfg["target_model"] = args.model
    if args.service_line:
        cfg["service_line"] = args.service_line
    if args.population is not None:
        cfg["population"] = args.population
    if args.seed is not None:
        cfg["seed"] = args.seed
    out = args.out or "Twin Scope Config - Pilot - v1.json"
    if os.path.exists(out) and not args.force:
        print(f"ERROR: {out} exists; pass --force to overwrite.", file=sys.stderr)
        return 2
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(cfg, fh, indent=2)
    print(f"Wrote starter scope config -> {out}")
    print("Fill in the AI plug-in contract reference and in-scope domains, then --validate-config.")
    return 0


def validate_config(path):
    if not os.path.exists(path):
        print(f"FAIL: config not found: {path}", file=sys.stderr)
        return 2
    with open(path, encoding="utf-8") as fh:
        try:
            cfg = json.load(fh)
        except json.JSONDecodeError as exc:
            print(f"FAIL: not valid JSON: {exc}", file=sys.stderr)
            return 2
    errors = []
    for key in CONFIG_TEMPLATE:
        if key not in cfg:
            errors.append(f"missing key: {key}")
    if cfg.get("target_model") not in SUPPORTED_MODELS:
        errors.append(f"target_model must be one of {SUPPORTED_MODELS}")
    if not isinstance(cfg.get("population"), int) or cfg.get("population", 0) <= 0:
        errors.append("population must be a positive integer")
    if not isinstance(cfg.get("seed"), int):
        errors.append("seed must be an integer (reproducibility anchor)")
    if not cfg.get("in_scope_domains"):
        errors.append("in_scope_domains must be non-empty")
    if errors:
        print("FAIL: scope config invalid:")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"PASS: {path} is a valid Twin Scope Config.")
    return 0


def _check_present(label, value, findings, why):
    if value:
        findings.append(_finding("OK", label, f"present: {value}"))
    else:
        findings.append(_finding("BLOCKER", label, f"missing — {why}"))


def assess(args):
    findings = []

    # Python environment
    py_ok = sys.version_info >= (3, 10)
    findings.append(_finding(
        "OK" if py_ok else "BLOCKER", "python_env",
        f"Python {sys.version.split()[0]}" + ("" if py_ok else " (need 3.10+)")))

    # Target model
    if args.model in SUPPORTED_MODELS:
        findings.append(_finding("OK", "target_model", f"model = {args.model}"))
    else:
        findings.append(_finding("BLOCKER", "target_model",
                                 f"model '{args.model}' not in {SUPPORTED_MODELS}"))

    # AI use cases
    use_cases = [u for u in (args.use_cases or "").split(",") if u.strip()]
    _check_present("ai_use_cases", ",".join(use_cases), findings,
                   "pilot AI use cases drive scenarios and fidelity")

    # Synthetic source reachability (metadata only — never reads PHI)
    if args.synthetic_source:
        exists = os.path.exists(args.synthetic_source)
        findings.append(_finding(
            "OK" if exists else "WARN", "synthetic_source",
            f"{args.synthetic_source} " + ("found" if exists else "not found (bind before build)")))
    else:
        findings.append(_finding("BLOCKER", "synthetic_source",
                                 "no synthetic feed declared — twin cannot be populated"))

    # AI plug-in contract present
    if args.plugin_contract:
        exists = os.path.exists(args.plugin_contract)
        findings.append(_finding("OK" if exists else "WARN", "ai_plugin_contract",
                                 f"{args.plugin_contract} " + ("found" if exists else "declared")))
    else:
        findings.append(_finding("BLOCKER", "ai_plugin_contract",
                                 "no AI plug-in contract — twin cannot invoke the AI under test"))

    # Scenario count
    if args.scenario_dir and os.path.isdir(args.scenario_dir):
        n = len([f for f in os.listdir(args.scenario_dir) if f.endswith(".json")])
        findings.append(_finding("OK" if n else "BLOCKER", "scenarios",
                                 f"{n} scenario file(s) in {args.scenario_dir}"))
    else:
        findings.append(_finding("WARN", "scenarios",
                                 "no scenario directory yet — author before validation"))

    # Reference profile
    _check_present("reference_profile", args.reference, findings,
                   "fidelity gates need a reference to compare against")

    # Acceptance gates
    _check_present("acceptance_gates", args.gates, findings,
                   "explicit pass/fail gates are required by the deployment model")

    blockers = sum(1 for f in findings if f["level"] == "BLOCKER")
    warns = sum(1 for f in findings if f["level"] == "WARN")
    oks = sum(1 for f in findings if f["level"] == "OK")
    total = len(findings)
    score = round(100.0 * (oks + 0.5 * warns) / total, 1) if total else 0.0

    report = {
        "artifact_name": "Twin Readiness - Pilot - v1",
        "generated_at": _now(),
        "target_model": args.model,
        "readiness_score": score,
        "blockers": blockers,
        "warnings": warns,
        "ok": oks,
        "findings": findings,
        "verdict": "READY" if blockers == 0 else "NOT READY (clear blockers)",
        "note": "No real PHI is read or written by this tool; determinations deferred to privacy/compliance.",
    }

    print(f"Twin readiness: {report['verdict']}  score={score}  "
          f"blockers={blockers} warnings={warns} ok={oks}")
    for f in findings:
        print(f"  [{f['level']:7}] {f['check']}: {f['detail']}")

    if args.output:
        with open(args.output, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2)
        print(f"Wrote readiness report -> {args.output}")

    return 0 if blockers == 0 else 1


def build_parser():
    p = argparse.ArgumentParser(
        description="Assess hospital-twin readiness and manage the Twin Scope Config record.")
    p.add_argument("--model", default="fhir",
                   help="target clinical data model: fhir | omop | native")
    p.add_argument("--use-cases", help="comma-separated pilot AI use cases (e.g. sepsis-alert)")
    p.add_argument("--synthetic-source", help="path/metadata of the synthetic feed (never PHI)")
    p.add_argument("--plugin-contract", help="path to the AI plug-in contract record")
    p.add_argument("--scenario-dir", help="directory containing scenario .json files")
    p.add_argument("--reference", help="reference profile path for fidelity gates")
    p.add_argument("--gates", help="acceptance gates path")
    p.add_argument("--output", help="write the readiness report JSON here")
    # config-helper subcommands
    p.add_argument("--init-config", action="store_true",
                   help="write a starter Twin Scope Config and exit")
    p.add_argument("--validate-config", metavar="PATH",
                   help="validate an existing Twin Scope Config and exit")
    p.add_argument("--service-line", help="(with --init-config) service line name")
    p.add_argument("--population", type=int, help="(with --init-config) population size")
    p.add_argument("--seed", type=int, help="(with --init-config) reproducibility seed")
    p.add_argument("--out", help="(with --init-config) output path for the config")
    p.add_argument("--force", action="store_true", help="(with --init-config) overwrite if exists")
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    if args.validate_config:
        return validate_config(args.validate_config)
    if args.init_config:
        return init_config(args)
    return assess(args)


if __name__ == "__main__":
    sys.exit(main())
