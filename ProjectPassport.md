# TaleKID - Project Passport

> **Version:** 1.4.0 | **Date:** 2026-03-16 | **Repository:** https://github.com/aka-sergey/TaleKid2 | **Branch:** master

---

## 1. Overview

**TaleKID** — mobile (Android) + web application for generating personalized illustrated children's fairy tales using AI. Users create characters (with photos), choose genre, world, illustration style, and optionally a base tale template; the system generates story text (Russian) and illustrations page by page in the selected artistic style.

**Target audience:** Parents with children aged 3-12, Russian-speaking market.

**Core flow:** Register → Create Characters → Wizard (genre, world, illustration style, age, education level) → Generation pipeline (9 stages) → Reading experience with educational content.

---

## 2. Architecture Overview

```
┌─────────────┐       ┌──────────────────┐       ┌─────────────────┐
│  Flutter App │──────▶│   FastAPI (API)   │──────▶│   PostgreSQL    │
│ (Android/Web)│  HTTP │  Railway Service  │  SQL  │   (TimeWeb)     │
└─────────────┘  REST └──────┬───────────┘       └─────────────────┘
                             │                          ▲
                             │ Redis LPUSH              │ SQL
                             ▼                          │
                      ┌──────────────┐           ┌─────┴───────────┐
                      │    Redis     │──BRPOP───▶│  Python Worker  │
                      │  (Railway)   │           │ Railway Service  │
                      └──────────────┘           └──────┬──────────┘
                                                        │
                                          ┌─────────────┼─────────────┐
                                          ▼             ▼             ▼
                                    ┌──────────┐ ┌───────────┐ ┌──────────┐
                                    │  OpenAI  │ │ Leonardo  │ │ TimeWeb  │
                                    │ GPT-4o   │ │    AI     │ │    S3    │
                                    └──────────┘ └───────────┘ └──────────┘
                                                       │
                                                 DALL-E fallback
```

**Monorepo structure:**

```
talekid/
├── backend/          # FastAPI API server
├── worker/           # Background generation worker
├── shared/           # Shared SQLAlchemy models & constants
├── flutter_app/      # Flutter (Android + Web)
├── Dockerfile.backend
├── Dockerfile.worker
├── Dockerfile.web
└── .github/workflows/
```

---

## 3. Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| **Frontend** | Flutter | SDK ^3.11.0 | Android + Web client |
| **State Mgmt** | Riverpod | ^2.6.1 | Reactive state, AsyncNotifier |
| **Navigation** | go_router | ^14.8.1 | Declarative routing, auth guard |
| **HTTP Client** | Dio | ^5.7.0 | HTTP with interceptors, JWT auto-refresh |
| **Backend API** | FastAPI | 0.115.0 | REST API, async, OpenAPI docs |
| **ORM** | SQLAlchemy 2.0 | 2.0.35 (async) | Shared models backend+worker |
| **DB Driver** | asyncpg | 0.30.0 | Async PostgreSQL |
| **Database** | PostgreSQL | 15+ | TimeWeb hosted, SSL |
| **Migrations** | Alembic | 1.13.0 | Schema versioning (manual) |
| **Queue** | Redis | 5.1.0 | BRPOP job queue + progress |
| **Auth** | JWT (HS256) | python-jose 3.3.0 | Access + Refresh tokens |
| **Password** | bcrypt | 4.1.3 | via passlib 1.7.4 |
| **Storage** | S3 (TimeWeb) | boto3 1.35.0 | Photos, illustrations, UI assets |
| **Text AI** | OpenAI GPT-4o | openai 1.50.0 | Text + Vision |
| **Image AI** | Leonardo.ai | HTTP API | Primary image generation |
| **Image Fallback** | DALL-E 3 | openai 1.50.0 | Fallback image generation |
| **Push** | Firebase FCM | firebase-admin 6.5.0 | Android + Web push |
| **PDF** | Flutter pdf | ^3.11.2 | Client-side PDF export |
| **Deploy** | Railway | Docker-based | 3 services: API, Worker, Web |
| **CI/CD** | GitHub Actions | - | Auto-deploy on push to master |

---

## 4. Database Schema

### 4.1 ER Diagram

```
users (UUID PK)
├── 1:N → characters (UUID PK)
│         └── 1:N → character_photos (UUID PK)
├── 1:N → stories (UUID PK)
│         ├── N:1 → genres (INT PK)
│         ├── N:1 → worlds (INT PK)
│         ├── N:1 → base_tales (INT PK, nullable)
│         │         └── 1:N → base_tale_characters (INT PK)
│         ├── 1:N → story_characters (UUID PK)
│         │         └── N:1 → characters
│         ├── 1:N → pages (UUID PK)
│         │         └── 1:1 → educational_content (UUID PK)
│         └── 1:1 → generation_jobs (UUID PK)
└── 1:N → device_tokens (UUID PK)
```

### 4.2 Table Definitions

#### `users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| email | VARCHAR(255) | UNIQUE, NOT NULL, INDEX |
| password_hash | VARCHAR(255) | NOT NULL |
| display_name | VARCHAR(100) | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |
| updated_at | TIMESTAMPTZ | NOT NULL, auto-update |

