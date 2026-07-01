#!/usr/bin/env python3
"""
Phase 1 — build the 3 standalone paid support add-on products for the Workplace Marketplace.
Generates a "Getting Started" PDF per tier (reportlab) + the loader listing JSON.
Output: support/deliverables/*.pdf and support/bagisto-products.json (in the CRM repo).
"""
import json
from pathlib import Path
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import inch
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, ListFlowable, ListItem

HERE = Path(__file__).resolve().parent
DELIV = HERE / "deliverables"; DELIV.mkdir(exist_ok=True)

TIERS = [
    {
        "sku": "PTK-SUPPORT-CHAT30-001", "price": 199.0,
        "name": "30-Day Chat Support", "url_key": "support-30-day-chat",
        "file": "Support-Chat30-Getting-Started.pdf",
        "short": "30 days of expert chat support over your preferred messaging app — SMS, WhatsApp, Teams, Slack, Telegram, or web.",
        "intro": "Thank you for purchasing <b>30-Day Chat Support</b>. You now have 30 days of direct chat access to our implementation team to help you deploy and operate your Phoenixtekk solution.",
        "bullets": [
            "Chat with our team over whatever messaging app you already use — SMS, WhatsApp, Microsoft Teams, Slack, Telegram, or the web.",
            "Ask implementation questions, get unblocked, and validate your rollout.",
            "Your 30-day window starts when your first session opens.",
        ],
    },
    {
        "sku": "PTK-SUPPORT-PRIORITY-001", "price": 499.0,
        "name": "Priority Implementation Support", "url_key": "support-priority-implementation",
        "file": "Support-Priority-Getting-Started.pdf",
        "short": "Priority, hands-on implementation support across your rollout — faster response and deeper help than standard chat.",
        "intro": "Thank you for purchasing <b>Priority Implementation Support</b>. You're now front-of-queue for hands-on help across your Phoenixtekk solution rollout.",
        "bullets": [
            "Priority response — your messages jump the queue.",
            "Hands-on guidance through implementation, testing, and validation.",
            "Chat over your preferred app, plus screen-share where it helps.",
        ],
    },
    {
        "sku": "PTK-SUPPORT-CALL60-001", "price": 250.0,
        "name": "Live Implementation Call (60 min)", "url_key": "support-live-call-60min",
        "file": "Support-Call60-Getting-Started.pdf",
        "short": "A scheduled 60-minute live call with a Phoenixtekk implementation engineer to plan or troubleshoot your deployment.",
        "intro": "Thank you for purchasing a <b>Live Implementation Call (60 minutes)</b>. We'll get you on a call with an implementation engineer to plan, configure, or troubleshoot your deployment.",
        "bullets": [
            "One scheduled 60-minute live session with an implementation engineer.",
            "Bring your environment specifics — we'll work through them with you.",
            "We'll send a scheduling link to book a time that suits you.",
        ],
    },
]

styles = getSampleStyleSheet()
H1 = ParagraphStyle("H1", parent=styles["Title"], textColor=colors.HexColor("#4c1d95"), fontSize=22, spaceAfter=4)
SUB = ParagraphStyle("SUB", parent=styles["Heading2"], textColor=colors.HexColor("#6b7280"), fontSize=13, spaceAfter=16)
BODY = ParagraphStyle("BODY", parent=styles["BodyText"], fontSize=11, leading=16, spaceAfter=10)
H3 = ParagraphStyle("H3", parent=styles["Heading3"], textColor=colors.HexColor("#111827"), spaceBefore=8, spaceAfter=6)


def build_pdf(t):
    doc = SimpleDocTemplate(str(DELIV / t["file"]), pagesize=LETTER,
                            leftMargin=0.9 * inch, rightMargin=0.9 * inch, topMargin=1 * inch, bottomMargin=1 * inch,
                            title=f"Phoenixtekk Support — {t['name']}")
    flow = [
        Paragraph("Phoenixtekk Support — Getting Started", H1),
        Paragraph(t["name"], SUB),
        Paragraph(t["intro"], BODY),
        Paragraph("How it works", H3),
        ListFlowable([ListItem(Paragraph(b, BODY), leftIndent=10) for b in t["bullets"]], bulletType="bullet"),
        Spacer(1, 10),
        Paragraph("What happens next", H3),
        Paragraph("We'll reach out within <b>1 business day</b> to open your support session and send your "
                  "chat or scheduling link. You'll be able to message us from whatever app you prefer — "
                  "nothing to install.", BODY),
        Spacer(1, 6),
        Paragraph("Questions in the meantime? Email <b>support@phoenixtekk.com</b> and reference your order number.", BODY),
    ]
    doc.build(flow)
    return (DELIV / t["file"]).stat().st_size


def desc(t):
    items = "".join(f"<li>{b}</li>" for b in t["bullets"])
    return (f"<h3>{t['name']}</h3><p>{t['intro']}</p>"
            f"<h4>What you get</h4><ul>{items}</ul>"
            f"<h4>What happens next</h4><p>After checkout we'll reach out within one business day to open your "
            f"session and send your chat or scheduling link — over your preferred messaging app (SMS, WhatsApp, "
            f"Teams, Slack, Telegram, or web). Your download below is your Getting Started guide.</p>"
            f"<p><em>One-time purchase. Questions? support@phoenixtekk.com</em></p>")


products = []
for t in TIERS:
    sz = build_pdf(t)
    print(f"  {t['file']:38} {sz:>7,} bytes")
    products.append({
        "sku": t["sku"], "name": t["name"], "type": "downloadable", "audience": "commercial",
        "price": t["price"], "short_description": f"<p>{t['short']}</p>", "description": desc(t),
        "meta_title": f"{t['name']} — Phoenixtekk Support",
        "meta_description": t["short"], "url_key": t["url_key"],
        "downloads": [{"title": "Getting Started (PDF)", "source_type": "file", "source": t["file"]}],
    })

listing = {"solution": {"slug": "phoenixtekk-support", "title": "Phoenixtekk Support & Services",
                        "category_path": ["Support & Services"], "version": "1.0.0"},
           "products": products}
(HERE / "bagisto-products.json").write_text(json.dumps(listing, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"wrote support/bagisto-products.json ({len(products)} products)")
