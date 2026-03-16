#!/usr/bin/env python3
"""
Generate 4 showcase stories + 5 UI images for TaleKID landing page.

Usage:
  pip install httpx boto3 python-dotenv openai psycopg2-binary
  python generate_showcase.py
"""

import json
import os
import ssl
import time
import uuid

import boto3
import httpx
import psycopg2
from dotenv import load_dotenv
from openai import OpenAI

# ── Load env ──────────────────────────────────────────────────────────────────
# Try Railway vars first (already exported), then .env file
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

OPENAI_API_KEY = os.environ["OPENAI_API_KEY"]
LEONARDO_API_KEY = os.environ["LEONARDO_API_KEY"]

PG_HOST = os.environ["POSTGRESQL_HOST"]
PG_PORT = int(os.environ.get("POSTGRESQL_PORT", "5432"))
PG_USER = os.environ["POSTGRESQL_USER"]
PG_PASS = os.environ["POSTGRESQL_PASSWORD"]
PG_DB = os.environ["POSTGRESQL_DBNAME"]
PG_SSLMODE = os.environ.get("POSTGRESQL_SSLMODE", "verify-full")

S3_ENDPOINT = os.environ["S3_ENDPOINT_URL"]
S3_KEY = os.environ["S3_ACCESS_KEY_ID"]
S3_SECRET = os.environ["S3_SECRET_ACCESS_KEY"]
S3_BUCKET = os.environ["S3_BUCKET"]
STORAGE_URL = os.environ["STORAGE_PUBLIC_URL"]

LEONARDO_API_BASE = "https://cloud.leonardo.ai/api/rest/v1"
LEONARDO_MODEL_ID = "6b645e3a-d64f-4341-a6d8-7a3690fbf042"  # Phoenix

NEGATIVE_PROMPT = (
    "ugly, deformed, blurry, low quality, text, words, letters, numbers, "
    "watermark, signature, adult content, violence, scary, horror"
)

# ── S3 client ─────────────────────────────────────────────────────────────────
s3 = boto3.client(
    "s3",
    endpoint_url=S3_ENDPOINT,
    aws_access_key_id=S3_KEY,
    aws_secret_access_key=S3_SECRET,
)

# ── OpenAI client ─────────────────────────────────────────────────────────────
openai_client = OpenAI(api_key=OPENAI_API_KEY)

# ── Leonardo headers ──────────────────────────────────────────────────────────
LEO_HEADERS = {
    "Authorization": f"Bearer {LEONARDO_API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json",
}

# ── PostgreSQL connection ─────────────────────────────────────────────────────

def get_pg_conn():
    """Create PostgreSQL connection with SSL."""
    return psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_USER,
        password=PG_PASS,
        dbname=PG_DB,
        sslmode="require",
    )


# ── Story definitions ─────────────────────────────────────────────────────────

