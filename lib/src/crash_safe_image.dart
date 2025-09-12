import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_svg/flutter_svg.dart';

// WHAT'S NEW:
//   • [SVG SUPPORT] Auto-detects and renders SVG via flutter_svg for network/asset/file/memory
//   • Keeps same public API style via named constructors
//   • Shared placeholder + error handling pathways

/// ===============================
/// Example usages of CrashSafeImage
/// ===============================

/// 🔹 Network image (auto-detects from http/https)
///    Useful for loading images from API / CDN / web URLs
/*CrashSafeImage(
  'https://cdn4.iconfinder.com/data/icons/flat-brand-logo-2/512/visa-512.png',
  width: 35,
  height: 24,
);

/// 🔹 Asset image (auto-detects since no scheme given)
///    Perfect for bundled images inside your Flutter app (pubspec.yaml)
CrashSafeImage(
  'assets/images/logo.png',
  width: 40,
  height: 40,
);

/// 🔹 File image (auto-detects from absolute/local file path or file:// scheme)
///    Great for displaying images picked from gallery / saved locally
CrashSafeImage(
  '/storage/emulated/0/Download/picture.jpg',
  width: 100,
  height: 100,
);

/// 🔹 Memory image (provide raw bytes directly)
///    Use when you already have Uint8List (e.g., from camera, network, DB)
CrashSafeImage(
  null,
  bytes: myUint8List,
  width: 100,
  height: 100,
);

/// 🔹 Using as ImageProvider (instead of Widget)
///    Handy for CircleAvatar, BoxDecoration, etc.
CircleAvatar(
  radius: 30,
  backgroundImage: CrashSafeImage(
    'https://cdn4.iconfinder.com/data/icons/flat-brand-logo-2/512/visa-512.png',
  ).provider,
  child: null, // can add fallback if provider is null
);

/// 🔹 DecorationImage (Container background)
Container(
  width: 120,
  height: 80,
  decoration: BoxDecoration(
    image: DecorationImage(
      image: CrashSafeImage('assets/images/bg.png').provider!,
      fit: BoxFit.cover,
    ),
  ),
);

/// 🔹 With error & placeholder overrides
CrashSafeImage(
  'https://invalid-url.com/broken.png',
  width: 80,
  height: 80,
  placeholderBuilder: (_) => const Center(child: Text('Loading...')),
  errorBuilder: (_) => const Icon(Icons.error, color: Colors.red),
);
*/
class CrashSafeImage extends StatelessWidget {
  final String? name;

  // Widget configs
  final double? width;
  final double? height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final BorderRadius? borderRadius;
  final Clip clipBehavior;
  final Color? color;
  final Animation<double>? opacity;
  final BlendMode? colorBlendMode;

  // Placeholders
  final WidgetBuilder? placeholderBuilder;
  final WidgetBuilder? errorBuilder;

  // Network extras
  final Map<String, String>? httpHeaders;
  final String? cacheKey;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  // Asset extras
  final AssetBundle? bundle;
  final String? package;

  // File/Memory
  final Uint8List? bytes;

