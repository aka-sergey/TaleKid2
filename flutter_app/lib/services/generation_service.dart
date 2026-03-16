import 'package:dio/dio.dart';

import '../models/story.dart';
import 'api_client.dart';

/// Service for generation job creation and status polling.
class GenerationService {
  final ApiClient _client;

  GenerationService(this._client);

  /// Create a new story generation job.
  Future<GenerationJob> createGeneration({
    required List<String> characterIds,
    required int genreId,
    required int worldId,
    int? baseTaleId,
    required String ageRange,
    required double educationLevel,
    required int pageCount,
    required int readingDurationMinutes,
    String? illustrationStyle,
  }) async {
    try {
      final response = await _client.dio.post(
        '/generation/create',
        data: {
          'character_ids': characterIds,
          'genre_id': genreId,
          'world_id': worldId,
          if (baseTaleId != null) 'base_tale_id': baseTaleId,
          'age_range': ageRange,
          'education_level': educationLevel,
          'page_count': pageCount,
          'reading_duration_minutes': readingDurationMinutes,
          if (illustrationStyle != null) 'illustration_style': illustrationStyle,
        },
      );
      return GenerationJob.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Get the current status of a generation job.
  Future<GenerationJob> getJobStatus(String jobId) async {
    try {
      final response = await _client.dio.get('/generation/$jobId/status');
      return GenerationJob.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }

  /// Cancel a generation job.
  Future<void> cancelJob(String jobId) async {
    try {
      await _client.dio.post('/generation/$jobId/cancel');
    } on DioException catch (e) {
      throw ApiError.fromDioException(e);
    }
  }
}
