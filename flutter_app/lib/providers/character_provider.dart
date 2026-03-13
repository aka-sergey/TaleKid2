import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/character.dart';
import '../services/character_service.dart';
import 'auth_provider.dart';

/// Provides the [CharacterApiService] singleton.
final characterApiServiceProvider = Provider<CharacterApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CharacterApiService(client);
});

/// Provides a reactive list of the current user's characters.
final charactersProvider =
    AsyncNotifierProvider<CharactersNotifier, List<CharacterModel>>(
  () => CharactersNotifier(),
);

class CharactersNotifier extends AsyncNotifier<List<CharacterModel>> {
  CharacterApiService get _service => ref.read(characterApiServiceProvider);

  @override
  Future<List<CharacterModel>> build() async {
    return _service.getCharacters();
  }

  /// Create a new character and add it to the list.
  Future<CharacterModel> createCharacter({
    required String name,
    required String characterType,
    required String gender,
    int? age,
    String? appearanceDescription,
  }) async {
    final character = await _service.createCharacter(
      name: name,
      characterType: characterType,
      gender: gender,
      age: age,
      appearanceDescription: appearanceDescription,
    );

    // Append to the current list without full reload.
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, character]);

    return character;
  }

  /// Update an existing character.
  Future<void> updateCharacter(
    String id, {
    String? name,
    String? characterType,
    String? gender,
    int? age,
    String? appearanceDescription,
  }) async {
    final updated = await _service.updateCharacter(
      id,
      name: name,
      characterType: characterType,
      gender: gender,
      age: age,
      appearanceDescription: appearanceDescription,
    );

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((c) => c.id == id ? updated : c).toList(),
    );
  }

  /// Delete a character.
  Future<void> deleteCharacter(String id) async {
    await _service.deleteCharacter(id);

    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  /// Upload a photo for a character.
  Future<void> addPhoto(
    String characterId,
    Uint8List bytes,
    String filename,
  ) async {
    final photo = await _service.uploadPhoto(characterId, bytes, filename);

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((c) {
        if (c.id == characterId) {
          return c.copyWith(photos: [...c.photos, photo]);
        }
        return c;
      }).toList(),
    );
  }

  /// Delete a photo from a character.
  Future<void> deletePhoto(String characterId, String photoId) async {
    await _service.deletePhoto(characterId, photoId);

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((c) {
        if (c.id == characterId) {
          return c.copyWith(
            photos: c.photos.where((p) => p.id != photoId).toList(),
          );
        }
        return c;
      }).toList(),
    );
  }

  /// Force-refresh the characters list from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getCharacters());
  }
}
