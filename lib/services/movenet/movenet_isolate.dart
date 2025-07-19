import 'dart:isolate';
import 'dart:typed_data';

import 'package:app/utils/camera_image_converter.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class MoveNetIsolate {
  final CameraImage cameraImage;
  final SendPort responsePort;

  MoveNetIsolate(this.cameraImage, this.responsePort);
}

Future<void> movenetIsolateEntryPoint(List<dynamic> args) async {
  final SendPort sendPort = args[0];
  final Uint8List modelBytes = args[1];

  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final interpreter = await Interpreter.fromBuffer(
    modelBytes,
    options: InterpreterOptions()..threads = 2,
  );

  receivePort.listen((message) async {
    if (message is MoveNetIsolate) {
      try {
        // Use the optimized camera_image_converter
        final inputUint8 = cameraImageToModelInput(message.cameraImage);
        // Model expects shape [1, 192, 192, 3]
        final inputBuffer = inputUint8.buffer.asUint8List().reshape([
          1,
          192,
          192,
          3,
        ]);
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
