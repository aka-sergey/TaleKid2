# TaleKID — Project Passport

> **Version:** 1.5.0 | **Date:** 2026-03-17 | **Repository:** https://github.com/aka-sergey/TaleKid2 | **Branch:** master

---

## 1. Что такое TaleKID

**TaleKID** — мобильное (Android) + веб-приложение для генерации персонализированных иллюстрированных детских сказок с помощью ИИ.

**Пользователь:**
1. Регистрируется / входит
2. Создаёт персонажей (имя, тип, пол, возраст, фото до 3 шт.)
3. Проходит 3-шаговый визард: выбирает персонажей → жанр, мир, стиль, возраст, уровень образовательности → формат (страниц, минут)
4. Запускает генерацию
5. Читает готовую сказку в иммерсивном ридере (веб — fullscreen, мобайл — листание)

**Целевая аудитория:** Родители с детьми 3–12 лет, русскоязычный рынок.

---

## 2. Архитектура системы

```
┌──────────────────────────────────────────────────────────────────────┐
│                         Клиент                                       │
│   Flutter Web (https://talekid.ai)  │  Flutter Android (.apk)       │
└────────────────────┬─────────────────────────────────┬───────────────┘
                     │ HTTPS REST/JSON                  │ HTTPS REST/JSON
                     ▼                                  ▼
           ┌─────────────────────────────────────────────────┐
           │         FastAPI (TaleKid API)                    │
           │  https://talekid-production.up.railway.app       │
           │  Railway Service · Dockerfile.backend            │
           └──────────┬──────────────┬──────────────┬────────┘
                      │ asyncpg      │ boto3         │ Redis LPUSH
                      ▼              ▼               ▼
              ┌─────────────┐ ┌──────────────┐ ┌──────────────┐
              │ PostgreSQL  │ │ TimeWeb S3   │ │    Redis     │
              │ (TimeWeb)   │ │  (хранилище) │ │  (Railway)   │
              └─────────────┘ └──────────────┘ └──────┬───────┘
                                                       │ BRPOP
                                                       ▼
                                           ┌───────────────────────┐
                                           │   Python Worker        │
                                           │  (TaleKid Worker)      │
                                           │  Railway Service        │
                                           │  Dockerfile.worker      │
                                           └────────┬──────────────┘
                                                    │
                                   ┌────────────────┼──────────────┐
                                   ▼                ▼              ▼
                             ┌──────────┐   ┌─────────────┐ ┌──────────┐
                             │  OpenAI  │   │ Leonardo.ai │ │TimeWeb S3│
                             │ GPT-4o   │   │  (images)   │ │ (upload) │
                             └──────────┘   └──────┬──────┘ └──────────┘
                                                   │ fallback
                                            ┌──────▼──────┐
                                            │   DALL-E 3  │
                                            └─────────────┘
```

### Monorepo структура

```
NewProject/
├── backend/              # FastAPI API-сервер
│   ├── app/
│   │   ├── main.py       # Приложение, CORS, lifespan, auto-seed
│   │   ├── config.py     # Pydantic BaseSettings, все env vars
│   │   ├── database.py   # Async SQLAlchemy engine, SSL fallback
│   │   ├── routers/      # auth, characters, catalog, generation, stories, health
│   │   ├── schemas/      # Pydantic request/response модели
│   │   ├── services/     # generation_service (enqueue), etc.
│   │   └── seed/         # seed_db.py (31 жанров, 30 миров, 50 сказок)
├── worker/               # Background generation worker
│   └── app/
│       ├── main.py       # Redis BRPOP loop, orchestrator
│       └── pipeline/     # 9 stages (base, photo_analysis, story_bible,
│                         #   text_generation, scene_decomposition,
│                         #   character_references, illustration,
│                         #   education, title_generation, finalization)
├── shared/               # Shared SQLAlchemy models + constants
│   ├── models/           # user, character, story, generation_job, etc.
│   └── constants.py      # Enums + STYLE_PROMPTS + VALID_ILLUSTRATION_STYLES
├── flutter_app/          # Flutter (Android + Web)
├── Dockerfile.backend
├── Dockerfile.worker
├── Dockerfile.web
└── .github/workflows/    # CI/CD: auto-deploy API + Worker on master push
```

---

## 3. Технологический стек

| Слой | Технология | Версия | Назначение |
|------|-----------|--------|------------|
| **Frontend** | Flutter | SDK ^3.11.0 | Android + Web клиент |
| **State Mgmt** | Riverpod | ^2.6.1 | Reactive state, AsyncNotifier |
| **Navigation** | go_router | ^14.8.1 | Декларативная маршрутизация, auth guard |
| **HTTP Client** | Dio | ^5.7.0 | HTTP с interceptors, JWT auto-refresh |
| **Backend API** | FastAPI | 0.115.0 | REST API, async, OpenAPI docs |
| **ORM** | SQLAlchemy 2.0 | 2.0.35 (async) | Shared models backend + worker |
| **DB Driver** | asyncpg | 0.30.0 | Async PostgreSQL |
| **Database** | PostgreSQL | 15+ | TimeWeb хостинг, SSL |
| **Migrations** | Alembic | 1.13.0 | Версионирование схемы (ручное) |
| **Queue** | Redis | 5.1.0 | BRPOP job queue + progress |
| **Auth** | JWT HS256 | python-jose 3.3.0 | Access (30 мин) + Refresh (30 дней) |
| **Password** | bcrypt | 4.1.3 | via passlib 1.7.4 |
| **Storage** | S3 (TimeWeb) | boto3 1.35.0 | Фото, иллюстрации, UI ассеты |
| **Text AI** | OpenAI GPT-4o | openai 1.50.0 | Текст + Vision |
| **Image AI** | Leonardo.ai | HTTP API | Основная генерация изображений |
| **Image Fallback** | DALL-E 3 | openai 1.50.0 | Фоллбэк при ошибке Leonardo |
| **Push** | Firebase FCM | firebase-admin 6.5.0 | Android + Web push (graceful degrade) |
| **PDF** | Flutter pdf | ^3.11.2 | Клиентский PDF экспорт |
| **Deploy** | Railway | Docker-based | 3 сервиса: API, Worker, Web |
| **CI/CD** | GitHub Actions | — | Auto-deploy на push в master |

