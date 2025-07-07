import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/services/camera_provider.dart';
import 'package:camera/camera.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CameraProvider>(context, listen: false);
    provider.initCamera();
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);

    if (!cameraProvider.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final aspectRatio = cameraProvider.controller!.value.aspectRatio;
    final previewHeight = screenWidth * aspectRatio;

    return SizedBox(
      width: screenWidth,
      height: previewHeight,
      child: CameraPreview(cameraProvider.controller!),
    );
  }
}
