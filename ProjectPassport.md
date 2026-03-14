# TaleKID - Project Passport

> **Version:** 1.0.0 | **Date:** 2026-03-14 | **Repository:** https://github.com/aka-sergey/TaleKid2 | **Branch:** master

---

## 1. Overview

**TaleKID** — mobile (Android) + web application for generating personalized illustrated children's fairy tales using AI. Users create characters (with photos), choose genre, world, and optionally a base tale template; the system generates story text (Russian) and illustrations page by page.

**Target audience:** Parents with children aged 3-12, Russian-speaking market.

**Core flow:** Register → Create Characters → Wizard (genre, world, age, education level) → Generation pipeline (9 stages) → Reading experience with educational content.

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
| **Migrations** | Alembic | 1.13.0 | Schema versioning |
| **Queue** | Redis | 5.1.0 | BRPOP job queue + progress |
| **Auth** | JWT (HS256) | python-jose 3.3.0 | Access + Refresh tokens |
| **Password** | bcrypt | 4.1.3 | via passlib 1.7.4 |
| **Storage** | S3 (TimeWeb) | boto3 1.35.0 | Photos, illustrations |
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
  "visual_style": "Illustration style description"
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

**Registration request:**
```json
{
  "email": "user@example.com",
  "password": "min6chars",
  "display_name": "Optional Name"
}
```

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

**CharacterResponse:**
```json
{
  "id": "uuid",
  "name": "string",
  "character_type": "child|adult|pet",
  "gender": "male|female",
  "age": null,
  "appearance_description": null,
  "photos": [
    {"id": "uuid", "s3_url": "https://...", "sort_order": 0}
  ],
  "created_at": "2026-03-14T12:00:00Z",
  "updated_at": "2026-03-14T12:00:00Z"
}
```

**Constraints:** max 3 photos per character.

### 5.3 Catalog (No Auth Required)

| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/catalog/genres` | `[{id, slug, name_ru, description_ru, icon_url, sort_order}, ...]` |
| GET | `/catalog/worlds` | `[{id, slug, name_ru, description_ru, icon_url, sort_order}, ...]` |
| GET | `/catalog/base-tales` | `[{id, slug, name_ru, icon_url}, ...]` |
| GET | `/catalog/base-tales/{id}` | `{id, slug, name_ru, summary_ru, moral_ru, icon_url, characters: [...]}` |

**BaseTaleResponse (detail):**
```json
{
  "id": 1,
  "slug": "kolobok",
  "name_ru": "Kolok",
  "summary_ru": "...",
  "moral_ru": "...",
  "icon_url": null,
  "characters": [
    {"id": 1, "name_ru": "Kolok", "role": "protagonist", "personality_ru": "..."}
  ]
}
```

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
  "reading_duration_minutes": 10
}
```

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

**StoryDetailResponse:**
```json
{
  "id": "uuid",
  "title": "Story Title",
  "title_suggested": "AI Suggested Title",
  "cover_image_url": "https://...",
  "status": "completed",
  "age_range": "6-8",
  "page_count": 10,
  "reading_duration_minutes": 10,
  "created_at": "2026-03-14T12:00:00Z",
  "pages": [
    {
      "id": "uuid",
      "page_number": 1,
      "text_content": "Story text in Russian...",
      "image_url": "https://s3.../page_01.png",
      "educational_content": {
        "content_type": "fact",
        "text_ru": "Interesting fact in Russian",
        "answer_ru": null,
        "topic": "Nature"
      }
    }
  ],
  "characters": [
    {
      "character_id": "uuid",
      "character_name": "Character Name",
      "role_in_story": "protagonist",
      "reference_image_url": "https://..."
    }
  ]
}
```

### 5.6 Health

| Method | Endpoint | Auth | Response |
|--------|----------|------|----------|
| GET | `/health` | No | `{"status": "ok"}` |
| GET | `/health/db` | No | `{"status": "ok", "database": "connected"}` |

### 5.7 Error Responses