---

## 4. Продуктовый процесс (полный flow)

### 4.1 Онбординг и создание персонажа

```
Пользователь → /  (лендинг)
  → Нажимает «Создать сказку» → /auth/register или /auth/login
  → JWT сохраняется в flutter_secure_storage
  → Редирект → /home

/home → Нажимает «Создать новую сказку» → /wizard

Wizard Step 1 (Characters):
  - Список персонажей из GET /characters
  - Создать нового: bottom-sheet диалог (character_create_dialog.dart)
      → POST /characters → POST /characters/{id}/photos (до 3 фото)
      → Фото сразу загружаются на S3 через API
  - Выбрать >= 1 персонажа → перейти к Step 2
```

### 4.2 Настройка сказки (Wizard Steps 2–3)

```
Step 2 (Settings):
  - Возраст: 3-5 / 6-8 / 9-12
  - Уровень образования: 0.0–1.0 (развлечение ↔ обучение)
  - Жанр (обязательно): GET /catalog/genres → 31 жанр с обложками S3
  - Мир (обязательно): GET /catalog/worlds → 30 миров с обложками S3
  - Базовая сказка (опционально): GET /catalog/base-tales → 50 шаблонов
  - Стиль иллюстраций: 8 вариантов с обложками S3
    (watercolor · 3d-pixar · disney · comic · anime · pastel · classic-book · pop-art)

Step 3 (Format):
  - Количество страниц: 5–30 (слайдер + пресеты)
  - Время чтения: 5–30 мин (слайдер + пресеты)
  - Личный контекст (опционально): текст до 1000 символов
    Пример: «Сегодня ходили в зоопарк, Маша была в восторге от попугаев»
    → ИИ органично вплетает это событие в сюжет сказки
```

### 4.3 Запуск генерации

```
POST /generation/create
  {character_ids, genre_id, world_id, age_range, education_level,
   page_count, reading_duration_minutes, illustration_style, user_context}

API:
  1. Создаёт Story (status: 'draft') в PostgreSQL
  2. Создаёт GenerationJob (status: 'queued')
  3. LPUSH → Redis очередь talekid:jobs
  4. Возвращает {job_id, story_id}

Flutter → /wizard/progress/{jobId}
  - Polling GET /generation/{job_id}/status каждые 3 секунды
  - Отображает прогресс-бар + статус (pipeline timeline с 9 этапами)
```

### 4.4 Worker Pipeline (9 этапов)

```
Redis BRPOP (timeout=5s) → Worker получает job_payload

┌─────┬──────────────────────────────┬─────────┬────────────────────────────────────┐
│  #  │ Этап                         │ %       │ Что делает                         │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  1  │ Photo Analysis               │  5→15%  │ GPT-4o Vision → appearance_desc    │
│     │                              │         │ для каждого персонажа              │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  2  │ Story Bible                  │ 15→30%  │ GPT-4o → story_bible JSON          │
│     │                              │         │ (сюжет, роли, темы, стиль)         │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  3  │ Text + Scene Generation      │ 30→65%  │ 2-волновая параллельная генерация  │
│     │ (merged Stage 3+4)           │         │ Wave 1: страницы 1-3 параллельно   │
│     │                              │         │ Wave 2: страницы 4-N параллельно   │
│     │                              │         │    с контекстом Wave 1             │
│     │                              │         │ Каждая страница = 1 GPT вызов:     │
│     │                              │         │   text_content + scene_description │
│     │                              │         │   + image_prompt                   │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  4  │ Scene Decomposition          │ 65%     │ NO-OP (ctx.scenes уже заполнены    │
│     │ (скип-стадия)                │         │ Stage 3). Сохранён как fallback.   │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  5  │ Character References         │ 65→70%  │ Leonardo.ai → референс-образ       │
│     │                              │         │ каждого персонажа (768×1024px)     │
│     │                              │         │ → Upload S3                        │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  6  │ Illustration Generation      │ 70→90%  │ Leonardo.ai (10 параллельных)      │
│     │                              │         │ → 1024×768px иллюстрации           │
│     │                              │         │ → Upload S3 → cover_image_url      │
│     │                              │         │ Fallback: DALL-E 3                 │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  7  │ Educational Content          │ 90→93%  │ GPT-4o → факт или вопрос           │
│     │                              │         │ для каждой страницы                │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  8  │ Title Generation             │ 93→96%  │ GPT-4o → заголовок сказки (рус)    │
├─────┼──────────────────────────────┼─────────┼────────────────────────────────────┤
│  9  │ Finalization                 │ 96→100% │ stories.status = 'completed'       │
│     │                              │         │ FCM push уведомление               │
└─────┴──────────────────────────────┴─────────┴────────────────────────────────────┘
```

