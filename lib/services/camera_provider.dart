import 'package:app/services/movenet/movenet_isolate_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CameraProvider extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = false;
  bool _isStreaming = false;
  bool _isActive = true;
  CameraImage? _lastImage;
  int _frameCount = 0;
  bool _isProcessing = false;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  CameraImage? get lastImage => _lastImage;

  bool get isStreaming => _isStreaming;

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
        ResolutionPreset.low, // TODO: change to low, test
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

    _controller!.startImageStream((CameraImage image) async {
      debugPrint("🟢 Frame received: ${image.width}x${image.height}");
      _lastImage = image;

      // Process every 3rd frame
      _frameCount++;
      if (_frameCount % 3 == 0 && !_isProcessing) {
        _isProcessing = true;

        try {
          await processFrame(image);
        } catch (e) {
          debugPrint("🔴 Error processing frame: $e");
        } finally {
          _isProcessing = false;
        }
      }
    });

    _isStreaming = true;
    notifyListeners();
  }

  void stopImageStream() {
    if (!isInitialized || !_isStreaming) return;

    _controller!.stopImageStream();
    _lastImage = null; // clear last image
    _isStreaming = false;
    _isProcessing = false;
    notifyListeners();
  }

  // Pause or resume camera based on app lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint("### AppLifecycleState changed: $state");

    switch (state) {
      case AppLifecycleState.paused:
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
    _isProcessing = false;
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

  Future<void> processFrame(CameraImage cameraImage) async {
    try {
      final controller = MoveNetIsolateController();
      final result = await controller.runInference(cameraImage);
      debugPrint("🟢 Inference result: $result");
      // TODO: Pass keypoint to overlay and exercise model
    } catch (e) {
      debugPrint("🔴 Error processing frame: $e");
    }
  }
}
