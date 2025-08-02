import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import 'movenet_isolate.dart';

class MoveNetIsolateController {
  static final MoveNetIsolateController _instance =
      MoveNetIsolateController._internal();

  factory MoveNetIsolateController() => _instance;

  MoveNetIsolateController._internal();

  late Isolate _isolate;
  late SendPort _sendPort;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(Uint8List modelBytes) async {
    if (_isInitialized) return;

    final ReceivePort receivePort = ReceivePort();
    
    // Get the root isolate token for background isolate communication
    final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;

    try {
      _isolate = await Isolate.spawn(movenetIsolateEntryPoint, [
        receivePort.sendPort,
        modelBytes,
        rootIsolateToken,
      ]);
      _sendPort = await receivePort.first as SendPort;
      _isInitialized = true;
      print("MoveNetIsolateController initialized successfully");
    } catch (e) {
      throw Exception('Failed to initialize MoveNetIsolateController: $e');
    }
  }

  Future<List<List<double>>?> runInference(
    CameraImage cameraImage, [
    int sensorOrientation = 0,
  ]) async {
    if (!_isInitialized) {
      throw Exception('MoveNetIsolateController is not initialized');
    }

    final ReceivePort responsePort = ReceivePort();
    _sendPort.send(MoveNetIsolate(cameraImage, responsePort.sendPort, sensorOrientation));
    final result = await responsePort.first;

    if (result == null) return null;
    return (result as List).cast<List<double>>();
  }

  void dispose() {
    if (_isInitialized) {
      _isolate.kill(priority: Isolate.immediate);
      _isInitialized = false;
    }
  }
}
