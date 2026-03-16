"""
Generate cover images for all new genres and worlds via Leonardo AI.
Uploads to S3 and outputs Dart constants.
"""
import time
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

# ── NEW GENRES (not yet in wizard_screen.dart _genreAssets) ──────────────────
NEW_GENRES = [
    ("detective", "Children's book illustration, a cute young detective kid with magnifying glass investigating clues in a cozy library, cartoon style, warm lighting"),
    ("rescue", "Children's book illustration, a brave young hero rescuing a fluffy animal from a tall tree, bright colors, action scene, cheerful cartoon style"),
    ("riddles", "Children's book illustration, a magical glowing question mark surrounded by puzzles, keys, treasure boxes and mysterious symbols, whimsical children's art"),
    ("journey", "Children's book illustration, a cheerful child with a backpack walking along a winding road through colorful landscapes, mountains and forests, adventure"),
    ("fantasy", "Children's book illustration, a young wizard child casting colorful spells, magical crystals, glowing potions and enchanted books floating around, fantasy"),
    ("space-sci-fi", "Children's book illustration, a young astronaut child floating in space near colorful planets and stars, rocket ship nearby, bright cartoon space adventure"),
    ("animal-stories", "Children's book illustration, a group of cute cartoon animals having a picnic in a sunny meadow — fox, rabbit, bear, owl — bright friendly colors"),
    ("superheroes", "Children's book illustration, a young child wearing a colorful superhero costume flying over a cartoon city at sunset, dynamic pose, bright cape"),
    ("light-mystery", "Children's book illustration, a curious child with a lantern exploring a magical glowing forest at night, soft mysterious atmosphere, gentle moonlight"),
    ("everyday-stories", "Children's book illustration, a happy family having breakfast together in a cozy colorful kitchen, warm morning light, everyday life, cheerful cartoon"),
    ("school-stories", "Children's book illustration, cheerful children at school desks with colorful books, pencils, backpacks and a friendly teacher, bright classroom"),
    ("moral-stories", "Children's book illustration, a kind child sharing food with animals and friends in a sunny park, warm golden light, heartwarming scene"),
    ("survival-nature", "Children's book illustration, a child building a cozy shelter in a lush forest, woodland animals helping, adventure camping scene, bright nature colors"),
    ("historical-adventure", "Children's book illustration, a young adventurer exploring ancient ruins and temples with a treasure map, torches, mysterious artifacts"),
    ("creativity-imagination", "Children's book illustration, a child painting a magical world that comes to life from the canvas — rainbow, butterflies, flowers emerging"),
    ("holiday-stories", "Children's book illustration, children celebrating a joyful holiday with colorful decorations, balloons, cake, fireworks and smiling faces"),
    ("science-adventure", "Children's book illustration, a young scientist child doing colorful experiments in a laboratory, bubbling potions, rockets, robots, bright STEM art"),
    ("quest-treasure-hunt", "Children's book illustration, children following a treasure map through a magical forest, X marks the spot, glowing treasure chest found"),
    ("sea-adventure", "Children's book illustration, a brave young sailor child on a colorful boat sailing through sparkling ocean waves, seagulls, dolphins jumping alongside"),
    ("prehistoric-world", "Children's book illustration, a child adventurer riding a friendly cartoon dinosaur through a lush prehistoric jungle with volcanoes and ferns"),
    ("robots-technology", "Children's book illustration, a young inventor child with a friendly robot helper in a colorful workshop, gears, gadgets and glowing screens"),
    ("profession-stories", "Children's book illustration, a child dressed as a doctor, firefighter and baker — three panels showing different profession adventures, bright colors"),
    ("magical-worlds", "Children's book illustration, a child stepping through a magical portal into a glowing rainbow world with floating castles and fairy creatures"),
    ("secrets-mysteries", "Children's book illustration, a young detective child discovering a secret door behind a bookshelf in a cozy candlelit library, mysterious atmosphere"),
    ("self-discovery-growing-up", "Children's book illustration, a child looking at their reflection in a magical mirror showing their future self, garden of possibilities around them"),
]

