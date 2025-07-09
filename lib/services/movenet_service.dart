import 'package:tflite_flutter/tflite_flutter.dart';

class MoveNetService {
  static final MoveNetService _instance = MoveNetService._internal();

  factory MoveNetService() => _instance;

  MoveNetService._internal();

  late final Interpreter _interpreter;
  bool _isLoaded = false;

  Future<void> loadModel() async {
    if (_isLoaded) return;

    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/movenet_singlepose_lightning.tflite',
      );
      _isLoaded = true;
      print('MoveNet model loaded successfully.');
    } catch (e) {
      print('Error loading MoveNet model: $e');
      rethrow;
    }
  }

  bool get isLoaded => _isLoaded;

  Interpreter get interpreter {
    if (!_isLoaded) {
      throw Exception('Model not loaded.');
    }
    return _interpreter;
  }

  void dispose() {
    if (_isLoaded) {
      _interpreter.close();
      _isLoaded = false;
      print('MoveNet model disposed.');
    }
  }
}
