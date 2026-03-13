import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../services/story_service.dart';
import 'auth_provider.dart';

/// Provides the [StoryService] singleton.
final storyServiceProvider = Provider<StoryService>((ref) {
  final client = ref.watch(apiClientProvider);
  return StoryService(client);
});

/// Provides the user's story library.
final storiesProvider =
    AsyncNotifierProvider<StoriesNotifier, List<StoryModel>>(
  () => StoriesNotifier(),
);

class StoriesNotifier extends AsyncNotifier<List<StoryModel>> {
  StoryService get _service => ref.read(storyServiceProvider);

  @override
  Future<List<StoryModel>> build() async {
    return _service.getStories();
  }

  /// Force-refresh the story list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.getStories());
  }

  /// Rename a story.
  Future<void> updateTitle(String storyId, String title) async {
    await _service.updateTitle(storyId, title);

    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((s) {
        if (s.id == storyId) {
          return StoryModel(
            id: s.id,
            title: title,
            titleSuggested: s.titleSuggested,
            coverImageUrl: s.coverImageUrl,
            status: s.status,
            ageRange: s.ageRange,
            educationLevel: s.educationLevel,
            pageCount: s.pageCount,
            readingDurationMinutes: s.readingDurationMinutes,
            createdAt: s.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return s;
      }).toList(),
    );
  }

  /// Delete a story.
  Future<void> deleteStory(String storyId) async {
    await _service.deleteStory(storyId);

    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != storyId).toList());
  }
}

/// Fetch story detail by ID.
final storyDetailProvider =
    FutureProvider.family<StoryDetail, String>((ref, storyId) async {
  final service = ref.watch(storyServiceProvider);
  return service.getStoryDetail(storyId);
});
