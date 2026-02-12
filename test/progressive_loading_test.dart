// test/progressive_loading_test.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progressive Loading', () {
    testWidgets('accepts thumbnailUrl and useProgressiveLoading parameters',
        (tester) async {
      const mainUrl = 'https://example.com/image.jpg';
      const thumbUrl = 'https://example.com/thumb.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              mainUrl,
              thumbnailUrl: thumbUrl,
              useProgressiveLoading: true,
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
    });

    testWidgets('works without progressive loading when not enabled',
        (tester) async {
      const mainUrl = 'https://example.com/image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              mainUrl,
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsWidgets);
    });

    testWidgets('svgString factory includes progressive loading parameters',
        (tester) async {
      const svgContent = '<svg></svg>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage.svgString(
              svgContent,
              thumbnailUrl: 'https://example.com/thumb.jpg',
              useProgressiveLoading: true,
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
    });
  });
}
