import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crash_safe_image/crash_safe_image.dart';

void main() {
  group('CrashSafeImage Widget Tests', () {
    testWidgets('Empty string should show error icon', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: CrashSafeImage('')));

      // Expect the default error icon when the image path is empty
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('Null name with bytes should render memory image', (
      tester,
    ) async {
      // Provide a simple byte array (dummy Uint8List)
      final bytes = Uint8List.fromList([0, 0, 0, 0]);

      await tester.pumpWidget(
        MaterialApp(
          home: CrashSafeImage(null, bytes: bytes, width: 10, height: 10),
        ),
      );

      // Expect an Image widget rendered from memory bytes
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Invalid asset path should show error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrashSafeImage('assets/invalid.png')),
      );

      // Try to load an invalid asset, should eventually fall back to error icon
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('Network URL should render CachedNetworkImage', (tester) async {
      const url = 'https://example.com/fake.png';

      await tester.pumpWidget(const MaterialApp(home: CrashSafeImage(url)));

      // A CachedNetworkImage should be used for network URLs
      expect(find.byType(Image), findsNothing);
    });
  });
}
