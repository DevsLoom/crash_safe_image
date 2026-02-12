// test/hero_animations_test.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crash_safe_image/crash_safe_image.dart';

void main() {
  group('Hero Animations', () {
    testWidgets('CrashSafeImage without heroTag does not wrap with Hero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              'assets/test_image.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      // Should not find Hero widget
      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('CrashSafeImage with heroTag wraps with Hero', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              'assets/test_image.png',
              width: 100,
              height: 100,
              heroTag: 'test_hero',
            ),
          ),
        ),
      );

      // Should find Hero widget
      expect(find.byType(Hero), findsOneWidget);

      // Verify Hero tag
      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, equals('test_hero'));
    });

    testWidgets('Hero tag can be an integer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              'assets/test_image.png',
              width: 100,
              height: 100,
              heroTag: 123,
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, equals(123));
    });

    testWidgets('Hero transitions work between pages', (
      WidgetTester tester,
    ) async {
      const String heroTag = 'shared_image';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CrashSafeImage(
                  'assets/test_image.png',
                  width: 100,
                  height: 100,
                  heroTag: heroTag,
                ),
                ElevatedButton(onPressed: () {}, child: const Text('Navigate')),
              ],
            ),
          ),
        ),
      );

      // Initial page should have Hero
      expect(find.byType(Hero), findsOneWidget);

      // Simulate navigation
      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            body: CrashSafeImage(
                              'assets/test_image.png',
                              width: 300,
                              height: 300,
                              heroTag: heroTag,
                            ),
                          ),
                        ),
                      );
                    },
                    child: CrashSafeImage(
                      'assets/test_image.png',
                      width: 100,
                      height: 100,
                      heroTag: heroTag,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Should still have Hero on first page
      expect(find.byType(Hero), findsOneWidget);
    });

    testWidgets('Memory image with Hero tag works', (
      WidgetTester tester,
    ) async {
      // Use a valid 1x1 transparent PNG
      const String transparentPngBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABJwNfWQAAAABJRU5ErkJggg==';
      final Uint8List bytes = base64Decode(transparentPngBase64);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              null,
              bytes: bytes,
              width: 100,
              height: 100,
              heroTag: 'memory_hero',
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, equals('memory_hero'));
    });

    testWidgets('Hero with transformations applied', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              'assets/test_image.png',
              width: 100,
              height: 100,
              heroTag: 'transformed_hero',
              transformations: [ResizeTransformation(200, 200)],
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);

      // Verify Hero contains our image with transformations
      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, equals('transformed_hero'));
      expect(hero.child, isNotNull);
    });

    testWidgets('Hero with svgString factory', (WidgetTester tester) async {
      const String svgContent = '<svg width="100" height="100"></svg>';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage.svgString(
              svgContent,
              width: 100,
              height: 100,
              heroTag: 'svg_hero',
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);
      final Hero hero = tester.widget(find.byType(Hero));
      expect(hero.tag, equals('svg_hero'));
    });
  });
}
