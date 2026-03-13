import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/character.dart';
import 'api_client.dart';

/// Character management API service.
class CharacterApiService {
  final ApiClient _client;

  CharacterApiService(this._client);

  /// Fetch all characters for the current user.
  Future<List<CharacterModel>> getCharacters() async {
    try {
      final response = await _client.dio.get('/characters');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => CharacterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Fetch a single character by ID.
  Future<CharacterModel> getCharacter(String id) async {
    try {
      final response = await _client.dio.get('/characters/$id');
      return CharacterModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Create a new character.
  Future<CharacterModel> createCharacter({
    required String name,
    required String characterType,
    required String gender,
    int? age,
    String? appearanceDescription,
  }) async {
    try {
      final response = await _client.dio.post(
        '/characters',
        data: {
          'name': name,
          'character_type': characterType,
          'gender': gender,
          if (age != null) 'age': age,
          if (appearanceDescription != null)
            'appearance_description': appearanceDescription,
        },
      );
      return CharacterModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Update an existing character.
  Future<CharacterModel> updateCharacter(
    String id, {
    String? name,
    String? characterType,
    String? gender,
    int? age,
    String? appearanceDescription,
  }) async {
    try {
      final response = await _client.dio.patch(
        '/characters/$id',
        data: {
          if (name != null) 'name': name,
          if (characterType != null) 'character_type': characterType,
          if (gender != null) 'gender': gender,
          if (age != null) 'age': age,
          if (appearanceDescription != null)
            'appearance_description': appearanceDescription,
        },
      );
      return CharacterModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Delete a character.
  Future<void> deleteCharacter(String id) async {
    try {
      await _client.dio.delete('/characters/$id');
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Upload a photo for a character using multipart form data.
  /// Works with [Uint8List] bytes for cross-platform compatibility (Android + Web).
  Future<CharacterPhoto> uploadPhoto(
    String characterId,
    Uint8List fileBytes,
    String filename,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
        ),
      });

      final response = await _client.dio.post(
        '/characters/$characterId/photos',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return CharacterPhoto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Delete a photo from a character.
  Future<void> deletePhoto(String characterId, String photoId) async {
    try {
      await _client.dio.delete('/characters/$characterId/photos/$photoId');
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }
}
