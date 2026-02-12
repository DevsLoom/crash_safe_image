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

    // Note: Tests that require CacheManager instantiation are skipped
    // because they require full Flutter runtime environment with
    // platform channels and database factory initialization.
    // These are tested through integration tests and widget tests.
  });
}