#### `characters`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| user_id | UUID | FK→users(CASCADE), NOT NULL, INDEX |
| name | VARCHAR(100) | NOT NULL |
| character_type | VARCHAR(20) | NOT NULL, CHECK IN ('child','adult','pet') |
| gender | VARCHAR(10) | NOT NULL, CHECK IN ('male','female') |
| age | INTEGER | NULLABLE |
| appearance_description | TEXT | NULLABLE (filled by GPT-4 Vision) |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |
| updated_at | TIMESTAMPTZ | NOT NULL, auto-update |

#### `character_photos`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| character_id | UUID | FK→characters(CASCADE), NOT NULL, INDEX |
| s3_key | VARCHAR(500) | NOT NULL |
| s3_url | VARCHAR(1000) | NOT NULL |
| sort_order | INTEGER | NOT NULL, default: 0 |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |

#### `genres`
| Column | Type | Constraints |
|--------|------|-------------|
| id | SERIAL | PK |
| slug | VARCHAR(50) | UNIQUE, NOT NULL |
| name_ru | VARCHAR(100) | NOT NULL |
| description_ru | TEXT | NULLABLE |
| prompt_hint | TEXT | NOT NULL |
| icon_url | VARCHAR(500) | NULLABLE |
| sort_order | INTEGER | NOT NULL, default: 0 |

#### `worlds`
| Column | Type | Constraints |
|--------|------|-------------|
| id | SERIAL | PK |
| slug | VARCHAR(50) | UNIQUE, NOT NULL |
| name_ru | VARCHAR(100) | NOT NULL |
| description_ru | TEXT | NULLABLE |
| prompt_hint | TEXT | NOT NULL |
| visual_style_hint | TEXT | NOT NULL |
| icon_url | VARCHAR(500) | NULLABLE |
| sort_order | INTEGER | NOT NULL, default: 0 |

#### `base_tales`
| Column | Type | Constraints |
|--------|------|-------------|
| id | SERIAL | PK |
| slug | VARCHAR(100) | UNIQUE, NOT NULL |
| name_ru | VARCHAR(200) | NOT NULL |
| summary_ru | TEXT | NOT NULL |
| plot_structure | JSONB | NOT NULL |
| moral_ru | TEXT | NULLABLE |
| icon_url | VARCHAR(500) | NULLABLE |
| sort_order | INTEGER | NOT NULL, default: 0 |

**plot_structure JSONB format:**
```json
{
  "setup": "Initial situation in Russian",
  "encounters": ["Character1", "Character2"],
  "climax": "Key conflict in Russian",
  "resolution": "How it resolves (optional)",
  "moral": "Lesson in Russian"
}
```

#### `base_tale_characters`
| Column | Type | Constraints |
|--------|------|-------------|
| id | SERIAL | PK |
| base_tale_id | INTEGER | FK→base_tales(CASCADE), NOT NULL, INDEX |
| name_ru | VARCHAR(100) | NOT NULL |
| role | VARCHAR(50) | NOT NULL, CHECK IN ('protagonist','antagonist','helper','secondary') |
| appearance_prompt | TEXT | NOT NULL |
| personality_ru | TEXT | NULLABLE |
| sort_order | INTEGER | NOT NULL, default: 0 |

#### `stories`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| user_id | UUID | FK→users(CASCADE), NOT NULL, INDEX |
| title | VARCHAR(300) | NULLABLE |
| title_suggested | VARCHAR(300) | NULLABLE |
| base_tale_id | INTEGER | FK→base_tales, NULLABLE |
| genre_id | INTEGER | FK→genres, NOT NULL |
| world_id | INTEGER | FK→worlds, NOT NULL |
| age_range | VARCHAR(10) | NOT NULL, CHECK IN ('3-5','6-8','9-12') |
| education_level | FLOAT | NOT NULL, default: 0.0 |
| page_count | INTEGER | NOT NULL |
| reading_duration_minutes | INTEGER | NOT NULL |
| cover_image_url | VARCHAR(1000) | NULLABLE |
| **illustration_style** | **VARCHAR(50)** | **NULLABLE** (watercolor/3d-pixar/disney/comic/anime/pastel/classic-book/pop-art) |
| **user_context** | **TEXT** | **NULLABLE** — personal context from user, woven into story by AI (e.g. "We visited the zoo today") |
| status | VARCHAR(20) | NOT NULL, default: 'draft', CHECK IN ('draft','generating','completed','failed'), INDEX |
| story_bible | JSONB | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |
| updated_at | TIMESTAMPTZ | NOT NULL, auto-update |

**story_bible JSONB format:**
```json
{
  "title_working": "Working title (Russian)",
  "tone": "Story tone description",
  "setting_description": "Detailed world/setting",
  "character_roles": [
    {"character_id": "uuid", "name": "Name", "role": "protagonist", "arc": "Character arc (Russian)"}
  ],
  "plot_outline": [
    {"act": 1, "summary": "Act summary (Russian)", "key_events": ["event1", "event2"]}
  ],
  "themes": ["theme1", "theme2"],
  "moral": "Story moral (Russian)",
  "vocabulary_level": "simple|moderate|advanced",
  "visual_style": "Illustration style description (guided by illustration_style field)"
}
```

#### `story_characters`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| story_id | UUID | FK→stories(CASCADE), NOT NULL, INDEX |
| character_id | UUID | FK→characters(CASCADE), NOT NULL, INDEX |
| role_in_story | VARCHAR(50) | NULLABLE |
| reference_image_url | VARCHAR(1000) | NULLABLE |
| | | UNIQUE(story_id, character_id) |