STORIES = [
    {
        "key": "tale1",
        "genre_slug": "fairy-tale",
        "world_slug": "enchanted-forest",
        "style_prefix": (
            "Soft watercolor illustration, wet-on-wet technique, loose flowing "
            "brushstrokes, visible paper texture, delicate color bleeds, "
            "traditional children's book art, warm pastel tones."
        ),
        "preset_style": "ILLUSTRATION",
        "badge": "Акварель",
        "badge_color": "#059669",
        "gpt_prompt": """Ты — детский писатель. Напиши сказку на русском языке для детей 3-5 лет.
Сказка: «Маша и Двенадцать Месяцев»
Сюжет: Маша идёт в зимний лес за подснежниками. Встречает двенадцать братьев-Месяцев у волшебного костра. Апрель дарит ей весну — подснежники расцветают прямо на снегу. Маша возвращается с цветами и добрым сердцем.
Главный герой: Девочка Маша, 4 года, кудрявые русые волосы, голубые глаза, красное пальто с мехом, красные варежки.

Требования:
- Ровно 10 страниц
- Каждая страница: 3-5 предложений, простой язык для малышей
- На каждой странице добавь образовательный контент: интересный факт ИЛИ вопрос ребёнку
- Главный герой: описание выше

Ответь СТРОГО в JSON формате:
{
  "title": "Название сказки",
  "pages": [
    {
      "page_number": 1,
      "text": "Текст страницы...",
      "image_prompt": "Detailed English prompt for illustration: описание сцены для иллюстрации, включи описание персонажа",
      "educational": {
        "type": "fact",
        "text": "Текст факта или вопроса на русском",
        "answer": null,
        "topic": "природа"
      }
    }
  ]
}""",
    },
    {
        "key": "tale2",
        "genre_slug": "adventure",
        "world_slug": "space",
        "style_prefix": (
            "3D rendered illustration in Pixar animation style, smooth rounded "
            "characters, subsurface scattering, vibrant saturated colors, "
            "cinematic lighting, depth of field, polished CGI look, big "
            "expressive eyes."
        ),
        "preset_style": "ILLUSTRATION",
        "badge": "3D Анимация",
        "badge_color": "#6366F1",
        "gpt_prompt": """Ты — детский писатель. Напиши сказку на русском языке для детей 3-5 лет.
Сказка: «Дима и Звёздный Кот»
Сюжет: Дима и кот Барсик строят ракету из картонной коробки, но она оживает и уносит их в космос. Они летят мимо планет, встречают добрых инопланетян, помогают починить сломанную звезду и находят дорогу домой по Полярной звезде.
Главный герой: Мальчик Дима, 5 лет, рыжие вихрастые волосы, веснушки, зелёные глаза, оранжевый скафандр. Компаньон — пушистый серый кот Барсик в маленьком синем скафандре.

Требования:
- Ровно 10 страниц
- Каждая страница: 3-5 предложений, простой язык для малышей
- На каждой странице добавь образовательный контент: интересный факт ИЛИ вопрос ребёнку

Ответь СТРОГО в JSON формате:
{
  "title": "Название сказки",
  "pages": [
    {
      "page_number": 1,
      "text": "Текст страницы...",
      "image_prompt": "Detailed English prompt for illustration: описание сцены для иллюстрации, включи описание персонажей",
      "educational": {
        "type": "fact",
        "text": "Текст факта или вопроса на русском",
        "answer": null,
        "topic": "космос"
      }
    }
  ]
}""",
    },
    {
        "key": "tale3",
        "genre_slug": "fairy-tale",
        "world_slug": "underwater",
        "style_prefix": (
            "Classic Disney 2D animation style, clean flowing linework, "
            "cel-shaded coloring, rich jewel-tone palette, dramatic theatrical "
            "lighting, large expressive eyes, lush painted backgrounds, "
            "reminiscent of The Little Mermaid."
        ),
        "preset_style": "ILLUSTRATION",
        "badge": "Disney",
        "badge_color": "#DB2777",
        "gpt_prompt": """Ты — детский писатель. Напиши сказку на русском языке для детей 3-5 лет.
Сказка: «Алиса и Коралловое Королевство»
Сюжет: Русалочка Алиса узнаёт что коралловый дворец теряет цвета. Она отправляется в путешествие по океану, собирает волшебные жемчужины у добрых обитателей моря, возвращает краски дворцу и устраивает праздник для всего подводного королевства.
Главный герой: Девочка-русалка Алиса, 4 года, длинные тёмные волосы, карие глаза, бирюзово-фиолетовый хвост. Компаньон — золотистый морской конёк Лучик.

Требования:
- Ровно 10 страниц
- Каждая страница: 3-5 предложений, простой язык для малышей
- На каждой странице добавь образовательный контент: интересный факт ИЛИ вопрос ребёнку

Ответь СТРОГО в JSON формате:
{
  "title": "Название сказки",
  "pages": [
    {
      "page_number": 1,
      "text": "Текст страницы...",
      "image_prompt": "Detailed English prompt for illustration: описание сцены для иллюстрации, включи описание персонажей",
      "educational": {
        "type": "fact",
        "text": "Текст факта или вопроса на русском",
        "answer": null,
        "topic": "океан"
      }
    }
  ]
}""",
    },
    {
        "key": "tale4",
        "genre_slug": "adventure",
        "world_slug": "modern-city",
        "style_prefix": (
            "Bold comic book illustration, thick black ink outlines, dynamic "
            "poses, Ben-Day dots halftone, vivid pop-art colors, speed lines, "
            "dramatic angles, child-friendly superhero art, expressive "
            "exaggerated features."
        ),
        "preset_style": "ILLUSTRATION",
        "badge": "Комикс",
        "badge_color": "#D97706",
        "gpt_prompt": """Ты — детский писатель. Напиши сказку на русском языке для детей 3-5 лет.
Сказка: «Супергерой Тимофей»
Сюжет: Тимофей находит волшебный плащ в шкафу дедушки. Плащ даёт ему суперсилу — он может летать и становиться очень сильным. Тимофей спасает котёнка, помогает бабушке, ловит воздушный шарик для девочки. В конце узнаёт что настоящая суперсила — доброе сердце.
Главный герой: Мальчик Тимофей, 5 лет, короткие чёрные волосы, смелые тёмные глаза, жёлто-синий костюм супергероя с буквой «Т» на груди, синяя маска, синий плащ.

Требования:
- Ровно 10 страниц
- Каждая страница: 3-5 предложений, простой язык для малышей
- На каждой странице добавь образовательный контент: интересный факт ИЛИ вопрос ребёнку

Ответь СТРОГО в JSON формате:
{
  "title": "Название сказки",
  "pages": [
    {
      "page_number": 1,
      "text": "Текст страницы...",
      "image_prompt": "Detailed English prompt for illustration: описание сцены для иллюстрации, включи описание персонажа",
      "educational": {
        "type": "fact",
        "text": "Текст факта или вопроса на русском",
        "answer": null,
        "topic": "город"
      }
    }
  ]
}""",
    },
]

