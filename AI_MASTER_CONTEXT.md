# TALEKID — AI MASTER CONTEXT DOCUMENT
# Version: 1.6.0 | Generated: 2026-03-18 | For: AI assistants, not humans
# Purpose: Complete machine-parseable project state for zero-context bootstrapping
# Repo: https://github.com/aka-sergey/TaleKid2 | Branch: master
# Local root: /Users/sergeysobolev/NewProject

---

## §1. PROJECT IDENTITY

```yaml
product_name: TaleKID
domain_primary: https://www.talekid.ai
domain_alt: https://talekid.ai
api_production: https://talekid-production.up.railway.app/api/v1
web_production: https://talekid2-production.up.railway.app
github_repo: https://github.com/aka-sergey/TaleKid2
legal_entity: ИП Ткаченко Алексей Александрович
INN: 230101662439
OGRNIP: 325237500108117
support_email: support@talekid.ai
privacy_email: privacy@talekid.ai
language: ru-RU (all UI, story content, legal docs)
target_audience: Russian-speaking parents, children 3-12
platforms: Android APK, Flutter Web (SPA)
flutter_version: "^3.11.0"
project_version: 1.6.0
```

---

## §2. MONOREPO DIRECTORY TREE

```
/Users/sergeysobolev/NewProject/
├── AI_MASTER_CONTEXT.md          ← THIS FILE
├── ProjectPassport.md            ← Full technical spec v1.6.0 (human-readable)
├── PIPELINE.md                   ← Generation pipeline detailed docs
├── CHANGELOG.md                  ← Version history
├── DNS_MIGRATION.md              ← Domain migration notes
├── .env                          ← ALL secrets (never commit)
├── .gitignore
├── Dockerfile.backend            ← Python 3.12-slim + FastAPI + uvicorn
├── Dockerfile.web                ← Flutter build + nginx SPA
├── Dockerfile.worker             ← Python 3.12-slim + async worker
├── generate_ui_assets.py         ← Writes lib/config/ui_assets.dart from S3
├── generate_catalog_assets.py    ← Catalog asset generation
├── generate_showcase.py          ← Showcase tale assets
├── generate_styles.py            ← Style preview generation
│
├── backend/                      ← FastAPI REST API service
│   ├── railway.toml
│   ├── requirements.txt
│   └── app/
│       ├── main.py               ← FastAPI app, CORS, lifespan, auto-seed
│       ├── config.py             ← Pydantic BaseSettings (reads .env)
│       ├── database.py           ← async SQLAlchemy engine, SSL
│       ├── dependencies.py       ← get_db(), get_current_user()
│       ├── core/
│       │   ├── exceptions.py     ← NotFoundException, UnauthorizedException
│       │   ├── middleware.py     ← RequestLoggingMiddleware
│       │   └── security.py       ← JWT create/verify, bcrypt hash/verify
│       ├── routers/
│       │   ├── auth.py           ← /register /login /refresh /me
│       │   ├── characters.py     ← CRUD + photo upload (max 3)
│       │   ├── catalog.py        ← genres / worlds / base-tales
│       │   ├── generation.py     ← create job / status poll / cancel
│       │   ├── stories.py        ← list / detail / update-title / delete
│       │   └── health.py         ← GET /health → {status: ok}
│       ├── schemas/
│       │   ├── auth.py           ← UserRegisterRequest, TokenResponse
│       │   ├── catalog.py        ← GenreResponse, WorldResponse, BaseTaleResponse
│       │   ├── character.py      ← CharacterCreateRequest, CharacterResponse
│       │   ├── generation.py     ← GenerationCreateRequest, GenerationJobResponse
│       │   └── story.py          ← StoryResponse, StoryListResponse, StoryDetailResponse
│       ├── services/
│       │   ├── auth_service.py   ← register, login, refresh, JWT verify
│       │   ├── character_service.py
│       │   ├── generation_service.py ← create job, push to Redis queue
│       │   ├── story_service.py
│       │   ├── s3_service.py     ← boto3 S3 upload
│       │   └── redis_service.py  ← LPUSH/BRPOP wrappers
│       └── seed/
│           └── seed_db.py        ← Auto-seeds genres, worlds, base_tales on startup
│
├── worker/                       ← Async background job processor
│   ├── railway.toml
│   ├── requirements.txt
│   └── app/
│       ├── main.py               ← Redis BRPOP loop → runs 9 pipeline stages
│       ├── config.py
│       ├── database.py
│       ├── pipeline/             ← 9 stages (see §9)
│       │   ├── base.py           ← PipelineStage ABC
│       │   ├── photo_analysis.py
│       │   ├── story_bible.py
│       │   ├── text_generation.py
│       │   ├── scene_decomposition.py  ← NO-OP (data filled in text_generation)
│       │   ├── character_references.py
│       │   ├── illustration.py
│       │   ├── education.py
│       │   ├── title_generation.py
│       │   └── finalization.py
│       └── services/
│           ├── openai_service.py
│           ├── leonardo_service.py
│           ├── dalle_service.py
│           ├── image_service.py  ← orchestrates Leonardo + DALL-E fallback
│           ├── s3_service.py
│           ├── redis_service.py  ← SET progress with TTL 3600s
│           └── push_service.py   ← Firebase FCM
│
├── shared/                       ← Shared between backend + worker
│   ├── constants.py              ← VALID_ILLUSTRATION_STYLES, STYLE_PROMPTS, enums
│   └── models/                   ← SQLAlchemy ORM (12 files)
│       ├── base.py               ← DeclarativeBase, TimestampMixin
│       ├── user.py
│       ├── character.py
│       ├── character_photo.py
│       ├── story.py
│       ├── page.py               ← Table name: "pages" (NOT "story_pages")
│       ├── genre.py              ← Column: name_ru (NOT "name")
│       ├── world.py
│       ├── base_tale.py
│       ├── generation_job.py
│       └── device_token.py
│
├── scripts/
│   ├── optimize_ui_assets.py
│   └── set_s3_cors.py            ← Sets CORS on S3 bucket
│
└── flutter_app/                  ← Flutter multi-platform app
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── app.dart              ← MaterialApp + ProviderScope
    │   ├── config/               ← §4
    │   ├── models/               ← §11
    │   ├── providers/            ← §10
    │   ├── services/             ← §7
    │   ├── screens/              ← §8
    │   └── widgets/              ← §8.1
    └── assets/
        ├── images/
        ├── icons/
        └── landing/              ← Bundled for APK (no network needed on landing)
            ├── ui/               ← hero-bg.png, cta-bg.png, how-step1/2/3.png
            ├── styles/           ← 8 style cover images
            └── stories/          ← tale1-tale4 (cover + 10 pages each)
```