#### `pages`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| story_id | UUID | FK→stories(CASCADE), NOT NULL, INDEX |
| page_number | INTEGER | NOT NULL |
| text_content | TEXT | NOT NULL |
| image_url | VARCHAR(1000) | NULLABLE |
| image_s3_key | VARCHAR(500) | NULLABLE |
| image_prompt | TEXT | NULLABLE |
| scene_description | JSONB | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |
| | | UNIQUE(story_id, page_number) |

**scene_description JSONB format:**
```json
{
  "setting": "Background/environment description",
  "characters_present": ["character names"],
  "character_actions": "What characters are doing",
  "mood": "Emotional mood",
  "lighting": "Lighting description",
  "key_objects": ["important objects"],
  "color_palette": "Suggested colors"
}
```

#### `educational_content`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| page_id | UUID | FK→pages(CASCADE), UNIQUE, NOT NULL, INDEX |
| content_type | VARCHAR(20) | NOT NULL, CHECK IN ('fact','question') |
| text_ru | TEXT | NOT NULL |
| answer_ru | TEXT | NULLABLE |
| topic | VARCHAR(100) | NULLABLE |

#### `generation_jobs`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| story_id | UUID | FK→stories(CASCADE), UNIQUE, NOT NULL, INDEX |
| status | VARCHAR(20) | NOT NULL, default: 'queued', INDEX |
| progress_pct | INTEGER | NOT NULL, default: 0, CHECK 0..100 |
| status_message | VARCHAR(500) | NULLABLE |
| error_message | TEXT | NULLABLE |
| started_at | TIMESTAMPTZ | NULLABLE |
| completed_at | TIMESTAMPTZ | NULLABLE |
| retry_count | INTEGER | NOT NULL, default: 0 |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |
| updated_at | TIMESTAMPTZ | NOT NULL, auto-update |

**status CHECK values:** `queued`, `processing`, `photo_analysis`, `story_bible`, `text_generation`, `scene_decomposition`, `character_references`, `illustration`, `education`, `title_generation`, `saving`, `completed`, `failed`

#### `device_tokens`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, default: gen_random_uuid() |
| user_id | UUID | FK→users(CASCADE), NOT NULL, INDEX |
| token | VARCHAR(500) | NOT NULL |
| platform | VARCHAR(10) | NOT NULL, CHECK IN ('android','web') |
| created_at | TIMESTAMPTZ | NOT NULL, default: NOW |
| | | UNIQUE(user_id, token) |

---

## 5. API Specification

**Base URL:** `https://talekid-production.up.railway.app/api/v1`
**Docs:** `https://talekid-production.up.railway.app/docs` (Swagger UI)
**Format:** JSON (application/json), multipart/form-data for file uploads
**Auth:** Bearer JWT in `Authorization` header

### 5.1 Authentication

| Method | Endpoint | Auth | Request Body | Response |
|--------|----------|------|-------------|----------|
| POST | `/auth/register` | No | `{email, password, display_name?}` | `{access_token, refresh_token, token_type}` |
| POST | `/auth/login` | No | `{email, password}` | `{access_token, refresh_token, token_type}` |
| POST | `/auth/refresh` | No | `{refresh_token}` | `{access_token, refresh_token, token_type}` |
| GET | `/auth/me` | JWT | - | `{id, email, display_name, created_at}` |

**JWT Token structure:**
```json
{
  "sub": "user-uuid",
  "type": "access|refresh",
  "iat": 1710000000,
  "exp": 1710001800
}
```
- Access token: 30 min TTL
- Refresh token: 30 days TTL
- Algorithm: HS256

### 5.2 Characters

| Method | Endpoint | Auth | Request/Query | Response |
|--------|----------|------|--------------|----------|
| GET | `/characters` | JWT | - | `[CharacterResponse, ...]` |
| POST | `/characters` | JWT | `{name, character_type, gender, age?}` | `CharacterResponse` (201) |
| GET | `/characters/{id}` | JWT | UUID path | `CharacterResponse` |
| PUT | `/characters/{id}` | JWT | `{name?, character_type?, gender?, age?}` | `CharacterResponse` |
| DELETE | `/characters/{id}` | JWT | UUID path | 204 |
| POST | `/characters/{id}/photos` | JWT | multipart: `file` (image) | `CharacterPhotoResponse` (201) |
| DELETE | `/characters/{id}/photos/{photo_id}` | JWT | UUID paths | 204 |

**Constraints:** max 3 photos per character.

### 5.3 Catalog (No Auth Required)

| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/catalog/genres` | `[{id, slug, name_ru, description_ru, icon_url, sort_order}, ...]` |
| GET | `/catalog/worlds` | `[{id, slug, name_ru, description_ru, icon_url, sort_order}, ...]` |
| GET | `/catalog/base-tales` | `[{id, slug, name_ru, icon_url}, ...]` |
| GET | `/catalog/base-tales/{id}` | `{id, slug, name_ru, summary_ru, moral_ru, icon_url, characters: [...]}` |

### 5.4 Generation

| Method | Endpoint | Auth | Request/Query | Response |
|--------|----------|------|--------------|----------|
| POST | `/generation/create` | JWT | GenerationCreateRequest | `GenerationJobResponse` (201) |
| GET | `/generation/{job_id}/status` | JWT | UUID path | `GenerationStatusResponse` |
| POST | `/generation/{job_id}/cancel` | JWT | UUID path | `GenerationJobResponse` |

**GenerationCreateRequest:**
```json
{
  "character_ids": ["uuid1", "uuid2"],
  "genre_id": 1,
  "world_id": 1,
  "base_tale_id": null,
  "age_range": "3-5|6-8|9-12",
  "education_level": 0.5,
  "page_count": 10,
  "reading_duration_minutes": 10,
  "illustration_style": "watercolor",
  "user_context": "We visited the zoo today and saw elephants, giraffes and parrots"
}
```

**`illustration_style` allowed values:** `watercolor` · `3d-pixar` · `disney` · `comic` · `anime` · `pastel` · `classic-book` · `pop-art` · `null` (defaults to `watercolor` in worker)

**`user_context`** — optional, max 1000 chars. Personal context from user. AI weaves this event/memory into the story plot organically. Example: "Сегодня мы ходили в зоопарк, Маша была в восторге от попугаев"

**GenerationStatusResponse:**
```json
{
  "job_id": "uuid",
  "story_id": "uuid",
  "status": "processing",
  "progress_pct": 45,
  "status_message": "Generating illustrations...",
  "error_message": null,
  "story_title": null,
  "cover_image_url": null
}
```

### 5.5 Stories

| Method | Endpoint | Auth | Request/Query | Response |
|--------|----------|------|--------------|----------|
| GET | `/stories` | JWT | `?skip=0&limit=20` | `{stories: [...], total: int}` |
| GET | `/stories/{id}` | JWT | UUID path | `StoryDetailResponse` |
| PUT | `/stories/{id}/title` | JWT | `{title: "string"}` | `StoryResponse` |
| DELETE | `/stories/{id}` | JWT | UUID path | 204 |

### 5.6 Health

| Method | Endpoint | Auth | Response |
|--------|----------|------|----------|
| GET | `/health` | No | `{"status": "ok"}` |
| GET | `/health/db` | No | `{"status": "ok", "database": "connected"}` |

### 5.7 Error Responses

| Code | Exception | Meaning |
|------|-----------|---------|
| 400 | BadRequestException | Invalid input |
| 401 | UnauthorizedException | Missing/invalid/expired JWT |
| 403 | ForbiddenException | Ownership check failed |
| 404 | NotFoundException | Resource not found |
| 409 | ConflictException | Duplicate (e.g., email) |

---

## 6. Worker Pipeline

### 6.1 Queue Architecture

```
Backend (API)                Redis                    Worker
     │                         │                        │
     │  POST /generation/create│                        │
     │─── LPUSH job payload ──▶│                        │
     │                         │◀── BRPOP (timeout=5) ──│
     │                         │─── job payload ───────▶│
     │                         │                        │── run 9 stages
     │                         │◀── SET progress ───────│   (per-stage updates)
     │  GET /status            │                        │
     │─── GET progress ───────▶│                        │
     │◀── progress JSON ───────│                        │
