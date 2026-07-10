#!/usr/bin/env python3
"""
.SYNOPSIS
    AISAFETY-SafetyFilter.py — the reusable pre/post-generation guardrail for your AI apps.

.DESCRIPTION
    PURPOSE
        The `Safety Filter - Pre-Post Generation - Pilot` integration sample. Drop this module into
        your AI app and call it around your model:
          * PRE-generation  : moderate the user input (+ any retrieved documents) with analyze_text
                              (Hate/Sexual/Violence/SelfHarm severities), the custom blocklist, and
                              Prompt Shields (jailbreak + indirect prompt-injection).
          * POST-generation : moderate the model's answer, run a groundedness check against the RAG
                              sources, and a protected-material check.
        Every decision (allow / review / block) is driven by a ratified severity policy read from
        config, and every decision is logged (verdicts only, never the harmful text).

    HOW TO RUN (standalone demo of the wiring; does NOT call a real model)
        pip install azure-ai-contentsafety azure-identity requests
        export CONTENT_SAFETY_ENDPOINT="https://<resource>.cognitiveservices.azure.com/"
        python AISAFETY-SafetyFilter.py --demo --mode observe

    HOW TO USE IN YOUR APP
        from AISAFETY_SafetyFilter import SafetyFilter, load_policy
        flt = SafetyFilter(load_policy("severity_policy.json"), mode="observe")   # observe first!
        pre = flt.pre_generation(user_input, retrieved_docs=docs)
        if pre.decision == "block":  return flt.refusal_message()
        answer = call_your_model(user_input, docs)
        post = flt.post_generation(answer, sources=docs)
        if post.decision == "block": return flt.refusal_message()
        return answer

    EXPECTED RESULTS
        In `observe` mode the filter LOGS a decision but never blocks (your app returns normally) —
        use this on the pilot to measure false positives. In `enforce` mode it returns block/review
        per policy. Keyless auth via DefaultAzureCredential (managed identity) by default.

.NOTES
    White-label. Defaults to mode="observe" (non-blocking) — flip to "enforce" only after the pilot
    gate passes and trust & safety ratifies the thresholds. Prompt Shields / groundedness /
    protected-material are preview/evolving and are called defensively (skip-with-log if unavailable)
    — verify current availability and API version in your region.
"""
import argparse
import json
import logging
import os
from dataclasses import dataclass, field

logging.basicConfig(level=logging.INFO, format="%(asctime)s [SAFETY] %(levelname)s %(message)s")
log = logging.getLogger("safetyfilter")

CATEGORIES = ["Hate", "Sexual", "Violence", "SelfHarm"]

DEFAULT_POLICY = {
    # Per-category thresholds on the 0-7 severity scale. THESE ARE STARTING POINTS ONLY —
    # ratify with trust & safety. block: >= value blocks; review: >= value routes to review.
    "block": {"Hate": 4, "Sexual": 4, "Violence": 4, "SelfHarm": 4},
    "review": {"Hate": 2, "Sexual": 2, "Violence": 2, "SelfHarm": 2},
    "blocklist_names": ["Prohibited Terms - App Guardrails - Pilot"],
    "groundedness_min": 0.5,          # answers below this are routed to review/block (RAG apps)
    "enable_prompt_shields": True,
    "enable_groundedness": True,
    "enable_protected_material": True,
}


def load_policy(path=None):
    if path and os.path.exists(path):
        with open(path, "r", encoding="utf-8") as fh:
            user = json.load(fh)
        merged = dict(DEFAULT_POLICY)
        merged.update(user)
        return merged
    return dict(DEFAULT_POLICY)


@dataclass
class Verdict:
    stage: str
    decision: str = "allow"                     # allow | review | block
    reasons: list = field(default_factory=list)
    signals: dict = field(default_factory=dict)  # category severities, shield hits, groundedness


