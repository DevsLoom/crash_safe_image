// ─────────────────────────────────────────────────────────────────────────────
// CrashSafeImage — with SVG support (network/asset/file/memory) + svgString()
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // AssetBundle
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'image_transformation.dart';
import 'cache_config.dart';

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

/// CrashSafeImage is a safe image widget that auto-detects source
/// (network, asset, file, memory, svg) with friendly placeholders,
/// error UI and caching for network images.
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

  // Progressive loading
  final String? thumbnailUrl;
  final bool useProgressiveLoading;

  // Transformations
  final List<ImageTransformation>? transformations;

  // Cache configuration
  final CrashSafeImageCacheConfig? cacheConfig;

  // Hero animations
  final Object? heroTag;

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
    this.thumbnailUrl,
    this.useProgressiveLoading = false,
    this.transformations,
    this.cacheConfig,
    this.heroTag,
    this.bundle,
    this.package,
    this.bytes,
  });

  // ───────────────────────────────────────────────────────────────────────────
  /// Create from raw SVG string
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
    String? thumbnailUrl,
    bool useProgressiveLoading = false,
    List<ImageTransformation>? transformations,
    CrashSafeImageCacheConfig? cacheConfig,
    Object? heroTag,
    AssetBundle? bundle,
    String? package,
  }) {
    final bytes = utf8.encode(rawSvg);
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
      thumbnailUrl: thumbnailUrl,
      useProgressiveLoading: useProgressiveLoading,
      transformations: transformations,
      cacheConfig: cacheConfig,
      heroTag: heroTag,
      bundle: bundle,
      package: package,
      bytes: bytes,
    );
  }

  /// ImageProvider<Object> (NEVER-NULL):
  /// - Memory SVG / Null / Empty / SVG path/url → returns transparent 1×1 PNG
  /// - Otherwise returns appropriate raster provider
  // Returns a safe [ImageProvider]. Never null; for null/invalid/SVG inputs
  /// it falls back to a 1×1 transparent image (assertion-safe).
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
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      return CachedNetworkImageProvider(
        src,
        headers: httpHeaders,
        cacheKey: cacheKey,
        cacheManager: CrashSafeImageCache.getCacheManager(cacheConfig),
      );
    }

    // File (raster) - safer file checks
    if (src.startsWith('file://')) {
      try {
        final file = File.fromUri(Uri.parse(src));
        return FileImage(file);
      } catch (_) {
        return _kTransparentImageProvider;
      }
    }

    // Check if it's a valid file path (safer approach)
    if (_looksLikeFilePath(src)) {
      return FileImage(File(src));
    }

    // Asset (raster) — if not found at runtime, Flutter will surface error via logs
    return AssetImage(src, package: package);
  }

  /// Like [provider], but returns [fallback] instead of the transparent 1×1
  /// image for null/empty sources and SVG inputs.
  ImageProvider<Object> providerOr(ImageProvider<Object> fallback) {
    final p = provider;
    return identical(p, _kTransparentImageProvider) ? fallback : p;
  }

  Widget _sizedBox(BuildContext context, Widget child) {
    Widget result = SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        clipBehavior: clipBehavior,
        child: child,
      ),
    );

    // Apply transformations if any
    result = _applyTransformations(result);

    // Apply Hero wrapper if heroTag is provided
    return _maybeWrapHero(result);
  }

  /// Apply image transformations to the widget
  Widget _applyTransformations(Widget child) {
    if (transformations == null || transformations!.isEmpty) {
      return child;
    }

    Widget result = child;

    for (final transform in transformations!) {
      if (transform is ResizeTransformation) {
        // Resize already handled by width/height, but we can override
        if (transform.width != null || transform.height != null) {
          result = SizedBox(
            width: transform.width ?? width,
            height: transform.height ?? height,
            child: FittedBox(
              fit: transform.fit ?? fit ?? BoxFit.contain,
              child: result,
            ),
          );
        }
      } else if (transform is CropTransformation) {
        // Apply crop using ClipRect
        result = ClipRect(
          clipper: _CropClipper(transform.cropRect),
          child: result,
        );
      }
    }

    return result;
  }

  // Default placeholder/error are bare content: they render inside an image
  // widget that is already framed by [_sizedBox], so wrapping them again would
  // nest a second Hero with the same tag and re-apply transformations.
  Widget _defaultPlaceholder(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }

  Widget _defaultError(BuildContext context) {
    return const Center(child: Icon(Icons.broken_image_rounded));
  }

  // Absolute paths are files; everything else without a scheme is an asset.
  // Decided from the string alone so build() never does blocking file I/O —
  // a missing file is reported through Image.file's errorBuilder instead.
  static final RegExp _windowsAbsolutePath = RegExp(r'^[a-zA-Z]:[\\/]');

  bool _looksLikeFilePath(String path) {
    return path.startsWith('/') ||
        path.startsWith(r'\\') ||
        _windowsAbsolutePath.hasMatch(path);
  }

  // [SVG SUPPORT] — Detect SVG by path/URL
  bool _looksLikeSvgFromPath(String? path) {
    if (path == null) return false;
    final p = path.toLowerCase().trim();

    // Check for .svg extension (but not if it's part of another extension)
    if (p.endsWith('.svg')) return true;

    // Check for .svg with query parameters or fragments
    final uri = Uri.tryParse(p);
    if (uri != null && uri.path.toLowerCase().endsWith('.svg')) {
      return true;
    }

    return false;
  }

  // [SVG SUPPORT] — Detect SVG by memory bytes (peek first ~256 bytes)
  bool _looksLikeSvgFromBytes(Uint8List? data) {
    if (data == null || data.isEmpty) return false;

    try {
      // Handle BOM and decode more bytes for better detection
      final peekSize = data.length < 256 ? data.length : 256;
      var startIndex = 0;

      // Skip BOM if present
      if (data.length >= 3 &&
          data[0] == 0xEF &&
          data[1] == 0xBB &&
          data[2] == 0xBF) {
        startIndex = 3;
      }

      final head = utf8
          .decode(data.sublist(startIndex, peekSize), allowMalformed: true)
          .trim();

      // More precise SVG detection
      final lowerHead = head.toLowerCase();
      return lowerHead.startsWith('<svg') ||
          lowerHead.startsWith('<?xml') && lowerHead.contains('<svg') ||
          lowerHead.startsWith('<!doctype svg');
    } catch (_) {
      return false;
    }
  }

  // [SVG SUPPORT] — Wrap with opacity for SVG (flutter_svg lacks opacity param)
  Widget _maybeWrapOpacity(Widget child) {
    if (opacity == null) return child;
    // FadeTransition listens to the animation; Opacity would freeze its value.
    return FadeTransition(opacity: opacity!, child: child);
  }

  // [HERO SUPPORT] — Wrap with Hero for page transitions
  Widget _maybeWrapHero(Widget child) {
    if (heroTag == null) return child;
    return Hero(tag: heroTag!, child: child);
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
          errorBuilder: (ctx, _, _) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 2: empty/null
    if (src == null || src.isEmpty) {
      return errorBuilder?.call(context) ??
          _sizedBox(context, _defaultError(context));
    }

    // Decide SVG by path once
    final isSvgPath = _looksLikeSvgFromPath(src);

    // Case 3: network
    final uri = Uri.tryParse(src);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      // CachedNetworkImage only takes Alignment; resolve directional values
      // (e.g. AlignmentDirectional.centerStart) against the ambient direction.
      final networkAlignment = alignment.resolve(
        Directionality.maybeOf(context) ?? TextDirection.ltr,
      );

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
      // Progressive loading: show thumbnail first if available
      if (useProgressiveLoading &&
          thumbnailUrl != null &&
          thumbnailUrl!.isNotEmpty) {
        return _sizedBox(
          context,
          CachedNetworkImage(
            imageUrl: src,
            width: width,
            height: height,
            fit: fit,
            alignment: networkAlignment,
            color: color,
            colorBlendMode: colorBlendMode,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration,
            filterQuality: FilterQuality.high,
            httpHeaders: httpHeaders,
            cacheKey: cacheKey,
            cacheManager: CrashSafeImageCache.getCacheManager(cacheConfig),
            placeholder: (ctx, _) {
              // Show thumbnail as placeholder
              return CachedNetworkImage(
                imageUrl: thumbnailUrl!,
                width: width,
                height: height,
                fit: fit,
                alignment: networkAlignment,
                fadeInDuration: const Duration(milliseconds: 150),
                fadeOutDuration: const Duration(milliseconds: 150),
                httpHeaders: httpHeaders,
                cacheManager: CrashSafeImageCache.getCacheManager(cacheConfig),
                placeholder: (c, _) =>
                    placeholderBuilder?.call(c) ?? _defaultPlaceholder(c),
                errorWidget: (c, _, _) =>
                    placeholderBuilder?.call(c) ?? _defaultPlaceholder(c),
              );
            },
            errorWidget: (ctx, _, _) =>
                errorBuilder?.call(ctx) ?? _defaultError(ctx),
          ),
        );
      }

      // Standard network loading
      return _sizedBox(
        context,
        CachedNetworkImage(
          imageUrl: src,
          width: width,
          height: height,
          fit: fit,
          alignment: networkAlignment,
          color: color,
          colorBlendMode: colorBlendMode,
          fadeInDuration: fadeInDuration,
          fadeOutDuration: fadeOutDuration,
          filterQuality: FilterQuality.high,
          httpHeaders: httpHeaders,
          cacheKey: cacheKey,
          cacheManager: CrashSafeImageCache.getCacheManager(cacheConfig),
          placeholder: (ctx, _) =>
              placeholderBuilder?.call(ctx) ?? _defaultPlaceholder(ctx),
          errorWidget: (ctx, _, _) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 4: file
    if (src.startsWith('file://')) {
      try {
        final file = File.fromUri(Uri.parse(src));
        if (isSvgPath) {
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
            file,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            color: color,
            opacity: opacity,
            colorBlendMode: colorBlendMode,
            filterQuality: FilterQuality.high,
            errorBuilder: (ctx, _, _) =>
                errorBuilder?.call(ctx) ?? _defaultError(ctx),
          ),
        );
      } catch (_) {
        return errorBuilder?.call(context) ??
            _sizedBox(context, _defaultError(context));
      }
    }

    // Check for regular file path
    if (_looksLikeFilePath(src)) {
      final file = File(src);
      if (isSvgPath) {
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
          file,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          opacity: opacity,
          colorBlendMode: colorBlendMode,
          filterQuality: FilterQuality.high,
          errorBuilder: (ctx, _, _) =>
              errorBuilder?.call(ctx) ?? _defaultError(ctx),
        ),
      );
    }

    // Case 5: asset (final fallback)
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

    // Raster asset (final fallback)
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
        filterQuality: FilterQuality.high,
        colorBlendMode: colorBlendMode,
        errorBuilder: (ctx, _, _) =>
            errorBuilder?.call(ctx) ?? _defaultError(ctx),
      ),
    );
  }
}

/// Custom clipper for crop transformation
class _CropClipper extends CustomClipper<Rect> {
  final Rect cropRect;

  _CropClipper(this.cropRect);

  @override
  Rect getClip(Size size) {
    return cropRect;
  }

  @override
  bool shouldReclip(covariant _CropClipper oldClipper) {
    return oldClipper.cropRect != cropRect;
  }
}