UI_IMAGES = [
    {
        "key": "hero_bg",
        "width": 1536,
        "height": 768,
        "s3_key": "landing-assets/ui/hero-bg.png",
        "prompt": (
            "Breathtaking panoramic fantasy landscape for children's storybook. "
            "Enchanted rolling hills, winding golden path to distant magical "
            "castle with glowing windows, enormous ancient tree with fairy "
            "lights, fireflies sparkles in warm golden-hour light, painted "
            "sunset sky pink purple, butterflies wildflowers foreground. Warm "
            "inviting magical. Watercolor gouache, vibrant, dreamy. Wide "
            "panoramic, no characters. High detail."
        ),
    },
    {
        "key": "how_step1",
        "width": 512,
        "height": 512,
        "s3_key": "landing-assets/ui/how-step1.png",
        "prompt": (
            "Children's watercolor illustration. Magical character creation — "
            "child's photo in golden frame transforming into storybook "
            "character in swirl of golden sparkles. Paint brushes pencils "
            "floating, color splashes. Warm pastels gold accents. Light background."
        ),
    },
    {
        "key": "how_step2",
        "width": 512,
        "height": 512,
        "s3_key": "landing-assets/ui/how-step2.png",
        "prompt": (
            "Children's watercolor illustration. Magical story settings as "
            "glowing circular portals showing different worlds — forest, space, "
            "underwater, castle. Sparkles connecting them, wand making one "
            "glow. Vibrant, each portal own color. Light background."
        ),
    },
    {
        "key": "how_step3",
        "width": 512,
        "height": 512,
        "s3_key": "landing-assets/ui/how-step3.png",
        "prompt": (
            "Children's watercolor illustration. Warm bedtime scene — parent "
            "and child in armchair reading glowing storybook. Magical scenes "
            "float above book. Lamp golden light, teddy bear, cat, starry "
            "window. Warm golden tones."
        ),
    },
    {
        "key": "cta_bg",
        "width": 1536,
        "height": 768,
        "s3_key": "landing-assets/ui/cta-bg.png",
        "prompt": (
            "Magical starry night sky panorama. Deep blue-purple sky, twinkling "
            "stars, crescent moon warm glow, soft aurora green pink, shooting "
            "stars golden trails. Bottom — silhouettes fairy tale rooftops "
            "trees. Rich blues purples golden highlights. Wide. Watercolor gouache."
        ),
    },
]


