// test/transformations_test.dart
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Image Transformations', () {
    testWidgets('accepts resize transformation', (tester) async {
      const url = 'https://example.com/image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              url,
              transformations: [
                ImageTransformation.resize(200, 200, fit: BoxFit.cover),
              ],
              width: 300,
              height: 300,
            ),
          ),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
    });

    testWidgets('accepts crop transformation', (tester) async {
      const url = 'https://example.com/image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              url,
              transformations: [
                ImageTransformation.crop(const Rect.fromLTWH(0, 0, 100, 100)),
              ],
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
    });

    testWidgets('accepts multiple transformations', (tester) async {
      const url = 'https://example.com/image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrashSafeImage(
              url,
              transformations: [
                ImageTransformation.resize(150, 150),
                ImageTransformation.crop(const Rect.fromLTWH(10, 10, 130, 130)),
              ],
              width: 200,
              height: 200,
            ),
          ),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
    });

    test('ResizeTransformation has correct type', () {
      final transform = ImageTransformation.resize(100, 100);
      expect(transform.type, ImageTransformationType.resize);
      expect(transform, isA<ResizeTransformation>());
    });

    test('CropTransformation has correct type', () {
      final transform = ImageTransformation.crop(
        const Rect.fromLTWH(0, 0, 50, 50),
      );
      expect(transform.type, ImageTransformationType.crop);
      expect(transform, isA<CropTransformation>());
    });

    testWidgets('works without transformations', (tester) async {
      const url = 'https://example.com/image.jpg';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CrashSafeImage(url, width: 200, height: 200)),
        ),
      );

      expect(find.byType(CrashSafeImage), findsOneWidget);
    });
  });
}
