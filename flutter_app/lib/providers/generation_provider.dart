import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/story.dart';
import '../services/generation_service.dart';
import 'auth_provider.dart';

/// Provides the [GenerationService] singleton.
final generationServiceProvider = Provider<GenerationService>((ref) {
  final client = ref.watch(apiClientProvider);
  return GenerationService(client);
});

/// Holds the state of a generation job being polled.
class GenerationJobState {
  final GenerationJob job;
  final bool isPolling;

  const GenerationJobState({required this.job, this.isPolling = true});

  GenerationJobState copyWith({GenerationJob? job, bool? isPolling}) {
    return GenerationJobState(
      job: job ?? this.job,
      isPolling: isPolling ?? this.isPolling,
    );
  }
}

/// Manages the lifecycle of a generation job: creation, polling, cancellation.
final generationJobProvider = AutoDisposeAsyncNotifierProviderFamily<
    GenerationJobNotifier, GenerationJobState, String>(
  () => GenerationJobNotifier(),
);

class GenerationJobNotifier
    extends AutoDisposeFamilyAsyncNotifier<GenerationJobState, String> {
  Timer? _pollTimer;
  static const _pollInterval = Duration(seconds: 3);

  @override
  Future<GenerationJobState> build(String arg) async {
    // arg = jobId
    ref.onDispose(() => _pollTimer?.cancel());

    final service = ref.read(generationServiceProvider);
    final job = await service.getJobStatus(arg);
    final jobState = GenerationJobState(job: job);

    if (job.isProcessing) {
      _startPolling(arg);
    }

    return jobState;
  }

  void _startPolling(String jobId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      try {
        final service = ref.read(generationServiceProvider);
        final job = await service.getJobStatus(jobId);

        state = AsyncData(
          GenerationJobState(
            job: job,
            isPolling: job.isProcessing,
          ),
        );

        if (!job.isProcessing) {
          _pollTimer?.cancel();
        }
      } catch (_) {
        // Silently handle polling errors — don't crash the UI
      }
    });
  }

  /// Cancel the current generation job.
  Future<void> cancelJob() async {
    _pollTimer?.cancel();
    try {
      final service = ref.read(generationServiceProvider);
      await service.cancelJob(arg);

      final currentState = state.valueOrNull;
      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            job: GenerationJob(
              id: currentState.job.id,
              storyId: currentState.job.storyId,
              status: 'failed',
              progressPct: currentState.job.progressPct,
              statusMessage: 'Отменено пользователем',
              errorMessage: 'Cancelled by user',
              createdAt: currentState.job.createdAt,
            ),
            isPolling: false,
          ),
        );
      }
    } catch (_) {
      // Handle cancellation error
    }
  }
}
