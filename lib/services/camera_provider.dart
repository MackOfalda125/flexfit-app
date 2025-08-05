import 'dart:async';

import 'package:app/services/movenet/movenet_isolate_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CameraProvider extends ChangeNotifier with WidgetsBindingObserver {
  CameraController? _cameraController;

  CameraController? get controller => _cameraController;

  bool _isInitializing = false;

  bool _isStreaming = false;

  bool get isStreaming => _isStreaming;

  bool _isActive = true;

  int _frameCount = 0;
  bool _isProcessing = false;

  int _sensorOrientation = 0;

  int get sensorOrientation => _sensorOrientation;

  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  List<List<double>>? _keypoints;

  List<List<double>>? get keypoints => _keypoints;

  CameraProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initCamera() async {
    if (_isInitializing || isInitialized) return;

    _isInitializing = true;

    try {
      // Lock device orientation to portrait up (camera at top)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) =>
            c.lensDirection ==
            CameraLensDirection.back, // change to back for emulator testing
        orElse: () => cameras.first,
      );

      _sensorOrientation = frontCamera.sensorOrientation;

      // _sensorOrientation = 0; // uncomment for testing without rotation

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium, // TODO: change to low, test
        enableAudio: false,
        fps: 30, // Adjust as needed
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();

      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      _isActive = true;
      notifyListeners();
    } catch (e) {
      debugPrint('CameraProvider error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  void startFrameCapture() {
    if (!isInitialized || _isStreaming) return;

    try {
      _cameraController!.startImageStream((CameraImage image) {
        // Process every 3rd frame
        _frameCount++;
        if (_frameCount % 3 == 0 && _isStreaming) {
          // Double-check processing flag to ensure only one frame at a time
          if (_isProcessing) {
            debugPrint("🟡 Skipping frame - already processing");
            return;
          }

          _isProcessing = true;
          _frameCount =
              0; // Reset frame count immediately when starting processing

          // Use unawaited to avoid blocking the stream
          unawaited(
            processFrame(image)
                .catchError((error) {
                  debugPrint("🔴 Error processing frame: $error");
                })
                .whenComplete(() {
                  if (_isStreaming) {
                    _isProcessing = false;
                  }
                }),
          );
        }
      });

      _isStreaming = true;
      _frameCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("🔴 Error starting image stream: $e");
      _isStreaming = false;
      notifyListeners();
    }
  }

  void stopFrameCapture() {
    if (!isInitialized || !_isStreaming) return;

    try {
      _cameraController!.stopImageStream();
    } catch (e) {
      debugPrint("🔴 Error stopping image stream: $e");
    } finally {
      _isStreaming = false;
      _isProcessing = false;
      _keypoints = null;
      _frameCount = 0;
      notifyListeners();
    }
  }

  // Pause or resume camera based on app lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

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
      return;
    }

    debugPrint("*** Pausing camera.");
    _isActive = false;

    if (_isStreaming) stopFrameCapture();
    _isProcessing = false;
    _cameraController?.dispose();
    _cameraController = null;

    notifyListeners();
  }

  Future<void> _resumeCamera() async {
    if (_isActive || _isInitializing) {
      debugPrint("*** Camera is already active or initializing.");
      return;
    }

    debugPrint("*** Resuming camera.");
    await initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();

    // Reset device orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    try {
      // Get current sensor orientation from camera controller

      final MoveNetIsolateController movenetController =
          MoveNetIsolateController();
      final List<List<double>>? result = await movenetController.runInference(
        cameraImage,
        _sensorOrientation, // Pass the sensor orientation for proper rotation
      );
      _keypoints = result;
      notifyListeners();
      debugPrint(
        "🟢 Inference completed (image: ${cameraImage.width}x${cameraImage.height}, orientation: $_sensorOrientation°)",
      );
    } catch (e) {
      debugPrint("🔴 Error in processFrame: $e");
    }
  }
}