All errors follow the format:
```json
{
  "detail": "Error description"
}
```

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
  "reading_duration_minutes": 10
}
```

**Progress payload (JSON in Redis key):**
```json
{
  "status": "processing|completed|failed",
  "progress_pct": 0-100,
  "status_message": "Human readable (Russian/English)",
  "error_message": null
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

**Image generation fallback chain:** Leonardo.ai → (2 failures) → DALL-E 3

**Concurrency:** `asyncio.Semaphore(IMAGE_MAX_CONCURRENT=10)` for parallel illustration

**Error handling:** Each stage retries up to 3x with exponential backoff. On final failure: `generation_jobs.status='failed'`, `stories.status='failed'`, error saved to `generation_jobs.error_message`.

### 6.3 AI Model Configuration

**Text generation (OpenAI):**
- Model: `gpt-4o` (configurable via `OPENAI_MODEL`)
- Vision model: `gpt-4o` (configurable via `OPENAI_VISION_MODEL`)
- Max tokens: 4096 (configurable)
- Temperature: 0.7 for JSON mode, 0.8 for regular chat
- Response format: `{"type": "json_object"}` for structured outputs

**Image generation (Leonardo.ai):**
- Model: Leonardo Phoenix (`6b645e3a-d64f-4341-a6d8-7a3690fbf042`)
- Character Reference: preprocessorId 133, strength "Mid"
- Page illustrations: 1024x768 px
- Character references: 768x1024 px
- Alchemy: enabled
- Style preset: ILLUSTRATION
- Negative prompt: `"ugly, deformed, blurry, low quality, text, watermark, signature, adult content, violence, scary, horror"`
- Polling: GET every 3s, max 60 attempts (3 min timeout)

**Image generation (DALL-E 3 fallback):**
- Model: DALL-E 3
- Sizes: 1792x1024 (landscape), 1024x1792 (portrait), 1024x1024 (square)
- Quality: standard
- Style: vivid
- Concurrency: Semaphore(5) (stricter limits)
- Safety prefix auto-prepended to all prompts

---

## 7. S3 Storage Structure

**Provider:** TimeWeb S3 (S3-compatible, region `ru-1`, signature `s3v4`)

```
{S3_BUCKET}/
├── character-photos/{user_id}/{character_id}/
│   ├── photo_1.jpg
│   ├── photo_2.jpg
│   └── photo_3.jpg
└── stories/{story_id}/
    ├── characters/{character_id}/
    │   └── reference.png
    ├── pages/
    │   ├── 1.png
    │   ├── 2.png
    │   └── ...N.png
    └── cover.png (= first page image)
```

**Access:** All objects uploaded with `ACL: public-read`
**Public URL pattern:** `{STORAGE_PUBLIC_URL}/{key}`

---

## 8. Flutter App Architecture

### 8.1 Project Structure

```
flutter_app/lib/
├── main.dart              # Entry point, ProviderScope
├── app.dart               # MaterialApp.router, theme, locale
├── config/
│   ├── app_config.dart    # API URL, timeouts, limits
│   ├── theme.dart         # Material 3 theme, brand colors
│   └── router.dart        # go_router, auth guard, routes
├── models/
│   ├── character.dart     # CharacterModel, CharacterPhoto
│   ├── story.dart         # StoryModel, StoryDetail, StoryPage, GenerationJob
│   └── catalog.dart       # Genre, World, BaseTale
├── providers/
│   ├── auth_provider.dart       # AuthNotifier, apiClient
│   ├── character_provider.dart  # CharactersNotifier
│   ├── catalog_provider.dart    # genres, worlds, baseTales FutureProviders
│   ├── generation_provider.dart # GenerationJobNotifier (polling)
│   └── story_provider.dart      # StoriesNotifier
├── services/
│   ├── api_client.dart          # Dio wrapper, JWT interceptor
│   ├── auth_service.dart        # register, login, logout
│   ├── catalog_service.dart     # genres, worlds, baseTales
│   ├── character_service.dart   # CRUD + photo upload
│   ├── generation_service.dart  # create, status, cancel
│   ├── story_service.dart       # library, detail, rename, delete
│   ├── pdf_service.dart         # landscape PDF generation
│   └── share_service.dart       # link sharing, PDF sharing
├── screens/
│   ├── landing/           # Public landing page
│   ├── auth/              # Login + Register
│   ├── home/              # Dashboard
│   ├── wizard/            # 3-step story creation + character dialog
│   ├── generation/        # Progress screen with polling
│   ├── reader/            # Story reader (mobile/web layouts)
│   ├── library/           # Story library grid
│   └── legal/             # Terms, Privacy, Consent
└── widgets/
    ├── character_card.dart      # Character list item
    ├── photo_picker.dart        # Cross-platform photo upload
    ├── educational_popup.dart   # Fact/question bottom sheet
    └── title_dialog.dart        # Story naming dialog
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
| `/terms` | LegalScreen (Terms) | No |
| `/privacy` | LegalScreen (Privacy) | No |
| `/consent` | LegalScreen (Consent) | No |

**Auth guard:** Unauthenticated users redirected to `/auth/login`. Public routes (landing, auth, legal, catalog) bypass the guard.

### 8.3 API Client & Auth Flow

```
┌─ Dio Interceptor ─────────────────────────────────┐
│                                                     │
│  Request:                                           │
│    if path NOT in [/auth/*, /health, /catalog/*]:   │
│      → add Authorization: Bearer {accessToken}      │
│                                                     │
│  Response 401:                                      │
│    → POST /auth/refresh {refresh_token}             │
│    → if success: save new tokens, retry request     │
│    → if fail: clear tokens, redirect to login       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Token storage:** `flutter_secure_storage` (encrypted on device)
**Keys:** `access_token`, `refresh_token`

### 8.4 State Management Pattern

```dart
// Provider chain:
apiClientProvider → authServiceProvider → authStateProvider
apiClientProvider → characterApiServiceProvider → charactersProvider
apiClientProvider → catalogServiceProvider → genresProvider / worldsProvider / baseTalesProvider
apiClientProvider → generationServiceProvider → generationJobProvider(jobId)
apiClientProvider → storyServiceProvider → storiesProvider / storyDetailProvider(storyId)
```

All data providers use `AsyncNotifier` or `FutureProvider`. Catalog providers are cached while listeners exist. Character and story providers support optimistic updates.

### 8.5 Brand Theme

| Token | Value | Usage |
|-------|-------|-------|
| Primary | `#6C5CE7` (purple) | Buttons, AppBar, accents |
| Secondary | `#FF6B6B` (red) | Secondary actions |
| Accent | `#FFD93D` (yellow) | Highlights |
| Success | `#00B894` (green) | Completed status |
| Error | `#E17055` (orange-red) | Error states |
| Warning | `#FDCB6E` (amber) | Warnings |
| Info | `#74B9FF` (light blue) | Info badges |
| Font | Google Fonts Nunito | All text |

### 8.6 Wizard Steps

**Step 1 — Characters:**
- Select existing characters (multi-select)
- Create new character inline (bottom sheet dialog)
- At least 1 character required

**Step 2 — Settings:**
- Age range: `3-5` / `6-8` / `9-12` (ChoiceChips)
- Education level: 0.0–1.0 (Slider, "Entertainment ↔ Learning")
- Genre: select from catalog (ChoiceChips, required)
- World: select from catalog (ChoiceChips, required)
- Base tale: select from catalog or "Original Plot" (optional)

**Step 3 — Format:**
- Page count: 5–30 (Slider)
- Reading duration: 5–30 min (Slider)
- Quick presets (e.g., "Short 5 min", "Medium 15 min")

### 8.7 Reader UX

**Mobile (Android):**
- Horizontal `PageView` (swipe between pages)
- Full-bleed illustration + text overlay at bottom
- Top overlay: back button, title, page counter
- Bottom: page dots, lightbulb (educational content)

**Web:**
- Vertical layout, image (4:3 aspect) + text below
- Left/right arrow navigation
- AppBar: title, page indicator, lightbulb, PDF, share buttons
- Max 10 page dots (ellipsis for more)

---

## 9. Environment Variables

### 9.1 Backend API (Railway service: `api`)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRESQL_HOST` | Yes | - | TimeWeb PostgreSQL host |
| `POSTGRESQL_PORT` | No | 5432 | PostgreSQL port |
| `POSTGRESQL_USER` | Yes | - | DB username |
| `POSTGRESQL_PASSWORD` | Yes | - | DB password |
| `POSTGRESQL_DBNAME` | Yes | - | Database name |
| `POSTGRESQL_SSLMODE` | No | verify-full | SSL mode |
| `S3_ENDPOINT_URL` | Yes | - | TimeWeb S3 endpoint |
| `S3_ACCESS_KEY_ID` | Yes | - | S3 access key |
| `S3_SECRET_ACCESS_KEY` | Yes | - | S3 secret key |
| `S3_BUCKET` | Yes | - | S3 bucket name |
| `STORAGE_PUBLIC_URL` | Yes | - | Public URL for S3 files |
| `JWT_SECRET` | Yes | - | JWT signing secret (base64) |
| `JWT_ALGORITHM` | No | HS256 | JWT algorithm |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | No | 30 | Access token TTL |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | No | 30 | Refresh token TTL |
| `OPENAI_API_KEY` | Yes | - | OpenAI API key |
| `LEONARDO_API_KEY` | Yes | - | Leonardo.ai API key |
| `REDIS_URL` | No | redis://localhost:6379 | Redis connection URL |
| `IMAGE_ENGINE` | No | leonardo | Image engine: leonardo/dalle |
| `IMAGE_MAX_CONCURRENT` | No | 10 | Max parallel image generation |

### 9.2 Worker (Railway service: `worker`)

All variables from 9.1 plus:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `OPENAI_MODEL` | No | gpt-4o | Text generation model |
| `OPENAI_VISION_MODEL` | No | gpt-4o | Vision analysis model |
| `OPENAI_MAX_TOKENS` | No | 4096 | Max response tokens |
| `REDIS_QUEUE` | No | talekid:jobs | Redis queue name |
| `REDIS_PROGRESS_PREFIX` | No | talekid:progress | Progress key prefix |
| `REDIS_PROGRESS_TTL` | No | 3600 | Progress TTL (seconds) |
| `WORKER_CONCURRENCY` | No | 1 | Worker instances (reserved) |
| `GOOGLE_APPLICATION_CREDENTIALS` | No | - | Firebase service account JSON path |

### 9.3 Web (Railway service: `web`)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `PORT` | Auto | 80 | Railway injects dynamically |

**Build-time variable (baked into Flutter):**
- `API_BASE_URL` — set in `Dockerfile.web` as `--dart-define`

---

## 10. Deployment

### 10.1 Railway Services

| Service | Dockerfile | Healthcheck | Start Command |
|---------|-----------|-------------|---------------|
| api | `Dockerfile.backend` | `/api/v1/health` (300s timeout) | `uvicorn app.main:app --host 0.0.0.0 --port ${PORT}` |
| worker | `Dockerfile.worker` | None | `python -m app.main` |
| web | `Dockerfile.web` | None | nginx (auto) |
| redis | Railway managed | Auto | Auto |

**Railway settings (all services):**
- Root Directory: `` (empty, repo root)
- Builder: Dockerfile
- Restart policy: ON_FAILURE, max 10 retries

### 10.2 CI/CD (GitHub Actions)

**Triggers:** Push to `master` branch

**api-deploy.yml:** backend/**, shared/**, Dockerfile.backend
1. Checkout → Setup Python 3.12 → Install deps → Run pytest → Install Railway CLI → `railway up --service api`

**worker-deploy.yml:** worker/**, shared/**, Dockerfile.worker
1. Checkout → Setup Python 3.12 → Install deps → Run pytest → Install Railway CLI → `railway up --service worker`

**Web:** Deployed manually or via Railway auto-deploy on push (watches Dockerfile.web)

### 10.3 Database Initialization

On first startup (`lifespan` in `main.py`):
1. `Base.metadata.create_all` — creates all tables if missing
2. `_seed_catalog_if_empty()` — inserts 6 genres + 6 worlds if genres table is empty

**Production migrations:** Alembic (configured but manual)

### 10.4 SSL

- Backend + Worker: look for `root.crt` in project directory
- If found: full certificate verification
- If not found (Railway): encrypted connection without cert verification (`CERT_NONE`)

---

## 11. Seed Data

### 11.1 Genres (6)

| slug | name_ru | prompt_hint (summary) |
|------|---------|----------------------|
| adventure | Appended | Exciting journey, discoveries, obstacles |
| fairy-tale | Fairy Tale | Magic, enchantments, transformations |
| educational | Educational | Interesting facts woven into narrative |
| friendship | About Friendship | Loyalty, helping each other |
| funny | Funny Story | Comic situations, wordplay |
| bedtime | Bedtime Tale | Calm, soothing, peaceful |

### 11.2 Worlds (6)

| slug | name_ru | visual_style_hint (summary) |
|------|---------|----------------------------|
| enchanted-forest | Enchanted Forest | Studio Ghibli, warm tones |
| space | Space | Pixar-style kid-friendly sci-fi |
| underwater | Underwater | Colorful coral, bioluminescent |
| medieval-kingdom | Fairy Kingdom | Classic Disney storybook |
| modern-city | Modern City | Friendly, warm urban |
| dinosaur-world | Dinosaur World | Bright, adventurous jungle |

### 11.3 Base Tales (3, from seed script)

| slug | name_ru | summary |
|------|---------|---------|
| kolobok | Kolobok | Round bun escapes, meets animals |
| teremok | Teremok | Animals settle in a small house |
| repka | Repka (Turnip) | Grandfather can't pull out a huge turnip |

---

## 12. Shared Constants (Enums)

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
```

---

## 13. Key Files Reference

### Backend
| File | Purpose |
|------|---------|
| `backend/app/main.py` | FastAPI app, CORS, lifespan, auto-seed |
| `backend/app/config.py` | Pydantic BaseSettings, all env vars |
| `backend/app/database.py` | Async SQLAlchemy engine, SSL fallback |
| `backend/app/dependencies.py` | get_db, get_current_user (JWT) |
| `backend/app/core/security.py` | JWT create/decode, bcrypt hash/verify |
| `backend/app/core/exceptions.py` | HTTP exceptions (400/401/403/404/409) |
| `backend/app/core/middleware.py` | Request logging, X-Request-ID |
| `backend/app/routers/*.py` | API endpoints (auth, characters, catalog, generation, stories, health) |
| `backend/app/schemas/*.py` | Pydantic request/response models |
| `backend/app/services/*.py` | Business logic (auth, character, story, generation, s3, redis) |
| `backend/requirements.txt` | Python dependencies |

### Worker
| File | Purpose |
|------|---------|
| `worker/app/main.py` | Redis BRPOP loop, pipeline orchestrator |
| `worker/app/config.py` | Worker env vars |
| `worker/app/database.py` | Async engine for worker |
| `worker/app/pipeline/base.py` | PipelineContext, PipelineStage base |
| `worker/app/pipeline/*.py` | 9 pipeline stages |
| `worker/app/services/openai_service.py` | GPT-4o text + Vision |
| `worker/app/services/leonardo_service.py` | Leonardo.ai image generation |
| `worker/app/services/dalle_service.py` | DALL-E 3 fallback |
| `worker/app/services/image_service.py` | Unified image router with fallback |
| `worker/app/services/s3_service.py` | S3 upload/delete |
| `worker/app/services/redis_service.py` | Queue consume, progress tracking |
| `worker/app/services/push_service.py` | FCM push notifications |
| `worker/app/utils/text.py` | JSON cleanup, truncation |
| `worker/requirements.txt` | Worker Python dependencies |

### Shared
| File | Purpose |
|------|---------|
| `shared/models/base.py` | DeclarativeBase, TimestampMixin |
| `shared/models/*.py` | All SQLAlchemy ORM models (12 files) |
| `shared/constants.py` | Enums for types, statuses, roles |

### Flutter
| File | Purpose |
|------|---------|
| `flutter_app/lib/main.dart` | App entry, ProviderScope |
| `flutter_app/lib/app.dart` | MaterialApp.router, theme |
| `flutter_app/lib/config/app_config.dart` | API URL, timeouts |
| `flutter_app/lib/config/theme.dart` | Material 3 theme |
| `flutter_app/lib/config/router.dart` | go_router, auth guard |
| `flutter_app/lib/models/*.dart` | Dart data models (3 files) |
| `flutter_app/lib/providers/*.dart` | Riverpod providers (5 files) |
| `flutter_app/lib/services/*.dart` | API services (7 files) |
| `flutter_app/lib/screens/**/*.dart` | UI screens (8 sections) |
| `flutter_app/lib/widgets/*.dart` | Reusable widgets (4 files) |
| `flutter_app/pubspec.yaml` | Flutter dependencies |

### Infrastructure
| File | Purpose |
|------|---------|
| `Dockerfile.backend` | API Docker build |
| `Dockerfile.worker` | Worker Docker build |
| `Dockerfile.web` | Flutter web → nginx build |
| `backend/railway.toml` | Backend Railway config |
| `worker/railway.toml` | Worker Railway config |
| `.github/workflows/api-deploy.yml` | Backend CI/CD |
| `.github/workflows/worker-deploy.yml` | Worker CI/CD |
| `backend/.env.example` | Env vars template |

---

## 14. Current Production URLs

| Service | URL |
|---------|-----|
| API | https://talekid-production.up.railway.app |
| API Docs | https://talekid-production.up.railway.app/docs |
| Web App | (Railway web service URL) |
| Domain (planned) | https://talekid.ai |

---

## 15. Known Constraints & Notes

1. **CORS:** Currently `allow_origins=["*"]` — to be restricted in production
2. **Password hashing:** Requires `bcrypt==4.1.3` (passlib 1.7.4 incompatible with bcrypt >=5.0)
3. **Email validation:** Requires `pydantic[email]` (includes email-validator package)
4. **SSL fallback:** Without `root.crt`, SSL connection is encrypted but without certificate verification
5. **Image consistency:** Leonardo Character Reference (preprocessorId 133) used for visual consistency across pages; DALL-E fallback loses character consistency
6. **Catalog auto-seed:** 6 genres + 6 worlds inserted on first startup; base tales (3) available via seed script only
7. **Firebase FCM:** Not yet initialized in Flutter; push_service in worker gracefully degrades if credentials missing
8. **PDF generation:** Client-side (Flutter `pdf` package), no server load
9. **Localization:** Russian UI throughout; API prompts in English for AI models, user-facing content in Russian