---

## §3. ENVIRONMENT VARIABLES (ALL)

```bash
# === DATABASE (TimeWeb PostgreSQL) ===
POSTGRESQL_HOST=<host>
POSTGRESQL_PORT=5432
POSTGRESQL_USER=<user>
POSTGRESQL_PASSWORD=<password>
POSTGRESQL_DBNAME=default_db
POSTGRESQL_SSLMODE=verify-full

# === S3 STORAGE (TimeWeb S3-compatible) ===
S3_ENDPOINT_URL=https://s3.twcstorage.ru
S3_ACCESS_KEY_ID=<key>
S3_SECRET_ACCESS_KEY=<secret>
S3_BUCKET=3e487a89-899c-4ef8-91e2-0900cb899801
STORAGE_PUBLIC_URL=https://s3.twcstorage.ru/3e487a89-899c-4ef8-91e2-0900cb899801

# === AI SERVICES ===
OPENAI_API_KEY=sk-proj-...
LEONARDO_API_KEY=<key>
IMAGE_ENGINE=leonardo          # or "dalle" to force DALL-E
IMAGE_MAX_CONCURRENT=10        # asyncio.Semaphore for parallel image gen

# === AUTH ===
JWT_SECRET=<strong-random-secret>
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=30

# === REDIS (Redis Labs) ===
REDIS_URL=redis://default:<password>@<host>:<port>

# === FIREBASE (FCM push notifications) ===
FIREBASE_CREDENTIALS=<json-string-or-path>

# === FLUTTER (build-time --dart-define) ===
API_BASE_URL=https://talekid-production.up.railway.app/api/v1
# Dev: API_BASE_URL=http://localhost:8000/api/v1
```

---

## §4. FLUTTER CONFIG FILES

### app_config.dart
```dart
class AppConfig {
  static const appName = 'TaleKID';
  static const appVersion = '1.0.0';
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:8000/api/v1');
  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 60);
  static const pollingInterval = Duration(seconds: 3);
  static const maxPhotosPerCharacter = 3;
  // Legal document URLs (published on web, linked from APK)
  static const termsUrl   = 'https://www.talekid.ai/terms';
  static const privacyUrl = 'https://www.talekid.ai/privacy';
  static const consentUrl = 'https://www.talekid.ai/consent';
}
```