# ── Helper functions ──────────────────────────────────────────────────────────

def generate_text_with_gpt(prompt: str) -> dict:
    """Call GPT-4o to generate story text. Returns parsed JSON dict."""
    print("  📝 Calling GPT-4o for story text...")
    response = openai_client.chat.completions.create(
        model="gpt-4o",
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.8,
        max_tokens=4096,
    )
    content = response.choices[0].message.content
    return json.loads(content)


def leonardo_generate(
    prompt: str,
    width: int = 1024,
    height: int = 768,
    preset_style: str = "ILLUSTRATION",
) -> str:
    """Generate image with Leonardo AI. Returns image URL."""
    body = {
        "modelId": LEONARDO_MODEL_ID,
        "prompt": prompt,
        "negative_prompt": NEGATIVE_PROMPT,
        "width": width,
        "height": height,
        "num_images": 1,
        "alchemy": True,
        "photoReal": False,
        "contrastRatio": 0.5,
        "presetStyle": preset_style,
    }

    with httpx.Client(timeout=120.0) as client:
        # Submit
        resp = client.post(
            f"{LEONARDO_API_BASE}/generations",
            headers=LEO_HEADERS,
            json=body,
        )
        resp.raise_for_status()
        gen_id = resp.json()["sdGenerationJob"]["generationId"]
        print(f"    🎨 Leonardo generation: {gen_id}")

        # Poll
        for attempt in range(90):
            time.sleep(4)
            resp = client.get(
                f"{LEONARDO_API_BASE}/generations/{gen_id}",
                headers=LEO_HEADERS,
            )
            resp.raise_for_status()
            gen_data = resp.json().get("generations_by_pk", {})
            status = gen_data.get("status")

            if status == "COMPLETE":
                images = gen_data.get("generated_images", [])
                if images:
                    url = images[0]["url"]
                    print(f"    ✅ Image ready: {url[:60]}...")
                    return url
                raise RuntimeError("No images in COMPLETE response")

            if status == "FAILED":
                raise RuntimeError(f"Leonardo generation {gen_id} FAILED")

            if attempt % 5 == 0:
                print(f"    ⏳ Polling... attempt {attempt+1}, status={status}")

        raise TimeoutError(f"Leonardo generation {gen_id} timed out")


def download_image(url: str) -> bytes:
    """Download image bytes from URL."""
    with httpx.Client(timeout=60.0) as client:
        resp = client.get(url)
        resp.raise_for_status()
        return resp.content


def upload_to_s3(data: bytes, key: str) -> str:
    """Upload bytes to S3. Returns public URL."""
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=key,
        Body=data,
        ContentType="image/png",
        CacheControl="public, max-age=31536000",
    )
    public_url = f"{STORAGE_URL}/{key}"
    print(f"    ☁️  S3: {public_url}")
    return public_url


def get_or_create_demo_user(cur) -> str:
    """Create demo user or get existing one. Returns user_id as string."""
    cur.execute("""
        INSERT INTO users (id, email, password_hash, display_name)
        VALUES (gen_random_uuid(), 'demo@talekid.ai', '$2b$12$demo_hash_placeholder', 'TaleKID Demo')
        ON CONFLICT (email) DO UPDATE SET display_name = 'TaleKID Demo'
        RETURNING id::text
    """)
    return cur.fetchone()[0]


def get_catalog_id(cur, table: str, slug: str) -> int:
    """Get genre or world ID by slug."""
    cur.execute(f"SELECT id FROM {table} WHERE slug = %s LIMIT 1", (slug,))
    row = cur.fetchone()
    if not row:
        raise ValueError(f"{table} with slug '{slug}' not found in DB")
    return row[0]


# ── Main flow ─────────────────────────────────────────────────────────────────

