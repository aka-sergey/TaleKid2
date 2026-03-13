/// Data models for character management.

class CharacterPhoto {
  final String id;
  final String s3Url;
  final int sortOrder;

  const CharacterPhoto({
    required this.id,
    required this.s3Url,
    required this.sortOrder,
  });

  factory CharacterPhoto.fromJson(Map<String, dynamic> json) {
    return CharacterPhoto(
      id: json['id'] as String,
      s3Url: json['s3_url'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      's3_url': s3Url,
      'sort_order': sortOrder,
    };
  }
}

class CharacterModel {
  final String id;
  final String name;
  final String characterType; // child, adult, pet
  final String gender; // male, female
  final int? age;
  final String? appearanceDescription;
  final List<CharacterPhoto> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CharacterModel({
    required this.id,
    required this.name,
    required this.characterType,
    required this.gender,
    this.age,
    this.appearanceDescription,
    this.photos = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as String,
      name: json['name'] as String,
      characterType: json['character_type'] as String,
      gender: json['gender'] as String,
      age: json['age'] as int?,
      appearanceDescription: json['appearance_description'] as String?,
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => CharacterPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'character_type': characterType,
      'gender': gender,
      if (age != null) 'age': age,
      if (appearanceDescription != null)
        'appearance_description': appearanceDescription,
      'photos': photos.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CharacterModel copyWith({
    String? id,
    String? name,
    String? characterType,
    String? gender,
    int? age,
    String? appearanceDescription,
    List<CharacterPhoto>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CharacterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      characterType: characterType ?? this.characterType,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      appearanceDescription:
          appearanceDescription ?? this.appearanceDescription,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns localized display name for character type.
  String get characterTypeLabel {
    switch (characterType) {
      case 'child':
        return 'Ребёнок';
      case 'adult':
        return 'Взрослый';
      case 'pet':
        return 'Питомец';
      default:
        return characterType;
    }
  }

  /// Returns localized display name for gender.
  String get genderLabel {
    switch (gender) {
      case 'male':
        return characterType == 'child' ? 'Мальчик' : 'Мужской';
      case 'female':
        return characterType == 'child' ? 'Девочка' : 'Женский';
      default:
        return gender;
    }
  }

  /// Returns the first photo URL or null.
  String? get avatarUrl => photos.isNotEmpty ? photos.first.s3Url : null;
}