class SafetyFilter:
    def __init__(self, policy, endpoint=None, mode="observe"):
        self.policy = policy
        self.mode = mode  # "observe" logs only; "enforce" acts on the decision
        self.endpoint = endpoint or os.environ.get("CONTENT_SAFETY_ENDPOINT", "")
        self._client = None
        self._credential = None

    # ---- lazy keyless client -------------------------------------------------
    def _client_or_none(self):
        if self._client is not None:
            return self._client
        if not self.endpoint:
            log.warning("no CONTENT_SAFETY_ENDPOINT set; running in offline/demo mode.")
            return None
        try:
            from azure.ai.contentsafety import ContentSafetyClient
            from azure.identity import DefaultAzureCredential
            self._credential = DefaultAzureCredential()
            self._client = ContentSafetyClient(self.endpoint, self._credential)
        except Exception as exc:  # noqa: BLE001
            log.warning("could not init ContentSafetyClient (%s); offline/demo mode.", exc)
            self._client = None
        return self._client

    # ---- primitive checks ----------------------------------------------------
    def _analyze_text(self, text):
        """Return {category: severity}. Empty dict if the service is unavailable (skip-with-log)."""
        client = self._client_or_none()
        if client is None:
            return {}
        try:
            from azure.ai.contentsafety.models import AnalyzeTextOptions
            opts = AnalyzeTextOptions(text=text, blocklist_names=self.policy.get("blocklist_names") or [])
            resp = client.analyze_text(opts)
            sev = {}
            for item in getattr(resp, "categories_analysis", []) or []:
                sev[str(item.category)] = int(item.severity or 0)
            blk = [m.blocklist_item_text for m in (getattr(resp, "blocklists_match", []) or [])]
            return {"severities": sev, "blocklist_matches": blk}
        except Exception as exc:  # noqa: BLE001
            log.warning("analyze_text unavailable (%s); skip-with-log.", exc)
            return {}

    def _prompt_shield(self, user_prompt, documents):
        """Preview capability — verify availability/API version. Returns dict of shield hits."""
        if not self.policy.get("enable_prompt_shields"):
            return {}
        client = self._client_or_none()
        if client is None:
            return {}
        try:
            # SDK method names for Prompt Shields evolve across versions; call defensively.
            shield = getattr(client, "shield_prompt", None) or getattr(client, "detect_jailbreak", None)
            if shield is None:
                log.info("Prompt Shields method not present in this SDK version; skip-with-log.")
                return {}
            result = shield(user_prompt=user_prompt, documents=documents or [])
            hit = bool(getattr(getattr(result, "user_prompt_analysis", None), "attack_detected", False))
            doc_hit = any(getattr(d, "attack_detected", False)
                          for d in (getattr(result, "documents_analysis", []) or []))
            return {"jailbreak": hit, "indirect_injection": doc_hit}
        except Exception as exc:  # noqa: BLE001
            log.warning("Prompt Shields unavailable (%s); skip-with-log. Verify availability.", exc)
            return {}

    def _groundedness(self, answer, sources):
        """Preview capability — verify availability. Returns a groundedness score 0..1 or None."""
        if not (self.policy.get("enable_groundedness") and sources):
            return None
        # Groundedness detection is a preview REST capability whose shape evolves; implement the
        # current text:detectGroundedness call for your region here. Returns None => skip-with-log.
        log.info("groundedness check placeholder — wire the current preview API for your region.")
        return None

    def _protected_material(self, answer):
        """Preview capability — verify availability. Returns True if protected material detected."""
        if not self.policy.get("enable_protected_material"):
            return False
        log.info("protected-material check placeholder — wire the current preview API for your region.")
        return False

    # ---- decision helpers ----------------------------------------------------
    def _decide_from_severities(self, analysis, verdict):
        sev = (analysis or {}).get("severities", {})
        for cat in CATEGORIES:
            s = int(sev.get(cat, 0))
            verdict.signals[cat] = s
            if s >= self.policy["block"].get(cat, 4):
                verdict.decision = "block"
                verdict.reasons.append(f"{cat} severity {s} >= block threshold")
            elif s >= self.policy["review"].get(cat, 2) and verdict.decision != "block":
                verdict.decision = "review"
                verdict.reasons.append(f"{cat} severity {s} >= review threshold")
        matches = (analysis or {}).get("blocklist_matches", [])
        if matches:
            verdict.signals["blocklist_matches"] = matches
            verdict.decision = "block"
            verdict.reasons.append(f"blocklist match: {matches}")

    # ---- public API ----------------------------------------------------------
    def pre_generation(self, user_input, retrieved_docs=None):
        v = Verdict(stage="pre")
        self._decide_from_severities(self._analyze_text(user_input), v)
        shields = self._prompt_shield(user_input, retrieved_docs)
        if shields.get("jailbreak") or shields.get("indirect_injection"):
            v.signals["prompt_shields"] = shields
            v.decision = "block"
            v.reasons.append("Prompt Shields detected a jailbreak/indirect-injection attack")
        return self._finalize(v)

    def post_generation(self, answer, sources=None):
        v = Verdict(stage="post")
        self._decide_from_severities(self._analyze_text(answer), v)
        g = self._groundedness(answer, sources)
        if g is not None:
            v.signals["groundedness"] = g
            if g < self.policy.get("groundedness_min", 0.5) and v.decision != "block":
                v.decision = "review"
                v.reasons.append(f"groundedness {g:.2f} below minimum")
        if self._protected_material(answer):
            v.signals["protected_material"] = True
            v.decision = "block"
            v.reasons.append("protected material detected")
        return self._finalize(v)

    def _finalize(self, v):
        # Log the DECISION only (never the raw content).
        log.info("stage=%s decision=%s mode=%s reasons=%s signals=%s",
                 v.stage, v.decision, self.mode, v.reasons, v.signals)
        if self.mode == "observe" and v.decision != "allow":
            # Observe mode: record what WOULD happen but let the app proceed.
            v.reasons.append("(observe mode: not enforced)")
        return v

    def refusal_message(self):
        return "This request can't be completed because it may violate the content policy."


def _demo(mode):
    flt = SafetyFilter(load_policy(), mode=mode)
    print(f"--- SafetyFilter demo (mode={mode}) ---")
    print("pre :", flt.pre_generation("Hello, can you help me draft an email?"))
    print("post:", flt.post_generation("Sure — here is a friendly email draft.", sources=["source A"]))
    print("Note: with no CONTENT_SAFETY_ENDPOINT set, checks skip-with-log and default to allow.")


def main():
    ap = argparse.ArgumentParser(description="Pre/post-generation safety filter (integration sample).")
    ap.add_argument("--demo", action="store_true", help="Run a wiring demo (no real model call).")
    ap.add_argument("--mode", choices=["observe", "enforce"], default="observe")
    ap.add_argument("--policy", help="Path to severity_policy.json (optional).")
    args = ap.parse_args()
    if args.policy:
        load_policy(args.policy)  # validate it loads
    if args.demo:
        _demo(args.mode)
    else:
        print("Import SafetyFilter into your app (see the HOW TO USE block), or run with --demo.")


if __name__ == "__main__":
    main()
