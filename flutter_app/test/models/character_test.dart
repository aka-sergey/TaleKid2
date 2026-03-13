import 'package:flutter_test/flutter_test.dart';
import 'package:talekid/models/character.dart';

void main() {
  group('CharacterPhoto', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'photo-1',
        's3_url': 'https://cdn.test/photo.jpg',
        'sort_order': 0,
      };
      final photo = CharacterPhoto.fromJson(json);

      expect(photo.id, 'photo-1');
      expect(photo.s3Url, 'https://cdn.test/photo.jpg');
      expect(photo.sortOrder, 0);
    });

    test('toJson round-trips', () {
      final photo = CharacterPhoto(
        id: 'p1',
        s3Url: 'https://cdn.test/p.jpg',
        sortOrder: 1,
      );
      final json = photo.toJson();
      final restored = CharacterPhoto.fromJson(json);

      expect(restored.id, photo.id);
      expect(restored.s3Url, photo.s3Url);
      expect(restored.sortOrder, photo.sortOrder);
    });
  });

  group('CharacterModel', () {
    test('fromJson parses full character', () {
      final json = {
        'id': 'char-1',
        'name': 'Алиса',
        'character_type': 'child',
        'gender': 'female',
        'age': 7,
        'appearance_description': 'Голубые глаза, светлые волосы',
        'photos': [
          {
            'id': 'ph-1',
            's3_url': 'https://cdn.test/photo1.jpg',
            'sort_order': 0,
          },
        ],
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final model = CharacterModel.fromJson(json);

      expect(model.id, 'char-1');
      expect(model.name, 'Алиса');
      expect(model.characterType, 'child');
      expect(model.gender, 'female');
      expect(model.age, 7);
      expect(model.appearanceDescription, 'Голубые глаза, светлые волосы');
      expect(model.photos.length, 1);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'char-2',
        'name': 'Барсик',
        'character_type': 'pet',
        'gender': 'male',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final model = CharacterModel.fromJson(json);

      expect(model.age, isNull);
      expect(model.appearanceDescription, isNull);
      expect(model.photos, isEmpty);
    });

    test('characterTypeLabel returns localized string', () {
      expect(_makeChar(type: 'child').characterTypeLabel, 'Ребёнок');
      expect(_makeChar(type: 'adult').characterTypeLabel, 'Взрослый');
      expect(_makeChar(type: 'pet').characterTypeLabel, 'Питомец');
      expect(_makeChar(type: 'unknown').characterTypeLabel, 'unknown');
    });

    test('genderLabel returns localized string for child', () {
      expect(
        _makeChar(type: 'child', gender: 'male').genderLabel,
        'Мальчик',
      );
      expect(
        _makeChar(type: 'child', gender: 'female').genderLabel,
        'Девочка',
      );
    });

    test('genderLabel returns localized string for adult', () {
      expect(
        _makeChar(type: 'adult', gender: 'male').genderLabel,
        'Мужской',
      );
      expect(
        _makeChar(type: 'adult', gender: 'female').genderLabel,
        'Женский',
      );
    });

    test('avatarUrl returns first photo URL', () {
      final model = CharacterModel.fromJson({
        'id': 'c',
        'name': 'T',
        'character_type': 'child',
        'gender': 'male',
        'photos': [
          {'id': 'p1', 's3_url': 'https://cdn.test/first.jpg', 'sort_order': 0},
          {'id': 'p2', 's3_url': 'https://cdn.test/second.jpg', 'sort_order': 1},
        ],
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      });

      expect(model.avatarUrl, 'https://cdn.test/first.jpg');
    });

    test('avatarUrl returns null when no photos', () {
      final model = _makeChar();
      expect(model.avatarUrl, isNull);
    });

    test('copyWith creates modified copy', () {
      final original = _makeChar(name: 'Алиса');
      final copy = original.copyWith(name: 'Боб');

      expect(copy.name, 'Боб');
      expect(copy.id, original.id);
      expect(copy.characterType, original.characterType);
    });

    test('toJson produces expected keys', () {
      final model = _makeChar(name: 'Тест');
      final json = model.toJson();

      expect(json['name'], 'Тест');
      expect(json['character_type'], isNotNull);
      expect(json['gender'], isNotNull);
      expect(json.containsKey('created_at'), isTrue);
    });
  });
}

/// Helper to create a CharacterModel with minimal fields.
CharacterModel _makeChar({
  String name = 'Персонаж',
  String type = 'child',
  String gender = 'male',
}) {
  return CharacterModel.fromJson({
    'id': 'test-id',
    'name': name,
    'character_type': type,
    'gender': gender,
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
  });
}
