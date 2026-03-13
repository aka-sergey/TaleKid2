import 'package:dio/dio.dart';

import '../models/story.dart';
import 'api_client.dart';

/// Service for managing stories (library).
class StoryService {
  final ApiClient _client;

  StoryService(this._client);

  /// Fetch the user's story library.
  Future<List<StoryModel>> getStories({int skip = 0, int limit = 50}) async {
    try {
      final response = await _client.dio.get(
        '/stories',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Fetch full story detail with pages and characters.
  Future<StoryDetail> getStoryDetail(String storyId) async {
    try {
      final response = await _client.dio.get('/stories/$storyId');
      return StoryDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Rename a story.
  Future<void> updateTitle(String storyId, String title) async {
    try {
      await _client.dio.put(
        '/stories/$storyId/title',
        data: {'title': title},
      );
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Delete a story.
  Future<void> deleteStory(String storyId) async {
    try {
      await _client.dio.delete('/stories/$storyId');
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }
}
