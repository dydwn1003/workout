"""Builds preview/adapt-preview.html: a single self-contained file (no network,
no external files) that runs the app in any browser or in the Claude Code
file viewer.

Embeds NanumSquareRound (OFL) subset to KS X 1001 Hangul + ASCII + every
character used in the page, as base64 WOFF2.

Run: python3 tool/build_preview.py   (needs: pip install fonttools brotli)
"""
import base64
import io
import os

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
SRC = os.path.join(ROOT, "preview", "src", "app.html")
OUT = os.path.join(ROOT, "preview", "adapt-preview.html")
FONTS = os.path.join(ROOT, "assets", "fonts")


def charset(extra_text: str) -> str:
    chars = set(extra_text)
    chars.update(chr(c) for c in range(0x20, 0x7F))
    # The 2,350 common Hangul syllables of KS X 1001 (EUC-KR).
    for hi in range(0xB0, 0xC9):
        for lo in range(0xA1, 0xFF):
            try:
                chars.add(bytes([hi, lo]).decode("euc-kr"))
            except UnicodeDecodeError:
                pass
    chars.update("·•…–—→←↑↓±×÷°%₩~“”‘’「」✓")
    return "".join(sorted(chars))


def woff2_b64(ttf: str, text: str) -> str:
    font = TTFont(os.path.join(FONTS, ttf))
    opts = subset.Options()
    opts.flavor = "woff2"
    opts.layout_features = ["*"]
    opts.name_IDs = ["*"]
    sub = subset.Subsetter(opts)
    sub.populate(text=text)
    sub.subset(font)
    buf = io.BytesIO()
    font.flavor = "woff2"
    font.save(buf)
    return base64.b64encode(buf.getvalue()).decode("ascii")


def main() -> None:
    html = open(SRC, encoding="utf-8").read()
    text = charset(html)
    out = html.replace("/*FONT_R*/", woff2_b64("NanumSquareRoundR.ttf", text))
    out = out.replace("/*FONT_EB*/", woff2_b64("NanumSquareRoundEB.ttf", text))
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"wrote {os.path.relpath(OUT, ROOT)} ({len(out) / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
