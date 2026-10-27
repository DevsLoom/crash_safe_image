// test/cache_config_test.dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crash_safe_image/crash_safe_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock platform channel for path_provider
  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getTemporaryDirectory' ||
            methodCall.method == 'getApplicationSupportDirectory') {
          return '/tmp/cache';
        }
        return null;
      });
  group('CrashSafeImageCacheConfig', () {
    test('default config has correct values', () {
      const config = CrashSafeImageCacheConfig.defaultConfig;
      expect(config.maxNrOfCacheObjects, equals(200));
      expect(config.stalePeriod, equals(const Duration(days: 30)));
      expect(config.repoKey, isNull);
    });

    test('aggressive config has correct values', () {
      const config = CrashSafeImageCacheConfig.aggressive;
      expect(config.maxNrOfCacheObjects, equals(500));
      expect(config.stalePeriod, equals(const Duration(days: 90)));
    });

    test('conservative config has correct values', () {
      const config = CrashSafeImageCacheConfig.conservative;
      expect(config.maxNrOfCacheObjects, equals(50));
      expect(config.stalePeriod, equals(const Duration(days: 7)));
    });

    test('minimal config has correct values', () {
      const config = CrashSafeImageCacheConfig.minimal;
      expect(config.maxNrOfCacheObjects, equals(20));
      expect(config.stalePeriod, equals(const Duration(days: 1)));
    });

    test('custom config can be created', () {
      const config = CrashSafeImageCacheConfig(
        maxNrOfCacheObjects: 100,
        stalePeriod: Duration(days: 15),
        repoKey: 'customCache',
      );
      expect(config.maxNrOfCacheObjects, equals(100));
      expect(config.stalePeriod, equals(const Duration(days: 15)));
      expect(config.repoKey, equals('customCache'));
    });
  });

  group('CrashSafeImageCache', () {
    test('configure updates global config', () {
      const customConfig = CrashSafeImageCacheConfig(
        maxNrOfCacheObjects: 150,
        stalePeriod: Duration(days: 20),
      );

      CrashSafeImageCache.configure(customConfig);

      expect(CrashSafeImageCache.config.maxNrOfCacheObjects, equals(150));
      expect(
        CrashSafeImageCache.config.stalePeriod,
        equals(const Duration(days: 20)),
      );
    });

    test('getStats returns cache statistics', () async {
      const config = CrashSafeImageCacheConfig(
        maxNrOfCacheObjects: 300,
        stalePeriod: Duration(days: 45),
      );
      CrashSafeImageCache.configure(config);

      final stats = await CrashSafeImageCache.getStats();
      expect(stats['maxObjects'], equals(300));
      expect(stats['stalePeriod'], equals(45));
    });

    test('equal configs compare equal and share a storage key', () {
      const a = CrashSafeImageCacheConfig(maxNrOfCacheObjects: 42);
      const b = CrashSafeImageCacheConfig(maxNrOfCacheObjects: 42);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.effectiveRepoKey, equals(b.effectiveRepoKey));
    });

    test('different presets get different storage keys', () {
      expect(
        CrashSafeImageCacheConfig.defaultConfig.effectiveRepoKey,
        equals('crashSafeImageCache'),
      );
      expect(
        CrashSafeImageCacheConfig.aggressive.effectiveRepoKey,
        isNot(CrashSafeImageCacheConfig.conservative.effectiveRepoKey),
      );
      expect(
        const CrashSafeImageCacheConfig(repoKey: 'mine').effectiveRepoKey,
        equals('mine'),
      );
    });

    test('getCacheManager honors per-call config over global config', () {
      CrashSafeImageCache.configure(CrashSafeImageCacheConfig.minimal);

      final global = CrashSafeImageCache.getCacheManager();
      final perWidget = CrashSafeImageCache.getCacheManager(
        CrashSafeImageCacheConfig.aggressive,
      );

      expect(global.config.maxNrOfCacheObjects, equals(20));
      expect(perWidget.config.maxNrOfCacheObjects, equals(500));
      expect(perWidget.config.stalePeriod, equals(const Duration(days: 90)));
    });

    test('getCacheManager reuses one instance per config', () {
      final first = CrashSafeImageCache.getCacheManager(
        const CrashSafeImageCacheConfig(maxNrOfCacheObjects: 77),
      );
      final second = CrashSafeImageCache.getCacheManager(
        const CrashSafeImageCacheConfig(maxNrOfCacheObjects: 77),
      );
      expect(identical(first, second), isTrue);
    });
  });
}
