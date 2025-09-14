// ─────────────────────────────────────────────────────────────────────────────
// CrashSafeImage — with SVG support (network/asset/file/memory) + svgString()
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // AssetBundle
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

// WHAT'S NEW:
//   • [SVG SUPPORT] Auto-detects and renders SVG via flutter_svg for network/asset/file/memory
//   • [NEW] factory CrashSafeImage.svgString('<svg ...>')
//   • Shared placeholder + error handling pathways
//   • Provider is now NEVER-NULL (transparent 1×1 fallback)

/// ======  Example usages of CrashSafeImage =======

/// 🔹 Network image (auto-detects from http/https)
/*CrashSafeImage(
  'https://cdn4.iconfinder.com/data/icons/flat-brand-logo-2/512/visa-512.png',
  width: 35,
  height: 24,
);

/// 🔹 Asset image (no scheme → asset)
CrashSafeImage(
  'assets/images/logo.png',
  width: 40,
  height: 40,
);

/// 🔹 File image (absolute/local file path or file://)
CrashSafeImage(
  '/storage/emulated/0/Download/picture.jpg',
  width: 100,
  height: 100,
);

/// 🔹 Memory image (provide raw bytes directly)
CrashSafeImage(
  null,
  bytes: myUint8List,
  width: 100,
  height: 100,
);

/// 🔹 Using as ImageProvider
CircleAvatar(
  radius: 30,
  backgroundImage: CrashSafeImage(
    'https://cdn4.iconfinder.com/data/icons/flat-brand-logo-2/512/visa-512.png',
  ).provider,
);

/// 🔹 With error & placeholder overrides
CrashSafeImage(
  'https://invalid-url.com/broken.png',
  width: 80,
  height: 80,
  placeholderBuilder: (_) => const Center(child: Text('Loading...')),
  errorBuilder:     (_) => const Icon(Icons.error, color: Colors.red),
);
*/

const String _kTransparentPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABJwNfWQAAAABJRU5ErkJggg==';
final Uint8List _kTransparentPngBytes = base64Decode(_kTransparentPngBase64);
final ImageProvider<Object> _kTransparentImageProvider = MemoryImage(
  _kTransparentPngBytes,
);

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

  // ───────────────────────────────────────────────────────────────────────────
  // [NEW] Create from raw SVG string
  // ───────────────────────────────────────────────────────────────────────────
  factory CrashSafeImage.svgString(
    String rawSvg, {
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    BorderRadius? borderRadius,
    Clip clipBehavior = Clip.hardEdge,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    WidgetBuilder? placeholderBuilder,
    WidgetBuilder? errorBuilder,
    Map<String, String>? httpHeaders,
    String? cacheKey,
    Duration fadeInDuration = const Duration(milliseconds: 250),
    Duration fadeOutDuration = const Duration(milliseconds: 250),
    AssetBundle? bundle,
    String? package,
  }) {
    final bytes = Uint8List.fromList(rawSvg.codeUnits);
    return CrashSafeImage(
      null,
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      borderRadius: borderRadius,
      clipBehavior: clipBehavior,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      placeholderBuilder: placeholderBuilder,
      errorBuilder: errorBuilder,
      httpHeaders: httpHeaders,
      cacheKey: cacheKey,
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      bundle: bundle,
      package: package,
      bytes: bytes,
    );
  }

  /// ImageProvider<Object> (NEVER-NULL):
  /// - Memory SVG / Null / Empty / SVG path/url → returns transparent 1×1 PNG
  /// - Otherwise returns appropriate raster provider
  ImageProvider<Object> get provider {
    // return type: non-nullable
    // Memory image
    if (bytes != null && bytes!.isNotEmpty) {
      if (_looksLikeSvgFromBytes(bytes)) {
        return _kTransparentImageProvider; //  used to be null
      }
      return MemoryImage(bytes!);
    }

    // Null/empty → transparent
    if (name == null || name!.trim().isEmpty) {
      return _kTransparentImageProvider; //  used to be null
    }
    final src = name!.trim();

    // SVG path/url → transparent
    if (_looksLikeSvgFromPath(src)) {
      return _kTransparentImageProvider; // used to be null
    }

    // Network (raster)
    final uri = Uri.tryParse(src);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return CachedNetworkImageProvider(
        src,
        headers: httpHeaders,
        cacheKey: cacheKey,
      );
    }

    // File (raster)
    if (src.startsWith('file://')) {
      return FileImage(File.fromUri(Uri.parse(src)));
    }
    if (FileSystemEntity.typeSync(src) != FileSystemEntityType.notFound) {
      return FileImage(File(src));
    }

    // Asset (raster) — if not found at runtime, Flutter will surface error via logs
    return AssetImage(src, package: package);
  }

  // (Optional helpers provider  safe)
  ImageProvider<Object> providerOr(ImageProvider<Object> fallback) {
    return provider; // provider already never-null; fallback unused
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

  // [SVG SUPPORT] — Detect SVG by path/URL
  bool _looksLikeSvgFromPath(String? path) {
    if (path == null) return false;
    final p = path.toLowerCase().trim();
    return p.endsWith('.svg') || p.contains('.svg?') || p.contains('.svg#');
  }

  // [SVG SUPPORT] — Detect SVG by memory bytes (peek first ~128 bytes)
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

  // [SVG SUPPORT] — Wrap with opacity for SVG (flutter_svg lacks opacity param)
  Widget _maybeWrapOpacity(Widget child) {
    if (opacity == null) return child;
    return Opacity(opacity: opacity!.value, child: child);
  }

  // [SVG SUPPORT] — Derive a ColorFilter for SVG tinting from color/colorBlendMode
  ColorFilter? get _svgColorFilter {
    if (color == null) return null;
    return ColorFilter.mode(color!, colorBlendMode ?? BlendMode.srcIn);
  }

  @override
  Widget build(BuildContext context) {
    final src = name?.trim();

    // Case 1: memory
    if (bytes != null && bytes!.isNotEmpty) {
      // SVG bytes → SvgPicture.memory
      if (_looksLikeSvgFromBytes(bytes)) {
        final svg = SvgPicture.memory(
          bytes!,
          width: width,
          height: height,
          fit: fit ?? BoxFit.contain,
          alignment: alignment,
          colorFilter: _svgColorFilter,
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

    // Decide SVG by path once
    final isSvgPath = _looksLikeSvgFromPath(src);

    // Case 3: network
    final uri = Uri.tryParse(src);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      if (isSvgPath) {
        final widget = SvgPicture.network(
          src,
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

      // Raster network
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
          errorWidget: (ctx, _, __) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 4: file
    final isFilePath =
        src.startsWith('file://') ||
        FileSystemEntity.typeSync(src) != FileSystemEntityType.notFound;

    if (isFilePath) {
      if (isSvgPath) {
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

      // Raster file
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
          errorBuilder: (ctx, _, __) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 5: asset
    if (isSvgPath) {
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

    // Raster asset
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
        errorBuilder: (ctx, _, __) =>
            errorBuilder?.call(ctx) ?? _defaultError(ctx),
      ),
    );
  }
}
