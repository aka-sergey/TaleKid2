# TaleKID — Generation Pipeline

Полная схема пайплайна генерации сказки от нажатия кнопки до читалки.

---

## Пользовательский ввод (Wizard)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         ПОЛЬЗОВАТЕЛЬ                                    │
│                                                                         │
│  Шаг 1: Персонажи    Шаг 2: Жанр/Мир/Стиль    Шаг 3: Формат           │
│  [👦 Миша] [🐶 Бим]  [Приключения][Космос]      [10 стр][10 мин]       │
│                       [Акварель ✓]              [📝 "Были в зоопарке"]  │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │  POST /generation/create
                                 │  { character_ids, genre_id, world_id,
                                 │    illustration_style, user_context,
                                 │    age_range, page_count, ... }
                                 ▼
```

---

## Backend (FastAPI)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         FASTAPI (Backend)                               │
│                                                                         │
│  1. Валидация (персонажи твои? жанр существует?)                        │
│  2. Story → INSERT в PostgreSQL                                         │
│     { genre, world, illustration_style, user_context, status=generating}│
│  3. GenerationJob → INSERT                                              │
│  4. Redis LPUSH → payload { story_id, character_ids,                   │
│                              illustration_style, user_context, ... }    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                        Redis Queue (LPUSH)
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    WORKER — PipelineContext                              │
│   story_id, character_ids, illustration_style, user_context             │
│   story_bible={}, pages_text=[], character_descriptions={}              │
└──┬──────────────────────────────────────────────────────────────────────┘
   │
```

---

## Worker — 9 стадий

```
   │ ══════════════════════ 9 СТАДИЙ ══════════════════════
   │
   ▼ 0% ──────────────────────────────────────────── Stage 1
┌─────────────────────────────────────────────────────────┐
│  📸 PHOTO ANALYSIS  (0% → 15%)                          │
│                                                         │
│  Для каждого персонажа с фото:                          │
│  GPT-4 Vision → "Мальчик ~7 лет, тёмные волосы,        │
│                  синяя футболка, весёлый взгляд"        │
│                                                         │
│  ctx.character_descriptions = { uuid: "описание" }     │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 15% ─────────────────────────────────────────── Stage 2
┌─────────────────────────────────────────────────────────┐
│  📖 STORY BIBLE  (15% → 30%)                            │
│                                                         │
│  GPT-4o получает:                                       │
│  • Возраст: 3-5 лет                                     │
│  • Жанр: Приключения                                    │
│  • Мир: Космос                                          │
│  • Стиль: "warm watercolor children's book,             │
│            soft flowing colors..."                      │
│  • 🌟 КОНТЕКСТ: "Были в зоопарке, видели слонов"        │
│    └→ "органично вплети в сюжет, это центральная тема" │
│  • Персонажи: Миша (описание), Бим (описание)          │
│                                                         │
│  Возвращает JSON:                                       │
│  { title_working, tone, setting_description,           │
│    character_roles, plot_outline[act1,act2,act3],      │
│    themes, moral, visual_style }                       │
│                                                         │
│  ctx.story_bible = { ... }                             │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 30% ─────────────────────────────────────────── Stage 3
┌─────────────────────────────────────────────────────────┐
│  ✍️  TEXT GENERATION  (30% → 55%)                       │
│                                                         │
│  Для каждой из 10 страниц:                              │
│                                                         │
│  GPT-4o получает:                                       │
│  • Story Bible (весь сюжетный план)                     │
│  • 🌟 КОНТЕКСТ (повторяется на каждой странице!)        │
│  • Страница 1/10 → "Введи главного героя и мир"        │
│    + "На первой странице введи элементы контекста"     │
│  • Страница 5/10 → Act 2: приключения                  │
│  • Страница 10/10 → "Финал, эхо личного контекста"     │
│  • Последние 3 страницы как история для связности      │
│                                                         │
│  Возвращает JSON каждый раз:                            │
│  { text_content: "...(русский текст)...",              │
│    suggested_illustration: "boy and elephant in space" }│
│                                                         │
│  → INSERT INTO pages (page_number, text_content,       │
│                        image_prompt)                    │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 55% ─────────────────────────────────────────── Stage 4
┌─────────────────────────────────────────────────────────┐
│  🎬 SCENE DECOMPOSITION  (55% → 60%)                    │
│                                                         │
│  Для каждой страницы:                                   │
│  GPT-4o анализирует text_content + suggested_illust.   │
│                                                         │
│  visual_style =                                         │
│    если illustration_style → STYLE_PROMPTS["watercolor"]│
│    иначе → bible["visual_style"]                       │
│                                                         │
│  Возвращает:                                            │
│  { scene_description, characters_present,              │
│    background, lighting, mood,                         │
│    visual_style: "warm watercolor, soft colors..." }   │
│                                                         │
│  → UPDATE pages SET scene_data = { ... }               │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 60% ─────────────────────────────────────────── Stage 5
┌─────────────────────────────────────────────────────────┐
│  🖼️  CHARACTER REFERENCES  (60% → 65%)                  │
│                                                         │
│  Для каждого персонажа с фото:                          │
│  Загружаем фото → Leonardo AI Image2Image               │
│  Получаем "reference image" в нужном стиле             │
│  → S3 upload → UPDATE story_characters                 │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 65% ─────────────────────────────────────────── Stage 6
┌─────────────────────────────────────────────────────────┐
│  🎨 ILLUSTRATION GENERATION  (65% → 90%)                │
│                                                         │
│  Для каждой из 10 страниц (параллельно):               │
│                                                         │
│  Собираем финальный промпт:                            │
│  scene_data + visual_style + character ref images      │
│  → Leonardo Phoenix API                                │
│     (polling каждые 3с пока не COMPLETE)               │
│                                                         │
│  Если Leonardo упал → DALL-E 3 fallback                │
│                                                         │
│  → S3 upload → UPDATE pages SET image_url              │
│  Первая страница → UPDATE stories SET cover_image_url  │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 90% ─────────────────────────────────────────── Stage 7
┌─────────────────────────────────────────────────────────┐
│  🎓 EDUCATION CONTENT  (90% → 95%)                      │
│                                                         │
│  GPT-4o для каждой страницы:                           │
│  → интересный факт связанный со сценой                  │
│  → вопрос для обсуждения с ребёнком                    │
│  → INSERT INTO educational_content                     │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 95% ─────────────────────────────────────────── Stage 8
┌─────────────────────────────────────────────────────────┐
│  📌 TITLE GENERATION  (95% → 98%)                       │
│                                                         │
│  GPT-4o: story_bible + первые страницы                 │
│  → "Миша и Космический Зоопарк"                        │
│  → UPDATE stories SET title_suggested                  │
└─────────────────────────────────────────────────────────┘
   │
   ▼ 98% ─────────────────────────────────────────── Stage 9
┌─────────────────────────────────────────────────────────┐
│  💾 SAVE & COMPLETE  (98% → 100%)                       │
│                                                         │
│  UPDATE stories SET status = 'completed'               │
│  UPDATE generation_jobs SET status = 'completed'       │
│  Redis → publish progress 100%                         │
└─────────────────────────────────────────────────────────┘
   │
   ▼
┌─────────────────────────────────────────────────────────┐
│  📱 FLUTTER — polling каждые 2с                         │
│  /generation/{jobId}/status → { progress_pct, message }│
│                                                         │
│  100% → context.go('/story/{storyId}/reader')          │
│                                                         │
│  Читалка: иллюстрация на весь экран +                  │
│  frosted glass текст + образовательный контент         │
└─────────────────────────────────────────────────────────┘
```

