// lib/src/cache_config.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Cache configuration for CrashSafeImage
class CrashSafeImageCacheConfig {
  /// Maximum number of cached objects (default: 200)
  final int maxNrOfCacheObjects;

  /// Maximum cache duration (default: 30 days)
  final Duration stalePeriod;

  /// Repository name for cache storage
  final String? repoKey;

  const CrashSafeImageCacheConfig({
    this.maxNrOfCacheObjects = 200,
    this.stalePeriod = const Duration(days: 30),
    this.repoKey,
  });

  /// Default cache configuration
  static const CrashSafeImageCacheConfig defaultConfig =
      CrashSafeImageCacheConfig();

  /// Aggressive caching (more items, longer duration)
  static const CrashSafeImageCacheConfig aggressive = CrashSafeImageCacheConfig(
    maxNrOfCacheObjects: 500,
    stalePeriod: Duration(days: 90),
  );

  /// Conservative caching (fewer items, shorter duration)
  static const CrashSafeImageCacheConfig conservative =
      CrashSafeImageCacheConfig(
        maxNrOfCacheObjects: 50,
        stalePeriod: Duration(days: 7),
      );

  /// Minimal caching (very limited cache)
  static const CrashSafeImageCacheConfig minimal = CrashSafeImageCacheConfig(
    maxNrOfCacheObjects: 20,
    stalePeriod: Duration(days: 1),
  );

  /// Storage key used by the underlying cache. Configs without an explicit
  /// [repoKey] get a key derived from their limits, so different presets never
  /// share (and fight over) the same cache database.
  String get effectiveRepoKey {
    if (repoKey != null) return repoKey!;
    if (this == defaultConfig) return 'crashSafeImageCache';
    return 'crashSafeImageCache_${maxNrOfCacheObjects}_${stalePeriod.inSeconds}';
  }

  @override
  bool operator ==(Object other) =>
      other is CrashSafeImageCacheConfig &&
      other.maxNrOfCacheObjects == maxNrOfCacheObjects &&
      other.stalePeriod == stalePeriod &&
      other.repoKey == repoKey;

  @override
  int get hashCode => Object.hash(maxNrOfCacheObjects, stalePeriod, repoKey);
}

/// Global cache manager for CrashSafeImage
class CrashSafeImageCache {
  static CrashSafeImageCacheConfig _config =
      CrashSafeImageCacheConfig.defaultConfig;

  /// One manager per storage key; reused so the same cache database is never
  /// opened by two [CacheManager] instances.
  static final Map<String, CacheManager> _managers = {};

  /// Get current cache configuration
  static CrashSafeImageCacheConfig get config => _config;

  /// Configure global cache settings. Applies to every widget that does not
  /// pass its own `cacheConfig`.
  static void configure(CrashSafeImageCacheConfig config) {
    _config = config;
  }

  /// Get the cache manager for [config], or for the global config if null.
  ///
  /// Configs sharing the same [CrashSafeImageCacheConfig.repoKey] share one
  /// manager (the first config registered for that key wins).
  static CacheManager getCacheManager([CrashSafeImageCacheConfig? config]) {
    final c = config ?? _config;
    return _managers.putIfAbsent(
      c.effectiveRepoKey,
      () => CacheManager(
        Config(
          c.effectiveRepoKey,
          stalePeriod: c.stalePeriod,
          maxNrOfCacheObjects: c.maxNrOfCacheObjects,
        ),
      ),
    );
  }

  /// Clear all cached images (global and per-widget caches)
  static Future<void> clear() async {
    getCacheManager();
    await Future.wait(_managers.values.map((m) => m.emptyCache()));
  }

  /// Remove a specific cached image by URL (or custom cacheKey) from all caches
  static Future<void> remove(String url) async {
    getCacheManager();
    await Future.wait(_managers.values.map((m) => m.removeFile(url)));
  }

  /// Returns the active global cache limits.
  ///
  /// flutter_cache_manager exposes no file count/size API, so this reports
  /// the configured limits rather than live usage.
  static Future<Map<String, dynamic>> getStats() async {
    return {
      'maxObjects': _config.maxNrOfCacheObjects,
      'stalePeriod': _config.stalePeriod.inDays,
    };
  }
}
