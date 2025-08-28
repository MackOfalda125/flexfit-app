# FlexFit - Exercise Form Correction Application

FlexFit is a Flutter-based mobile application that uses computer vision and machine learning to provide real-time exercise form correction and feedback to users during their workouts.

## Project Overview

This application leverages TensorFlow Lite and MoveNet for pose estimation to analyze exercise form and provide corrective feedback. The app uses a custom Flutter plugin for native Android inference processing to achieve optimal performance.

## Main Project Structure

### Core Application (`lib/`)
The main Flutter application code containing:

- **`main.dart`** - Application entry point and initialization
- **`screens/`** - UI screens and components
  - `home/` - Main application interface
  - `loading/` - Loading and splash screens
- **`services/`** - Business logic and external integrations
  - `camera_provider.dart` - Camera functionality and stream management
  - `native_inference_channel.dart` - Communication with native Android plugin
- **`utils/`** - Helper utilities and custom widgets
  - `skeletal_overlay_painter.dart` - Custom painter for drawing skeletal overlays
  - `permissions.dart` - Permission handling utilities
- **`core/`** - Application constants and configurations
  - `constants.dart` - App-wide constants and configurations

### Native Android Plugin (`movenet_image_processor/`)
Custom Flutter plugin for native Android inference processing:

- **`android/src/main/kotlin/com/example/movenet_image_processor/`**
  - `MovenetImageProcessorPlugin.kt` - Main plugin entry point and method channel
  - `InferenceProcessor.kt` - Core inference processing logic
  - `ExerciseInference.kt` - Exercise-specific pose analysis and form correction
  - `ModelLoader.kt` - TensorFlow Lite model loading and management

## Key Features

- **Real-time Pose Estimation** - Uses MoveNet for accurate body pose detection
- **Exercise Form Analysis** - Analyzes exercise form and provides corrective feedback
- **Native Performance** - Custom Android plugin for optimized inference processing
- **Camera Integration** - Real-time camera feed with skeletal overlay visualization
- **Permission Management** - Handles camera and storage permissions appropriately

## Dependencies

The application uses several key dependencies:
- `camera: ^0.11.1` - Camera functionality
- `permission_handler: ^12.0.1` - Permission management
- `provider: 6.1.5` - State management
- Custom `movenet_image_processor` plugin for native inference

## Assets

- **Models**: TensorFlow Lite MoveNet model for pose estimation
- **Images**: Application logos and loading animations
- **Fonts**: Custom fonts (FiraCode, WorkSans) for enhanced UI

## Technical Architecture

The application follows a modular architecture with clear separation of concerns:
- **UI Layer**: Flutter screens and widgets
- **Service Layer**: Business logic and external integrations
- **Native Layer**: Android plugin for performance-critical operations
- **Utility Layer**: Helper functions and custom painters

This architecture ensures maintainable code while providing optimal performance for real-time pose estimation and form correction.
