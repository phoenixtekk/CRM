#!/usr/bin/env python3
"""dolibarr_client.py — thin REST client for the Dolibarr ERP/CRM at crm.phoenixtekk.com.

Shared by the Dolibarr sync tools (catalog / third-parties / etc.). Credentials load from a
repo-EXTERNAL secrets file so nothing sensitive is committed:

  ~/.claude/.dolibarr.env   with:
      DOLIBARR_URL=https://crm.phoenixtekk.com
      DOLIBARR_API_KEY=xxxxxxxxxxxxxxxx      # Dolibarr: Home > Setup > Users > (user) > API key

Falls back to a repo-local ./.dolibarr.env, then real environment variables. The key is sent as
the `DOLAPIKEY` header (Dolibarr REST convention). Never print or log the key.
"""
import os
import json
import urllib.request
import urllib.error
from pathlib import Path

_UA = "Mozilla/5.0 (compatible; phoenixtekk-dolibarr-sync/1.0)"


def _load_env():
    """Load DOLIBARR_URL / DOLIBARR_API_KEY from ~/.claude/.dolibarr.env, ./.dolibarr.env, or env."""
    for p in (Path.home() / ".claude" / ".dolibarr.env", Path(".dolibarr.env")):
        if p.is_file():
            for line in p.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                os.environ.setdefault(k.strip(), v.strip().strip('"').strip("'"))
    url = os.environ.get("DOLIBARR_URL", "").rstrip("/")
    key = os.environ.get("DOLIBARR_API_KEY", "")
    return url, key


class DolibarrError(RuntimeError):
    pass


class DolibarrClient:
    def __init__(self, url=None, key=None, timeout=30):
        env_url, env_key = _load_env()
        self.url = (url or env_url).rstrip("/")
        self.key = key or env_key
        self.timeout = timeout
        if not self.url or not self.key:
            raise DolibarrError(
                "Missing DOLIBARR_URL / DOLIBARR_API_KEY. Create ~/.claude/.dolibarr.env with:\n"
                "  DOLIBARR_URL=https://crm.phoenixtekk.com\n"
                "  DOLIBARR_API_KEY=<key from Dolibarr: Home > Setup > Users > (user) > API key>"
            )
        self.base = f"{self.url}/api/index.php"

    def _req(self, method, path, body=None, params=None):
        u = f"{self.base}/{path.lstrip('/')}"
        if params:
            from urllib.parse import urlencode
            u += "?" + urlencode(params)
        data = json.dumps(body).encode("utf-8") if body is not None else None
        req = urllib.request.Request(u, data=data, method=method)
        req.add_header("DOLAPIKEY", self.key)
        req.add_header("Accept", "application/json")
        req.add_header("User-Agent", _UA)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as r:
                raw = r.read().decode("utf-8")
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "ignore")[:400]
            raise DolibarrError(f"{method} {path} -> HTTP {e.code}: {detail}") from None
        except urllib.error.URLError as e:
            raise DolibarrError(f"{method} {path} -> {e}") from None

    def get(self, path, params=None):
        return self._req("GET", path, params=params)

    def post(self, path, body):
        return self._req("POST", path, body=body)

    def put(self, path, body):
        return self._req("PUT", path, body=body)

    # ---- convenience ----
    def ping(self):
        """Return the Dolibarr status payload (proves auth works)."""
        return self.get("status")

    def get_product_by_ref(self, ref):
        """Return the product dict for an exact ref, or None if not found."""
        try:
            return self.get(f"products/ref/{ref}")
        except DolibarrError as e:
            if "HTTP 404" in str(e):
                return None
            raise

    def upsert_product(self, ref, payload):
        """Create-or-update a product/service keyed on ref. Returns (action, id)."""
        existing = self.get_product_by_ref(ref)
        if existing and existing.get("id"):
            pid = existing["id"]
            self.put(f"products/{pid}", payload)
            return ("updated", pid)
        body = dict(payload)
        body["ref"] = ref
        pid = self.post("products", body)  # Dolibarr returns the new id (int)
        return ("created", pid)
