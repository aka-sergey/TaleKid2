#!/usr/bin/env python3
"""
TaleKID UI Asset Optimizer
Downloads all PNG ui-assets from S3, resizes to ≤400px, converts to WebP (quality=82),
re-uploads under the same path but with .webp extension.
"""

import io
import os
import sys
import time
import urllib.request

import boto3
from botocore.exceptions import ClientError
from PIL import Image

# ── S3 config ────────────────────────────────────────────────────────────────
ENDPOINT   = "https://s3.twcstorage.ru"
ACCESS_KEY = "ILEWOHQJS9SA93VZ7OTY"
SECRET_KEY = "jYzbW0MPRRMm0EkowurYXpRQ12eePXRT7BmVl1e3"
BUCKET     = "3e487a89-899c-4ef8-91e2-0900cb899801"
PUBLIC_URL = f"https://s3.twcstorage.ru/{BUCKET}"

MAX_DIM    = 400   # px — more than enough for 2× retina thumbnails
WEBP_QUAL  = 82    # quality 82 keeps visuals crisp at ~70-80% size reduction

# ── All asset paths ───────────────────────────────────────────────────────────
ASSETS = [
    # Worlds (30)
    "ui-assets/worlds/magic-forest.png",
    "ui-assets/worlds/space.png",
    "ui-assets/worlds/underwater.png",
    "ui-assets/worlds/medieval-kingdom.png",
    "ui-assets/worlds/modern-city.png",
    "ui-assets/worlds/dinosaur-world.png",
    "ui-assets/worlds/ancient-legends.png",
    "ui-assets/worlds/underground-world.png",
    "ui-assets/worlds/sky-kingdom.png",
    "ui-assets/worlds/dragon-world.png",
    "ui-assets/worlds/robot-world.png",
    "ui-assets/worlds/enchanted-castle.png",
    "ui-assets/worlds/mysterious-island.png",
    "ui-assets/worlds/wonder-desert.png",
    "ui-assets/worlds/north-pole.png",
    "ui-assets/worlds/jungle.png",
    "ui-assets/worlds/candy-land.png",
    "ui-assets/worlds/dream-world.png",
    "ui-assets/worlds/lost-city.png",
    "ui-assets/worlds/pirate-islands.png",
    "ui-assets/worlds/magic-school.png",
    "ui-assets/worlds/deep-ocean.png",
    "ui-assets/worlds/moon-base.png",
    "ui-assets/worlds/monster-planet.png",
    "ui-assets/worlds/giant-world.png",
    "ui-assets/worlds/miniature-world.png",
    "ui-assets/worlds/cloud-country.png",
    "ui-assets/worlds/shadow-labyrinth.png",
    "ui-assets/worlds/time-kingdom.png",
    "ui-assets/worlds/elemental-world.png",
    # Genres (31)
    "ui-assets/genres/adventure.png",
    "ui-assets/genres/fairy-tale.png",
    "ui-assets/genres/educational.png",
    "ui-assets/genres/friendship.png",
    "ui-assets/genres/funny.png",
    "ui-assets/genres/bedtime.png",
    "ui-assets/genres/detective.png",
    "ui-assets/genres/rescue.png",
    "ui-assets/genres/riddles.png",
    "ui-assets/genres/journey.png",
    "ui-assets/genres/fantasy.png",
    "ui-assets/genres/space-sci-fi.png",
    "ui-assets/genres/animal-stories.png",
    "ui-assets/genres/superheroes.png",
    "ui-assets/genres/light-mystery.png",
    "ui-assets/genres/everyday-stories.png",
    "ui-assets/genres/school-stories.png",
    "ui-assets/genres/moral-stories.png",
    "ui-assets/genres/survival-nature.png",
    "ui-assets/genres/historical-adventure.png",
    "ui-assets/genres/creativity-imagination.png",
    "ui-assets/genres/holiday-stories.png",
    "ui-assets/genres/science-adventure.png",
    "ui-assets/genres/quest-treasure-hunt.png",
    "ui-assets/genres/sea-adventure.png",
    "ui-assets/genres/prehistoric-world.png",
    "ui-assets/genres/robots-technology.png",
    "ui-assets/genres/profession-stories.png",
    "ui-assets/genres/magical-worlds.png",
    "ui-assets/genres/secrets-mysteries.png",
    "ui-assets/genres/self-discovery-growing-up.png",
    # Ages (3)
    "ui-assets/ages/age-3-5.png",
    "ui-assets/ages/age-6-8.png",
    "ui-assets/ages/age-9-12.png",
    # UI (5)
    "ui-assets/ui/hero-create-story.png",
    "ui-assets/ui/empty-library.png",
    "ui-assets/ui/generation-magic.png",
    "ui-assets/ui/landing-hero.png",
    "ui-assets/ui/character-create.png",
]

