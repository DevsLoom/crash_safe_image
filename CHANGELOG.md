## 0.3.0 - 2025-01-XX
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
- Replaced synchronous file operations with async-safe alternatives
- Added path traversal protection for file paths
- Enhanced network URI validation
- Improved type casting safety
- Better error handling in build method

### Testing
- Added 25 new tests (32 total)
- Tests for progressive loading, transformations, caching, and hero animations
- Improved test coverage for edge cases

### Dependencies
- Added `flutter_cache_manager: ^3.4.1` for advanced caching

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