### router.dart — All Routes
```
ROUTE_NAME          PATH                           SCREEN                  AUTH
landing             /                              LandingScreen           no
login               /auth/login                    LoginScreen             no
register            /auth/register                 RegisterScreen          no
terms               /terms                         TermsScreen             no
privacy             /privacy                       PrivacyScreen           no
consent             /consent                       ConsentScreen           no
home                /home                          HomeScreen (Shell)      yes → redirect /auth/login
wizard              /wizard                        WizardScreen            yes
generationProgress  /wizard/progress/:jobId        GenerationProgressScreen yes
storyReader         /stories/:id                   ReaderScreen            yes
library             /library                       LibraryScreen           yes
```

Auth guard logic (in redirect):
- Not logged in + protected → `/auth/login`
- Logged in + on login/register → `/home`
- Logged in + on landing → `/home`

### theme.dart — Design Tokens
```dart
// Colors
primaryColor      = #6366F1  (Indigo 500)
primaryLight      = #818CF8  (Indigo 400)
secondaryColor    = #FB7185  (Rose 400)
accentColor       = #FFBF24  (Amber 400)
goldColor         = #FFD700
purpleAccent      = #A78BFA
// Backgrounds
backgroundColor   = #0C0A1D  (Deep midnight)
surfaceColor      = #12102B
cardColor         = #161430
glassColor        = rgba(255,255,255,0.06)
glassBorder       = rgba(255,255,255,0.08)
// Text
textPrimary       = #FFFFFF
textSecondary     = rgba(255,255,255,0.60)
// Spacing scale
spacingXs = 4, spacingSm = 8, spacingMd = 16,
spacingLg = 24, spacingXl = 32, spacingXxl = 48
// Border radii
radiusSm = 10, radiusMd = 14, radiusLg = 20, radiusXl = 28, radiusFull = 999
// Fonts
headlineFont = Google Fonts Comfortaa (w800)
bodyFont     = Google Fonts NunitoSans (w400/w600)
```

### landing_assets.dart — Asset Resolution
```dart
// S3 base (for web)
const _s3 = 'https://s3.twcstorage.ru/3e487a89-899c-4ef8-91e2-0900cb899801';
// APK: assets/landing/... (bundled)  |  Web: S3 URLs

// LandingImage widget:
//   kIsWeb → Image.network(s3_url)
//   !kIsWeb → Image.asset('assets/landing/...')
```

---

## §5. FLUTTER DEPENDENCIES (pubspec.yaml)

```yaml
# Runtime dependencies
cupertino_icons: ^1.0.8
google_fonts: ^6.2.1           # Comfortaa + NunitoSans
flutter_riverpod: ^2.6.1       # State management
riverpod_annotation: ^2.6.1
go_router: ^14.8.1             # Declarative routing + auth guard
dio: ^5.7.0                    # HTTP client, JWT interceptor, auto-refresh
http: ^1.2.2                   # Secondary HTTP (multipart uploads)
flutter_secure_storage: ^9.2.4 # JWT token storage (keychain/keystore)
freezed_annotation: ^3.0.0    # Immutable models
json_annotation: ^4.9.0
hive_flutter: ^1.1.0           # Local cache
image_picker: ^1.1.2           # Photo selection
cached_network_image: ^3.4.1   # S3 image caching
firebase_core: ^3.12.1
firebase_messaging: ^15.2.4    # FCM push notifications
flutter_local_notifications: ^18.0.1
pdf: ^3.11.2                   # Client-side PDF export
printing: ^5.13.5
share_plus: ^10.1.4            # Share story/PDF
url_launcher: ^6.3.1           # Open legal URLs in browser (APK)
flutter_markdown: ^0.7.4       # Render legal docs inline (web)
intl: ^0.19.0                  # Dates, locale
flutter_svg: ^2.0.17
shimmer: ^3.0.0                # Loading skeletons
path_provider: ^2.1.5

# Dev dependencies
riverpod_generator: ^2.6.2
freezed: ^3.0.0
json_serializable: ^6.9.4
build_runner: ^2.4.14
custom_lint: ^0.7.5
riverpod_lint: ^2.6.2
```

---

## §6. BACKEND API — COMPLETE ENDPOINT REFERENCE

Base path: `/api/v1`
Auth header: `Authorization: Bearer <access_token>`

### 6.1 Auth (`/auth`)
```
POST   /auth/register     body:{email,password,display_name?}  → 201 TokenResponse
POST   /auth/login        body:{email,password}                 → 200 TokenResponse
POST   /auth/refresh      body:{refresh_token}                  → 200 TokenResponse
GET    /auth/me           header:Bearer                         → 200 UserResponse

TokenResponse = {access_token, refresh_token, token_type:"bearer"}
UserResponse  = {id, email, display_name, created_at}
```