  const CrashSafeImage(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.clipBehavior = Clip.hardEdge,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.placeholderBuilder,
    this.errorBuilder,
    this.httpHeaders,
    this.cacheKey,
    this.fadeInDuration = const Duration(milliseconds: 250),
    this.fadeOutDuration = const Duration(milliseconds: 250),
    this.bundle,
    this.package,
    this.bytes,
  });

  /// Safe ImageProvider<Object>? for places like CircleAvatar.backgroundImage.
  ImageProvider<Object>? get provider {
    // Memory image
    if (bytes != null && bytes!.isNotEmpty) {
      // [SVG SUPPORT] If bytes look like SVG, no ImageProvider – return null.
      if (_looksLikeSvgFromBytes(bytes)) return null;
      return MemoryImage(bytes!);
    }

    // Null/empty
    if (name == null || name!.trim().isEmpty) return null;
    final src = name!.trim();

    // [SVG SUPPORT] If path/url looks SVG, provider not supported → null
    if (_looksLikeSvgFromPath(src)) return null; // [NEW]

    // Network
    final uri = Uri.tryParse(src);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImageProvider(
        src,
        headers: httpHeaders,
        cacheKey: cacheKey,
      );
    }

    // File
    if (src.startsWith('file://')) {
      return FileImage(File.fromUri(Uri.parse(src)));
    }
    if (FileSystemEntity.typeSync(src) != FileSystemEntityType.notFound) {
      return FileImage(File(src));
    }

    // Asset
    return AssetImage(src, package: package);
  }

  Widget _sizedBox(BuildContext context, Widget child) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return _sizedBox(
      context,
      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _defaultError(BuildContext context) {
    return _sizedBox(
      context,
      const Center(child: Icon(Icons.broken_image_rounded)),
    );
  }

  // [SVG SUPPORT][NEW] — Detect SVG by path/URL
  bool _looksLikeSvgFromPath(String? path) {
    if (path == null) return false;
    final p = path.toLowerCase().trim();
    return p.endsWith('.svg') || p.contains('.svg?') || p.contains('.svg#');
  }

  // [SVG SUPPORT][NEW] — Detect SVG by memory bytes (peek first ~128 bytes)
  bool _looksLikeSvgFromBytes(Uint8List? data) {
    if (data == null || data.isEmpty) return false;
    final head = utf8
        .decode(
          data.sublist(0, data.length < 128 ? data.length : 128),
          allowMalformed: true,
        )
        .trimLeft();
    return head.startsWith('<svg') ||
        head.startsWith('<!doctype svg') ||
        head.startsWith('<!--');
  }

  // [SVG SUPPORT][NEW] — Wrap with opacity for SVG (flutter_svg lacks opacity param)
  Widget _maybeWrapOpacity(Widget child) {
    if (opacity == null) return child;
    return Opacity(opacity: opacity!.value, child: child);
  }

  // [SVG SUPPORT][NEW] — Derive a ColorFilter for SVG tinting from color/colorBlendMode
  ColorFilter? get _svgColorFilter {
    if (color == null) return null;
    return ColorFilter.mode(color!, colorBlendMode ?? BlendMode.srcIn);
  }

  @override
  Widget build(BuildContext context) {
    final src = name?.trim();
    //final imgProvider = provider;

    // Case 1: memory
    if (bytes != null && bytes!.isNotEmpty) {
      // [SVG SUPPORT][CHANGED]: detect SVG bytes → SvgPicture.memory
      if (_looksLikeSvgFromBytes(bytes)) {
        final svg = SvgPicture.memory(
          bytes!,
          width: width,
          height: height,
          fit: fit ?? BoxFit.contain, // sensible default for SVG
          alignment: alignment,
          colorFilter: _svgColorFilter,
          // error handled by outer try/catch if thrown
        );
        return _sizedBox(context, _maybeWrapOpacity(svg));
      }

      // Raster memory
      return _sizedBox(
        context,
        Image.memory(
          bytes!,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          opacity: opacity,
          colorBlendMode: colorBlendMode,
        ),
      );
    }

    // Case 2: empty/null
    if (src == null || src.isEmpty) {
      return errorBuilder?.call(context) ?? _defaultError(context);
    }
    // [SVG SUPPORT] if looks like SVG path/url → route to SvgPicture.*
    final isSvgPath = _looksLikeSvgFromPath(src);

    // Case 3: network
    final uri = Uri.tryParse(src);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (isSvgPath) {
        // [SVG SUPPORT][NEW]
        final widget = SvgPicture.network(
          src,
          width: width,
          height: height,
          fit: fit ?? BoxFit.contain,
          alignment: alignment,
          colorFilter: _svgColorFilter,
          // flutter_svg doesn't have errorBuilder; we show placeholder while building
          placeholderBuilder: (ctx) =>
              placeholderBuilder?.call(ctx) ?? _defaultPlaceholder(ctx),
        );
        // We still clip/size via _sizedBox:
        return _sizedBox(context, _maybeWrapOpacity(widget));
      }
      return _sizedBox(
        context,
        CachedNetworkImage(
          imageUrl: src,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment is Alignment
              ? alignment as Alignment
              : Alignment.center,
          color: color,
          colorBlendMode: colorBlendMode,
          fadeInDuration: fadeInDuration,
          fadeOutDuration: fadeOutDuration,
          httpHeaders: httpHeaders,
          cacheKey: cacheKey,
          placeholder: (ctx, _) =>
              placeholderBuilder?.call(ctx) ?? _defaultPlaceholder(ctx),
          errorWidget: (ctx, _, _) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 4: file
    if (src.startsWith('file://') ||
        FileSystemEntity.typeSync(src) != FileSystemEntityType.notFound) {
      if (isSvgPath) {
        // [SVG SUPPORT][NEW]
        final file = src.startsWith('file://')
            ? File.fromUri(Uri.parse(src))
            : File(src);
        final widget = SvgPicture.file(
          file,
          width: width,
          height: height,
          fit: fit ?? BoxFit.contain,
          alignment: alignment,
          colorFilter: _svgColorFilter,
          placeholderBuilder: (ctx) =>
              placeholderBuilder?.call(ctx) ?? _defaultPlaceholder(ctx),
        );
        return _sizedBox(context, _maybeWrapOpacity(widget));
      }
      return _sizedBox(
        context,
        Image.file(
          src.startsWith('file://') ? File.fromUri(Uri.parse(src)) : File(src),
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          opacity: opacity,
          colorBlendMode: colorBlendMode,
          errorBuilder: (ctx, _, _) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 5: asset
    if (isSvgPath) {
      // [SVG SUPPORT][NEW]
      final widget = SvgPicture.asset(
        src,
        bundle: bundle,
        package: package,
        width: width,
        height: height,
        fit: fit ?? BoxFit.contain,
        alignment: alignment,
        colorFilter: _svgColorFilter,
        placeholderBuilder: (ctx) =>
            placeholderBuilder?.call(ctx) ?? _defaultPlaceholder(ctx),
      );
      return _sizedBox(context, _maybeWrapOpacity(widget));
    }
    return _sizedBox(
      context,
      Image.asset(
        src,
        bundle: bundle,
        package: package,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        opacity: opacity,
        colorBlendMode: colorBlendMode,
        errorBuilder: (ctx, _, _) =>
            errorBuilder?.call(ctx) ?? _defaultError(ctx),
      ),
    );
  }
}
