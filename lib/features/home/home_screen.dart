import 'package:app/core/constants.dart';
import 'package:app/features/home/bottom_app_bar.dart';
import 'package:app/features/home/camera_widget.dart';
import 'package:app/features/home/exercise_menu_panel.dart';
import 'package:app/services/camera_provider.dart';
import 'package:app/utils/skeletal_overlay_painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _toggleTracking() {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    if (!cameraProvider.isStreaming) {
      cameraProvider.startFrameCapture();
    } else {
      cameraProvider.stopFrameCapture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = context.watch<CameraProvider>().aspectRatio;
    final double previewWidth = MediaQuery.of(context).size.width;
    final double previewHeight = previewWidth * aspectRatio;
    final int score = 55;
    final bool isTracking = context.watch<CameraProvider>().isStreaming;
    final List<List<double>>? keypoints = context
        .watch<CameraProvider>()
        .keypoints;
    final sensorOrientation = context.watch<CameraProvider>().sensorOrientation;
    final paddingRatio = context.watch<CameraProvider>().paddingRatio;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      extendBody: true,
      body: Stack(
        children: [
          // Camera preview with skeletal overlay
          Positioned(
            right: 0,
            bottom: 64,
            child: Container(
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
                    sensorOrientation: sensorOrientation,
                    paddingRatio: paddingRatio,
                  ),
                  child: const CameraWidget(),
                ),
              ),
            ),
          ),
          // Bottom App Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomAppBar(
              onMenuPressed: _toggleMenu,
              score: score,
              onStartStop: _toggleTracking,
              isTracking: isTracking,
            ),
          ),
          // Dimmed background
          if (_isMenuOpen)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleMenu,
              child: Container(color: Color(0x4C1B1B1B)),
            ),
          // Sliding panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: _isMenuOpen ? 0 : -230,
            top: 0,
            bottom: 0,
            child: ExerciseMenuPanel(onBackPressed: _toggleMenu),
          ),
        ],
      ),
    );
  }
}
