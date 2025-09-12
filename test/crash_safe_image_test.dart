// test/crash_safe_image_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crash_safe_image/crash_safe_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

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
  group('CrashSafeImage (raster baseline)', () {
    testWidgets('Empty or null source -> shows custom errorBuilder', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(CrashSafeImage('', errorBuilder: (_) => const Text('ERR_EMPTY'))),
      );
      await tester.pump();
      expect(find.text('ERR_EMPTY'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          CrashSafeImage(null, errorBuilder: (_) => const Text('ERR_NULL')),
        ),
      );
      await tester.pump();
      expect(find.text('ERR_NULL'), findsOneWidget);
    });

    testWidgets('Memory bytes (PNG) render without throwing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CrashSafeImage(null, bytes: kTransparentPng, width: 10, height: 10),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Invalid asset path (PNG) -> custom errorBuilder appears', (
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
      await tester.pumpAndSettle();
      expect(find.text('ERR_ASSET'), findsOneWidget);
    });

    testWidgets('Network raster URL -> uses CachedNetworkImage widget', (
      tester,
    ) async {
      const url = 'https://example.com/fake.png';
      await tester.pumpWidget(_wrap(CrashSafeImage(url)));
      await tester.pump(); // first frame
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });
  });

  group('CrashSafeImage (SVG support)', () {
    testWidgets('Network SVG URL -> renders SvgPicture (mocked HTTP)', (
      tester,
    ) async {
      const url = 'https://example.com/icon.svg';
      const svgOk =
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
          '<rect width="24" height="24"/></svg>';

      await HttpOverrides.runZoned(() async {
        await tester.pumpWidget(
          _wrap(CrashSafeImage(url, width: 24, height: 24)),
        );

        // a couple of finite pumps to allow async loader to finish
        await tester.pump(const Duration(milliseconds: 40));
        await tester.pump(const Duration(milliseconds: 40));

        expect(find.byType(SvgPicture), findsOneWidget);
      }, createHttpClient: (_) => _FakeHttpClient(svgOk));
    });

    testWidgets('SVG raw string -> renders SvgPicture', (tester) async {
      const raw =
          '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
          '<rect width="24" height="24"/></svg>';
      await tester.pumpWidget(
        _wrap(CrashSafeImage.svgString(raw, width: 24, height: 24)),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('SVG bytes -> renders SvgPicture', (tester) async {
      final svgBytes = Uint8List.fromList(
        ('<svg viewBox="0 0 10 10" xmlns="http://www.w3.org/2000/svg">'
                '<circle cx="5" cy="5" r="5"/></svg>')
            .codeUnits,
      );
      await tester.pumpWidget(
        _wrap(CrashSafeImage(null, bytes: svgBytes, width: 16, height: 16)),
      );
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });

  group('CrashSafeImage (provider & passthrough)', () {
    test('provider returns null for SVG paths', () {
      final svgProvider = CrashSafeImage('assets/icons/logo.svg').provider;
      expect(svgProvider, isNull);
    });

    testWidgets(
      'Network raster passes httpHeaders & cacheKey to CachedNetworkImage',
      (tester) async {
        const url = 'https://example.com/pic.png';
        await tester.pumpWidget(
          _wrap(
            CrashSafeImage(
              url,
              httpHeaders: const {'Authorization': 'Bearer TOKEN'},
              cacheKey: 'k1',
            ),
          ),
        );
        await tester.pump();

        final matches = tester
            .widgetList(find.byType(CachedNetworkImage))
            .where((w) {
              final c = w as CachedNetworkImage;
              return c.imageUrl == url &&
                  c.cacheKey == 'k1' &&
                  c.httpHeaders?['Authorization'] == 'Bearer TOKEN';
            });
        expect(matches.length, 1);
      },
    );
  });
}

/// -------------------- HTTP MOCK HELPERS --------------------
class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.svgBody);
  final String svgBody;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpRequest(svgBody, method: method, uri: url);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpRequest(svgBody, method: 'GET', uri: url);
  }

  // ✅ NEW: IOClient.close(force: true) সাপোর্ট
  @override
  void close({bool force = false}) {
    // nothing to dispose in this fake
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  _FakeHttpRequest(this.svgBody, {required this.method, required this.uri});
  final String svgBody;

  @override
  final String method;

  @override
  final Uri uri;

  final _headers = _FakeHttpHeaders();
  final List<int> _buffer = [];

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = false;

  @override
  int contentLength = -1;

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      _buffer.addAll(chunk);
    }
  }

  @override
  void add(List<int> data) => _buffer.addAll(data);

  @override
  void write(Object? obj) => add(utf8.encode(obj?.toString() ?? ''));

  @override
  Future<void> flush() async {}

  @override
  Future<HttpClientResponse> get done async => close();

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpResponse(utf8.encode(svgBody));
  }

  @override
  Encoding encoding = utf8;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpResponse(this._bytes);
  final List<int> _bytes;

  // ---- values IOClient/clients read ----
  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  bool get persistentConnection => false;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  int get contentLength => _bytes.length;

  @override
  final HttpHeaders headers = _FakeHttpHeaders()
    ..set('content-type', 'image/svg+xml; charset=utf-8');

  @override
  List<Cookie> get cookies => const [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;
  // --------------------------------------

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    return controller;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _map = {};

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _map[name.toLowerCase()] = [value.toString()];
  }

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    final k = name.toLowerCase();
    _map.putIfAbsent(k, () => []);
    _map[k]!.add(value.toString());
  }

  // IOClient copies headers via forEach(...)
  @override
  void forEach(void Function(String name, List<String> values) action) {
    _map.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _map[name.toLowerCase()];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
