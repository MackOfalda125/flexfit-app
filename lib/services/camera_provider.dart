import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitializing = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initCamera() async {
    if (_isInitializing || isInitialized) return;

    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      notifyListeners();
    } catch (e) {
      debugPrint('CameraProvider error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}