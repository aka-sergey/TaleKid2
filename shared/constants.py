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
