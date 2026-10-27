## 0.4.0 - 2026-10-26

This one is mostly about fixing things that didn't quite work the way 0.3.0 promised, plus catching up on dependencies. If you use `heroTag`, `cacheConfig` or `svgString()`, you'll want this update.

### Fixed
- **Hero no longer breaks when an image fails to load.** If an image with a `heroTag` showed the default placeholder or error icon, we accidentally put a second `Hero` with the same tag inside the first one. Flutter would then throw an assertion during navigation. Now there's exactly one `Hero`, and transformations aren't applied twice anymore either.
- **`cacheConfig` actually does something now.** Before, passing `cacheConfig` to a widget silently used the global config instead, and `CrashSafeImageCache.configure()` only kicked in if a widget also passed a `cacheConfig`. Now each widget uses its own config, and widgets without one fall back to the global config. `clear()` and `remove()` also clean up every cache that's in use, not just one.
- **`svgString()` handles non-ASCII text.** Bangla, `©`, emoji and other non-ASCII characters inside an SVG string used to come out corrupted. The string is now properly UTF-8 encoded.
- **Animated `opacity` works on SVGs.** It used to read the animation value once and then stay frozen. It now animates like it does for raster images.
- **No more blocking file checks in `build()`.** We used to call `File.existsSync()` on every rebuild, which could cause jank in long lists. File paths are now recognised from the path itself.
- **Broken image bytes show the error UI** instead of throwing.
- **Progressive loading sends your `httpHeaders` for the thumbnail too**, so thumbnails behind auth load properly.
- **`AlignmentDirectional` works for network images** and respects RTL. It used to quietly fall back to center.
- **`providerOr(fallback)` returns your fallback** for empty or SVG sources. It used to ignore it.

### Heads up: things that behave differently
- **File paths:** only absolute paths (`/…`, `C:\…`, `\\…`) and `file://` URIs are treated as files. A relative path like `images/pic.png` is now always treated as an asset, even if a file with that name happens to exist on disk.
- **Network caching:** network images without a `cacheConfig` now go through CrashSafeImage's own cache (using your global config) instead of `DefaultCacheManager`. Your users' existing image cache will be rebuilt once after upgrading.

### Dependencies
- **Now requires Flutter 3.44.0+ and Dart 3.12.0+**, because `cached_network_image` 4.x needs them. If you're stuck on an older Flutter, stay on `crash_safe_image: ^0.3.0`.
- `cached_network_image` ^3.4.1 → ^4.0.5
- `flutter_cache_manager` → ^3.4.5
- `flutter_svg` → ^2.3.0

## 0.3.0 - 2026-02-12
**Phase 1 Release - Advanced Features**

### New Features
- **Progressive Loading**: Show thumbnail first, then load full image with `thumbnailUrl` and `useProgressiveLoading` parameters
- **Image Transformations**: Resize and crop operations with `ImageTransformation.resize()` and `ImageTransformation.crop()`
- **Enhanced Caching**: Configurable cache with 4 presets (default, aggressive, conservative, minimal) via `CrashSafeImageCacheConfig`
  - Global cache configuration with `CrashSafeImageCache.configure()`
  - Per-widget cache configuration with `cacheConfig` parameter
  - Cache management: `clear()`, `remove()`, `getStats()`
- **Hero Animations**: Smooth page transitions with `heroTag` parameter

### Improvements
- Fixed SVG detection false positives (e.g., image.svg.png)
- Enhanced network URI validation
- Improved type casting safety
- Better error handling in build method

### Testing
- Added 25 new tests (32 total)
- Tests for progressive loading, transformations, caching, and hero animations
- Improved test coverage for edge cases

### Dependencies
- Added `flutter_cache_manager` as a direct dependency (used by the cache presets)

## 0.2.1 - 2025-09-14
- Fixed: `provider` could return `null` in some cases.  
  Now always returns a safe transparent fallback image (never-null).
- Improved: safer behavior in `CircleAvatar` / `DecorationImage` usage, no user-side null checks needed.

## 0.2.0 - 2025-09-11
- Added **SVG support** via `flutter_svg`.
- Auto-detects `.svg` in network, asset, file, and memory sources.
- Provides new factory: `CrashSafeImage.svgString('<svg ...>')`.
- Unified placeholder/error behavior for raster & SVG.

## 0.1.0 - 2025-08-31
- Initial public release.
- CrashSafeImage widget with network / asset / file / memory support.
- Custom placeholder & error builders.
- Cached network images via `cached_network_image`.
- Example app and basic widget tests.
