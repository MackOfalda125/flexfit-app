import 'dart:math';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// TODO: Test this

class PoseEstimator {
  static const _modelSize = 192;

  static img.Image convertCameraImage(CameraImage image) {
    final img.Image rawImage = img.Image(image.width, image.height);
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final rgb = _yuv2rgb(
          image.planes[0].bytes[y * image.width + x],
          image.planes[1].bytes[uvIndex],
          image.planes[2].bytes[uvIndex],
        );
        rawImage.setPixel(x, y, rgb);
      }
    }
    return img.flipHorizontal(img.copyRotate(rawImage, 270));
  }

  static int _yuv2rgb(int y, int u, int v) {
    final int u1 = u - 128;
    final int v1 = v - 128;

    final int r = (y + ((1436 * v1) >> 10)).clamp(0, 255);
    final int g = (y - ((352 * u1 + 731 * v1) >> 10)).clamp(0, 255);
    final int b = (y + ((1815 * u1) >> 10)).clamp(0, 255);

    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  static TensorImage imageToTensorImage(img.Image convertedImage) {
    final tensorImage = TensorImage(TfLiteType.uint8);
    tensorImage.loadImage(convertedImage);

    final padSize = max(tensorImage.height, tensorImage.width);
    final imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(_modelSize, _modelSize, ResizeMethod.BILINEAR))
        .build();

    return imageProcessor.process(tensorImage);
  }
}