**Прогресс:** Worker пишет `SET talekid:progress:{job_id}` (JSON, TTL 3600s) → API читает при polling.

**Стиль иллюстраций через pipeline:**
- Stage 2: `illustration_style` → инжектируется в OpenAI prompt → AI генерирует matching `visual_style` в story_bible
- Stage 3: `STYLE_PROMPTS[slug]` используется как primary override для `image_prompt`
- Stage 5: `style_hint` из story_bible → Leonardo.ai промпт для референсов

**Параллелизм:** `asyncio.Semaphore(IMAGE_MAX_CONCURRENT=10)` для иллюстраций; `asyncio.gather()` для 2-волновой генерации текста.

**Fallback:** Leonardo.ai → (2 ошибки) → DALL-E 3

### 4.5 Чтение сказки

```
Генерация завершена → FCM push → Flutter показывает уведомление
  → Пользователь нажимает → /stories/{story_id}

GET /stories/{id} → StoryDetailResponse
  {story, pages: [{page_number, text_content, image_url,
                   educational_content: {type, text_ru, answer_ru}}]}

ReaderScreen:
  - Web:    fullscreen Stack, BackdropFilter blur, keyboard ←/→,
            floating navigation arrows, заголовок в топ-баре
  - Mobile: горизонтальный PageView (свайп), frosted glass текст снизу,
            топ-бар без заголовка и без blur, page dots снизу
  - Оба:   lightbulb → educational popup, PDF export, Share
```

---

## 5. База данных

### 5.1 ER-диаграмма

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

### 5.2 Таблицы

#### `users`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK, gen_random_uuid() |
| email | VARCHAR(255) | UNIQUE, NOT NULL, INDEX |
| password_hash | VARCHAR(255) | NOT NULL |
| display_name | VARCHAR(100) | NULLABLE |
| created_at | TIMESTAMPTZ | NOT NULL, NOW |
| updated_at | TIMESTAMPTZ | NOT NULL, auto-update |

#### `characters`
| Column | Type | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | FK→users(CASCADE), INDEX |
| name | VARCHAR(100) | NOT NULL |
| character_type | VARCHAR(20) | CHECK IN ('child','adult','pet') |
| gender | VARCHAR(10) | CHECK IN ('male','female') |
| age | INTEGER | NULLABLE |
| appearance_description | TEXT | NULLABLE — заполняется GPT-4o Vision |
| created_at / updated_at | TIMESTAMPTZ | — |

**Ограничение:** до 3 фото на персонажа.

#### `character_photos`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| character_id | UUID | FK→characters(CASCADE) |
| s3_key | VARCHAR(500) | Ключ в S3 |
| s3_url | VARCHAR(1000) | Публичный URL |
| sort_order | INTEGER | default 0 |

#### `genres`
| Column | Type |
|--------|------|
| id | SERIAL PK |
| slug | VARCHAR(50) UNIQUE |
| name_ru | VARCHAR(100) |
| description_ru | TEXT |
| prompt_hint | TEXT |
| icon_url | VARCHAR(500) |
| sort_order | INTEGER |

#### `worlds`
Аналогично genres + `visual_style_hint TEXT NOT NULL`.

#### `base_tales`
| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL PK | — |
| slug | VARCHAR(100) UNIQUE | — |
| name_ru | VARCHAR(200) | — |
| summary_ru | TEXT | — |
| plot_structure | JSONB | `{setup, encounters[], climax, resolution, moral}` |
| moral_ru | TEXT | NULLABLE |
| icon_url | VARCHAR(500) | NULLABLE |

#### `stories`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | — |
| user_id | UUID | FK→users |
| title / title_suggested | VARCHAR(300) | — |
| base_tale_id | INTEGER | FK→base_tales, NULLABLE |
| genre_id / world_id | INTEGER | FK→genres/worlds |
| age_range | VARCHAR(10) | '3-5' / '6-8' / '9-12' |
| education_level | FLOAT | 0.0–1.0 |
| page_count | INTEGER | — |
| reading_duration_minutes | INTEGER | — |
| cover_image_url | VARCHAR(1000) | NULLABLE |
| **illustration_style** | **VARCHAR(50)** | watercolor / 3d-pixar / disney / comic / anime / pastel / classic-book / pop-art |
| **user_context** | **TEXT** | Личный контекст от пользователя (до 1000 симв.) |
| status | VARCHAR(20) | draft / generating / completed / failed |
| story_bible | JSONB | `{title_working, tone, setting_description, character_roles[], plot_outline[], themes[], moral, vocabulary_level, visual_style}` |
| created_at / updated_at | TIMESTAMPTZ | — |

#### `pages`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | — |
| story_id | UUID | FK→stories |
| page_number | INTEGER | UNIQUE с story_id |
| text_content | TEXT | Текст страницы (рус) |
| image_url | VARCHAR(1000) | URL иллюстрации из S3 |
| image_s3_key | VARCHAR(500) | S3 ключ |
| image_prompt | TEXT | Английский промпт для ИИ |
| scene_description | JSONB | `{setting, characters_present[], character_actions, mood, lighting, key_objects[], color_palette}` |

#### `educational_content`
| Column | Type |
|--------|------|
| id | UUID PK |
| page_id | UUID UNIQUE FK→pages |
| content_type | VARCHAR(20) CHECK IN ('fact','question') |
| text_ru | TEXT |
| answer_ru | TEXT NULLABLE |
| topic | VARCHAR(100) |