### 6.2 Characters (`/characters`) — all require Bearer
```
GET    /characters                         → List[CharacterResponse]
POST   /characters                         body:CharacterCreateRequest → 201 CharacterResponse
GET    /characters/{id}                    → CharacterResponse (with photos)
PUT    /characters/{id}                    body:CharacterUpdateRequest → CharacterResponse
DELETE /characters/{id}                    → 204
POST   /characters/{id}/photos             multipart:file (jpg/png, max 3) → CharacterPhotoResponse
DELETE /characters/{id}/photos/{photo_id}  → 204

CharacterCreateRequest = {name, character_type, gender, age?}
character_type: child | adult | pet
gender: male | female
```

### 6.3 Catalog (`/catalog`) — no auth required
```
GET /catalog/genres      → List[GenreResponse]      (31 genres)
GET /catalog/worlds      → List[WorldResponse]      (30 worlds)
GET /catalog/base-tales  → List[BaseTaleListResponse] (50 tales)
GET /catalog/base-tales/{id} → BaseTaleResponse (with characters)

GenreResponse = {id, slug, name_ru, description_ru, icon_url, sort_order}
WorldResponse = {id, slug, name_ru, description_ru, visual_style_hint, icon_url, sort_order}
```

### 6.4 Generation (`/generation`) — require Bearer
```
POST /generation/create      body:GenerationCreateRequest → 201 GenerationJobResponse
GET  /generation/{job_id}/status → GenerationStatusResponse
POST /generation/{job_id}/cancel → GenerationJobResponse

GenerationCreateRequest = {
  character_ids: [uuid],      // 1-3 characters
  genre_id: int,
  world_id: int,
  base_tale_id: int | null,
  age_range: "3-5"|"6-8"|"9-12",
  education_level: 0.0-1.0,
  page_count: 5-30,
  reading_duration_minutes: 5-25,
  illustration_style: see §12,
  user_context: str | null
}

GenerationStatusResponse = {
  job_id, story_id, status, progress_pct: 0-100,
  status_message: str (Russian),
  error_message: str | null
}

Job statuses: queued → processing → completed | failed | cancelled
```

### 6.5 Stories (`/stories`) — require Bearer
```
GET    /stories?skip=0&limit=20  → StoryListResponse (paginated)
GET    /stories/{id}             → StoryDetailResponse (with pages + characters)
PUT    /stories/{id}/title       body:{title:str} → StoryResponse
DELETE /stories/{id}             → 204 (deletes S3 images too)

StoryDetailResponse includes:
  - pages: List[PageResponse] (ordered by page_number)
  - characters: List[StoryCharacterInfo]
  - educational_content per page (optional popup)
```

### 6.6 Health
```
GET /health → {status: "ok"} 200
```

---

## §7. FLUTTER SERVICES (lib/services/)

```dart
api_client.dart
  // Dio instance, base URL from AppConfig.apiBaseUrl
  // Interceptors: add Bearer header, auto-refresh on 401
  // Stores tokens in flutter_secure_storage
  // Provider: apiClientProvider (Riverpod)

auth_service.dart
  // register(email, password, displayName?)
  // login(email, password)
  // logout() → clears secure storage
  // getCurrentUser()

character_service.dart
  // getCharacters()
  // createCharacter(name, type, gender, age?)
  // updateCharacter(id, data)
  // deleteCharacter(id)
  // uploadPhoto(characterId, file) → multipart POST
  // deletePhoto(characterId, photoId)

story_service.dart
  // getStories(skip, limit)
  // getStoryDetail(id)
  // updateTitle(id, title)
  // deleteStory(id)

generation_service.dart
  // createGenerationJob(request) → jobId
  // pollStatus(jobId) → GenerationStatusResponse
  // cancelJob(jobId)

catalog_service.dart
  // getGenres(), getWorlds(), getBaseTales()
  // getBaseTaleDetail(id)

pdf_service.dart
  // exportToPdf(story) → downloads PDF client-side

share_service.dart
  // shareStory(story) → share_plus
```

---

## §8. FLUTTER SCREENS (lib/screens/)

```
SCREEN                    FILE                              ROUTE              AUTH
LandingScreen             landing/landing_screen.dart       /                  no
LoginScreen               auth/login_screen.dart            /auth/login        no
RegisterScreen            auth/register_screen.dart         /auth/register     no
TermsScreen               legal/legal_screen.dart           /terms             no
PrivacyScreen             legal/legal_screen.dart           /privacy           no
ConsentScreen             legal/legal_screen.dart           /consent           no
HomeScreen                home/home_screen.dart             /home              yes
WizardScreen              wizard/wizard_screen.dart         /wizard            yes
CharacterCreateDialog     wizard/character_create_dialog.dart  (modal)         yes
GenerationProgressScreen  generation/generation_progress_screen.dart /wizard/progress/:jobId yes
LibraryScreen             library/library_screen.dart       /library           yes
ReaderScreen              reader/reader_screen.dart         /stories/:id       yes
```

