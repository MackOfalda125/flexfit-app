import 'dart:async';

import 'package:app/services/native_inference_channel.dart';
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

  double _aspectRatio = 1.5;
  double get aspectRatio => _aspectRatio;

  int _frameCount = 0;
  static const int _skipFrameN = 3;
  bool _isProcessing = false;

  int _sensorOrientation = 0;

  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  List<List<double>>? _keypoints;
  List<List<double>>? get keypoints => _keypoints;

  double? _formScore;
  double? get formScore => _formScore;

  int? _instructionId;
  int? get instructionId => _instructionId;

  // Buffers
  List<Uint8List>? _planeBytesBuffer;
  List<int>? _bytesPerRowBuffer;
  List<int>? _bytesPerPixelBuffer;
  int _lastPlaneCount = 0;

  CameraProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> initCamera() async {
    if (_isInitializing || isInitialized) return;

    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) =>
            c.lensDirection ==
            CameraLensDirection.front, // Change camera orientation here
        orElse: () => cameras.first,
      );

      _sensorOrientation = frontCamera.sensorOrientation;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false,
        fps: 30,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController!.initialize();

      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      _aspectRatio = _cameraController!.value.aspectRatio;

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
      _isStreaming = true;
      _frameCount = 0;
      notifyListeners();

      _cameraController!.startImageStream((CameraImage image) {
        if (!_isStreaming) return;

        _frameCount++;
        if (_frameCount % _skipFrameN != 0) return;

        if (_isProcessing) {
          debugPrint("🟡 Skipping frame - already processing");
          return;
        }

        _isProcessing = true;

        // Use unawaited to avoid blocking the stream
        unawaited(
          processFrame(image)
              .catchError((error) {
                debugPrint("🔴 Error processing frame: $error");
              })
              .whenComplete(() {
                _isProcessing = false;
              }),
        );
      });
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
      _planeBytesBuffer = null;
      _bytesPerRowBuffer = null;
      _bytesPerPixelBuffer = null;
      notifyListeners();
    }
  }

  void toggleTracking() {
    if (_isStreaming) {
      stopFrameCapture();
    } else {
      startFrameCapture();
    }
  }

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
    _isActive = false;

    if (_isStreaming) stopFrameCapture();
    _isProcessing = false;
    _cameraController?.dispose();
    _cameraController = null;

    notifyListeners();
  }

  Future<void> _resumeCamera() async {
    if (_isActive || _isInitializing) {
      return;
    }
    await initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopFrameCapture();

    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> processFrame(CameraImage cameraImage) async {
    try {
      final planeCount = cameraImage.planes.length;

      // Initialize or resize buffers if needed
      if (_planeBytesBuffer == null || _lastPlaneCount != planeCount) {
        _planeBytesBuffer = List<Uint8List>.filled(
          planeCount,
          Uint8List(0),
          growable: false,
        );
        _bytesPerRowBuffer = List<int>.filled(planeCount, 0, growable: false);
        _bytesPerPixelBuffer = List<int>.filled(planeCount, 0, growable: false);
        _lastPlaneCount = planeCount;
      }

      for (int i = 0; i < planeCount; i++) {
        final plane = cameraImage.planes[i];
        _planeBytesBuffer![i] = plane.bytes;
        _bytesPerRowBuffer![i] = plane.bytesPerRow;
        _bytesPerPixelBuffer![i] = plane.bytesPerPixel ?? 1;
      }

      final result = await NativeInferenceChannel.processFrame(
        _planeBytesBuffer!,
        _bytesPerRowBuffer!,
        _bytesPerPixelBuffer!,
        cameraImage.width,
        cameraImage.height,
        _sensorOrientation,
      );
      _keypoints = result[0] as List<List<double>>;
      _formScore = result[1] as double;
      _instructionId = result[2] as int;

      notifyListeners();

      debugPrint(
        "🟢 Inference completed: ${cameraImage.width}x${cameraImage.height}",
      );
    } catch (e) {
      debugPrint("🔴 Error in processFrame: $e");
    }
  }
}
