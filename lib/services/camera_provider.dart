import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CameraProvider extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = false;
  bool _isStreaming = false;
  bool _isActive = true;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  CameraImage? _lastImage;

  CameraImage? get lastImage => _lastImage;

  CameraProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

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
      _isActive = true;
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

  // Pause or resume camera based on app lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint("### AppLifecycleState changed: $state");

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _pauseCamera();
        break;
      case AppLifecycleState.resumed:
        _resumeCamera();
        break;
      default:
        break;
    }
  }

  void _pauseCamera() {
    if (!_isActive) {
      debugPrint("*** Camera is already paused.");
      return;
    }

    debugPrint("*** Pausing camera.");
    _isActive = false;

    if (_isStreaming) stopImageStream();
    _controller?.dispose();
    _controller = null;
    _lastImage = null;
    notifyListeners();
  }

  Future<void> _resumeCamera() async {
    if (_isActive) {
      debugPrint("*** Camera is already active.");
      return;
    }

    if (_isInitializing) {
      debugPrint("*** Camera is initializing, waiting for completion.");
      return;
    }

    debugPrint("*** Resuming camera.");
    await initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }
}
