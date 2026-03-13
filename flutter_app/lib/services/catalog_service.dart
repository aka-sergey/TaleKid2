import 'package:dio/dio.dart';

import '../models/catalog.dart';
import 'api_client.dart';

/// Catalog API service for fetching genres, worlds, and base tales.
class CatalogService {
  final ApiClient _client;

  CatalogService(this._client);

  /// Fetch all available genres.
  Future<List<Genre>> getGenres() async {
    try {
      final response = await _client.dio.get('/catalog/genres');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => Genre.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Fetch all available worlds / settings.
  Future<List<World>> getWorlds() async {
    try {
      final response = await _client.dio.get('/catalog/worlds');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => World.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Fetch all base tale templates.
  Future<List<BaseTale>> getBaseTales() async {
    try {
      final response = await _client.dio.get('/catalog/base-tales');
      final data = response.data as List<dynamic>;
      return data
          .map((e) => BaseTale.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Fetch detailed information about a single base tale, including characters.
  Future<BaseTale> getBaseTaleDetail(int id) async {
    try {
      final response = await _client.dio.get('/catalog/base-tales/$id');
      return BaseTale.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }
}
