import 'dart:isolate';
import 'dart:typed_data';
import 'package:app/utils/camera_image_converter.dart';
import 'package:app/utils/image_cropper.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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

  final interpreter = Interpreter.fromBuffer(
    modelBytes,
    options: InterpreterOptions()..threads = 2,
  );

  receivePort.listen((message) async {
    if (message is MoveNetIsolate) {
      try {
        // Convert CameraImage to img.Image
        final img.Image rgbImage = cameraImageToImage(message.cameraImage);
        // Crop and resize for MoveNet (using full image for now)
        final img.Image cropped = cropAndResize(
          image: rgbImage,
          keypoints: List.generate(17, (_) => [0.0, 0.0, 0.0]), // dummy keypoints for full image
          previousKeypoints: null,
        );
        // Convert to Uint8List (RGB order)
        final Uint8List rgbBytes = imageToUint8List(cropped);
        // Reshape to [1, 192, 192, 3] as Uint8List
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