#### `generation_jobs`
| Column | Type | Description |
|--------|------|-------------|
| id | UUID PK | — |
| story_id | UUID UNIQUE FK→stories | — |
| status | VARCHAR(20) | queued / processing / photo_analysis / story_bible / text_generation / scene_decomposition / character_references / illustration / education / title_generation / saving / completed / failed |
| progress_pct | INTEGER | 0–100 |
| status_message | VARCHAR(500) | Текст для UI (рус) |
| error_message | TEXT | — |
| started_at / completed_at / created_at | TIMESTAMPTZ | — |
| retry_count | INTEGER | — |

#### `device_tokens`
| Column | Type |
|--------|------|
| id | UUID PK |
| user_id | UUID FK→users |
| token | VARCHAR(500) |
| platform | VARCHAR(10) CHECK IN ('android','web') |
| UNIQUE(user_id, token) | — |

---

## 6. API

**Base URL:** `https://talekid-production.up.railway.app/api/v1`
**Docs:** `https://talekid-production.up.railway.app/docs`
**Auth:** `Authorization: Bearer {access_token}`

### 6.1 Auth

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| POST | `/auth/register` | `{email, password, display_name?}` | `{access_token, refresh_token, token_type}` |
| POST | `/auth/login` | `{email, password}` | `{access_token, refresh_token, token_type}` |
| POST | `/auth/refresh` | `{refresh_token}` | `{access_token, refresh_token, token_type}` |
| GET | `/auth/me` | — | `{id, email, display_name, created_at}` |

- Access token: 30 мин, HS256
- Refresh token: 30 дней
- Хранятся в `flutter_secure_storage`

**JWT interceptor (Dio):** При 401/403 → POST /auth/refresh → retry; при ошибке refresh → logout → redirect /auth/login.

### 6.2 Characters

| Method | Endpoint | Описание |
|--------|----------|----------|
| GET | `/characters` | Список персонажей текущего пользователя |
| POST | `/characters` | Создать персонажа |
| GET/PUT/DELETE | `/characters/{id}` | CRUD |
| POST | `/characters/{id}/photos` | Загрузить фото (multipart, max 3) |
| DELETE | `/characters/{id}/photos/{photo_id}` | Удалить фото |

### 6.3 Catalog (без авторизации)

| Endpoint | Описание |
|----------|----------|
| GET `/catalog/genres` | 31 жанр |
| GET `/catalog/worlds` | 30 миров |
| GET `/catalog/base-tales` | 50 базовых сказок (список) |
| GET `/catalog/base-tales/{id}` | Детали сказки + персонажи |

### 6.4 Generation

| Method | Endpoint | Описание |
|--------|----------|----------|
| POST | `/generation/create` | Создать job, поставить в очередь |
| GET | `/generation/{job_id}/status` | Прогресс (polling каждые 3с) |
| POST | `/generation/{job_id}/cancel` | Отменить |

**GenerationCreateRequest:**
```json
{
  "character_ids": ["uuid1"],
  "genre_id": 1,
  "world_id": 1,
  "base_tale_id": null,
  "age_range": "6-8",
  "education_level": 0.5,
  "page_count": 10,
  "reading_duration_minutes": 10,
  "illustration_style": "watercolor",
  "user_context": "Сегодня ходили в зоопарк, Маша была в восторге от попугаев"
}
```

### 6.5 Stories

| Method | Endpoint | Описание |
|--------|----------|----------|
| GET | `/stories?skip=0&limit=20` | Библиотека сказок пользователя |
| GET | `/stories/{id}` | Сказка со всеми страницами и educational_content |
| PUT | `/stories/{id}/title` | Переименовать |
| DELETE | `/stories/{id}` | Удалить |

### 6.6 Коды ошибок

| Код | Причина |
|-----|---------|
| 400 | Неверный запрос |
| 401 | Нет/истёк JWT |
| 403 | Нет доступа к ресурсу |
| 404 | Ресурс не найден |
| 409 | Дублирование (email) |

---

## 7. S3 Хранилище

**Провайдер:** TimeWeb S3 (S3-compatible, endpoint: `https://s3.timeweb.cloud`)
**Доступ:** Все объекты загружаются с `ACL: public-read`

```
{S3_BUCKET}/
├── character-photos/{user_id}/{character_id}/
│   └── photo_N.jpg
├── stories/{story_id}/
│   ├── characters/{character_id}/reference.png   ← Leonardo character ref
│   ├── pages/1.png … N.png                        ← иллюстрации
│   └── cover.png                                   ← обложка
├── ui-assets/
│   ├── genres/{slug}.png          # 31 обложка жанра (512×384)
│   ├── worlds/{slug}.png          # 30 обложка мира  (512×384)
│   ├── ages/age-{range}.png       # 3 картинки возраста
│   └── ui/*.png                   # UI иллюстрации
└── landing-assets/
    ├── ui/hero-bg.png, cta-bg.png, how-step1-3.png
    ├── styles/{slug}.png          # 8 превью стилей иллюстраций
    └── showcase/                  # 4 демо-сказки лендинга (10 стр. с текстом)
```

> ⚠️ `STORAGE_PUBLIC_URL` уже содержит имя бакета. **Никогда не добавляй имя бакета повторно.**

**CORS S3:** Разрешены GET/HEAD из:
- `https://talekid2-production.up.railway.app`
- `https://talekid.ai`
- `https://www.talekid.ai`
- `http://localhost:*`