### LandingScreen — Sections
```
Sections (all rendered as Column):
  1. _HeroSection          — fullscreen bg, title, CTA button
  2. _ShowcaseSection      — 4 example stories (horizontal scroll cards)
  3. _StylesSection        — 8 illustration style cards (2x4 grid)
  4. _HowItWorksSection    — 3 steps (wide: Row, narrow: Column)
  5. _WhyTaleKidSection    — 6 feature cards
  6. _ReviewsSection       — 3 user reviews
  7. _CtaSection           — CTA with background image
  8. _Footer               — logo + 3 legal links + copyright

Responsive breakpoints:
  isWide = screenWidth > 900     → full desktop layout (wide)
  isMobileWeb = kIsWeb && screenWidth < 600  → mobile browser (reduced sizes)
  !kIsWeb (APK)                  → mobile layout with APK-optimized sizes

LandingImage widget:
  kIsWeb  → Image.network(s3_url)
  !kIsWeb → Image.asset('assets/landing/...')
```

### Legal Screens
```dart
// 3 screens share LegalScreen wrapper:
// TermsScreen    → title: 'Пользовательское соглашение' url: AppConfig.termsUrl
// PrivacyScreen  → title: 'Политика конфиденциальности' url: AppConfig.privacyUrl
// ConsentScreen  → title: 'Согласие на обработку данных' url: AppConfig.consentUrl

// Behavior:
// kIsWeb  → flutter_markdown renders full MD text inline (from legal_content.dart)
// !kIsWeb → ElevatedButton opens url in system browser via url_launcher

// Content source: legal_content.dart (3 Dart string constants)
// kTermsMarkdown, kPrivacyMarkdown, kConsentMarkdown
// Legal text version: 1.0, dated 13 February 2026
```

### §8.1 Widgets (lib/widgets/)
```
GlassCard             → frosted glass container (BackdropFilter)
GradientButton        → primary action button with gradient
AppCard               → standard card container
CharacterCard         → character preview (photo + name + type)
EducationalPopup      → lightbulb icon → fact/question popup overlay
PhotoPicker           → image picker trigger + preview
ShimmerLoading        → skeleton placeholder
TitleDialog           → text input modal dialog
```

---

## §9. GENERATION PIPELINE (9 stages)

```
INPUT: GenerationJob (from Redis queue, key: talekid:jobs)
PROGRESS TRACKING: Redis SET talekid:progress:{job_id} = JSON {progress_pct, status_message}
TTL: 3600s

STAGE  %       NAME                   SERVICE              OUTPUT
1      5→15    photo_analysis         GPT-4o Vision        character.appearance_description (per char)
2      15→30   story_bible            GPT-4o               story.story_bible = {plot, roles, themes, visual_style}
3      30→65   text_generation        GPT-4o (2-wave)      pages[].text_content + pages[].image_prompt (English)
                 Wave 1: pages 1-3 parallel
                 Wave 2: pages 4-N parallel (with Wave 1 context)
4      65      scene_decomposition    NO-OP                (data from stage 3)
5      65→70   character_references   Leonardo.ai          story_characters[].reference_image_url (S3)
6      70→90   illustration           Leonardo.ai + DALL-E pages[].image_url (S3)
                 asyncio.Semaphore(IMAGE_MAX_CONCURRENT=10)
                 Fallback: after 2 Leonardo errors → DALL-E 3
7      90→93   education              GPT-4o               educational_content per page (fact|question)
8      93→96   title_generation       GPT-4o               story.title_suggested (Russian)
9      96→100  finalization           FCM push             status=completed, push notification to user
```

---

## §10. RIVERPOD PROVIDERS (lib/providers/)

