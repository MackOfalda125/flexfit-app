import 'dart:isolate';

import 'package:app/services/native_image_processor.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MoveNetIsolate {
  final CameraImage cameraImage;
  final SendPort responsePort;
  final List<List<double>>? previousKeypoints;

  MoveNetIsolate(this.cameraImage, this.responsePort, [this.previousKeypoints]);
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
    options: InterpreterOptions()..threads = 2,
  );

  receivePort.listen((message) async {
    if (message is MoveNetIsolate) {
      try {
        final Uint8List yuvBytes = message.cameraImage.planes.fold<Uint8List>(
          Uint8List(0),
          (prev, plane) => Uint8List.fromList([...prev, ...plane.bytes]),
        );
        final int width = message.cameraImage.width;
        final int height = message.cameraImage.height;

        final Uint8List rgbBytes = await NativeImageProcessor.processYUVPlanes(
          yuvBytes,
          width,
          height,
          message.previousKeypoints,
        );
        // Reshape to [1, 192, 192, 3]
        final inputBuffer = rgbBytes.reshape([1, 192, 192, 3]);
        final outputBuffer = List.generate(
          1 * 1 * 17 * 3,
          (_) => 0.0,
        ).reshape([1, 1, 17, 3]);

        interpreter.run(inputBuffer, outputBuffer);
        message.responsePort.send(outputBuffer[0][0]);
      } catch (e) {
        print('Error during inference: $e');
        message.responsePort.send(null);
      }
    }
  });
}