---

## 8. Flutter App

### 8.1 Структура

```
flutter_app/lib/
├── config/
│   ├── theme.dart          # «Зачарованная ночь» dark theme
│   ├── router.dart         # go_router, auth guard, маршруты
│   ├── app_config.dart     # API_BASE_URL, таймауты, лимиты
│   ├── ui_assets.dart      # S3 URL константы (жанры×31, миры×30, etc.)
│   └── landing_assets.dart # Ассеты лендинга + данные showcase сказок
├── models/                 # character.dart, story.dart, catalog.dart
├── providers/              # auth, character, catalog, generation, story
├── services/               # api_client, auth, catalog, character,
│                           #   generation, story, pdf, share
├── screens/
│   ├── landing/            # Публичный лендинг
│   ├── auth/               # Login + Register
│   ├── home/               # Дашборд
│   ├── wizard/             # 3-шаговый визард + character_create_dialog
│   ├── generation/         # Прогресс генерации (timeline 9 этапов)
│   ├── reader/             # Иммерсивный ридер (mobile + web)
│   ├── library/            # Библиотека сказок
│   └── legal/              # Terms, Privacy, Consent
└── widgets/
    ├── app_card.dart, glass_card.dart, gradient_button.dart
    ├── shimmer_loading.dart, character_card.dart
    ├── educational_popup.dart, title_dialog.dart
    └── photo_picker.dart   # Загрузка фото с pendingCount лимитом
```

### 8.2 Маршруты

| Path | Screen | Auth |
|------|--------|------|
| `/` | LandingScreen | Нет |
| `/auth/login` | LoginScreen | Нет |
| `/auth/register` | RegisterScreen | Нет |
| `/terms`, `/privacy`, `/consent` | LegalScreen | Нет |
| `/home` | HomeScreen | JWT |
| `/wizard` | WizardScreen | JWT |
| `/wizard/progress/:jobId` | GenerationProgressScreen | JWT |
| `/stories/:id` | ReaderScreen | JWT |
| `/library` | LibraryScreen | JWT |

### 8.3 API Client (Dio)

```
Запрос:
  Interceptor → добавляет Authorization: Bearer {accessToken}

Ответ 401 или 403:
  → POST /auth/refresh (один раз)
  → Успех: сохранить новые токены → retry исходного запроса
  → Неудача: clear tokens → navigator → /auth/login
```

**app_config.dart:**
- `API_BASE_URL` — `--dart-define` при сборке (web: auto в Dockerfile.web; APK: передать вручную)
- Default: `http://localhost:8000/api/v1` — только для локальной разработки
- Connection timeout: 30с, receive timeout: 60с
- Polling interval: 3с
- Max photos per character: 3

### 8.4 Тема — «Зачарованная ночь»

| Токен | Значение | Применение |
|-------|----------|------------|
| Background | `#0C0A1D` (глубокий midnight) | Фон приложения |
| Surface | `rgba(255,255,255,0.06)` | Стеклянные поверхности |
| Card | glass-morphism (blur 20px) | Карточки и панели |
| Text Primary | `#E8E5F0` (мягкая лаванда) | Основной текст |
| Text Secondary | `#9B95B0` (приглушённая лаванда) | Второстепенный текст |
| Primary | `#6366F1` (индиго) + glow | Кнопки, акценты |
| Accent Gold | `#FFD700` | Выделения, заголовки разделов |
| Accent Purple | `#A78BFA` | Второстепенные акценты |
| Border | `rgba(255,255,255,0.08)` | Границы карточек |
| Font (заголовки) | Google Fonts Comfortaa | Все заголовки |
| Font (текст) | Google Fonts Nunito Sans | Тело текста |

### 8.5 Platform-specific UI (`kIsWeb` guards)

Все изменения под `kIsWeb` сделаны с мобильным приоритетом (APK как основная платформа):

| Экран | Web | Mobile (APK) |
|-------|-----|--------------|
| Home — badge | «✨ Магия искусственного интеллекта» | Скрыт |
| Home — subtitle | fontSize: 51 | fontSize: 15 |
| Home — CTA кнопка | Статичный текст | AnimatedBuilder: shine sweep + breathing opacity |
| Wizard Characters — подзаголовок | Показан | Скрыт |
| Wizard Characters — аватар | 156×156px, emoji 60px | 58×58px, emoji 22px |
| Wizard Characters — имя/возраст | 30px / 24px | 16px / 13px |
| Wizard Settings — жёлтые заголовки | 26px | 15px |
| Character dialog — высота | Без ограничений | `maxHeight: 88%` + scroll |
| Reader — топ-бар | Frosted glass blur + заголовок сказки | Прозрачный градиент, без заголовка |

**Shine анимация CTA (mobile):**
```dart
AnimationController(vsync: this, duration: Duration(milliseconds: 2800))..repeat()
// breathing:  0.7 + 0.3 * sin(t * π)
// sweep:      LinearGradient с 5 stops, pos = t (0→1)
// ShaderMask + BlendMode.srcIn поверх текста
```

### 8.6 Wizard — Шаги

**Step 1 — Characters:**
- Мультиселект из существующих персонажей
- Inline создание (bottom-sheet `CharacterCreateDialog`)
  - Тип/пол: compact карточки (emoji 22px, padding 8), светлокожие эмодзи: 👶🏼 🧑🏼 👦🏼 👧🏼 👨🏼 👩🏼
  - Фото до 3 шт.; pending фото отображаются как `Image.memory()` thumbnails 80×80 с кнопкой удаления
  - `PhotoPicker` принимает `pendingCount` → корректно считает existing + pending при отображении лимита
