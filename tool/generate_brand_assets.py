"""Regenerate every Wazifly raster asset FROM the single source of truth:
`assets/brand/wazifly_logo.svg`.

Replace that SVG with the official vector, then run:
    python tool/generate_brand_assets.py
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create

Produces (all derived from the SVG):
  assets/images/wazifly_mark.png  — in-app logo (transparent)
  assets/icon/splash_logo.png     — native splash mark (transparent)
  assets/icon/ic_foreground.png   — Android adaptive foreground (padded)
  assets/icon/ic_background.png    — Android adaptive background (Deep Navy)
  assets/icon/app_icon.png        — full app icon (navy tile + mark)

Dev-only deps: svglib, reportlab, pypdfium2, Pillow.
Pipeline: SVG --svglib--> ReportLab drawing --> PDF --pypdfium2--> raster,
then Pillow composites (no native cairo needed on Windows).
"""
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPDF
import pypdfium2 as pdfium
from PIL import Image, ImageDraw
import os, tempfile

NAVY = (11, 29, 58, 255)  # #0B1D3A
SVG = "assets/brand/wazifly_logo.svg"


def render_mark(px):
    d = svg2rlg(SVG)
    tmp = os.path.join(tempfile.gettempdir(), "_wazifly_mark.pdf")
    renderPDF.drawToFile(d, tmp)
    pdf = pdfium.PdfDocument(tmp)
    img = pdf[0].render(scale=px / 200.0, fill_color=(255, 255, 255, 0)) \
        .to_pil().convert("RGBA")
    return img


def centered(mark, px, frac, bg=None):
    m = int(px * frac)
    mk = mark.resize((m, m), Image.LANCZOS)
    canvas = Image.new("RGBA", (px, px), bg or (0, 0, 0, 0))
    off = (px - m) // 2
    canvas.alpha_composite(mk, (off, off))
    return canvas


def rounded_navy(px, radius_frac=0.22):
    canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
    ImageDraw.Draw(canvas).rounded_rectangle(
        [0, 0, px - 1, px - 1], radius=int(px * radius_frac), fill=NAVY)
    return canvas


def main():
    mark = render_mark(1024)
    centered(mark, 1024, 0.92).save("assets/images/wazifly_mark.png")
    centered(mark, 1024, 0.78).save("assets/icon/splash_logo.png")
    centered(mark, 1024, 0.58).save("assets/icon/ic_foreground.png")
    Image.new("RGBA", (1024, 1024), NAVY).save("assets/icon/ic_background.png")
    icon = rounded_navy(1024)
    icon.alpha_composite(centered(mark, 1024, 0.70))
    icon.save("assets/icon/app_icon.png")
    print("Regenerated all Wazifly raster assets from", SVG)


if __name__ == "__main__":
    main()
