import 'package:flutter/material.dart';
import 'dart:async';

import 'package:movenet_image_processor/movenet_image_processor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Unknown';
  final _movenetImageProcessorPlugin = MovenetImageProcessor();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Initialize model on startup
  Future<void> initPlatformState() async {
    final ok = await _movenetImageProcessorPlugin.initializeModel();
    if (!mounted) return;
    setState(() {
      _status = ok ? 'Model initialized' : 'Initialization failed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Status: $_status\n'),
        ),
      ),
    );
  }
}