```dart
// auth_provider.dart
apiClientProvider        → Provider<ApiClient>           Dio + JWT interceptor
authServiceProvider      → Provider<AuthService>
authStateProvider        → AsyncNotifierProvider         current user | null
                           auto-redirects via GoRouter on change

// character_provider.dart
characterApiServiceProvider → Provider<CharacterService>
charactersProvider          → FutureProvider<List<CharacterModel>>

// story_provider.dart
storyServiceProvider    → Provider<StoryService>
storiesProvider         → AsyncNotifierProvider<List<StoryModel>>
storyDetailProvider     → FutureProvider.family<StoryDetail, String>(storyId)

// generation_provider.dart
generationServiceProvider   → Provider<GenerationService>
generationJobProvider       → AutoDisposeAsyncNotifierProvider.family(jobId)
                              polls every 3s (AppConfig.pollingInterval)
                              auto-cancels timer on dispose

// catalog_provider.dart
catalogServiceProvider  → Provider<CatalogService>
genresProvider          → FutureProvider<List<Genre>>
worldsProvider          → FutureProvider<List<World>>
baseTalesProvider       → FutureProvider<List<BaseTale>>
baseTaleDetailProvider  → FutureProvider.family<BaseTale, int>(id)
```

---

## §11. DATA MODELS

### Flutter models (lib/models/)

```dart
// character.dart
CharacterModel {id, userId, name, characterType, gender, age, appearanceDescription, photos}
CharacterPhoto  {id, s3Url, sortOrder}

// story.dart
StoryModel      {id, title, status, ageRange, educationLevel, pageCount, readingDuration,
                 illustrationStyle, coverImageUrl, genreId, worldId, createdAt}
StoryDetail     extends StoryModel + {pages, characters}
StoryPage       {id, pageNumber, textContent, imageUrl, educationalContent}
StoryCharInfo   {characterId, name, roleInStory, referenceImageUrl}
EducationalContent {contentType, textRu, answerRu, topic}
GenerationJob   {id, storyId, status, progressPct, statusMessage, errorMessage}

// catalog.dart
Genre  {id, slug, nameRu, descriptionRu, iconUrl}
World  {id, slug, nameRu, descriptionRu, visualStyleHint, iconUrl}
BaseTale {id, slug, nameRu, summaryRu, plotStructure, moralRu, characters}
BaseTaleCharacter {nameRu, role, appearancePrompt, personalityRu}

// Serialization: json_annotation + freezed (code generated)
// Run: flutter pub run build_runner build --delete-conflicting-outputs
```

### SQLAlchemy ORM (shared/models/)

```python
# IMPORTANT: use correct column/table names:
# Table "pages" (NOT "story_pages")
# Genre column "name_ru" (NOT "name")

User          id(UUID), email(unique), password_hash, display_name, timestamps
Character     id(UUID), user_id(FK→users), name, character_type(child|adult|pet),
              gender(male|female), age, appearance_description
CharacterPhoto id(UUID), character_id(FK), s3_key, s3_url, sort_order
Genre         id(SERIAL), slug(unique), name_ru, description_ru, prompt_hint, icon_url, sort_order
World         id(SERIAL), slug(unique), name_ru, description_ru, prompt_hint,
              visual_style_hint, icon_url, sort_order
BaseTale      id(SERIAL), slug(unique), name_ru, summary_ru, plot_structure(JSONB),
              moral_ru, icon_url, sort_order
BaseTaleCharacter id(SERIAL), base_tale_id(FK), name_ru, role(protagonist|antagonist|secondary|helper),
              appearance_prompt, personality_ru, sort_order
Story         id(UUID), user_id(FK), title, title_suggested, base_tale_id(FK nullable),
              genre_id(FK), world_id(FK), age_range, education_level(float 0-1),
              page_count, reading_duration_minutes, cover_image_url, illustration_style,
              user_context, status(draft|generating|completed|failed), story_bible(JSONB),
              timestamps
StoryCharacter id(UUID), story_id(FK), character_id(FK), role_in_story, reference_image_url, sort_order
Page          id(UUID), story_id(FK), page_number, text_content, image_url, image_s3_key,
              image_prompt, scene_description(JSONB)
EducationalContent id(UUID), page_id(UNIQUE FK), content_type(fact|question),
              text_ru, answer_ru, topic
GenerationJob id(UUID), story_id(UNIQUE FK), status, progress_pct(0-100),
              status_message, error_message, started_at, completed_at, retry_count
DeviceToken   id(UUID), user_id(FK), token, platform(android|web), UNIQUE(user_id, token)
```

---

## §12. ILLUSTRATION STYLES

```python
# All valid values for illustration_style field:
VALID_ILLUSTRATION_STYLES = [
    'watercolor',     # Акварель
    '3d-pixar',       # 3D Анимация (Pixar)
    'disney',         # Disney
    'comic',          # Комикс
    'anime',          # Аниме
    'pastel',         # Пастель
    'classic-book',   # Книжная классика
    'pop-art',        # Поп-арт
]
# Each has a STYLE_PROMPTS[style] string injected into illustration prompt
```

---

## §13. S3 STORAGE STRUCTURE