# ── NEW WORLDS (not yet in wizard_screen.dart _worldAssets) ──────────────────
NEW_WORLDS = [
    ("ancient-legends", "Children's book illustration, magical ancient temple ruins covered in glowing vines, mysterious stone statues, golden light through jungle canopy"),
    ("underground-world", "Children's book illustration, a magical underground world with glowing crystals, mushroom forests, underground rivers and friendly cave creatures"),
    ("sky-kingdom", "Children's book illustration, a beautiful floating kingdom on clouds, rainbow bridges between islands, sky castles with colorful flags and hot air balloons"),
    ("dragon-world", "Children's book illustration, a majestic mountain valley filled with friendly colorful dragons, dragon caves with gems, soft glowing magical atmosphere"),
    ("robot-world", "Children's book illustration, a futuristic world of friendly colorful robots and machines in a city with glowing neon lights and flying vehicles"),
    ("enchanted-castle", "Children's book illustration, a magical glowing castle at night with towers, moat, drawbridge, fireflies and moonlight, enchanted fairy tale atmosphere"),
    ("mysterious-island", "Children's book illustration, a tropical island with hidden caves, ancient ruins, colorful parrots, waterfalls and mysterious glowing plants"),
    ("wonder-desert", "Children's book illustration, a magical desert with golden dunes, colorful oasis with palm trees, flying carpets, magical lamps and starry night sky"),
    ("north-pole", "Children's book illustration, a cozy magical North Pole with colorful Northern Lights, friendly polar bears, reindeer, an elf workshop and snow igloos"),
    ("jungle", "Children's book illustration, a vibrant tropical jungle with colorful exotic birds, friendly tigers, monkeys swinging on vines, waterfalls and giant flowers"),
    ("candy-land", "Children's book illustration, a magical candy land with chocolate rivers, lollipop trees, gingerbread houses, rainbow candy mountains and sugar clouds"),
    ("dream-world", "Children's book illustration, a surreal dreamy world with floating islands, upside-down castles, clouds you can walk on, soft pastel colors and stars"),
    ("lost-city", "Children's book illustration, ancient lost city in the jungle with glowing golden temples, waterfalls, mysterious ruins and magical creatures guarding"),
    ("pirate-islands", "Children's book illustration, colorful pirate islands with treasure maps, friendly pirate ships, mermaids, hidden caves filled with glowing treasure"),
    ("magic-school", "Children's book illustration, a magical school with towers, flying books, potions class, friendly owls, glowing wands and a grand enchanted library"),
    ("deep-ocean", "Children's book illustration, the deep magical ocean with bioluminescent creatures, ancient shipwrecks, friendly giant squids, colorful coral and mermaids"),
    ("moon-base", "Children's book illustration, a cozy futuristic base on the moon with transparent domes, friendly astronauts, Earth visible in the starry sky above"),
    ("monster-planet", "Children's book illustration, a friendly colorful planet with cute cartoon monsters, purple skies, strange plants, multiple moons and cozy monster houses"),
    ("giant-world", "Children's book illustration, a world of giants where children explore among enormous flowers, mushrooms and friendly giants in a magical oversized garden"),
    ("miniature-world", "Children's book illustration, a tiny magical world inside a tree stump with miniature houses, tiny creatures, bridges made of twigs, acorn cups"),
    ("cloud-country", "Children's book illustration, a country made entirely of fluffy clouds with cloud castles, rainbow slides, friendly cloud creatures and golden sunsets"),
    ("shadow-labyrinth", "Children's book illustration, a magical colorful labyrinth with glowing path lights, friendly shadow creatures, hidden doors and treasure at the center"),
    ("time-kingdom", "Children's book illustration, a magical kingdom with giant clocks, time portals to dinosaurs and knights, hourglasses and friendly time wizards"),
    ("elemental-world", "Children's book illustration, a magical world divided into fire, water, earth and wind kingdoms with elemental creatures and bridges between realms"),
]


