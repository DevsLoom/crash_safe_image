// lib/src/image_transformation.dart
import 'package:flutter/material.dart';

/// Defines types of image transformations available
enum ImageTransformationType { resize, crop }

/// Base class for image transformations
abstract class ImageTransformation {
  const ImageTransformation();

  /// Create a resize transformation
  factory ImageTransformation.resize(
    double? width,
    double? height, {
    BoxFit? fit,
  }) = ResizeTransformation;

  /// Create a crop transformation
  factory ImageTransformation.crop(Rect cropRect) = CropTransformation;

  ImageTransformationType get type;
}

/// Resize transformation
class ResizeTransformation extends ImageTransformation {
  final double? width;
  final double? height;
  final BoxFit? fit;

  const ResizeTransformation(this.width, this.height, {this.fit});

  @override
  ImageTransformationType get type => ImageTransformationType.resize;
}

/// Crop transformation
class CropTransformation extends ImageTransformation {
  final Rect cropRect;

  const CropTransformation(this.cropRect);

  @override
  ImageTransformationType get type => ImageTransformationType.crop;
}