```
BUCKET: 3e487a89-899c-4ef8-91e2-0900cb899801
BASE:   https://s3.twcstorage.ru/3e487a89-899c-4ef8-91e2-0900cb899801

{base}/character-photos/{user_id}/{character_id}/photo_{n}.jpg   (max 3)
{base}/stories/{story_id}/cover.png
{base}/stories/{story_id}/pages/{n}.png
{base}/stories/{story_id}/characters/{character_id}/reference.png
{base}/ui-assets/genres/{slug}.webp
{base}/ui-assets/worlds/{slug}.webp
{base}/ui-assets/ages/age-3-5.webp
{base}/ui-assets/ages/age-6-8.webp
{base}/ui-assets/ages/age-9-12.webp
{base}/landing-assets/ui/hero-bg.png
{base}/landing-assets/ui/cta-bg.png
{base}/landing-assets/ui/how-step{1,2,3}.png
{base}/landing-assets/styles/{style-slug}.png  (8 styles)
{base}/landing-assets/stories/tale{1-4}/cover.png
{base}/landing-assets/stories/tale{1-4}/pages/{n}.png  (10 pages per tale)

ACL: public-read (all objects)
CORS: configured for talekid.ai, www.talekid.ai, localhost (script: scripts/set_s3_cors.py)
```

### Local bundled copies (APK only)
```
flutter_app/assets/landing/ui/            ← hero-bg.png, cta-bg.png, how-step1/2/3.png
flutter_app/assets/landing/styles/        ← 8 style covers
flutter_app/assets/landing/stories/tale1/ ← cover.png
flutter_app/assets/landing/stories/tale1/pages/  ← p1.png ... p10.png
(same for tale2, tale3, tale4)
```

---

## §14. DEPLOYMENT CONFIGURATION

### Railway Services (3 separate services)
```yaml
# Service 1: backend API
dockerfile: Dockerfile.backend
port: 8000
healthcheck: GET /api/v1/health
restart: ON_FAILURE (max 10)
env: all §3 vars

# Service 2: worker
dockerfile: Dockerfile.worker
port: none (background process)
restart: ON_FAILURE (max 10)
env: all §3 vars

# Service 3: web (Flutter SPA)
dockerfile: Dockerfile.web
port: 80 (nginx)
routing: all /* → index.html (SPA)
env: none (compiled at build time)
```

### CORS (backend/app/main.py)
```python
allow_origins = [
    "https://talekid-production.up.railway.app",
    "https://talekid.ai",
    "https://www.talekid.ai",
]
allow_origin_regex = r"http://localhost:\d+"
allow_credentials = True
allow_methods = ["*"]
allow_headers = ["*"]
```

### Build commands
```bash
# APK release
flutter build apk --release \
  --dart-define=API_BASE_URL=https://talekid-production.up.railway.app/api/v1

# Web release
flutter build web --release \
  --dart-define=API_BASE_URL=https://talekid-production.up.railway.app/api/v1

# Backend local dev
cd backend && uvicorn app.main:app --reload --port 8000

# Worker local dev
cd worker && python -m app.main

# Generate code (freezed/riverpod)
cd flutter_app && flutter pub run build_runner build --delete-conflicting-outputs
```

---

## §15. AUTHENTICATION FLOW

```
REGISTRATION:
  1. POST /auth/register {email, password}
  2. backend: hash password (bcrypt), create User, return JWT pair
  3. Flutter: store access_token + refresh_token in flutter_secure_storage
  4. authStateProvider → user set → GoRouter redirects to /home

LOGIN:
  1. POST /auth/login {email, password}
  2. same as step 2-4 above

TOKEN REFRESH (auto, inside Dio interceptor):
  1. 401 response received
  2. POST /auth/refresh {refresh_token}
  3. If success: update stored tokens, retry original request
  4. If fail: clear tokens, redirect to /auth/login

LOGOUT:
  1. Clear flutter_secure_storage
  2. authStateProvider → null → GoRouter redirects to /

JWT:
  algorithm: HS256
  access_token TTL: 30 minutes
  refresh_token TTL: 30 days
  payload: {sub: user_id, exp, iat}
```

---

## §16. LEGAL DOCUMENTS (embedded in APK, served on web)