- Минимум 1 персонаж для перехода

**Step 2 — Settings:**
- Жанр и мир: адаптивная сетка (70% ширины, `(width/160).clamp(3,8)` колонок)
- Стиль иллюстраций: 8 карточек с обложками из S3, checkmark на выбранном

**Step 3 — Format:**
- Страницы + минуты: слайдеры + пресеты
- Личный контекст: текстовое поле (опционально, до 1000 симв.)

### 8.7 Reader UX

**Web (иммерсивный):**
- `Stack(fit: StackFit.expand)` — fullscreen `CachedNetworkImage`
- Топ-оверлей: `BackdropFilter(blur: 10)` + чёрный 54% gradient + заголовок сказки
- Текстовая карточка: `Positioned(bottom: 80)`, `BackdropFilter(blur: 16)`, max 700px
- Плавающие стрелки навигации (вертикально по центру)
- Клавиатурная навигация: ←/→
- Внизу: page dots

**Mobile (Android):**
- Горизонтальный `PageView` (свайп)
- Топ-оверлей: тонкий прозрачный gradient, **без blur, без заголовка**
- Full-bleed иллюстрация + frosted glass текстовый оверлей снизу
- Page dots снизу + lightbulb (образовательный контент)

---

## 9. Конфигурация окружения

### 9.1 Backend API (`backend/`)

