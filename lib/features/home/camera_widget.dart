import 'package:app/services/camera_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CameraWidget extends StatelessWidget {
  const CameraWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);

    if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(cameraProvider.controller!);
  }
}