```
3 documents, all version 1.0, dated 13 February 2026, language: Russian

DOCUMENT              ROUTE    APK BEHAVIOR              WEB BEHAVIOR
Пользовательское      /terms   url_launcher opens        flutter_markdown renders
 соглашение                    www.talekid.ai/terms      kTermsMarkdown inline
Политика              /privacy url_launcher opens        flutter_markdown renders
 конфиденциальности            www.talekid.ai/privacy    kPrivacyMarkdown inline
Согласие на           /consent url_launcher opens        flutter_markdown renders
 обработку ПД                  www.talekid.ai/consent    kConsentMarkdown inline

Source file: flutter_app/lib/screens/legal/legal_content.dart
Constants: kTermsMarkdown, kPrivacyMarkdown, kConsentMarkdown

Footer links (visible on landing page, all users):
  context.go(AppRoutes.terms)   → 'Соглашение'
  context.go(AppRoutes.privacy) → 'Конфиденциальность'
  context.go(AppRoutes.consent) → 'Согласие на обработку'

Register screen links (tappable text, line ~309 and ~330):
  GestureDetector onTap → context.push(AppRoutes.terms)   'соглашение'
  GestureDetector onTap → context.push(AppRoutes.privacy) 'политику'
```

---

## §17. KNOWN ISSUES & SCHEMA QUIRKS

```
# DB table name: "pages" (NOT "story_pages") — fixed 2026-03-18
# DB column: genres.name_ru (NOT genres.name) — fixed 2026-03-18
# flutter_markdown 0.7.4 is discontinued, replaced by flutter_markdown_plus
#   — still works, upgrade when breaking changes occur

# Domain redirect: talekid.ai → www.talekid.ai (Railway handles redirect)
# S3 CORS: configured for both talekid.ai and www.talekid.ai domains

# Responsive design:
#   Landing page uses 3-tier sizing:
#     isWide = screenWidth > 900     → desktop web (largest)
#     !kIsWeb                        → APK (medium, DPI-scaled)
#     isMobileWeb (kIsWeb && w<600)  → mobile browser (smallest)
#   Other screens (home, wizard, etc.) only check kIsWeb (binary)
```

---

## §18. SHOWCASE TALES (landing page examples)

```
ID   TITLE                              STYLE      BADGE COLOR
1    Маша и Двенадцать Месяцев          Акварель   #059669
2    Дима и Звёздный Кот                3D Анимация #6366F1
3    Алиса и Коралловое Королевство     Disney     #DB2777
4    Супергерой Тимофей                 Комикс     #D97706
```

---

## §19. GENERATION REQUEST CONSTRAINTS

```
age_range:              "3-5" | "6-8" | "9-12"
education_level:        0.0 (none) to 1.0 (maximum)
page_count:             5 to 30
reading_duration:       5 to 25 minutes
illustration_style:     see §12 (8 options)
character_ids:          1 to 3 UUIDs (must exist and belong to user)
base_tale_id:           optional, from catalog (50 base tales)
genre_id:               required, from catalog (31 genres)
world_id:               required, from catalog (30 worlds)
user_context:           optional free text (personalisation hint)
```

---

## §20. RECENT COMMITS (CHANGELOG SUMMARY)

```
f94d81f  feat(legal): embed policy docs + fix broken links on APK and web
076f9ec  fix(landing): responsive font/spacing for mobile browser
6ef79fd  (previous: landing bundled assets, ProjectPassport v1.6.0)
02e6c71  fix(cors): add talekid.ai and www.talekid.ai to allowed origins
f66ebbb  fix(s3-cors): configure S3 bucket CORS for new domain
```

---

## §21. FILE QUICK-REFERENCE INDEX

```
TOPIC                          FILE PATH
All routes                     flutter_app/lib/config/router.dart
API URLs & timeouts            flutter_app/lib/config/app_config.dart
Colors, spacing, fonts         flutter_app/lib/config/theme.dart
Landing S3/bundled assets      flutter_app/lib/config/landing_assets.dart
Legal docs (MD text)           flutter_app/lib/screens/legal/legal_content.dart
Legal screen (web/APK logic)   flutter_app/lib/screens/legal/legal_screen.dart
Register screen (legal links)  flutter_app/lib/screens/auth/register_screen.dart
Landing responsive sizing      flutter_app/lib/screens/landing/landing_screen.dart
All Flutter deps               flutter_app/pubspec.yaml
DB models (ORM)                shared/models/*.py
API endpoints (auth)           backend/app/routers/auth.py
API endpoints (gen)            backend/app/routers/generation.py
Pipeline stages                worker/app/pipeline/*.py
Illustration styles/prompts    shared/constants.py
CORS config                    backend/app/main.py
Environment variables          .env (+ §3 above)
Deploy config                  Dockerfile.backend / Dockerfile.web / Dockerfile.worker
S3 CORS setup                  scripts/set_s3_cors.py
Full technical spec (human)    ProjectPassport.md
```

---
# END OF AI_MASTER_CONTEXT.md
# Last updated: 2026-03-18
# To regenerate: update each section after code changes
