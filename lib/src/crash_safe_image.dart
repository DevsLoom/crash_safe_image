import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:typed_data';

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
      return MemoryImage(bytes!);
    }

    // Null/empty
    if (name == null || name!.trim().isEmpty) return null;
    final src = name!.trim();

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

  @override
  Widget build(BuildContext context) {
    final src = name?.trim();
    //final imgProvider = provider;

    // Case 1: memory
    if (bytes != null && bytes!.isNotEmpty) {
      return _sizedBox(
        context,
        Image.memory(
          bytes!,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment is Alignment
              ? alignment as Alignment
              : Alignment.center,
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

    // Case 3: network
    final uri = Uri.tryParse(src);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
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
