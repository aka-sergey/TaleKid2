import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog.dart';
import '../services/catalog_service.dart';
import 'auth_provider.dart';

/// Provides the [CatalogService] singleton.
final catalogServiceProvider = Provider<CatalogService>((ref) {
  final client = ref.watch(apiClientProvider);
  return CatalogService(client);
});

/// Cached list of genres -- stays alive while any listener exists.
final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getGenres();
});

/// Cached list of worlds / settings.
final worldsProvider = FutureProvider<List<World>>((ref) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getWorlds();
});

/// Cached list of base tale templates.
final baseTalesProvider = FutureProvider<List<BaseTale>>((ref) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getBaseTales();
});

/// Fetch detail for a specific base tale (with characters).
final baseTaleDetailProvider =
    FutureProvider.family<BaseTale, int>((ref, id) async {
  final service = ref.watch(catalogServiceProvider);
  return service.getBaseTaleDetail(id);
});