# ── S3 client ─────────────────────────────────────────────────────────────────
s3 = boto3.client(
    "s3",
    endpoint_url=ENDPOINT,
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    region_name="ru-1",
)


def download_from_s3(key: str) -> bytes:
    resp = s3.get_object(Bucket=BUCKET, Key=key)
    return resp["Body"].read()


def optimize_to_webp(png_bytes: bytes, max_dim: int, quality: int) -> bytes:
    img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
    # Resize if larger than max_dim on either side (keep aspect ratio)
    w, h = img.size
    if w > max_dim or h > max_dim:
        img.thumbnail((max_dim, max_dim), Image.LANCZOS)
    out = io.BytesIO()
    img.save(out, format="WEBP", quality=quality, method=6)
    return out.getvalue()


def upload_webp(key_webp: str, data: bytes) -> None:
    s3.put_object(
        Bucket=BUCKET,
        Key=key_webp,
        Body=data,
        ContentType="image/webp",
        ACL="public-read",
    )


def human_kb(n: int) -> str:
    return f"{n/1024:.1f} KB"


def main():
    total_orig = 0
    total_new  = 0
    errors     = []

    print(f"🔧  Processing {len(ASSETS)} assets  (max {MAX_DIM}px, WebP q{WEBP_QUAL})\n")

    for i, key_png in enumerate(ASSETS, 1):
        key_webp = key_png.replace(".png", ".webp")
        name     = os.path.basename(key_png)

        try:
            # Download original PNG
            png_bytes = download_from_s3(key_png)
            orig_size = len(png_bytes)

            # Optimize → WebP
            webp_bytes = optimize_to_webp(png_bytes, MAX_DIM, WEBP_QUAL)
            new_size   = len(webp_bytes)

            # Upload
            upload_webp(key_webp, webp_bytes)

            pct = (1 - new_size / orig_size) * 100
            total_orig += orig_size
            total_new  += new_size

            print(
                f"  [{i:02d}/{len(ASSETS)}] ✅  {name:<40} "
                f"{human_kb(orig_size):>9} → {human_kb(new_size):>9}  "
                f"(-{pct:.0f}%)"
            )
        except Exception as e:
            print(f"  [{i:02d}/{len(ASSETS)}] ❌  {name:<40} ERROR: {e}")
            errors.append((key_png, str(e)))

        # Small pause to avoid hammering S3
        time.sleep(0.1)

    # ── Summary ──────────────────────────────────────────────────────────────
    print()
    print("=" * 65)
    saved     = total_orig - total_new
    saved_pct = (1 - total_new / total_orig) * 100 if total_orig else 0
    print(f"  Total original : {total_orig/1024/1024:.1f} MB")
    print(f"  Total optimized: {total_new/1024/1024:.1f} MB")
    print(f"  Saved          : {saved/1024/1024:.1f} MB  (-{saved_pct:.0f}%)")
    if errors:
        print(f"\n  ⚠️  {len(errors)} errors:")
        for k, e in errors:
            print(f"     {k}: {e}")
    else:
        print("\n  🎉  All assets optimized successfully!")
    print("=" * 65)

    return len(errors)


if __name__ == "__main__":
    sys.exit(main())