| Переменная | Обязательно | Описание |
|-----------|-------------|----------|
| `POSTGRESQL_HOST/PORT/USER/PASSWORD/DBNAME` | Да | TimeWeb PostgreSQL |
| `POSTGRESQL_SSLMODE` | Нет (verify-full) | SSL режим |
| `S3_ENDPOINT_URL`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `S3_BUCKET`, `STORAGE_PUBLIC_URL` | Да | TimeWeb S3 |
| `JWT_SECRET` | Да | Base64 секрет |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | Нет (30) | TTL access token |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | Нет (30) | TTL refresh token |
| `OPENAI_API_KEY` | Да | — |
| `LEONARDO_API_KEY` | Да | — |
| `REDIS_URL` | Нет (redis://localhost:6379) | — |
| `IMAGE_ENGINE` | Нет (leonardo) | `leonardo` или `dalle` |
| `IMAGE_MAX_CONCURRENT` | Нет (10) | — |

### 9.2 Worker (`worker/`)

Все переменные из 9.1 плюс:

| Переменная | Default | Описание |
|-----------|---------|----------|
| `OPENAI_MODEL` | gpt-4o | Модель текста |
| `OPENAI_VISION_MODEL` | gpt-4o | Модель Vision |
| `REDIS_QUEUE` | talekid:jobs | Очередь |
| `REDIS_PROGRESS_PREFIX` | talekid:progress | Префикс ключей прогресса |
| `REDIS_PROGRESS_TTL` | 3600 | TTL прогресса (сек) |
| `GOOGLE_APPLICATION_CREDENTIALS` | — | Firebase service account |

### 9.3 Web / APK (Flutter)

**Сборка Web** (`Dockerfile.web`): `API_BASE_URL` задаётся автоматически как Railway URL.

**Сборка APK** (ручная): обязательно передавать:
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://talekid-production.up.railway.app/api/v1
```
> ⚠️ Без этого `API_BASE_URL` дефолтится в `http://localhost:8000/api/v1` и APK не работает в продакшне.

---

## 10. Деплой

### 10.1 Railway Services

| Сервис | Имя в Railway | Dockerfile | URL |
|--------|---------------|-----------|-----|
| API | TaleKid API | `Dockerfile.backend` | https://talekid-production.up.railway.app |
| Worker | TaleKid Worker | `Dockerfile.worker` | https://talekid-worker-production.up.railway.app |
| Web | TaleKid2 WEB | `Dockerfile.web` | https://talekid2-production.up.railway.app |
| Redis | Railway managed | — | внутри Railway network |

**Кастомный домен:** `talekid.ai` → `talekid2-production.up.railway.app` (TaleKid2 WEB)

### 10.2 CI/CD (GitHub Actions)

**Trigger:** Push в `master`
- Изменения в `backend/` → деплой API
- Изменения в `worker/` → деплой Worker
- Изменения в `flutter_app/` → деплой Web

### 10.3 CORS

**API CORS origins:**
```python
allow_origins = [
    "https://talekid2-production.up.railway.app",
    "https://talekid.ai",
    "https://www.talekid.ai",
    # localhost:* — через regex
]
```
> При добавлении нового домена — обновить `backend/app/main.py` + CORS правила S3.

### 10.4 Инициализация базы данных

При первом запуске API:
1. `Base.metadata.create_all` — создаёт все таблицы
2. `_seed_catalog_if_empty()` — 6 жанров + 6 миров + 6 базовых сказок (минимальный набор)

Полный каталог (31 жанр, 30 миров, 50 сказок):
```bash
python3 -m app.seed.seed_db
```

**Новые колонки добавлялись через прямой ALTER TABLE** (Alembic не использовался):
- `stories.illustration_style VARCHAR(50)` — добавлено 2026-03-16
- `stories.user_context TEXT` — добавлено 2026-03-16

---

## 11. Каталог контента

### 11.1 Жанры (31 шт.)

**Оригинальные 6:** adventure · fairy-tale · educational · friendship · funny · bedtime

**Новые 25:** detective · rescue · riddles · journey · fantasy · space-sci-fi · animal-stories · superheroes · light-mystery · everyday-stories · school-stories · moral-stories · survival-nature · historical-adventure · creativity-imagination · holiday-stories · science-adventure · quest-treasure-hunt · sea-adventure · prehistoric-world · robots-technology · profession-stories · magical-worlds · secrets-mysteries · self-discovery-growing-up

Обложки: `ui-assets/genres/{slug}.png` (512×384, Leonardo AI Phoenix)

### 11.2 Миры (30 шт.)

**Оригинальные 6:** enchanted-forest · space · underwater · medieval-kingdom · modern-city · dinosaur-world

**Новые 24:** ancient-legends · underground-world · sky-kingdom · dragon-world · robot-world · enchanted-castle · mysterious-island · wonder-desert · north-pole · jungle · candy-land · dream-world · lost-city · pirate-islands · magic-school · deep-ocean · moon-base · monster-planet · giant-world · miniature-world · cloud-country · shadow-labyrinth · time-kingdom · elemental-world

Обложки: `ui-assets/worlds/{slug}.png`

### 11.3 Базовые сказки (50 шт.)

50 шаблонов русских сказок с `plot_structure` (JSONB) и персонажами. Загружены через `seed_db.py`.

### 11.4 Стили иллюстраций (8 шт.)

| Slug | Название | Превью |
|------|----------|--------|
| watercolor | Акварель | `landing-assets/styles/watercolor.png` |
| 3d-pixar | 3D Анимация (Pixar) | `landing-assets/styles/3d-pixar.png` |
| disney | Disney | `landing-assets/styles/disney.png` |
| comic | Комикс | `landing-assets/styles/comic.png` |
| anime | Аниме | `landing-assets/styles/anime.png` |
| pastel | Пастель | `landing-assets/styles/pastel.png` |
| classic-book | Книжная классика | `landing-assets/styles/classic-book.png` |
| pop-art | Поп-арт | `landing-assets/styles/pop-art.png` |

---

## 12. Ключевые файлы

### Backend
| Файл | Назначение |
|------|-----------|
| `backend/app/main.py` | FastAPI app, CORS (с talekid.ai), lifespan, auto-seed |
| `backend/app/config.py` | Pydantic BaseSettings |
| `backend/app/database.py` | Async SQLAlchemy engine, SSL fallback |
| `backend/app/routers/*.py` | API endpoints |
| `backend/app/schemas/generation.py` | GenerationCreateRequest (illustration_style, user_context) |
| `backend/app/services/generation_service.py` | Job creation, Redis enqueue |
| `backend/app/seed/seed_db.py` | Full catalog seed |

### Worker
| Файл | Назначение |
|------|-----------|
| `worker/app/main.py` | Redis BRPOP loop, pipeline orchestrator |
| `worker/app/pipeline/base.py` | PipelineContext (illustration_style, user_context, scenes) |
| `worker/app/pipeline/text_generation.py` | **Stage 3+4 merged** — 2-wave parallel text + scene |
| `worker/app/pipeline/scene_decomposition.py` | Stage 4 — no-op guard (ctx.scenes check) |
| `worker/app/pipeline/story_bible.py` | Stage 2 — style + user_context injection |
| `worker/app/pipeline/illustration.py` | Stage 6 — 10 parallel Leonardo/DALL-E |
| `worker/app/services/image_service.py` | Image router с fallback chain |

### Shared
| Файл | Назначение |
|------|-----------|
| `shared/models/story.py` | Story model (illustration_style, user_context) |
| `shared/constants.py` | Enums + STYLE_PROMPTS + VALID_ILLUSTRATION_STYLES |

### Flutter
| Файл | Назначение |
|------|-----------|
| `flutter_app/lib/config/theme.dart` | «Зачарованная ночь» dark theme |
| `flutter_app/lib/config/app_config.dart` | API_BASE_URL, timeouts, max photos |
| `flutter_app/lib/config/ui_assets.dart` | S3 URL константы (86+ ассетов) |
| `flutter_app/lib/config/landing_assets.dart` | Лендинг ассеты + showcase stories |
| `flutter_app/lib/screens/home/home_screen.dart` | kIsWeb guards, shine animation |
| `flutter_app/lib/screens/wizard/wizard_screen.dart` | 3-step wizard, kIsWeb responsive sizes |
| `flutter_app/lib/screens/wizard/character_create_dialog.dart` | Photo thumbnails, compact cards, 88% height |
| `flutter_app/lib/screens/reader/reader_screen.dart` | _TopOverlay: web blur+title / mobile clean |
| `flutter_app/lib/widgets/photo_picker.dart` | pendingCount param, combined limit |
| `flutter_app/lib/services/generation_service.dart` | createGeneration(illustrationStyle, userContext) |

### Infrastructure
| Файл | Назначение |
|------|-----------|
| `Dockerfile.backend/worker/web` | Docker builds |
| `.github/workflows/` | CI/CD auto-deploy |
| `generate_catalog_assets.py` | Leonardo AI → S3 генерация ассетов |
| `DNS_MIGRATION.md` | Инструкция по миграции домена с Vercel на Railway |

---

## 13. Продакшн URLs

| Сервис | URL |
|--------|-----|
| **Web App** | https://talekid.ai |
| Web App (прямой Railway) | https://talekid2-production.up.railway.app |
| **API** | https://talekid-production.up.railway.app |
| API Docs (Swagger) | https://talekid-production.up.railway.app/docs |
| Worker | https://talekid-worker-production.up.railway.app |

---

## 14. Ограничения и важные заметки

1. **APK сборка:** Всегда использовать `--dart-define=API_BASE_URL=https://talekid-production.up.railway.app/api/v1`. Без этого дефолт — localhost.
2. **CORS:** `allow_origins` — явный список. При добавлении домена обновить API + S3 CORS.
3. **Пароли:** `bcrypt==4.1.3` — passlib 1.7.4 несовместим с bcrypt ≥5.0.
4. **SSL:** Без `root.crt` используется зашифрованное соединение без верификации сертификата.
5. **Consistency изображений:** Leonardo Character Reference с `initImageId/initImageType: "GENERATED"` — DALL-E fallback теряет consistency.
6. **Migrations:** Alembic не используется. Новые колонки — прямой `ALTER TABLE IF NOT EXISTS`.
7. **Каталог auto-seed:** При первом запуске только 6+6+6. Полный каталог — `python3 -m app.seed.seed_db` вручную.
8. **Firebase FCM:** Graceful degrade — push не является критичным.
9. **PDF:** Клиентская генерация (Flutter `pdf` package) — без сервера.
10. **Язык:** UI на русском, AI-промпты на английском.
11. **Wave-1/2 генерация:** Wave 1 (стр. 1-3) всегда без prior context; Wave 2 (стр. 4-N) получает краткие summary Wave 1 (первые 300 симв. каждой страницы).
12. **S3 URL:** `STORAGE_PUBLIC_URL` уже содержит бакет — никогда не добавлять имя бакета повторно.

---

## 15. Changelog

### v1.5.0 — 2026-03-17

**Worker — 2-волновая параллельная генерация:**
- Stage 3 (TextGeneration) + Stage 4 (SceneDecomposition) объединены в один GPT вызов на страницу
- Wave 1: страницы 1-3 параллельно (`asyncio.gather`)
- Wave 2: страницы 4-N параллельно с summary Wave 1 как контекст
- Stage 4 (SceneDecomposition) — no-op guard: `if ctx.scenes: skip`
- Ускорение: ~120с последовательных вызовов → ~8-12с с двумя `asyncio.gather()`

**Домен и CORS:**
- `talekid.ai` подключён к Railway (TaleKid2 WEB)
- API CORS: добавлены `https://talekid.ai` и `https://www.talekid.ai`
- S3 CORS: добавлен `https://www.talekid.ai`
- Создан `DNS_MIGRATION.md` со спекой миграции домена с Vercel на Railway

**Mobile APK — 7 layout изменений (`kIsWeb` guards):**
1. Home: subtitle 51px → 15px на мобайл
2. Home: скрыт badge «Магия искусственного интеллекта»
3. Home: CTA кнопка — shine sweep + breathing glow анимация (только mobile)
4. Wizard Characters: скрыт subtitle на мобайл
5. Wizard Characters: аватар 156→58px, имя 30→16px, возраст 24→13px
6. Character Dialog: `ConstrainedBox(maxHeight: 88%)` + scroll — кнопка ДАЛЬШЕ видна
7. Wizard Settings: 6 жёлтых заголовков 26→15px

**Character Dialog — 3 доработки:**
- Карточки тип/пол: emoji 28→22px, padding 14→8; светлокожие эмодзи 👶🏼 🧑🏼 👦🏼 👧🏼 👨🏼 👩🏼
- Pending фото: `Image.memory(bytes)` thumbnails 80×80 вместо filename chips
- Лимит фото: `PhotoPicker.pendingCount` — корректный подсчёт existing + pending

**Reader — mobile clean-up:**
- `_TopOverlay`: web сохраняет blur + заголовок; mobile — прозрачный gradient без blur и заголовка

---

### v1.4.0 — 2026-03-16

**Личный контекст пользователя:**
- Поле `user_context` в Step 3 визарда (до 1000 симв.)
- DB: `stories.user_context TEXT NULLABLE`
- Worker Stage 2 + Stage 3: контекст инжектируется в промпты как 🌟 priority
- Пример: «Сегодня ходили в зоопарк» → ИИ строит сюжет вокруг этого события

---

### v1.3.0 — 2026-03-16

**Стиль иллюстраций (full stack):**
- 8 стилей: watercolor · 3d-pixar · disney · comic · anime · pastel · classic-book · pop-art
- DB: `stories.illustration_style VARCHAR(50)`
- `_StyleSelector` в визарде; `STYLE_PROMPTS` в worker

**Расширенный каталог:** 31 жанр + 30 миров + 50 сказок + все обложки из S3

**Адаптивная сетка визарда:** 70% ширины, 3-8 колонок

**Тема «Зачарованная ночь»:** Полный dark theme редизайн

**Иммерсивный ридер (web):** Fullscreen + BackdropFilter + keyboard nav

**Лендинг:** Полный редизайн с 8 стилями и 4 интерактивными превью сказок

---

### v1.2.0 — 2026-03-15

- S3 CORS настроен для Railway web origin
- Исправлены double-bucket URL (18 страниц + 2 обложки + 2 референса)
- CORS middleware API: явный список origins вместо wildcard
- JWT interceptor: обработка 401 и 403; безопасный retry с fallback

---

### v1.1.0 — 2026-03-14

- S3 URL: убран дублирующийся бакет в URL
- Leonardo.ai 400: заменён `initImageUrl` на `initImageId + initImageType: "GENERATED"`
