import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  bool _isInitializing = false;
  bool _isStreaming = false;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  CameraImage? _lastImage;
  CameraImage? get lastImage => _lastImage;

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

  void startImageStream() {
    if (!isInitialized || _isStreaming) return;

    _controller!.startImageStream((CameraImage image) {
      debugPrint("🟢 Frame received: ${image.width}x${image.height}");

      _lastImage = image;
      // add frame processing here
    });

    _isStreaming = true;
  }

  void stopImageStream() {
    if (!isInitialized || !_isStreaming) return;

    _controller!.stopImageStream();
    _lastImage = null; // clear last image
    _isStreaming = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
