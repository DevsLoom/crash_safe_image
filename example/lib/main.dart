// example/lib/main.dart
import 'dart:convert'; // for base64 -> bytes
import 'dart:typed_data'; // for Uint8List
import 'dart:io' show File; // for File (non-web targets only)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:crash_safe_image/crash_safe_image.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrashSafeImage — Full Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Tiny 1x1 PNG (transparent) — just to demo bytes/memory
  Uint8List get tinyPngBytes => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQAB'
    'JwNfWQAAAABJRU5ErkJggg==',
  );

  @override
  Widget build(BuildContext context) {
    const goodUrl = 'https://picsum.photos/400/220';
    const badUrl = 'https://example.com/this-will-404.png';

    return Scaffold(
      appBar: AppBar(title: const Text('CrashSafeImage — Kitchen Sink')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: '1) Network (good) + placeholder/error + fade + radius',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CrashSafeImage(
                goodUrl,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 250),
                fadeOutDuration: const Duration(milliseconds: 250),
                placeholderBuilder: (_) => const _ShimmerishBox(),
                errorBuilder: (_) => _ErrorBox('Could not load image'),
              ),
            ),
          ),

          _Section(
            title: '2) Network (bad) — graceful error UI',
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: CrashSafeImage(
                badUrl,
                fit: BoxFit.cover,
                errorBuilder: (_) => _ErrorBox('404 / 400 → Fallback UI'),
              ),
            ),
          ),

          _Section(
            title: '3) With HTTP headers & custom cacheKey',
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child: CrashSafeImage(
                goodUrl,
                cacheKey: 'hero-header:v1',
                httpHeaders: const {'Accept': 'image/*'},
                fit: BoxFit.cover,
                placeholderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_) => _ErrorBox('Header request failed'),
              ),
            ),
          ),

          _Section(
            title: '4) Memory (bytes) — tiny PNG',
            child: Row(
              children: [
                CrashSafeImage(
                  null,
                  bytes: tinyPngBytes,
                  width: 60,
                  height: 60,
                  color: Colors.indigo, // tint
                  colorBlendMode: BlendMode.srcATop, // blend
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'A 1×1 transparent PNG rendered from memory bytes with tint.',
                  ),
                ),
              ],
            ),
          ),

          _Section(
            title: '5) Asset',
            child: Row(
              children: [
                CrashSafeImage(
                  'assets/logo.png', // add in example/pubspec.yaml
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (_) =>
                      _ErrorBox('Missing asset? Add to pubspec.'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Asset image (remember to declare in example/pubspec.yaml).',
                  ),
                ),
              ],
            ),
          ),

          if (!kIsWeb)
            _Section(
              title: '6) File (non-web) — if file exists',
              child: FutureBuilder<bool>(
                future: _exampleFileExists(),
                builder: (context, snap) {
                  final exists = snap.data ?? false;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 80,
                        child: exists
                            ? CrashSafeImage(
                                _exampleFilePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_) =>
                                    _ErrorBox('Could not read file'),
                              )
                            : _ErrorBox('Demo file not found'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(
                          exists
                              ? 'Loaded from local file path:\n${_wrapForBreaks(_exampleFilePath)}'
                              : 'Place an image at:\n${_wrapForBreaks(_exampleFilePath)}',
                          //softWrap: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          _Section(
            title: '7) CircleAvatar — assertion-safe (provider is never null)',
            child: const Row(
              children: [
                DemoAvatar(url: 'https://i.pravatar.cc/150?img=5'),
                SizedBox(width: 16),
                DemoAvatar(url: 'https://example.com/does-not-exist.png'),
                SizedBox(width: 16),
                DemoAvatar(url: null), // API returned null → still safe
              ],
            ),
          ),

          _Section(
            title:
                '8) DecorationImage (Container bg) — safe fallback via onError',
            child: const SafeDecoratedBox(
              url:
                  'https://example.com/broken-bg.jpg', // will fallback to grey color
              height: 120,
              child: Center(child: Text('Fallback color if background fails')),
            ),
          ),

          _Section(
            title:
                '9) Stack background via widget (easiest full-control fallback)',
            child: SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CrashSafeImage(
                    goodUrl,
                    fit: BoxFit.cover,
                    placeholderBuilder: (_) => const _ShimmerishBox(),
                    errorBuilder: (_) => Container(color: Colors.grey.shade300),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Overlay content',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- File demo helpers (non-web) ----
  static String get _exampleFilePath {
    // For Android emulator, e.g. '/sdcard/Download/demo.jpg'
    // For macOS/iOS dev, set a valid path on your machine.
    return '/sdcard/Download/demo.jpg';
  }

  Future<bool> _exampleFileExists() async {
    try {
      final f = File(_exampleFilePath);
      return await f.exists();
    } catch (_) {
      return false;
    }
  }
}

// ---------- Widgets & Helpers ----------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ShimmerishBox extends StatelessWidget {
  const _ShimmerishBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('Loading…'),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

// ---- Helper for wrapping very long paths/URLs inside Row ----
String _wrapForBreaks(String s) => s.replaceAll('/', '/\u200B');

// ---- CircleAvatar demo using never-null provider ----
class DemoAvatar extends StatefulWidget {
  const DemoAvatar({super.key, required this.url});
  final String? url;

  @override
  State<DemoAvatar> createState() => _DemoAvatarState();
}

class _DemoAvatarState extends State<DemoAvatar> {
  bool _broken = false;

  @override
  Widget build(BuildContext context) {
    // provider is NEVER null now (transparent fallback on null/invalid/SVG)
    final img = CrashSafeImage(widget.url).provider;

    // Show overlay fallback icon when:
    //  - URL is null (API returned null), OR
    //  - actual fetch/decoding fails (onBackgroundImageError)
    final overlayNeeded = widget.url == null || _broken;

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: img, // ← never null, so assertion-safe
      onBackgroundImageError: (exception, stack) {
        if (!mounted) return;
        setState(() => _broken = true);
      },
      child: overlayNeeded ? const Icon(Icons.person, size: 28) : null,
    );
  }
}

// ---- DecorationImage safe provider pattern ----
class SafeDecoratedBox extends StatefulWidget {
  const SafeDecoratedBox({
    super.key,
    required this.url,
    required this.height,
    this.child,
    this.borderRadius = 12,
  });

  final String url;
  final double height;
  final double borderRadius;
  final Widget? child;

  @override
  State<SafeDecoratedBox> createState() => _SafeDecoratedBoxState();
}

class _SafeDecoratedBoxState extends State<SafeDecoratedBox> {
  bool _bgBroken = false;

  @override
  Widget build(BuildContext context) {
    // provider is never null; onError swaps to fallback color
    final provider = CrashSafeImage(widget.url).provider;

    return Container(
      height: widget.height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: _bgBroken ? Colors.grey.shade200 : null, // fallback color
        image: _bgBroken
            ? null
            : DecorationImage(
                image: provider,
                fit: BoxFit.cover,
                onError: (_, __) =>
                    mounted ? setState(() => _bgBroken = true) : null,
              ),
      ),
      child: widget.child,
    );
  }
}
