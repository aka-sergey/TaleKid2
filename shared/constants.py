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
    "watercolor", "3d-pixar", "disney", "comic",
    "anime", "pastel", "classic-book", "pop-art",
})

STYLE_PROMPTS: dict[str, str] = {
    "watercolor": (
        "warm watercolor children's book illustration, soft flowing colors, "
        "delicate brushstrokes, gentle painted textures, impressionistic feel"
    ),
    "3d-pixar": (
        "3D CGI animation style inspired by Pixar movies, glossy surfaces, "
        "volumetric lighting, expressive cartoon characters, vibrant colors"
    ),
    "disney": (
        "classic Disney animation style, magical atmosphere, expressive large eyes, "
        "fluid movement, bold clean outlines, cinematic storybook lighting"
    ),
    "comic": (
        "comic book illustration style, bold black outlines, dynamic action poses, "
        "bright flat colors, halftone dot patterns, graphic novel look"
    ),
    "anime": (
        "Japanese anime illustration style, large expressive eyes, clean line art, "
        "vibrant saturated colors, detailed hand-drawn backgrounds"
    ),
    "pastel": (
        "soft pastel illustration style, muted gentle colors, dreamy atmosphere, "
        "tender soft textures, calming color palette for young children"
    ),
    "classic-book": (
        "classic children's book illustration, warm pencil and ink sketches "
        "with watercolor washes, vintage storybook feel, cozy detailed scenes"
    ),
    "pop-art": (
        "pop art illustration style, bold primary colors, strong graphic outlines, "
        "high contrast modern graphic design, playful and energetic"
    ),
}
