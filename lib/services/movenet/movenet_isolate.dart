import 'dart:isolate';

import 'package:app/services/movenet/pose_estimator.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class MoveNetIsolate {
  final CameraImage cameraImage;
  final SendPort responsePort;

  MoveNetIsolate(this.cameraImage, this.responsePort);
}

Future<void> movenetIsolateEntryPoint(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final interpreter = await Interpreter.fromAsset(
    'assets/models/movenet_singlepose_lightning.tflite',
    options: InterpreterOptions()..threads = 2,
  );

  receivePort.listen((message) async {
    if (message is MoveNetIsolate) {
      try {
        final img.Image rgbImage = PoseEstimator.convertCameraImage(
          message.cameraImage,
        );
        final TensorImage tensorImage = PoseEstimator.imageToTensorImage(
          rgbImage,
        );

        final inputBuffer = [tensorImage.buffer];
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
