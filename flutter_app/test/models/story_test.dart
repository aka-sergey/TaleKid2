import 'package:flutter_test/flutter_test.dart';
import 'package:talekid/models/story.dart';

void main() {
  group('StoryModel', () {
    test('fromJson parses minimal fields', () {
      final json = {
        'id': 'abc-123',
        'status': 'completed',
        'age_range': '3-5',
        'education_level': 0.7,
        'page_count': 10,
        'reading_duration_minutes': 15,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final model = StoryModel.fromJson(json);

      expect(model.id, 'abc-123');
      expect(model.status, 'completed');
      expect(model.ageRange, '3-5');
      expect(model.educationLevel, 0.7);
      expect(model.pageCount, 10);
      expect(model.readingDurationMinutes, 15);
      expect(model.title, isNull);
      expect(model.titleSuggested, isNull);
      expect(model.coverImageUrl, isNull);
    });

    test('fromJson parses optional fields', () {
      final json = {
        'id': 'abc-123',
        'title': 'Приключения зайчика',
        'title_suggested': 'Зайчик в лесу',
        'cover_image_url': 'https://cdn.test/cover.png',
        'status': 'draft',
        'age_range': '6-8',
        'education_level': 0.5,
        'page_count': 5,
        'reading_duration_minutes': 8,
        'created_at': '2026-03-14T10:00:00Z',
        'updated_at': '2026-03-14T10:00:00Z',
      };
      final model = StoryModel.fromJson(json);

      expect(model.title, 'Приключения зайчика');
      expect(model.titleSuggested, 'Зайчик в лесу');
      expect(model.coverImageUrl, 'https://cdn.test/cover.png');
    });

    test('fromJson uses defaults for missing nullable fields', () {
      final json = {
        'id': 'x',
        'status': 'generating',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final model = StoryModel.fromJson(json);

      expect(model.ageRange, '3-5'); // default
      expect(model.educationLevel, 0.5); // default
      expect(model.pageCount, 10); // default
      expect(model.readingDurationMinutes, 10); // default
    });

    test('isCompleted returns true for completed status', () {
      final model = _makeStory(status: 'completed');
      expect(model.isCompleted, isTrue);
      expect(model.isGenerating, isFalse);
      expect(model.isFailed, isFalse);
    });

    test('isGenerating returns true for generating status', () {
      final model = _makeStory(status: 'generating');
      expect(model.isGenerating, isTrue);
      expect(model.isCompleted, isFalse);
    });

    test('isFailed returns true for failed status', () {
      final model = _makeStory(status: 'failed');
      expect(model.isFailed, isTrue);
    });

    test('displayTitle uses title first, then suggested, then fallback', () {
      expect(_makeStory(title: 'Моя сказка').displayTitle, 'Моя сказка');
      expect(
        _makeStory(titleSuggested: 'Предложенное').displayTitle,
        'Предложенное',
      );
      expect(_makeStory().displayTitle, 'Без названия');
    });
  });

  group('StoryPage', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'page-1',
        'page_number': 1,
        'text_content': 'Жили-были...',
        'image_url': 'https://cdn.test/page1.png',
      };
      final page = StoryPage.fromJson(json);

      expect(page.id, 'page-1');
      expect(page.pageNumber, 1);
      expect(page.textContent, 'Жили-были...');
      expect(page.imageUrl, 'https://cdn.test/page1.png');
      expect(page.educationalContent, isNull);
    });

    test('fromJson parses educational content', () {
      final json = {
        'id': 'page-2',
        'page_number': 2,
        'text_content': 'Текст...',
        'educational_content': {
          'content_type': 'fact',
          'text_ru': 'Зайцы меняют цвет шерсти зимой',
          'topic': 'nature',
        },
      };
      final page = StoryPage.fromJson(json);

      expect(page.educationalContent, isNotNull);
      expect(page.educationalContent!.contentType, 'fact');
      expect(page.educationalContent!.isFact, isTrue);
      expect(page.educationalContent!.isQuestion, isFalse);
    });
  });

  group('EducationalContent', () {
    test('fromJson parses fact', () {
      final json = {
        'content_type': 'fact',
        'text_ru': 'Интересный факт',
        'topic': 'science',
      };
      final ec = EducationalContent.fromJson(json);

      expect(ec.contentType, 'fact');
      expect(ec.textRu, 'Интересный факт');
      expect(ec.topic, 'science');
      expect(ec.answerRu, isNull);
      expect(ec.isFact, isTrue);
    });

    test('fromJson parses question with answer', () {
      final json = {
        'content_type': 'question',
        'text_ru': 'Сколько ног у паука?',
        'answer_ru': 'Восемь',
        'topic': 'biology',
      };
      final ec = EducationalContent.fromJson(json);

      expect(ec.isQuestion, isTrue);
      expect(ec.answerRu, 'Восемь');
    });
  });

  group('StoryCharacterInfo', () {
    test('fromJson parses correctly', () {
      final json = {
        'character_id': 'char-1',
        'character_name': 'Зайчик',
        'role_in_story': 'protagonist',
        'reference_image_url': 'https://cdn.test/ref.png',
      };
      final info = StoryCharacterInfo.fromJson(json);

      expect(info.characterId, 'char-1');
      expect(info.characterName, 'Зайчик');
      expect(info.roleInStory, 'protagonist');
      expect(info.referenceImageUrl, 'https://cdn.test/ref.png');
    });

    test('fromJson handles nulls', () {
      final json = {
        'character_id': 'char-2',
        'character_name': 'Лисичка',
      };
      final info = StoryCharacterInfo.fromJson(json);

      expect(info.roleInStory, isNull);
      expect(info.referenceImageUrl, isNull);
    });
  });

  group('StoryDetail', () {
    test('fromJson parses full response', () {
      final json = {
        'id': 'story-1',
        'title': 'Сказка',
        'status': 'completed',
        'age_range': '3-5',
        'education_level': 0.5,
        'page_count': 2,
        'reading_duration_minutes': 5,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'pages': [
          {
            'id': 'p1',
            'page_number': 1,
            'text_content': 'Page 1 text',
          },
          {
            'id': 'p2',
            'page_number': 2,
            'text_content': 'Page 2 text',
          },
        ],
        'characters': [
          {
            'character_id': 'c1',
            'character_name': 'Герой',
          },
        ],
      };
      final detail = StoryDetail.fromJson(json);

      expect(detail.pages.length, 2);
      expect(detail.characters.length, 1);
      expect(detail.pages[0].textContent, 'Page 1 text');
      expect(detail.characters[0].characterName, 'Герой');
    });

    test('fromJson with empty pages and characters', () {
      final json = {
        'id': 'story-2',
        'status': 'draft',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final detail = StoryDetail.fromJson(json);

      expect(detail.pages, isEmpty);
      expect(detail.characters, isEmpty);
    });
  });

  group('GenerationJob', () {
    test('fromJson parses correctly', () {
      final json = {
        'job_id': 'job-1',
        'story_id': 'story-1',
        'status': 'illustration',
        'progress_pct': 65,
        'status_message': 'Рисуем картинки...',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final job = GenerationJob.fromJson(json);

      expect(job.id, 'job-1');
      expect(job.storyId, 'story-1');
      expect(job.status, 'illustration');
      expect(job.progressPct, 65);
      expect(job.statusMessage, 'Рисуем картинки...');
      expect(job.isProcessing, isTrue);
      expect(job.isCompleted, isFalse);
      expect(job.isFailed, isFalse);
    });

    test('fromJson with id fallback', () {
      final json = {
        'id': 'fallback-id',
        'story_id': 's',
        'status': 'completed',
        'created_at': '2026-01-01T00:00:00Z',
      };
      final job = GenerationJob.fromJson(json);
      expect(job.id, 'fallback-id');
      expect(job.isCompleted, isTrue);
    });

    test('isProcessing for non-terminal statuses', () {
      final job = GenerationJob.fromJson({
        'id': 'j',
        'story_id': 's',
        'status': 'text_generation',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(job.isProcessing, isTrue);
    });

    test('isFailed for failed status', () {
      final job = GenerationJob.fromJson({
        'id': 'j',
        'story_id': 's',
        'status': 'failed',
        'error_message': 'OpenAI timeout',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(job.isFailed, isTrue);
      expect(job.errorMessage, 'OpenAI timeout');
    });
  });
}

/// Helper to build a StoryModel with minimal fields.
StoryModel _makeStory({
  String status = 'draft',
  String? title,
  String? titleSuggested,
}) {
  return StoryModel.fromJson({
    'id': 'test',
    'status': status,
    if (title != null) 'title': title,
    if (titleSuggested != null) 'title_suggested': titleSuggested,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  });
}
