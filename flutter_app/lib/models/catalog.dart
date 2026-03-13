/// Data models for catalog (genres, worlds, base tales).

class Genre {
  final int id;
  final String slug;
  final String nameRu;
  final String? descriptionRu;
  final String? iconUrl;

  const Genre({
    required this.id,
    required this.slug,
    required this.nameRu,
    this.descriptionRu,
    this.iconUrl,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as int,
      slug: json['slug'] as String,
      nameRu: json['name_ru'] as String,
      descriptionRu: json['description_ru'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }
}

class World {
  final int id;
  final String slug;
  final String nameRu;
  final String? descriptionRu;
  final String? iconUrl;

  const World({
    required this.id,
    required this.slug,
    required this.nameRu,
    this.descriptionRu,
    this.iconUrl,
  });

  factory World.fromJson(Map<String, dynamic> json) {
    return World(
      id: json['id'] as int,
      slug: json['slug'] as String,
      nameRu: json['name_ru'] as String,
      descriptionRu: json['description_ru'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }
}

class BaseTaleCharacter {
  final int id;
  final String nameRu;
  final String role;
  final String? personalityRu;

  const BaseTaleCharacter({
    required this.id,
    required this.nameRu,
    required this.role,
    this.personalityRu,
  });

  factory BaseTaleCharacter.fromJson(Map<String, dynamic> json) {
    return BaseTaleCharacter(
      id: json['id'] as int,
      nameRu: json['name_ru'] as String,
      role: json['role'] as String,
      personalityRu: json['personality_ru'] as String?,
    );
  }
}

class BaseTale {
  final int id;
  final String slug;
  final String nameRu;
  final String? summaryRu;
  final String? moralRu;
  final String? iconUrl;
  final List<BaseTaleCharacter>? characters;

  const BaseTale({
    required this.id,
    required this.slug,
    required this.nameRu,
    this.summaryRu,
    this.moralRu,
    this.iconUrl,
    this.characters,
  });

  factory BaseTale.fromJson(Map<String, dynamic> json) {
    return BaseTale(
      id: json['id'] as int,
      slug: json['slug'] as String,
      nameRu: json['name_ru'] as String,
      summaryRu: json['summary_ru'] as String?,
      moralRu: json['moral_ru'] as String?,
      iconUrl: json['icon_url'] as String?,
      characters: (json['characters'] as List<dynamic>?)
          ?.map(
              (e) => BaseTaleCharacter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