```

**Redis keys:**
- Queue: `talekid:jobs` (list, LPUSH/BRPOP)
- Progress: `talekid:progress:{job_id}` (string, JSON, TTL 3600s)

**Job payload (JSON in Redis queue):**
```json
{
  "job_id": "uuid",
  "story_id": "uuid",
  "user_id": "uuid",
  "character_ids": ["uuid1"],
  "genre_id": 1,
  "world_id": 2,
  "base_tale_id": null,
  "age_range": "6-8",
  "education_level": 0.5,
  "page_count": 10,
  "reading_duration_minutes": 10,
  "illustration_style": "watercolor"
}
```

### 6.2 Pipeline Stages

| # | Stage | Progress | OpenAI | Leonardo | S3 | DB writes |
|---|-------|----------|--------|----------|----|-----------|
| 1 | Photo Analysis | 5→15% | Vision (GPT-4o) | - | - | characters.appearance_description |
| 2 | Story Bible | 15→30% | GPT-4o (JSON) | - | - | stories.story_bible, story_characters.role_in_story |
| 3 | Text Generation | 30→55% | GPT-4o (JSON) | - | - | pages (create records) |
| 4 | Scene Decomposition | 55→65% | GPT-4o (JSON) | - | - | pages.scene_description, pages.image_prompt |
| 5 | Character References | 65→70% | - | Generate | Upload | story_characters.reference_image_url |
| 6 | Illustration | 70→90% | - | Generate (10 parallel) | Upload | pages.image_url, pages.image_s3_key, stories.cover_image_url |
| 7 | Educational Content | 90→93% | GPT-4o (JSON) | - | - | educational_content (create records) |
| 8 | Title Generation | 93→96% | GPT-4o (JSON) | - | - | stories.title_suggested |
| 9 | Finalization | 96→100% | - | - | - | stories.status='completed', FCM push |

**Illustration style flow:**
- Stage 2 (Story Bible): `illustration_style` injected into OpenAI prompt → AI generates matching `visual_style` in story bible JSON
- Stage 4 (Scene Decomp): `STYLE_PROMPTS[illustration_style]` used as primary `visual_style` override; fallback to story bible value if no style set
- Stage 5 (Char Refs): `style_hint` passed to image service from story bible `visual_style`

**Image generation fallback chain:** Leonardo.ai → (2 failures) → DALL-E 3

**Concurrency:** `asyncio.Semaphore(IMAGE_MAX_CONCURRENT=10)` for parallel illustration

### 6.3 AI Model Configuration

**Text generation (OpenAI):**
- Model: `gpt-4o` (configurable via `OPENAI_MODEL`)
- Vision model: `gpt-4o` (configurable via `OPENAI_VISION_MODEL`)
- Temperature: 0.7 for JSON mode, 0.8 for regular chat

**Image generation (Leonardo.ai):**
- Model: Leonardo Phoenix (`6b645e3a-d64f-4341-a6d8-7a3690fbf042`)
- Character Reference: preprocessorId 133, strength "Mid", `initImageId`/`initImageType: "GENERATED"`
- Page illustrations: 1024x768 px
- Character references: 768x1024 px
- Alchemy: enabled, Style preset: ILLUSTRATION

**Image generation (DALL-E 3 fallback):**
- Model: DALL-E 3, Quality: standard, Style: vivid
- Concurrency: Semaphore(5)

---

## 7. S3 Storage Structure

**Provider:** TimeWeb S3 (S3-compatible)

```
{S3_BUCKET}/
├── character-photos/{user_id}/{character_id}/
│   └── photo_N.jpg
├── stories/{story_id}/
│   ├── characters/{character_id}/reference.png
│   ├── pages/1.png … N.png
│   └── cover.png
├── ui-assets/
│   ├── genres/{slug}.png          # 31 genre cover images (512×384)
│   ├── worlds/{slug}.png          # 30 world cover images (512×384)
│   ├── ages/age-{range}.png       # 3 age group images
│   └── ui/*.png                   # UI illustrations
└── landing-assets/
    ├── ui/hero-bg.png, cta-bg.png, how-step1-3.png
    ├── styles/{style}.png         # 8 illustration style previews
    └── showcase stories (4)       # landing page demo stories
```

**Access:** All objects uploaded with `ACL: public-read`

> ⚠️ `STORAGE_PUBLIC_URL` already includes bucket name. Never append bucket name again.

**CORS:** Bucket allows `GET`/`HEAD` from `https://talekid2-production.up.railway.app` + localhost ports.

---

## 8. Flutter App Architecture

### 8.1 Project Structure

```
flutter_app/lib/
├── config/
│   ├── theme.dart         # «Зачарованная ночь» dark theme
│   ├── router.dart        # go_router, auth guard, routes
│   ├── ui_assets.dart     # S3 URL constants (genres×31, worlds×30, ages×3, UI)
│   └── landing_assets.dart# Landing page assets + showcase story data
├── models/                # character.dart, story.dart, catalog.dart
├── providers/             # auth, character, catalog, generation, story
├── services/              # api_client, auth, catalog, character, generation, story, pdf, share
├── screens/
│   ├── landing/           # Public landing — hero, styles, genres, how-it-works, CTA
│   ├── auth/              # Login + Register
│   ├── home/              # Dashboard
│   ├── wizard/            # 3-step wizard + character dialog
│   ├── generation/        # Progress screen with pipeline timeline
│   ├── reader/            # Immersive story reader (mobile/web)
│   ├── library/           # Story library grid
│   └── legal/             # Terms, Privacy, Consent
└── widgets/
    ├── app_card.dart, glass_card.dart, gradient_button.dart
    ├── shimmer_loading.dart, character_card.dart
    ├── educational_popup.dart, title_dialog.dart, photo_picker.dart
```

### 8.2 Routing

| Path | Screen | Auth |
|------|--------|------|
| `/` | LandingScreen | No |
| `/auth/login` | LoginScreen | No |
| `/auth/register` | RegisterScreen | No |
| `/home` | HomeScreen | JWT |
| `/wizard` | WizardScreen | JWT |
| `/wizard/progress/:jobId` | GenerationProgressScreen | JWT |
| `/stories/:id` | ReaderScreen | JWT |
| `/library` | LibraryScreen | JWT |
| `/terms`, `/privacy`, `/consent` | LegalScreen | No |

### 8.3 API Client & Auth Flow

```
┌─ Dio Interceptor ─────────────────────────────────┐
│  Request: add Authorization: Bearer {accessToken}  │
│  Response 401 OR 403:                              │
│    → POST /auth/refresh                            │
│    → success: save tokens, retry request            │
│    → fail: clear tokens, redirect to login         │
└─────────────────────────────────────────────────────┘
```

**Token storage:** `flutter_secure_storage` · Keys: `access_token`, `refresh_token`

### 8.4 Brand Theme — «Зачарованная ночь»

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#0C0A1D` (deep midnight) | App background |
| Surface/Fill | `rgba(255,255,255,0.06)` | Glass surface |
| Card | glass-morphism (blur 20px) | Cards and panels |
| Text Primary | `#E8E5F0` (soft lavender) | Main text |
| Text Secondary | `#9B95B0` (muted lavender) | Secondary text |
| Primary | `#6366F1` (indigo) + glow shadow | Buttons, accents |
| Accent Gold | `#FFD700` | Highlights |
| Accent Purple | `#A78BFA` | Secondary accents |
| Border | `rgba(255,255,255,0.08)` | Card borders |
| Font (Headings) | Google Fonts Comfortaa | All headings |
| Font (Body) | Google Fonts Nunito Sans | Body text |

### 8.5 Wizard Steps

**Step 1 — Characters:**
- Select existing characters (multi-select)
- Create new character inline (bottom sheet dialog)
- At least 1 character required to proceed

**Step 2 — Settings:**
- Age range: `3-5` / `6-8` / `9-12` (image cards)
- Education level: 0.0–1.0 (Slider, "Entertainment ↔ Learning")
- **Genre** — select from catalog (responsive grid, 70% viewport width, 3-8 cols, required)
- **World** — select from catalog (same responsive grid, required)
- **Base tale** — optional selection from 50 templates
- **Illustration style** — 8 styles with cover images (responsive grid, same 70% layout):
  - Акварель · 3D Анимация (Pixar) · Disney · Комикс · Аниме · Пастель · Книжная классика · Поп-арт
  - Default: Акварель; cover images from `landing-assets/styles/{slug}.png`

**Step 3 — Format:**
- Page count: 5–30 (Slider + presets)
- Reading duration: 5–30 min (Slider + presets)

### 8.6 Reader UX

**Mobile (Android):**
- Horizontal `PageView` (swipe between pages)
- Full-bleed illustration + frosted glass text overlay at bottom
- Top overlay: back button, title, page counter
- Bottom: page dots, lightbulb (educational content)

**Web (immersive):**
- `Stack(fit: StackFit.expand)` — fullscreen CachedNetworkImage background
- Frosted glass top overlay (back/title/PDF/share/lightbulb) via `BackdropFilter`
- Text card: `Positioned(bottom: 80)` — `ClipRRect + BackdropFilter(blur: 16)`, black 40% + white 15% border, max 700px wide
- Floating arrow navigation (left/right, vertically centered)
- Bottom overlay: page dots
- Keyboard navigation: ←/→ arrow keys via `Focus + onKeyEvent`

---

## 9. Environment Variables

### 9.1 Backend API

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRESQL_HOST/PORT/USER/PASSWORD/DBNAME` | Yes | - | TimeWeb PostgreSQL |
| `POSTGRESQL_SSLMODE` | No | verify-full | SSL mode |
| `S3_ENDPOINT_URL`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_BUCKET`, `STORAGE_PUBLIC_URL` | Yes | - | TimeWeb S3 |
| `JWT_SECRET` | Yes | - | JWT signing secret (base64) |
| `JWT_ALGORITHM` | No | HS256 | JWT algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | No | 30 | Access token TTL |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | No | 30 | Refresh token TTL |
| `OPENAI_API_KEY` | Yes | - | OpenAI API key |
| `LEONARDO_API_KEY` | Yes | - | Leonardo.ai API key |
| `REDIS_URL` | No | redis://localhost:6379 | Redis connection URL |
| `IMAGE_ENGINE` | No | leonardo | `leonardo` or `dalle` |
| `IMAGE_MAX_CONCURRENT` | No | 10 | Max parallel image generation |

### 9.2 Worker

All variables from 9.1 plus:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_MODEL` | No | gpt-4o | Text generation model |
| `OPENAI_VISION_MODEL` | No | gpt-4o | Vision model |
| `REDIS_QUEUE` | No | talekid:jobs | Redis queue name |
| `REDIS_PROGRESS_PREFIX` | No | talekid:progress | Progress key prefix |
| `REDIS_PROGRESS_TTL` | No | 3600 | Progress TTL (seconds) |
| `GOOGLE_APPLICATION_CREDENTIALS` | No | - | Firebase service account |

### 9.3 Web

**Build-time variable (baked into Flutter):**
- `API_BASE_URL` — set in `Dockerfile.web` as `--dart-define`

---

## 10. Deployment

### 10.1 Railway Services

| Service | Dockerfile | Start Command |
|---------|-----------|---------------|
| api | `Dockerfile.backend` | `uvicorn app.main:app --host 0.0.0.0 --port ${PORT}` |
| worker | `Dockerfile.worker` | `python -m app.main` |
| web | `Dockerfile.web` | nginx (auto) |
| redis | Railway managed | Auto |

### 10.2 CI/CD (GitHub Actions)

**Triggers:** Push to `master` branch (auto-deploys api + worker on relevant file changes)

### 10.3 Database Initialization

On first startup:
1. `Base.metadata.create_all` — creates all tables if missing
2. `_seed_catalog_if_empty()` — inserts 6 genres + 6 worlds if genres table is empty

**New columns added to production via direct ALTER TABLE** (Alembic versions dir is empty):
- `stories.illustration_style VARCHAR(50)` — added 2026-03-16

Full catalog (31 genres, 30 worlds, 50 base tales) loaded via `python3 -m app.seed.seed_db`.

---

## 11. Seed Data

### 11.1 Genres (31 total)

Original 6 + 25 new (seeded via `backend/app/seed/genres.json`):

**Original:** adventure · fairy-tale · educational · friendship · funny · bedtime

**New:** detective · rescue · riddles · journey · fantasy · space-sci-fi · animal-stories · superheroes · light-mystery · everyday-stories · school-stories · moral-stories · survival-nature · historical-adventure · creativity-imagination · holiday-stories · science-adventure · quest-treasure-hunt · sea-adventure · prehistoric-world · robots-technology · profession-stories · magical-worlds · secrets-mysteries · self-discovery-growing-up

**Cover images:** All 31 genres have S3 cover images at `ui-assets/genres/{slug}.png` (512×384, generated via Leonardo AI Phoenix)

### 11.2 Worlds (30 total)

Original 6 + 24 new (seeded via `backend/app/seed/worlds.json`):

**Original:** enchanted-forest · space · underwater · medieval-kingdom · modern-city · dinosaur-world

**New:** ancient-legends · underground-world · sky-kingdom · dragon-world · robot-world · enchanted-castle · mysterious-island · wonder-desert · north-pole · jungle · candy-land · dream-world · lost-city · pirate-islands · magic-school · deep-ocean · moon-base · monster-planet · giant-world · miniature-world · cloud-country · shadow-labyrinth · time-kingdom · elemental-world

**Cover images:** All 30 worlds have S3 cover images at `ui-assets/worlds/{slug}.png`

### 11.3 Base Tales (50 total)

50 Russian fairy tale templates with plot structures and characters, seeded via `backend/app/seed/seed_db.py` (run once manually).

### 11.4 Illustration Style Previews (8)

Cover images at `landing-assets/styles/{slug}.png`:

| Slug | Name |
|------|------|
| watercolor | Акварель |
| 3d-pixar | 3D Анимация (Pixar) |
| disney | Disney |
| comic | Комикс |
| anime | Аниме |
| pastel | Пастель |
| classic-book | Книжная классика |
| pop-art | Поп-арт |

---

## 12. Shared Constants (`shared/constants.py`)

```python
CharacterType:   child | adult | pet
Gender:          male | female
AgeRange:        3-5 | 6-8 | 9-12
StoryStatus:     draft | generating | completed | failed
JobStatus:       queued | processing | photo_analysis | story_bible |
                 text_generation | scene_decomposition | character_references |
                 illustration | education | title_generation | saving |
                 completed | failed
Platform:        android | web
BaseTaleCharacterRole: protagonist | antagonist | helper | secondary
EducationalContentType: fact | question

# Illustration styles
VALID_ILLUSTRATION_STYLES: frozenset = {
    "watercolor", "3d-pixar", "disney", "comic",
    "anime", "pastel", "classic-book", "pop-art"
}
STYLE_PROMPTS: dict[str, str]  # slug → English AI prompt fragment
```

---

## 13. Key Files Reference

### Backend
| File | Purpose |
|------|---------|
| `backend/app/main.py` | FastAPI app, CORS, lifespan, auto-seed |
| `backend/app/config.py` | Pydantic BaseSettings, all env vars |
| `backend/app/database.py` | Async SQLAlchemy engine, SSL fallback |
| `backend/app/routers/*.py` | API endpoints |
| `backend/app/schemas/generation.py` | GenerationCreateRequest (incl. illustration_style) |
| `backend/app/services/generation_service.py` | Job creation, Redis enqueue |
| `backend/app/seed/seed_db.py` | Full catalog seed (31 genres, 30 worlds, 50 tales) |

### Worker
| File | Purpose |
|------|---------|
| `worker/app/main.py` | Redis BRPOP loop, pipeline orchestrator |
| `worker/app/pipeline/base.py` | PipelineContext (incl. illustration_style) |
| `worker/app/pipeline/story_bible.py` | Stage 2: style injected into OpenAI prompt |
| `worker/app/pipeline/scene_decomposition.py` | Stage 4: STYLE_PROMPTS override |
| `worker/app/services/image_service.py` | Unified image router with fallback |

### Shared
| File | Purpose |
|------|---------|
| `shared/models/story.py` | Story model (incl. illustration_style column) |
| `shared/constants.py` | Enums + STYLE_PROMPTS + VALID_ILLUSTRATION_STYLES |

### Flutter
| File | Purpose |
|------|---------|
| `flutter_app/lib/config/theme.dart` | «Зачарованная ночь» dark theme |
| `flutter_app/lib/config/ui_assets.dart` | S3 URL constants (86 total assets) |
| `flutter_app/lib/config/landing_assets.dart` | Landing assets + showcase story data |
| `flutter_app/lib/screens/wizard/wizard_screen.dart` | 3-step wizard + `_StyleSelector` |
| `flutter_app/lib/screens/reader/reader_screen.dart` | Immersive reader (mobile + web) |
| `flutter_app/lib/services/generation_service.dart` | createGeneration(illustrationStyle) |

### Infrastructure
| File | Purpose |
|------|---------|
| `Dockerfile.backend/worker/web` | Docker builds |
| `generate_catalog_assets.py` | Leonardo AI → S3 asset generation script |

---

## 14. Current Production URLs

| Service | URL |
|---------|-----|
| API | https://talekid-production.up.railway.app |
| API Docs | https://talekid-production.up.railway.app/docs |
| Web App | https://talekid2-production.up.railway.app |
| Domain (planned) | https://talekid.ai |

---

## 15. Known Constraints & Notes

1. **CORS (API):** `allow_origins` lists explicit origins — wildcard forbidden with `allow_credentials=True`.
2. **CORS (S3):** Explicit CORS rules for web origin. If domain changes, update via `boto3.put_bucket_cors()`.
3. **Password hashing:** Requires `bcrypt==4.1.3` (passlib 1.7.4 incompatible with bcrypt ≥5.0).
4. **SSL fallback:** Without `root.crt`, uses encrypted connection without cert verification.
5. **Image consistency:** Leonardo Character Reference + `initImageId`/`initImageType: "GENERATED"` for visual consistency; DALL-E fallback loses consistency.
6. **Catalog auto-seed:** Only 6 genres + 6 worlds on first startup; full 31+30+50 requires `python3 -m app.seed.seed_db`.
7. **illustration_style migration:** Column added via direct `ALTER TABLE` (not Alembic). Existing stories have `NULL` → treated as `watercolor` in worker.
8. **Firebase FCM:** Not yet initialized in Flutter; push_service gracefully degrades.
9. **PDF generation:** Client-side only (Flutter `pdf` package).
10. **Localization:** Russian UI; API prompts in English for AI models.

---

## 16. Changelog

### v1.4.0 — 2026-03-16

**New Features:**

- **User Context Field** — Personal context input in wizard Step 3, woven by AI into the story:
  - Flutter: text field in Step 3 (Format), up to 1000 chars, with hint "Например: «Сегодня мы ходили в зоопарк...»"
  - DB: `stories.user_context TEXT NULLABLE` column (ALTER TABLE executed in production)
  - Backend: `user_context: Optional[str]` field in `GenerationCreateRequest` (max 1000 chars)
  - Backend service: `user_context` stored in Story record + passed in Redis payload
  - Worker `PipelineContext`: `self.user_context: str | None`
  - Worker Stage 2 (Story Bible): context injected as 🌟 priority instruction requiring organic integration
  - Worker Stage 3 (Text Generation): context re-injected on every page prompt for consistency; special guidance on first/last pages
  - Example use: "Мы сегодня ходили в зоопарк, Маша была в восторге от попугаев" → ИИ строит вокруг этого весь сюжет

---

### v1.3.0 — 2026-03-16

**New Features:**

- **Illustration Style Selector** (full stack) — Users can choose 1 of 8 artistic styles when creating a story:
  - Акварель · 3D Анимация (Pixar) · Disney · Комикс · Аниме · Пастель · Книжная классика · Поп-арт
  - DB: `stories.illustration_style VARCHAR(50)` column (ALTER TABLE in production)
  - Backend: `illustration_style` field in `GenerationCreateRequest`, stored in Story + Redis payload
  - Worker Stage 2 (Story Bible): style injected into OpenAI prompt as forced `visual_style`
  - Worker Stage 4 (Scene Decomp): `STYLE_PROMPTS[slug]` overrides AI-generated visual style
  - `shared/constants.py`: `STYLE_PROMPTS` dict + `VALID_ILLUSTRATION_STYLES` frozenset
  - Flutter: `_StyleSelector` widget (responsive grid, 3-8 cols, cover images from S3, checkmark on selected)

- **Extended Catalog** — 31 genres + 30 worlds + 50 base tales:
  - 25 new genres + 24 new worlds added via `backend/app/seed/seed_db.py`
  - All 49 new catalog items have AI-generated cover images (Leonardo Phoenix, 512×384, uploaded to S3)
  - `ui_assets.dart`: 49 new Dart constants
  - `wizard_screen.dart`: `_genreAssets` / `_worldAssets` maps extended to all slugs

- **Responsive Wizard Grid** — Genre and world grids now fill 70% of browser viewport width:
  - Dynamic column count: `(width / 160).floor().clamp(3, 8)`
  - Separate `SizedBox(width: screenWidth * 0.70)` containers for genre/world/style sections
  - Age, education, base tale sections remain at `maxWidth: 640`

- **«Зачарованная ночь» Dark Theme** — Complete visual redesign:
  - Background `#0C0A1D`, glass-morphism cards, indigo/gold/purple accent palette
  - Comfortaa headings + Nunito Sans body fonts
  - All screens updated: home, wizard, generation progress, reader, library, auth, landing

- **Immersive Web Reader** — Fullscreen illustration with frosted glass text overlay:
  - `Stack(fit: StackFit.expand)` + `BackdropFilter(blur: 16)` text card
  - Keyboard navigation (←/→)
  - Floating navigation arrows

- **Landing Page** — Full redesign with 8 style cards showcase, 4 interactive story previews (10 pages each with real illustrations and text), features section.

- **Seed Script** (`backend/app/seed/seed_db.py`) — Idempotent upsert of full catalog (31 genres, 30 worlds, 50 base tales with characters).

**Technical:**
- `generate_catalog_assets.py` — standalone script for Leonardo AI → S3 cover generation
- Production PostgreSQL `ALTER TABLE stories ADD COLUMN IF NOT EXISTS illustration_style VARCHAR(50)` executed directly

---

### v1.2.0 — 2026-03-15

**Fixes:**
- **S3 CORS** — Configured `GET`/`HEAD` CORS rule on TimeWeb S3 for production web origin.
- **DB: double-bucket image URLs** — Fixed 18 pages + 2 covers + 2 character refs with `/{bucket}/{bucket}/{key}` paths.
- **CORS middleware (API)** — Replaced `allow_origins=["*"]` with explicit origin list.
- **JWT interceptor: 403 handling** — FastAPI `HTTPBearer` returns 403 when `Authorization` is absent; interceptor now handles both 401 and 403.
- **JWT interceptor: dangling handler** — Retry in `onError` now wrapped in `try/catch` with `handler.next()` fallback.

---

### v1.1.0 — 2026-03-14

**Fixes:**
- **S3 URL double-bucket** — `STORAGE_PUBLIC_URL` already contains bucket; removed duplicate append.
- **Leonardo.ai 400 Bad Request** — Replaced invalid `initImageUrl` with `initImageId` + `initImageType: "GENERATED"` in controlnets. Rewrote character reference pipeline (5 files).
