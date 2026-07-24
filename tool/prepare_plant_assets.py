"""Prepare generated plant cutouts as consistently sized Flutter assets."""

from pathlib import Path
from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
TMP = ROOT / "tmp" / "imagegen"
OUT = ROOT / "assets" / "images" / "plants"
COLLECTIBLES = ROOT / "assets" / "images" / "collectibles"
OUT.mkdir(parents=True, exist_ok=True)
COLLECTIBLES.mkdir(parents=True, exist_ok=True)


def normalize(image: Image.Image, output: Path, size: int = 512) -> None:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"No visible pixels for {output.name}")
    image = image.crop(bounds)
    max_subject = int(size * 0.88)
    scale = min(max_subject / image.width, max_subject / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - resized.width) // 2
    y = size - resized.height - int(size * 0.05)
    canvas.alpha_composite(resized, (x, y))
    canvas.save(output, optimize=True)


normalize(Image.open(TMP / "tulips_storybook_alpha.png"), OUT / "tulips.png")
normalize(
    Image.open(TMP / "cherry_tree_storybook_alpha.png"), OUT / "cherry_tree.png"
)
normalize(Image.open(TMP / "daisies_storybook_alpha.png"), OUT / "daisies.png")
normalize(Image.open(TMP / "sunflower_storybook_alpha.png"), OUT / "sunflower.png")
normalize(Image.open(TMP / "lavender_storybook_alpha.png"), OUT / "lavender.png")
normalize(
    Image.open(TMP / "hydrangea_storybook_alpha.png"), OUT / "hydrangea.png"
)
normalize(
    Image.open(TMP / "moon_mushrooms_storybook_alpha.png"),
    OUT / "moon_mushrooms.png",
)

print(f"Prepared 7 plant assets in {OUT}")

for name in (
    "mossy_stone",
    "snail",
    "bird_bath",
    "butterfly",
    "cottage",
    "fox",
    "lantern",
    "cat",
    "acorn_bench",
    "watering_can",
    "wind_chime",
):
    normalize(
        Image.open(TMP / f"{name}_storybook_alpha.png"),
        COLLECTIBLES / f"{name}.png",
    )

print(f"Prepared 11 collectible assets in {COLLECTIBLES}")
