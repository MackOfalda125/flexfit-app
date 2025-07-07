import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _cameraController;
  bool _isCameraInitializing = false; // Guard variable to prevent multiple initializations

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;

    try {
      final cameras = await availableCameras();

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium, // low/medium to save resources
        enableAudio: false,
      );

      await controller.initialize();

      if (mounted) {
        setState(() {
          _cameraController = controller;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      _isCameraInitializing = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = _cameraController!.value.aspectRatio;
    final previewHeight = screenWidth * aspectRatio;

    return SizedBox(
      width: screenWidth,
      height: previewHeight,
      child: CameraPreview(_cameraController!),
    );
  }
}
