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
}

/// Global cache manager for CrashSafeImage
class CrashSafeImageCache {
  static CrashSafeImageCacheConfig _config =
      CrashSafeImageCacheConfig.defaultConfig;
  static CacheManager? _customCacheManager;

  /// Get current cache configuration
  static CrashSafeImageCacheConfig get config => _config;

  /// Configure global cache settings
  static void configure(CrashSafeImageCacheConfig config) {
    _config = config;
    _customCacheManager = null; // Reset to recreate with new config
  }

  /// Get cache manager instance
  static CacheManager getCacheManager() {
    _customCacheManager ??= CacheManager(
      Config(
        _config.repoKey ?? 'crashSafeImageCache',
        stalePeriod: _config.stalePeriod,
        maxNrOfCacheObjects: _config.maxNrOfCacheObjects,
      ),
    );
    return _customCacheManager!;
  }

  /// Clear all cached images
  static Future<void> clear() async {
    await getCacheManager().emptyCache();
  }

  /// Remove a specific cached image by URL
  static Future<void> remove(String url) async {
    await getCacheManager().removeFile(url);
  }

  /// Get cache statistics (file count and size)
  static Future<Map<String, dynamic>> getStats() async {
    // Note: flutter_cache_manager doesn't provide direct stats API
    // This is a placeholder for future enhancement
    return {
      'maxObjects': _config.maxNrOfCacheObjects,
      'stalePeriod': _config.stalePeriod.inDays,
    };
  }
}
