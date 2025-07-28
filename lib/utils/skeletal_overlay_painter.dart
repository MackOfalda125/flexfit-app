import 'dart:ui';

import 'package:flutter/material.dart';

class SkeletalOverlayPainter extends CustomPainter {
  final List<List<double>>? inferenceList;
  final double canvasWidth;
  final double canvasHeight;
  final double showPointConfidence;
  final double correctPointConfidence;

  SkeletalOverlayPainter({
    required this.inferenceList,
    required this.canvasWidth,
    required this.canvasHeight,
    this.showPointConfidence = 0.2,
    this.correctPointConfidence = 0.4,
  });

  // Paint configurations
  final pointGreen = Paint()
    ..color = Colors.green
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 12;

  final pointRed = Paint()
    ..color = Colors.red.shade900
    ..strokeCap = StrokeCap.round
    ..strokeWidth = 12;

  final edgeGreen = Paint()
    ..color = Colors.lightGreen
    ..strokeWidth = 6;

  final edgeRed = Paint()
    ..color = Colors.red.shade300
    ..strokeWidth = 6;

  // MoveNet keypoint connections (17 keypoints)
  static const List<List<int>> edges = [
    [0, 1], // nose to left_eye
    [0, 2], // nose to right_eye
    [1, 3], // left_eye to left_ear
    [2, 4], // right_eye to right_ear
    [0, 5], // nose to left_shoulder
    [0, 6], // nose to right_shoulder
    [5, 7], // left_shoulder to left_elbow
    [7, 9], // left_elbow to left_wrist
    [6, 8], // right_shoulder to right_elbow
    [8, 10], // right_elbow to right_wrist
    [5, 6], // left_shoulder to right_shoulder
    [5, 11], // left_shoulder to left_hip
    [6, 12], // right_shoulder to right_hip
    [11, 12], // left_hip to right_hip
    [11, 13], // left_hip to left_knee
    [13, 15], // left_knee to left_ankle
    [12, 14], // right_hip to right_knee
    [14, 16], // right_knee to right_ankle
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (inferenceList == null) return;

    final List<Offset> pointsGreen = [];
    final List<Offset> pointsRed = [];

    // Draw keypoints
    _drawKeypoints(canvas, size, pointsGreen, pointsRed);

    // Draw connections
    _drawConnections(canvas, size);

    // Draw the points
    canvas.drawPoints(PointMode.points, pointsGreen, pointGreen);
    canvas.drawPoints(PointMode.points, pointsRed, pointRed);
  }

  void _drawKeypoints(
    Canvas canvas,
    Size size,
    List<Offset> pointsGreen,
    List<Offset> pointsRed,
  ) {
    for (int i = 0; i < inferenceList!.length; i++) {
      final point = inferenceList![i];
      if (point.length < 3) continue;

      final x = point[0];
      final y = point[1];
      final confidence = point[2];

      if (confidence > showPointConfidence) {
        final offset = Offset(x * size.width, y * size.height);

        if (confidence > correctPointConfidence) {
          pointsGreen.add(offset);
        } else {
          pointsRed.add(offset);
        }
      }
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    for (final edge in edges) {
      if (edge.length < 2) continue;

      final point1Index = edge[0];
      final point2Index = edge[1];

      if (point1Index >= inferenceList!.length ||
          point2Index >= inferenceList!.length) {
        continue;
      }

      final point1 = inferenceList![point1Index];
      final point2 = inferenceList![point2Index];

      if (point1.length < 3 || point2.length < 3) continue;

      final confidence1 = point1[2];
      final confidence2 = point2[2];

      if (confidence1 > showPointConfidence &&
          confidence2 > showPointConfidence) {
        final vertex1 = Offset(point1[0] * size.width, point1[1] * size.height);
        final vertex2 = Offset(point2[0] * size.width, point2[1] * size.height);

        final paint =
            (confidence1 > correctPointConfidence &&
                confidence2 > correctPointConfidence)
            ? edgeGreen
            : edgeRed;

        canvas.drawLine(vertex1, vertex2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is SkeletalOverlayPainter) {
      return oldDelegate.inferenceList != inferenceList ||
          oldDelegate.showPointConfidence != showPointConfidence ||
          oldDelegate.correctPointConfidence != correctPointConfidence;
    }
    return true;
  }
}