def generate_image(prompt):
    body = {
        "modelId": LEONARDO_MODEL_ID,
        "prompt": prompt,
        "negative_prompt": "ugly, deformed, blurry, low quality, text, watermark, signature, adult content, violence, scary, horror",
        "width": 512,
        "height": 384,
        "num_images": 1,
        "alchemy": True,
        "photoReal": False,
        "contrastRatio": 0.5,
        "presetStyle": "ILLUSTRATION",
    }
    with httpx.Client(timeout=120.0) as client:
        resp = client.post(f"{LEONARDO_API_BASE}/generations", headers=HEADERS, json=body)
        resp.raise_for_status()
        gen_id = resp.json()["sdGenerationJob"]["generationId"]
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
                raise RuntimeError("No images")
            if status == "FAILED":
                raise RuntimeError(f"Failed: {gen_id}")
            if attempt % 5 == 0:
                print(f"  Polling attempt {attempt+1}, status={status}")
        raise TimeoutError(f"Timeout: {gen_id}")


def upload_to_s3(image_url, s3_key):
    with httpx.Client(timeout=60.0) as client:
        resp = client.get(image_url)
        resp.raise_for_status()
        data = resp.content
    s3 = boto3.client("s3", endpoint_url=S3_ENDPOINT_URL,
                      aws_access_key_id=S3_ACCESS_KEY_ID,
                      aws_secret_access_key=S3_SECRET_ACCESS_KEY)
    s3.put_object(Bucket=S3_BUCKET, Key=s3_key, Body=data,
                  ContentType="image/png", ACL="public-read")
    return f"{STORAGE_PUBLIC_URL}/{s3_key}"


def main():
    genre_urls = {}
    world_urls = {}

    total = len(NEW_GENRES) + len(NEW_WORLDS)
    done = 0

    print(f"Generating {len(NEW_GENRES)} genre images...")
    for slug, prompt in NEW_GENRES:
        done += 1
        print(f"\n[{done}/{total}] Genre: {slug}")
        try:
            img_url = generate_image(prompt)
            s3_key = f"ui-assets/genres/{slug}.png"
            public_url = upload_to_s3(img_url, s3_key)
            genre_urls[slug] = public_url
            print(f"  OK: {public_url}")
        except Exception as e:
            print(f"  ERROR: {e}")
            genre_urls[slug] = ""

    print(f"\nGenerating {len(NEW_WORLDS)} world images...")
    for slug, prompt in NEW_WORLDS:
        done += 1
        print(f"\n[{done}/{total}] World: {slug}")
        try:
            img_url = generate_image(prompt)
            s3_key = f"ui-assets/worlds/{slug}.png"
            public_url = upload_to_s3(img_url, s3_key)
            world_urls[slug] = public_url
            print(f"  OK: {public_url}")
        except Exception as e:
            print(f"  ERROR: {e}")
            world_urls[slug] = ""

    # ── Output Dart code ───────────────────────────────────────────────
    print("\n\n=== DART GENRE CONSTANTS ===")
    for slug, url in genre_urls.items():
        const_name = slug.replace("-", "_")
        print(f"  static const String {const_name} = '{url}';")

    print("\n=== DART WORLD CONSTANTS ===")
    for slug, url in world_urls.items():
        const_name = slug.replace("-", "_")
        print(f"  static const String {const_name} = '{url}';")

    print("\n=== GENRE ASSET MAP ADDITIONS ===")
    for slug, url in genre_urls.items():
        const_name = slug.replace("-", "_")
        print(f"  '{slug}': UiAssets.{const_name},")

    print("\n=== WORLD ASSET MAP ADDITIONS ===")
    for slug, url in world_urls.items():
        const_name = slug.replace("-", "_")
        print(f"  '{slug}': UiAssets.{const_name},")


if __name__ == "__main__":
    main()
