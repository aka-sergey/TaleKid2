"""Generate 8 illustration style cover images for the landing page styles section."""

import os
import time
import json
import httpx
import boto3

LEONARDO_API_KEY = "0d7c3025-2971-486d-946f-a60cf83f272f"
LEONARDO_API_BASE = "https://cloud.leonardo.ai/api/rest/v1"
LEONARDO_MODEL_ID = "6b645e3a-d64f-4341-a6d8-7a3690fbf042"

S3_ENDPOINT_URL = "https://s3.twcstorage.ru"
S3_ACCESS_KEY_ID = "ILEWOHQJS9SA93VZ7OTY"
S3_SECRET_ACCESS_KEY = "jYzbW0MPRRMm0EkowurYXpRQ12eePXRT7BmVl1e3"
S3_BUCKET = "3e487a89-899c-4ef8-91e2-0900cb899801"
STORAGE_PUBLIC_URL = f"https://s3.twcstorage.ru/{S3_BUCKET}"

HEADERS = {
    "Authorization": f"Bearer {LEONARDO_API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json",
}

# 8 popular illustration styles with prompts
STYLES = [
    {
        "name": "Акварель",
        "slug": "watercolor",
        "prompt": "Watercolor illustration, a little girl in a red coat walking through a magical snowy forest with glowing lanterns hanging from trees, soft watercolor texture, pastel colors, delicate brushstrokes, warm cozy atmosphere, children's book illustration",
        "preset": "ILLUSTRATION",
    },
    {
        "name": "3D Анимация (Pixar)",
        "slug": "3d-pixar",
        "prompt": "3D rendered Pixar-style illustration, a cheerful boy with red curly hair and freckles riding a cardboard rocket through colorful outer space with cute planets and smiling stars, vibrant colors, smooth 3D render, Pixar quality, children's animation style",
        "preset": "ILLUSTRATION",
    },
    {
        "name": "Disney",
        "slug": "disney",
        "prompt": "Disney-style illustration, a beautiful little mermaid princess with long dark hair swimming through a magical coral palace with colorful fish and glowing jellyfish, Disney princess art style, vibrant ocean colors, magical sparkles, children's fairy tale",
        "preset": "ILLUSTRATION",
    },
    {
        "name": "Комикс",
        "slug": "comic",
        "prompt": "Comic book style illustration, a brave young superhero boy in a blue and yellow costume with cape flying over a modern city at sunset, dynamic comic book art, bold outlines, action poses, bright superhero colors, children's comic book",
        "preset": "ILLUSTRATION",
    },
    {
        "name": "Аниме",
        "slug": "anime",
        "prompt": "Anime style illustration, a young girl adventurer with big sparkling eyes and a magical staff standing in front of a crystal cave entrance, cherry blossom petals floating, Japanese anime art style, soft lighting, detailed background, kawaii children's anime",
        "preset": "ANIME",
    },
    {
        "name": "Пастель",
        "slug": "pastel",
        "prompt": "Soft pastel illustration, a little boy and his fluffy rabbit friend sitting on a cloud and looking at a rainbow, extremely soft pastel colors, dreamy atmosphere, gentle chalk-like texture, nursery art style, calming children's illustration",
        "preset": "ILLUSTRATION",
    },
    {
        "name": "Книжная классика",
        "slug": "classic-book",
        "prompt": "Classic storybook illustration, a prince on a white horse approaching an enchanted castle with towers and flags, traditional fairy tale art style, detailed pen and ink with color wash, golden age of illustration style, Arthur Rackham inspired, children's classic book",
        "preset": "ILLUSTRATION",
    },
    {
        "name": "Поп-арт",
        "slug": "pop-art",
        "prompt": "Pop art style illustration, a joyful girl with bright pink hair and star-shaped sunglasses riding a unicorn through a candy land with lollipop trees and rainbow rivers, bold pop art colors, Roy Lichtenstein inspired dots pattern, modern vibrant children's art",
        "preset": "ILLUSTRATION",
    },
]


def generate_image(prompt, preset="ILLUSTRATION"):
    """Submit generation and poll until complete."""
    body = {
        "modelId": LEONARDO_MODEL_ID,
        "prompt": prompt,
        "negative_prompt": "ugly, deformed, blurry, low quality, text, watermark, signature, adult content, violence, scary, horror",
        "width": 1024,
        "height": 768,
        "num_images": 1,
        "alchemy": True,
        "photoReal": False,
        "contrastRatio": 0.5,
    }
    if preset:
        body["presetStyle"] = preset

    with httpx.Client(timeout=120.0) as client:
        # Submit
        resp = client.post(f"{LEONARDO_API_BASE}/generations", headers=HEADERS, json=body)
        resp.raise_for_status()
        gen_id = resp.json()["sdGenerationJob"]["generationId"]
        print(f"  Generation submitted: {gen_id}")

        # Poll
        for attempt in range(60):
            time.sleep(3)
            resp = client.get(f"{LEONARDO_API_BASE}/generations/{gen_id}", headers=HEADERS)
            resp.raise_for_status()
            data = resp.json().get("generations_by_pk", {})
            status = data.get("status")
            if status == "COMPLETE":
                images = data.get("generated_images", [])
                if images:
                    return images[0]["url"]
                raise RuntimeError("No images in complete generation")
            if status == "FAILED":
                raise RuntimeError(f"Generation {gen_id} failed")
            if attempt % 5 == 0:
                print(f"  Polling {gen_id}: attempt {attempt+1}, status={status}")

        raise TimeoutError(f"Generation {gen_id} timed out")


def upload_to_s3(image_url, s3_key):
    """Download image and upload to S3."""
    with httpx.Client(timeout=60.0) as client:
        resp = client.get(image_url)
        resp.raise_for_status()
        image_data = resp.content

    s3 = boto3.client(
        "s3",
        endpoint_url=S3_ENDPOINT_URL,
        aws_access_key_id=S3_ACCESS_KEY_ID,
        aws_secret_access_key=S3_SECRET_ACCESS_KEY,
    )
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=image_data,
        ContentType="image/png",
        ACL="public-read",
    )
    return f"{STORAGE_PUBLIC_URL}/{s3_key}"


def main():
    urls = []
    for i, style in enumerate(STYLES):
        print(f"\n[{i+1}/8] Generating: {style['name']} ({style['slug']})")
        try:
            img_url = generate_image(style["prompt"], style["preset"])
            print(f"  Generated: {img_url}")

            s3_key = f"landing-assets/styles/{style['slug']}.png"
            public_url = upload_to_s3(img_url, s3_key)
            print(f"  Uploaded: {public_url}")
            urls.append(public_url)
        except Exception as e:
            print(f"  ERROR: {e}")
            urls.append("")

    print("\n\n=== RESULTS ===")
    for i, (style, url) in enumerate(zip(STYLES, urls)):
        print(f"{style['name']}: {url}")

    # Output as Dart list
    print("\n\n=== DART CODE ===")
    print("static const List<String> styleCovers = [")
    for url in urls:
        print(f"  '{url}',")
    print("];")


if __name__ == "__main__":
    main()