def main():
    results = {}  # key → {story_id, cover_url, page_urls, title, pages_data}

    # ── Connect to DB ──
    print("\n🗄️  Connecting to PostgreSQL...")
    conn = get_pg_conn()
    conn.autocommit = False
    cur = conn.cursor()

    # ── Demo user ──
    demo_user_id = get_or_create_demo_user(cur)
    conn.commit()
    print(f"  👤 Demo user: {demo_user_id}")

    # ── Process each story ──
    for i, story_def in enumerate(STORIES, 1):
        key = story_def["key"]
        print(f"\n{'='*60}")
        print(f"📖 Story {i}/4: {key}")
        print(f"{'='*60}")

        # Get catalog IDs
        genre_id = get_catalog_id(cur, "genres", story_def["genre_slug"])
        world_id = get_catalog_id(cur, "worlds", story_def["world_slug"])
        print(f"  Genre: {story_def['genre_slug']} (id={genre_id})")
        print(f"  World: {story_def['world_slug']} (id={world_id})")

        # Generate text with GPT-4o
        story_data = generate_text_with_gpt(story_def["gpt_prompt"])
        title = story_data["title"]
        pages = story_data["pages"]
        print(f"  📖 Title: {title}")
        print(f"  📄 Pages: {len(pages)}")

        # Create story record in DB
        story_id = str(uuid.uuid4())
        cur.execute("""
            INSERT INTO stories (id, user_id, title, title_suggested, genre_id, world_id,
                                 age_range, education_level, page_count, reading_duration_minutes,
                                 status)
            VALUES (%s, %s, %s, %s, %s, %s, '3-5', 0.5, 10, 10, 'completed')
        """, (story_id, demo_user_id, title, title, genre_id, world_id))
        conn.commit()
        print(f"  🆔 Story ID: {story_id}")

        # Generate illustrations & upload
        page_urls = {}
        page_texts = {}
        for pg in pages:
            pn = pg["page_number"]
            print(f"\n  📄 Page {pn}/10:")

            # Generate illustration
            full_prompt = f"{story_def['style_prefix']} {pg['image_prompt']}"
            try:
                image_url = leonardo_generate(
                    prompt=full_prompt,
                    width=1024,
                    height=768,
                    preset_style=story_def["preset_style"],
                )
            except Exception as e:
                print(f"    ⚠️ Leonardo failed ({e}), trying ILLUSTRATION preset...")
                image_url = leonardo_generate(
                    prompt=full_prompt,
                    width=1024,
                    height=768,
                    preset_style="ILLUSTRATION",
                )

            # Download & upload to S3
            img_bytes = download_image(image_url)
            s3_key = f"stories/{story_id}/pages/{pn}.png"
            public_url = upload_to_s3(img_bytes, s3_key)
            page_urls[pn] = public_url
            page_texts[pn] = pg["text"]

            # Also save as cover if page 1
            if pn == 1:
                cover_key = f"stories/{story_id}/cover.png"
                cover_url = upload_to_s3(img_bytes, cover_key)

            # Insert page into DB
            page_id = str(uuid.uuid4())
            cur.execute("""
                INSERT INTO pages (id, story_id, page_number, text_content, image_url,
                                   image_s3_key, image_prompt)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (page_id, story_id, pn, pg["text"], public_url, s3_key, pg["image_prompt"]))

            # Insert educational content
            edu = pg.get("educational")
            if edu:
                cur.execute("""
                    INSERT INTO educational_content (id, page_id, content_type, text_ru, answer_ru, topic)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (str(uuid.uuid4()), page_id, edu["type"], edu["text"],
                      edu.get("answer"), edu.get("topic")))

            conn.commit()

            # Pause between generations
            print("    ⏳ Waiting 5s before next generation...")
            time.sleep(5)

        # Update story with cover
        cur.execute("""
            UPDATE stories SET cover_image_url = %s WHERE id = %s
        """, (cover_url, story_id))
        conn.commit()

        results[key] = {
            "story_id": story_id,
            "title": title,
            "cover_url": cover_url,
            "page_urls": page_urls,
            "page_texts": page_texts,
        }

    # ── Generate 5 UI images ──
    print(f"\n{'='*60}")
    print("🎨 Generating 5 UI images for landing page")
    print(f"{'='*60}")

    ui_urls = {}
    for ui_img in UI_IMAGES:
        print(f"\n  🖼️  {ui_img['key']}:")
        image_url = leonardo_generate(
            prompt=ui_img["prompt"],
            width=ui_img["width"],
            height=ui_img["height"],
            preset_style="ILLUSTRATION",
        )
        img_bytes = download_image(image_url)
        public_url = upload_to_s3(img_bytes, ui_img["s3_key"])
        ui_urls[ui_img["key"]] = public_url
        print("    ⏳ Waiting 5s...")
        time.sleep(5)

    cur.close()
    conn.close()

    # ── Generate landing_assets.dart ──
    print(f"\n{'='*60}")
    print("📝 Generating landing_assets.dart")
    print(f"{'='*60}")

    dart_path = os.path.join(
        os.path.dirname(__file__),
        "flutter_app", "lib", "config", "landing_assets.dart",
    )

    dart_lines = [
        "/// Auto-generated by generate_showcase.py — DO NOT EDIT",
        "class LandingAssets {",
        "  LandingAssets._();",
        "",
        "  // ── UI backgrounds ──",
        f"  static const String heroBg = '{ui_urls['hero_bg']}';",
        f"  static const String ctaBg = '{ui_urls['cta_bg']}';",
        f"  static const String howStep1 = '{ui_urls['how_step1']}';",
        f"  static const String howStep2 = '{ui_urls['how_step2']}';",
        f"  static const String howStep3 = '{ui_urls['how_step3']}';",
        "",
        "  // ── Showcase story IDs ──",
    ]

    for i, sdef in enumerate(STORIES, 1):
        r = results[sdef["key"]]
        dart_lines.append(f"  static const String tale{i}Id = '{r['story_id']}';")

    dart_lines.append("")
    dart_lines.append("  // ── Showcase covers ──")
    for i, sdef in enumerate(STORIES, 1):
        r = results[sdef["key"]]
        dart_lines.append(f"  static const String tale{i}Cover = '{r['cover_url']}';")

    dart_lines.append("")
    dart_lines.append("  // ── Showcase page images (pages 3 and 7) ──")
    for i, sdef in enumerate(STORIES, 1):
        r = results[sdef["key"]]
        dart_lines.append(f"  static const String tale{i}Page3 = '{r['page_urls'].get(3, '')}';")
        dart_lines.append(f"  static const String tale{i}Page7 = '{r['page_urls'].get(7, '')}';")

    dart_lines.append("")
    dart_lines.append("  // ── Showcase page texts (pages 1, 3, 7) ──")
    for i, sdef in enumerate(STORIES, 1):
        r = results[sdef["key"]]
        for pn in [1, 3, 7]:
            text = r["page_texts"].get(pn, "").replace("'", "\\'").replace("\n", "\\n")
            dart_lines.append(f"  static const String tale{i}Text{pn} = '{text}';")

    dart_lines.append("")
    dart_lines.append("  // ── Showcase titles ──")
    for i, sdef in enumerate(STORIES, 1):
        r = results[sdef["key"]]
        dart_lines.append(f"  static const String tale{i}Title = '{r['title']}';")

    dart_lines.append("}")
    dart_lines.append("")

    os.makedirs(os.path.dirname(dart_path), exist_ok=True)
    with open(dart_path, "w") as f:
        f.write("\n".join(dart_lines))
    print(f"  ✅ Written: {dart_path}")

    # ── Summary ──
    print(f"\n{'='*60}")
    print("🎉 DONE!")
    print(f"{'='*60}")
    print(f"  Stories created: {len(results)}")
    print(f"  UI images: {len(ui_urls)}")
    for i, sdef in enumerate(STORIES, 1):
        r = results[sdef["key"]]
        print(f"  Tale {i}: {r['title']} → {r['story_id']}")
    print(f"\n  landing_assets.dart → {dart_path}")
    print("\nNext: Rewrite landing_screen.dart with the new assets!")


if __name__ == "__main__":
    main()
