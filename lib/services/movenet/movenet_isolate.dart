import 'dart:isolate';

import 'package:app/services/native_image_processor.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MoveNetIsolate {
  final CameraImage cameraImage;
  final SendPort responsePort;
  final int sensorOrientation;

  MoveNetIsolate(
    this.cameraImage,
    this.responsePort, [
    this.sensorOrientation = 0,
  ]);
}

Future<void> movenetIsolateEntryPoint(List<dynamic> args) async {
  final SendPort sendPort = args[0];
  final Uint8List modelBytes = args[1];
  final RootIsolateToken rootIsolateToken = args[2];

  // Initialize the binary messenger for the background isolate
  // This is required for plugins to work in background isolates
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final interpreter = Interpreter.fromBuffer(
    modelBytes,
    options: InterpreterOptions()
      ..threads =
          4 // Change and test
      ..useNnApiForAndroid = false,
  );

  receivePort.listen((message) async {
    if (message is MoveNetIsolate) {
      try {
        final int width = message.cameraImage.width;
        final int height = message.cameraImage.height;

        // Extract plane information for stride handling
        final planeBytes = message.cameraImage.planes
            .map((plane) => plane.bytes)
            .toList();
        final bytesPerRow = message.cameraImage.planes
            .map((plane) => plane.bytesPerRow)
            .toList();
        final bytesPerPixel = message.cameraImage.planes
            .map((plane) => plane.bytesPerPixel ?? 1)
            .toList();

        final List<dynamic> result =
            await NativeImageProcessor.processYUVPlanesWithStride(
              planeBytes,
              bytesPerRow,
              bytesPerPixel,
              width,
              height,
              message.sensorOrientation,
            );

        // Check if we got valid results
        if (result.isEmpty || result[0] == null || result[1] == null) {
          message.responsePort.send(null);
          return;
        }

        final Uint8List rgbBytes = result[0] as Uint8List;
        final double paddingRatio = result[1] as double;

        // Reshape to [1, 192, 192, 3]
        final inputBuffer = rgbBytes.reshape([1, 192, 192, 3]);
        final outputBuffer = List.generate(
          1 * 1 * 17 * 3,
          (_) => 0.0,
        ).reshape([1, 1, 17, 3]);

        interpreter.run(inputBuffer, outputBuffer);
        message.responsePort.send([outputBuffer[0][0], paddingRatio]);
      } catch (e) {
        print('Isolate: Error during inference: $e');
        message.responsePort.send(null);
      }
    }
  });
}
