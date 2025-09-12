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
