/// Data models for stories and generation jobs.

class StoryModel {
  final String id;
  final String? title;
  final String? titleSuggested;
  final String? coverImageUrl;
  final String status; // draft, generating, completed, failed
  final String ageRange;
  final double educationLevel;
  final int pageCount;
  final int readingDurationMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoryModel({
    required this.id,
    this.title,
    this.titleSuggested,
    this.coverImageUrl,
    required this.status,
    required this.ageRange,
    required this.educationLevel,
    required this.pageCount,
    required this.readingDurationMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] as String,
      title: json['title'] as String?,
      titleSuggested: json['title_suggested'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      status: json['status'] as String,
      ageRange: json['age_range'] as String? ?? '3-5',
      educationLevel: (json['education_level'] as num?)?.toDouble() ?? 0.5,
      pageCount: json['page_count'] as int? ?? 10,
      readingDurationMinutes: json['reading_duration_minutes'] as int? ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isGenerating => status == 'generating';
  bool get isFailed => status == 'failed';

  String get displayTitle => title ?? titleSuggested ?? 'Без названия';
}

class StoryPage {
  final String id;
  final int pageNumber;
  final String? textContent;
  final String? imageUrl;
  final EducationalContent? educationalContent;

  const StoryPage({
    required this.id,
    required this.pageNumber,
    this.textContent,
    this.imageUrl,
    this.educationalContent,
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      id: json['id'] as String,
      pageNumber: json['page_number'] as int,
      textContent: json['text_content'] as String?,
      imageUrl: json['image_url'] as String?,
      educationalContent: json['educational_content'] != null
          ? EducationalContent.fromJson(
              json['educational_content'] as Map<String, dynamic>)
          : null,
    );
  }
}

class EducationalContent {
  final String contentType; // fact, question
  final String textRu;
  final String? answerRu;
  final String? topic;

  const EducationalContent({
    required this.contentType,
    required this.textRu,
    this.answerRu,
    this.topic,
  });

  factory EducationalContent.fromJson(Map<String, dynamic> json) {
    return EducationalContent(
      contentType: json['content_type'] as String,
      textRu: json['text_ru'] as String,
      answerRu: json['answer_ru'] as String?,
      topic: json['topic'] as String?,
    );
  }

  bool get isFact => contentType == 'fact';
  bool get isQuestion => contentType == 'question';
}

class StoryCharacterInfo {
  final String characterId;
  final String characterName;
  final String? roleInStory;
  final String? referenceImageUrl;

  const StoryCharacterInfo({
    required this.characterId,
    required this.characterName,
    this.roleInStory,
    this.referenceImageUrl,
  });

  factory StoryCharacterInfo.fromJson(Map<String, dynamic> json) {
    return StoryCharacterInfo(
      characterId: json['character_id'] as String,
      characterName: json['character_name'] as String,
      roleInStory: json['role_in_story'] as String?,
      referenceImageUrl: json['reference_image_url'] as String?,
    );
  }
}

class StoryDetail extends StoryModel {
  final List<StoryPage> pages;
  final List<StoryCharacterInfo> characters;

  const StoryDetail({
    required super.id,
    super.title,
    super.titleSuggested,
    super.coverImageUrl,
    required super.status,
    required super.ageRange,
    required super.educationLevel,
    required super.pageCount,
    required super.readingDurationMinutes,
    required super.createdAt,
    required super.updatedAt,
    required this.pages,
    required this.characters,
  });

  factory StoryDetail.fromJson(Map<String, dynamic> json) {
    return StoryDetail(
      id: json['id'] as String,
      title: json['title'] as String?,
      titleSuggested: json['title_suggested'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      status: json['status'] as String,
      ageRange: json['age_range'] as String? ?? '3-5',
      educationLevel: (json['education_level'] as num?)?.toDouble() ?? 0.5,
      pageCount: json['page_count'] as int? ?? 10,
      readingDurationMinutes: json['reading_duration_minutes'] as int? ?? 10,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      pages: (json['pages'] as List<dynamic>?)
              ?.map((e) => StoryPage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      characters: (json['characters'] as List<dynamic>?)
              ?.map(
                  (e) => StoryCharacterInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class GenerationJob {
  final String id;
  final String storyId;
  final String status;
  final int progressPct;
  final String? statusMessage;
  final String? errorMessage;
  final String? storyTitle;
  final String? coverImageUrl;
  final DateTime createdAt;

  const GenerationJob({
    required this.id,
    required this.storyId,
    required this.status,
    required this.progressPct,
    this.statusMessage,
    this.errorMessage,
    this.storyTitle,
    this.coverImageUrl,
    required this.createdAt,
  });

  factory GenerationJob.fromJson(Map<String, dynamic> json) {
    return GenerationJob(
      id: json['job_id'] as String? ?? json['id'] as String,
      storyId: json['story_id'] as String,
      status: json['status'] as String,
      progressPct: json['progress_pct'] as int? ?? 0,
      statusMessage: json['status_message'] as String?,
      errorMessage: json['error_message'] as String?,
      storyTitle: json['story_title'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => !isCompleted && !isFailed;
}
