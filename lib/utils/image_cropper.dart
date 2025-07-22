import 'dart:math';

import 'package:image/image.dart' as img;

const double _minCropKeypointScore = 0.2;

const Map<String, int> _movenetKeypointDict = {
  'nose': 0,
  'left_eye': 1,
  'right_eye': 2,
  'left_ear': 3,
  'right_ear': 4,
  'left_shoulder': 5,
  'right_shoulder': 6,
  'left_elbow': 7,
  'right_elbow': 8,
  'left_wrist': 9,
  'right_wrist': 10,
  'left_hip': 11,
  'right_hip': 12,
  'left_knee': 13,
  'right_knee': 14,
  'left_ankle': 15,
  'right_ankle': 16,
};

Map<String, double> _initCropRegion(int imageHeight, int imageWidth) {
  double yMin, xMin, boxHeight, boxWidth;

  if (imageWidth > imageHeight) {
    boxHeight = imageWidth / imageHeight;
    boxWidth = 1.0;
    yMin = (imageHeight / 2 - imageWidth / 2) / imageHeight;
    xMin = 0.0;
  } else {
    boxHeight = 1.0;
    boxWidth = imageHeight / imageWidth;
    yMin = 0.0;
    xMin = (imageWidth / 2 - imageHeight / 2) / imageWidth;
  }

  return {
    'y_min': yMin,
    'x_min': xMin,
    'y_max': yMin + boxHeight,
    'x_max': xMin + boxWidth,
    'height': boxHeight,
    'width': boxWidth,
  };
}

bool _torsoVisible(List<List<double>> keypoints) {
  final leftHip = keypoints[_movenetKeypointDict['left_hip']!][2];
  final rightHip = keypoints[_movenetKeypointDict['right_hip']!][2];
  final leftShoulder = keypoints[_movenetKeypointDict['left_shoulder']!][2];
  final rightShoulder = keypoints[_movenetKeypointDict['right_shoulder']!][2];

  return ((leftHip > _minCropKeypointScore ||
          rightHip > _minCropKeypointScore) &&
      (leftShoulder > _minCropKeypointScore ||
          rightShoulder > _minCropKeypointScore));
}

List<double> _determineTorsoAndBodyRange(
  List<List<double>> keypoints,
  Map<String, List<double>> targetKeypoints,
  double centerY,
  double centerX,
) {
  final torsoJoints = [
    'left_shoulder',
    'right_shoulder',
    'left_hip',
    'right_hip',
  ];

  double maxTorsoY = 0.0;
  double maxTorsoX = 0.0;
  for (final joint in torsoJoints) {
    final dy = (centerY - targetKeypoints[joint]![0]).abs();
    final dx = (centerX - targetKeypoints[joint]![1]).abs();
    maxTorsoY = max(maxTorsoY, dy);
    maxTorsoX = max(maxTorsoX, dx);
  }

  double maxBodyY = 0.0;
  double maxBodyX = 0.0;
  for (final joint in _movenetKeypointDict.keys) {
    if (keypoints[_movenetKeypointDict[joint]!][2] < _minCropKeypointScore)
      continue;
    final dy = (centerY - targetKeypoints[joint]![0]).abs();
    final dx = (centerX - targetKeypoints[joint]![1]).abs();
    maxBodyY = max(maxBodyY, dy);
    maxBodyX = max(maxBodyX, dx);
  }

  return [maxTorsoY, maxTorsoX, maxBodyY, maxBodyX];
}

Map<String, double> _determineCropRegion(
  List<List<double>> keypoints,
  int imageHeight,
  int imageWidth,
) {
  final targetKeypoints = <String, List<double>>{};
  for (final joint in _movenetKeypointDict.keys) {
    final y = keypoints[_movenetKeypointDict[joint]!][0] * imageHeight;
    final x = keypoints[_movenetKeypointDict[joint]!][1] * imageWidth;
    targetKeypoints[joint] = [y, x];
  }

  if (_torsoVisible(keypoints)) {
    final centerY =
        (targetKeypoints['left_hip']![0] + targetKeypoints['right_hip']![0]) /
        2;
    final centerX =
        (targetKeypoints['left_hip']![1] + targetKeypoints['right_hip']![1]) /
        2;

    final range = _determineTorsoAndBodyRange(
      keypoints,
      targetKeypoints,
      centerY,
      centerX,
    );

    // There is an error here
    // Paramater of min is num not List<num>
    final a = [range[0] * 1.9, range[1] * 1.9, range[2] * 1.2, range[3] * 1.2].reduce(max);
    final b = [centerX, imageWidth - centerX, centerY, imageHeight - centerY].reduce(max);
    final cropLengthHalf = min(a, b);

    final cropCornerY = centerY - cropLengthHalf;
    final cropCornerX = centerX - cropLengthHalf;

    if (cropLengthHalf > max(imageWidth, imageHeight) / 2) {
      return _initCropRegion(imageHeight, imageWidth);
    }

    final cropLength = cropLengthHalf * 2;
    return {
      'y_min': cropCornerY / imageHeight,
      'x_min': cropCornerX / imageWidth,
      'y_max': (cropCornerY + cropLength) / imageHeight,
      'x_max': (cropCornerX + cropLength) / imageWidth,
      'height': cropLength / imageHeight,
      'width': cropLength / imageWidth,
    };
  } else {
    return _initCropRegion(imageHeight, imageWidth);
  }
}

/// Crops and resizes the image for MoveNet, using keypoints and previous keypoints if available.
/// If previousKeypoints is null, uses the full image as the crop region.
img.Image cropAndResize({
  required img.Image image,
  required List<List<double>> keypoints,
  List<List<double>>? previousKeypoints,
}) {
  final imageHeight = image.height;
  final imageWidth = image.width;

  // Determine crop region
  Map<String, double> cropRegion;
  if (previousKeypoints == null) {
    cropRegion = _initCropRegion(imageHeight, imageWidth);
  } else {
    cropRegion = _determineCropRegion(
      previousKeypoints,
      imageHeight,
      imageWidth,
    );
  }

  // Calculate crop rectangle in pixel coordinates
  final cropY = (cropRegion['y_min']! * imageHeight)
      .clamp(0, imageHeight - 1)
      .toInt();
  final cropX = (cropRegion['x_min']! * imageWidth)
      .clamp(0, imageWidth - 1)
      .toInt();
  final cropH = (cropRegion['height']! * imageHeight)
      .clamp(1, imageHeight - cropY)
      .toInt();
  final cropW = (cropRegion['width']! * imageWidth)
      .clamp(1, imageWidth - cropX)
      .toInt();

  // Crop the image
  final cropped = img.copyCrop(
    image,
    x: cropX,
    y: cropY,
    width: cropW,
    height: cropH,
  );
  // Resize to target size (hardcoded 192)
  final resized = img.copyResizeCropSquare(cropped, size: 192);
  return resized;
}
