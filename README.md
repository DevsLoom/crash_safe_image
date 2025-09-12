# crash_safe_image

[![pub version](https://img.shields.io/pub/v/crash_safe_image.svg)](https://pub.dev/packages/crash_safe_image)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/DevsLoom/crash_safe_image.svg?style=social)](https://github.com/DevsLoom/crash_safe_image)

Crash‑safe image widget for Flutter. It **auto‑detects** image source (network / asset / file / memory), shows **friendly placeholders & error UI**, and uses `cached_network_image` for smart caching.

> Minimal API · Safe defaults · Drop‑in replacement for many `Image.*` cases

---

## Table of contents
- [Features](#features)
- [Why CrashSafeImage?](#why-crash-safe-image)
- [Install](#install)
- [Quick start](#quick-start)
- [How it decides the source](#how-it-decides-the-source)
- [API](#api)
  - [Constructor parameters](#constructor-parameters)
  - [Using as `ImageProvider`](#using-as-imageprovider)
  - [Custom placeholders & errors](#custom-placeholders--errors)
- [Examples](#examples)
- [Platform support](#platform-support)
- [Performance notes](#performance-notes)
- [Version compatibility](#version-compatibility)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Features
- ✅ **Auto‑detects**: `http/https` → network · `file://`/absolute path → file · no scheme → asset · `bytes` → memory
- ✅ **SVG support**: auto-detects `.svg` for network/asset/file/memory, powered by `flutter_svg`
- ✅ **Crash‑safe defaults**: shows placeholder while loading and a clean error UI on failure
- ✅ **Network caching** via `cached_network_image`
- ✅ **Works in lists/grids** with optional fade‑in/out
- ✅ **ImageProvider getter** for `CircleAvatar`, `DecorationImage`, etc.
- ✅ **Customizable**: size, fit, alignment, borderRadius, color, opacity, blend mode, HTTP headers & cacheKey

---

## Why Crash Safe Image
- **Stops avoidable crashes**: invalid asset keys, missing files, empty/null sources → you get a friendly error UI instead of exceptions.
- **One widget, four sources**: network • asset • file • memory — no `if/else` soup.
- **Better UX by default**: placeholders and fade‑in/out already wired.
- **Caches network images** out of the box via `cached_network_image`.
- **Works with existing APIs**: grab `.provider` for `CircleAvatar`/`DecorationImage`.
- **Easy to style**: `fit`, `alignment`, `borderRadius`, `opacity`, `colorBlendMode`.
- **Lean & tested**: small surface area with widget tests.

**When should I use it?**
- Dynamic sources from API/user input where failures must not crash UI.
- Avatars, logos, list/grid images with consistent placeholders.

**When might I not need it?**
- You need custom decoding/stream control or web‑only file paths (until web‑safe mode ships).

**Before vs After**
```dart
// Before: branching + manual fallbacks
Widget buildAvatar(String? url) {
  if (url == null || url.isEmpty) return const Icon(Icons.person);
  return Image.network(url, errorBuilder: (_, __, ___) => const Icon(Icons.person));
}

// After: one line
CrashSafeImage(url, width: 40, height: 40, errorBuilder: (_) => const Icon(Icons.person));
```

---



## Install
Add to your `pubspec.yaml`:

```yaml
dependencies:
  crash_safe_image: ^0.1.0
```

Import:

```dart
import 'package:crash_safe_image/crash_safe_image.dart';
```

---

## Quick start
```dart
CrashSafeImage(
  'https://example.com/pic.png',
  width: 80,
  height: 80,
  placeholderBuilder: (_) => const Center(child: Text('Loading...')),
  errorBuilder: (_) => const Icon(Icons.error_outline),
);
```

**Using memory bytes** (e.g., from camera/DB):
```dart
CrashSafeImage(
  null,
  bytes: myUint8List,
  width: 120,
  height: 120,
  fit: BoxFit.cover,
);
```

**Using as provider** (e.g., for `CircleAvatar`):
```dart
CircleAvatar(
  radius: 24,
  backgroundImage: CrashSafeImage('https://example.com/avatar.png').provider,
);
```

---

## How it decides the source
1. If `bytes != null && bytes.isNotEmpty` → **MemoryImage**
2. Else if `name == null || name.trim().isEmpty` → **error UI**
3. Else if `name` is `http`/`https` → **CachedNetworkImage** / `CachedNetworkImageProvider`
4. Else if `name` looks like a file path (e.g., `file://`, absolute) → **FileImage**
5. Else → **AssetImage**

> Note: If the asset path is wrong or the file doesn’t exist, the widget shows the error UI instead of crashing.

---

## API

### Constructor parameters

| Param | Type | Default | Notes |
|------|------|---------|-------|
| `name` | `String?` | – | Path/URL/asset key. Can be `null` when using `bytes`.
| `width`, `height` | `double?` | – | Final rendered size.
| `fit` | `BoxFit?` | – | How to inscribe the image into the box.
| `alignment` | `AlignmentGeometry` | `Alignment.center` | Alignment for the image.
| `borderRadius` | `BorderRadius?` | – | Rounded corners; applied via `ClipRRect`.
| `clipBehavior` | `Clip` | `Clip.hardEdge` | Clip strategy for rounding.
| `color` | `Color?` | – | Color filter tint.
| `opacity` | `Animation<double>?` | – | Animated opacity for `Image.*`.
| `colorBlendMode` | `BlendMode?` | – | Blend mode with `color`.
| `placeholderBuilder` | `WidgetBuilder?` | built‑in spinner | Builder for loading state.
| `errorBuilder` | `WidgetBuilder?` | built‑in broken‑image icon | Builder for error state.
| `httpHeaders` | `Map<String, String>?` | – | Extra headers for network requests.
| `cacheKey` | `String?` | – | Custom cache key for network images.
| `fadeInDuration` | `Duration` | `250ms` | Network fade‑in.
| `fadeOutDuration` | `Duration` | `250ms` | Network fade‑out.
| `bundle` | `AssetBundle?` | – | Custom bundle for assets.
| `package` | `String?` | – | Asset package name.
| `bytes` | `Uint8List?` | – | Raw bytes (memory images).

### Using as `ImageProvider`
Get a provider for places that need it (e.g., `CircleAvatar`, `BoxDecoration`):
```dart
final provider = CrashSafeImage('assets/logo.png').provider; // ImageProvider<Object>?
```
If the source is invalid, `provider` may be `null`; handle that in your UI.

### Custom placeholders & errors
```dart
CrashSafeImage(
  'https://invalid-url.example/broken.png',
  width: 96,
  height: 96,
  placeholderBuilder: (_) => const Center(child: Text('Loading…')),
  errorBuilder: (_) => const Icon(Icons.warning_amber_rounded, color: Colors.red),
);
```

---

## Examples
**Basic**
```dart
CrashSafeImage('assets/images/logo.png', width: 40, height: 40);
```

**File path**
```dart
CrashSafeImage('/storage/emulated/0/Download/picture.jpg', width: 120, height: 90);
```

**DecorationImage**
```dart
Container(
  width: 160,
  height: 100,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    image: DecorationImage(
      image: CrashSafeImage('assets/bg.jpg').provider!,
      fit: BoxFit.cover,
    ),
  ),
);
```

---

## Platform support
- **Android/iOS**, **macOS**, **Windows** ✅
- **Web**: not officially supported yet if your app path relies on `dart:io` file checks. A web‑safe mode is on the roadmap (conditional imports).

> Network and asset images work on the web, but direct local file paths (`FileImage`) do not.

---

## Performance notes
- The widget wraps content in a `SizedBox` + `ClipRRect` for reliable sizing and rounded corners.
- Avoid extremely frequent rebuilds with changing `cacheKey` or headers.
- For very large images in lists, set an explicit `width/height` and `fit` to reduce layout thrash.

---

## Version compatibility
- Dart SDK: `>=3.9.0 <4.0.0`
- Flutter: `>=3.22.0`
- `cached_network_image: ^3.4.1`

See [`pubspec.yaml`](pubspec.yaml) for full constraints.

---

## Roadmap
- Web‑safe file detection (conditional `dart:io` imports)
- More knobs for placeholders (colors, shapes)
- Additional tests for builders and error propagation

Have ideas? Open an [issue](https://github.com/DevsLoom/crash_safe_image/issues) or a PR.

---

## Contributing
PRs are welcome! Please run the checks before opening a PR:

```bash
dart format .
flutter analyze
flutter test
```

---

## License
MIT © DevsLoom — see [LICENSE](LICENSE)

