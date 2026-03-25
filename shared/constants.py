from enum import Enum


class CharacterType(str, Enum):
    CHILD = "child"
    ADULT = "adult"
    PET = "pet"


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"


class AgeRange(str, Enum):
    RANGE_3_5 = "3-5"
    RANGE_6_8 = "6-8"
    RANGE_9_12 = "9-12"


class StoryStatus(str, Enum):
    DRAFT = "draft"
    GENERATING = "generating"
    COMPLETED = "completed"
    FAILED = "failed"


class JobStatus(str, Enum):
    QUEUED = "queued"
    PROCESSING = "processing"
    PHOTO_ANALYSIS = "photo_analysis"
    STORY_BIBLE = "story_bible"
    TEXT_GENERATION = "text_generation"
    SCENE_DECOMPOSITION = "scene_decomposition"
    CHARACTER_REFERENCES = "character_references"
    ILLUSTRATION = "illustration"
    EDUCATION = "education"
    TITLE_GENERATION = "title_generation"
    SAVING = "saving"
    COMPLETED = "completed"
    FAILED = "failed"


class Platform(str, Enum):
    ANDROID = "android"
    WEB = "web"


class BaseTaleCharacterRole(str, Enum):
    PROTAGONIST = "protagonist"
    ANTAGONIST = "antagonist"
    HELPER = "helper"
    SECONDARY = "secondary"


class EducationalContentType(str, Enum):
    FACT = "fact"
    QUESTION = "question"


# ── Illustration style slugs and their AI prompt descriptions ────────────────
VALID_ILLUSTRATION_STYLES: frozenset[str] = frozenset({
    "watercolor", "disney", "anime", "classic-book", "pixar", "painterly",
})

STYLE_PROMPTS: dict[str, str] = {
    "watercolor": (
        "warm watercolor children's book illustration, soft flowing colors, "
        "delicate brushstrokes, gentle painted textures, impressionistic feel"
    ),
    "disney": (
        "classic Disney animation style, magical atmosphere, expressive large eyes, "
        "fluid movement, bold clean outlines, cinematic storybook lighting"
    ),
    "anime": (
        "Japanese anime illustration style, large expressive eyes, clean line art, "
        "vibrant saturated colors, detailed hand-drawn backgrounds"
    ),
    "classic-book": (
        "classic children's book illustration, warm pencil and ink sketches "
        "with watercolor washes, vintage storybook feel, cozy detailed scenes"
    ),
    "pixar": (
        "Pixar-style stylized 3D fairytale look, soft volumetric lighting, "
        "rounded expressive characters, rich detailed environments, "
        "warm cinematic color grading, photorealistic textures with cartoon appeal"
    ),
    "painterly": (
        "lush cinematic painterly storybook illustration, rich oil-painting textures, "
        "dramatic warm lighting, deep saturated colors, masterful brushwork, "
        "epic fairy tale atmosphere, cinematic composition, detailed scenic backgrounds"
    ),
}
