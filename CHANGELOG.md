# Changelog

All notable changes to TaleKID are documented here.
Format: [Semantic Versioning](https://semver.org/)

---

## [1.4.0] — 2026-03-16

### Added
- **User Context Field** — Step 3 of the story wizard now includes a multiline text field where users can enter a personal memory or event (up to 1000 characters). The AI weaves this context organically into both the story bible and each page of the generated tale.
  - Flutter: `TextField` in `_Step3Format` with placeholder "Например: «Сегодня мы ходили в зоопарк...»"
  - Backend: `user_context: Optional[str]` (max 1000 chars) added to `GenerationCreateRequest` schema
  - DB: `stories.user_context TEXT` column (nullable, migrated in production)
  - Worker pipeline: `PipelineContext.user_context` propagated from Redis payload
  - Story Bible stage: context injected as top-priority instruction into OpenAI prompt
  - Text Generation stage: context re-injected on every page; special guidance on intro and closing pages

---

## [1.3.0] — 2026-03-16

### Added
- **Illustration Style Selector** — Users choose 1 of 8 artistic styles (Акварель, 3D Pixar, Disney, Комикс, Аниме, Пастель, Книжная классика, Поп-арт) when creating a story. Style flows from wizard → API → DB → Redis → worker → OpenAI/Leonardo prompts.
  - DB: `stories.illustration_style VARCHAR(50)` column
  - `shared/constants.py`: `STYLE_PROMPTS` + `VALID_ILLUSTRATION_STYLES`
  - Flutter: `_StyleSelector` responsive grid widget (3–8 columns, S3 cover images)

- **Extended Catalog** — 31 genres, 30 worlds, 50 base tales with AI-generated cover images (Leonardo Phoenix, uploaded to S3).

- **Responsive Wizard Grid** — Genre/world/style grids fill 70% of viewport width. Dynamic column count `(width / 160).clamp(3, 8)`.

### Technical
- Standalone `generate_catalog_assets.py` script for bulk Leonardo → S3 cover generation
- `ui_assets.dart` extended with 49 new S3 URL constants

---

## [1.2.0] — 2026-03-15

### Fixed
- **S3 CORS** — Configured GET/HEAD CORS rule on TimeWeb S3 for web origin.
- **DB: double-bucket image URLs** — Fixed 18 pages + 2 covers + 2 character refs with `/{bucket}/{bucket}/{key}` paths.
- **CORS middleware** — Replaced `allow_origins=["*"]` with explicit origin whitelist.
- **JWT interceptor: 403** — FastAPI HTTPBearer returns 403 when Authorization is absent; interceptor now handles both 401 and 403.
- **JWT interceptor: dangling handler** — Retry in `onError` wrapped in `try/catch` with `handler.next()` fallback.

---

## [1.1.0] — 2026-03-14

### Fixed
- **Leonardo API polling** — Fixed race condition where `getGenerationById` was called before job completion.
- **Page ordering** — Ensured pages are always returned in `page_number` ascending order.
- **Worker crash on empty photo** — Added guard for characters without photos in photo analysis stage.
- **Alembic bootstrap** — Documented that `alembic/versions/` is intentionally empty (schema managed via `create_all` + direct ALTER TABLE).

---

## [1.0.0] — 2026-03-13

### Initial Release
- Flutter app (Android + Web) with multi-step wizard
- 9-stage AI generation pipeline (photo analysis → story bible → text → scene decomp → character refs → illustrations → education → title → save)
- FastAPI backend with JWT auth (access + refresh tokens)
- Redis job queue with real-time progress updates
- Leonardo.ai primary image generation + DALL-E 3 fallback
- PDF export (client-side)
- Educational content (facts + questions) per page
- Landing page with story previews
- Railway deployment (3 services: API, Worker, Web)
- GitHub Actions CI/CD on push to master
