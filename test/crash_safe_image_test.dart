import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A valid 1x1 transparent PNG (8-bit RGBA)
final Uint8List kTransparentPng = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x60,
  0x00,
  0x02,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0xE2,
  0x26,
  0x05,
  0x9B,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('CrashSafeImage', () {
    testWidgets('Empty or null source -> shows custom errorBuilder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CrashSafeImage('', errorBuilder: (_) => const Text('ERR_EMPTY'))),
      );
      await tester.pump(); // allow a build frame
      expect(find.text('ERR_EMPTY'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          CrashSafeImage(null, errorBuilder: (_) => const Text('ERR_NULL')),
        ),
      );
      await tester.pump();
      expect(find.text('ERR_NULL'), findsOneWidget);
    });

    testWidgets('Memory bytes render without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CrashSafeImage(null, bytes: kTransparentPng, width: 10, height: 10),
        ),
      );
      await tester.pumpAndSettle();
      // We expect an Image to be present (rendered from memory)
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Invalid asset path -> custom errorBuilder appears', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CrashSafeImage(
            'assets/does_not_exist.png',
            errorBuilder: (_) => const Text('ERR_ASSET'),
          ),
        ),
      );
      // Give Flutter time to attempt resolving asset & fall back
      await tester.pumpAndSettle();
      expect(find.text('ERR_ASSET'), findsOneWidget);
    });

    testWidgets('Network URL -> uses CachedNetworkImage widget', (
      tester,
    ) async {
      const url = 'https://example.com/fake.png';
      await tester.pumpWidget(_wrap(CrashSafeImage(url)));
      await tester.pump(); // build first frame

      // Assert the CachedNetworkImage is present (it may render an Image internally)
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });
}
