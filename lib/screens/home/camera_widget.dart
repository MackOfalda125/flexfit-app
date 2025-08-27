import 'package:app/core/constants.dart';
import 'package:app/services/camera_provider.dart';
import 'package:app/utils/skeletal_overlay_painter.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CameraWidget extends StatelessWidget {
  const CameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.select<CameraProvider, CameraController?>(
      (p) => p.controller,
    );

    final isInitialized = context.select<CameraProvider, bool>(
      (p) => p.isInitialized,
    );

    final aspectRatio = context.select<CameraProvider, double>(
      (p) => p.aspectRatio,
    );

    final keypoints = context.select<CameraProvider, List<List<double>>?>(
      (p) => p.keypoints,
    );

    final previewWidth = MediaQuery.of(context).size.width;
    final previewHeight = previewWidth * aspectRatio;

    if (!isInitialized || controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      ); // TODO: Change to flexfit loading gif
    }

    return Container(
      width: previewWidth,
      height: previewHeight,
      color: AppColors.primaryBackground,
      child: RepaintBoundary(
        key: const ValueKey('camera_boundary'),
        child: CustomPaint(
          foregroundPainter: SkeletalOverlayPainter(
            inferenceList: keypoints,
            canvasWidth: previewWidth,
            canvasHeight: previewHeight,
          ),
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