---

## Ключевые механики

### `user_context` — личный контекст пользователя
Инжектируется **дважды** чтобы ИИ не «забыл»:
1. **Stage 2 (Story Bible)** — формирует весь сюжет вокруг контекста (флаг 🌟 = приоритет)
2. **Stage 3 (Text Generation)** — повторяется в промпте каждой страницы + специальные указания для первой (введи контекст) и последней (эхо/завершение) страниц

### `illustration_style` — стиль иллюстраций
Управляет `visual_style` по всему пайплайну:
- **Stage 2**: ИИ получает описание стиля → генерирует `visual_style` в story bible в нужном ключе
- **Stage 4**: `STYLE_PROMPTS[slug]` жёстко перезаписывает `visual_style` → передаётся в Leonardo

### Fallback цепочка для иллюстраций
```
Leonardo Phoenix → (timeout/error) → DALL-E 3 → (error) → placeholder
```

### Прогресс в реальном времени
```
Worker → Redis HSET progress:{jobId} → Backend → Flutter polling /status
```

---

## Файловая карта пайплайна

| Файл | Отвечает за |
|------|-------------|
| `worker/app/pipeline/base.py` | `PipelineContext` — общий контейнер данных |
| `worker/app/pipeline/photo_analysis.py` | Stage 1 — GPT-4 Vision |
| `worker/app/pipeline/story_bible.py` | Stage 2 — сюжетный план + user_context |
| `worker/app/pipeline/text_generation.py` | Stage 3 — текст страниц + user_context |
| `worker/app/pipeline/scene_decomposition.py` | Stage 4 — сцены + illustration_style override |
| `worker/app/pipeline/character_references.py` | Stage 5 — референсы персонажей |
| `worker/app/pipeline/illustration.py` | Stage 6 — Leonardo / DALL-E |
| `worker/app/pipeline/education.py` | Stage 7 — образовательный контент |
| `worker/app/pipeline/title_generation.py` | Stage 8 — название сказки |
| `worker/app/pipeline/save.py` | Stage 9 — финальное сохранение |
| `shared/constants.py` | `STYLE_PROMPTS`, `VALID_ILLUSTRATION_STYLES` |
| `shared/models/story.py` | Story model (incl. `illustration_style`, `user_context`) |
| `backend/app/services/generation_service.py` | Создание job + Redis enqueue |
