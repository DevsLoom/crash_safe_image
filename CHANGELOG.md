## 0.3.1 - 2026-10-26
### Fixes
- **Hero**: default placeholder/error UI no longer nests a second `Hero` with the same tag (caused Hero assertions during navigation)
- **Caching**: per-widget `cacheConfig` is now honored; `CrashSafeImageCache.configure()` applies to every widget without its own config; `clear()`/`remove()` cover all caches in use
- **SVG**: `CrashSafeImage.svgString()` now UTF-8 encodes input (non-ASCII text was corrupted)
- **SVG**: animated `opacity` now updates (uses `FadeTransition`)
- **File**: file paths are detected without blocking I/O in `build()`; absolute paths (`/…`, `C:\…`, `\\…`) are files, other scheme-less paths are assets
- **Memory**: undecodable raster bytes show the error UI instead of throwing
- **Network**: progressive thumbnails send `httpHeaders`; `AlignmentDirectional` is resolved for RTL
- `providerOr(fallback)` now returns `fallback` for null/empty/SVG sources

### Behavior changes
- Relative paths that exist on disk are no longer treated as files; use an absolute path or `file://`
- Network images without `cacheConfig` now use the CrashSafeImage cache (global config) instead of `DefaultCacheManager`

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
