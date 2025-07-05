import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    // Get the front camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // Initialize the controller
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false, // No audio
    );

    try {
      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    } else {
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
}
