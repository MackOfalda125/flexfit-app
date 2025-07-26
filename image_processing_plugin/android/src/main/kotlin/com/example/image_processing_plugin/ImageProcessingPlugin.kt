package com.example.image_processing_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ImageProcessingPlugin: FlutterPlugin, MethodChannel.MethodCallHandler { 
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "image_processing_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "processYUVPlanes") {
            val yuvBytes = call.argument<ByteArray>("yuvBytes")!!
            val width = call.argument<Int>("width")!!
            val height = call.argument<Int>("height")!!
            val previousKeypoints = call.argument<List<List<Double>>>("previousKeypoints") // [[x, y, confidence], ...]
            
            println("DEBUG: Image size: ${width}x${height}")
            println("DEBUG: Previous keypoints: $previousKeypoints")

            try {
                // 1. Convert YUV directly to RGB bytes (with rotation and flip)
                val rgbBytes = yuvToRgbBytes(yuvBytes, width, height)
                println("DEBUG: Converted YUV to RGB bytes: ${rgbBytes.size} bytes")

                // 2. Apply cropping algorithm based on previous keypoints
                val croppedRgbBytes = cropRgbBytes(rgbBytes, width, height, previousKeypoints)
                println("DEBUG: Cropped RGB bytes: ${croppedRgbBytes.size} bytes")

                // 3. Resize to 192x192 (square with padding if necessary)
                val finalRgbBytes = resizeRgbBytesToSquare(croppedRgbBytes, width, height, 192)
                println("DEBUG: Final RGB bytes: ${finalRgbBytes.size} bytes")

                result.success(finalRgbBytes)
            } catch (e: Exception) {
                result.error("PROCESSING_ERROR", "Failed to process YUV image: ${e.message}", null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    /**
     * Convert YUV directly to RGB bytes
     */
    private fun yuvToRgbBytes(yuvBytes: ByteArray, width: Int, height: Int): ByteArray {
        // Try NV21 format first (most common)
        try {
            return yuvToRgbBytesNV21(yuvBytes, width, height)
        } catch (e: Exception) {
            println("DEBUG: NV21 format failed, trying YV12: ${e.message}")
            // Try YV12 format as fallback
            try {
                return yuvToRgbBytesYV12(yuvBytes, width, height)
            } catch (e2: Exception) {
                throw Exception("Failed to process YUV with both NV21 and YV12 formats: ${e2.message}")
            }
        }
    }

    /**
     * Convert NV21 YUV to RGB bytes
     */
    private fun yuvToRgbBytesNV21(yuvBytes: ByteArray, width: Int, height: Int): ByteArray {
        val rgbBytes = ByteArray(width * height * 3)
        val ySize = width * height
        val uvSize = ySize / 2
        
        val y = yuvBytes
        val u = yuvBytes.copyOfRange(ySize, ySize + uvSize)
        val v = yuvBytes.copyOfRange(ySize + uvSize, ySize + uvSize * 2)
        
        var rgbIndex = 0
        for (i in 0 until height) {
            for (j in 0 until width) {
                val yIndex = i * width + j
                val uvIndex = (i / 2) * (width / 2) + (j / 2)
                
                val yVal = y[yIndex].toInt() and 0xFF
                val uVal = u[uvIndex].toInt() and 0xFF
                val vVal = v[uvIndex].toInt() and 0xFF
                
                // YUV to RGB conversion
                var r = yVal + (1.370705 * (vVal - 128)).toInt()
                var g = yVal - (0.698001 * (vVal - 128)).toInt() - (0.337633 * (uVal - 128)).toInt()
                var b = yVal + (1.732446 * (uVal - 128)).toInt()
                
                // Clamp values
                r = r.coerceIn(0, 255)
                g = g.coerceIn(0, 255)
                b = b.coerceIn(0, 255)
                
                // Apply rotation and flip (270 degrees + horizontal flip)
                val rotatedI = j
                val rotatedJ = height - 1 - i
                val rotatedIndex = rotatedI * height + rotatedJ
                
                rgbBytes[rotatedIndex * 3] = r.toByte()
                rgbBytes[rotatedIndex * 3 + 1] = g.toByte()
                rgbBytes[rotatedIndex * 3 + 2] = b.toByte()
            }
        }
        
        return rgbBytes
    }

    /**
     * Convert YV12 YUV to RGB bytes
     */
    private fun yuvToRgbBytesYV12(yuvBytes: ByteArray, width: Int, height: Int): ByteArray {
        val rgbBytes = ByteArray(width * height * 3)
        val ySize = width * height
        val uvSize = ySize / 4
        
        val y = yuvBytes
        val v = yuvBytes.copyOfRange(ySize, ySize + uvSize)
        val u = yuvBytes.copyOfRange(ySize + uvSize, ySize + uvSize * 2)
        
        var rgbIndex = 0
        for (i in 0 until height) {
            for (j in 0 until width) {
                val yIndex = i * width + j
                val uvIndex = (i / 2) * (width / 2) + (j / 2)
                
                val yVal = y[yIndex].toInt() and 0xFF
                val uVal = u[uvIndex].toInt() and 0xFF
                val vVal = v[uvIndex].toInt() and 0xFF
                
                // YUV to RGB conversion
                var r = yVal + (1.370705 * (vVal - 128)).toInt()
                var g = yVal - (0.698001 * (vVal - 128)).toInt() - (0.337633 * (uVal - 128)).toInt()
                var b = yVal + (1.732446 * (uVal - 128)).toInt()
                
                // Clamp values
                r = r.coerceIn(0, 255)
                g = g.coerceIn(0, 255)
                b = b.coerceIn(0, 255)
                
                // Apply rotation and flip (270 degrees + horizontal flip)
                val rotatedI = j
                val rotatedJ = height - 1 - i
                val rotatedIndex = rotatedI * height + rotatedJ
                
                rgbBytes[rotatedIndex * 3] = r.toByte()
                rgbBytes[rotatedIndex * 3 + 1] = g.toByte()
                rgbBytes[rotatedIndex * 3 + 2] = b.toByte()
            }
        }
        
        return rgbBytes
    }

    /**
     * Crop RGB bytes based on previous keypoints
     * If previousKeypoints is null or empty, return the full image
     */
    private fun cropRgbBytes(rgbBytes: ByteArray, width: Int, height: Int, previousKeypoints: List<List<Double>>?): ByteArray {
        if (previousKeypoints.isNullOrEmpty()) {
            return rgbBytes
        }

        // Determine crop region
        val cropRegion = determineCropRegion(previousKeypoints, height, width)
        
        // Calculate crop rectangle in pixel coordinates
        val cropY = (cropRegion["y_min"]!! * height).coerceIn(0.0, (height - 1).toDouble()).toInt()
        val cropX = (cropRegion["x_min"]!! * width).coerceIn(0.0, (width - 1).toDouble()).toInt()
        val cropH = (cropRegion["height"]!! * height).coerceIn(1.0, (height - cropY).toDouble()).toInt()
        val cropW = (cropRegion["width"]!! * width).coerceIn(1.0, (width - cropX).toDouble()).toInt()
        
        println("DEBUG: Crop region - x:$cropX, y:$cropY, w:$cropW, h:$cropH")
        
        // Crop the RGB bytes
        val croppedRgbBytes = ByteArray(cropW * cropH * 3)
        var croppedIndex = 0
        
        for (y in cropY until cropY + cropH) {
            for (x in cropX until cropX + cropW) {
                val sourceIndex = (y * width + x) * 3
                croppedRgbBytes[croppedIndex++] = rgbBytes[sourceIndex]     // R
                croppedRgbBytes[croppedIndex++] = rgbBytes[sourceIndex + 1] // G
                croppedRgbBytes[croppedIndex++] = rgbBytes[sourceIndex + 2] // B
            }
        }
        
        return croppedRgbBytes
    }

    private val minCropKeypointScore = 0.2

    private val movenetKeypointDict = mapOf(
        "nose" to 0,
        "left_eye" to 1,
        "right_eye" to 2,
        "left_ear" to 3,
        "right_ear" to 4,
        "left_shoulder" to 5,
        "right_shoulder" to 6,
        "left_elbow" to 7,
        "right_elbow" to 8,
        "left_wrist" to 9,
        "right_wrist" to 10,
        "left_hip" to 11,
        "right_hip" to 12,
        "left_knee" to 13,
        "right_knee" to 14,
        "left_ankle" to 15,
        "right_ankle" to 16
    )

    private fun initCropRegion(imageHeight: Int, imageWidth: Int): Map<String, Double> {
        val yMin: Double
        val xMin: Double
        val boxHeight: Double
        val boxWidth: Double

        if (imageWidth > imageHeight) {
            boxHeight = imageWidth.toDouble() / imageHeight
            boxWidth = 1.0
            yMin = (imageHeight / 2.0 - imageWidth / 2.0) / imageHeight
            xMin = 0.0
        } else {
            boxHeight = 1.0
            boxWidth = imageHeight.toDouble() / imageWidth
            yMin = 0.0
            xMin = (imageWidth / 2.0 - imageHeight / 2.0) / imageWidth
        }

        return mapOf(
            "y_min" to yMin,
            "x_min" to xMin,
            "y_max" to (yMin + boxHeight),
            "x_max" to (xMin + boxWidth),
            "height" to boxHeight,
            "width" to boxWidth
        )
    }

    private fun torsoVisible(keypoints: List<List<Double>>): Boolean {
        val leftHip = keypoints[movenetKeypointDict["left_hip"]!!][2]
        val rightHip = keypoints[movenetKeypointDict["right_hip"]!!][2]
        val leftShoulder = keypoints[movenetKeypointDict["left_shoulder"]!!][2]
        val rightShoulder = keypoints[movenetKeypointDict["right_shoulder"]!!][2]

        return ((leftHip > minCropKeypointScore || rightHip > minCropKeypointScore) &&
                (leftShoulder > minCropKeypointScore || rightShoulder > minCropKeypointScore))
    }

    private fun determineTorsoAndBodyRange(
        keypoints: List<List<Double>>,
        targetKeypoints: Map<String, List<Double>>,
        centerY: Double,
        centerX: Double
    ): List<Double> {
        val torsoJoints = listOf("left_shoulder", "right_shoulder", "left_hip", "right_hip")

        var maxTorsoY = 0.0
        var maxTorsoX = 0.0
        for (joint in torsoJoints) {
            val dy = kotlin.math.abs(centerY - targetKeypoints[joint]!![0])
            val dx = kotlin.math.abs(centerX - targetKeypoints[joint]!![1])
            maxTorsoY = kotlin.math.max(maxTorsoY, dy)
            maxTorsoX = kotlin.math.max(maxTorsoX, dx)
        }

        var maxBodyY = 0.0
        var maxBodyX = 0.0
        for (joint in movenetKeypointDict.keys) {
            if (keypoints[movenetKeypointDict[joint]!!][2] < minCropKeypointScore) continue
            val dy = kotlin.math.abs(centerY - targetKeypoints[joint]!![0])
            val dx = kotlin.math.abs(centerX - targetKeypoints[joint]!![1])
            maxBodyY = kotlin.math.max(maxBodyY, dy)
            maxBodyX = kotlin.math.max(maxBodyX, dx)
        }

        return listOf(maxTorsoY, maxTorsoX, maxBodyY, maxBodyX)
    }

    private fun determineCropRegion(
        keypoints: List<List<Double>>,
        imageHeight: Int,
        imageWidth: Int
    ): Map<String, Double> {
        val targetKeypoints = mutableMapOf<String, List<Double>>()
        for (joint in movenetKeypointDict.keys) {
            val y = keypoints[movenetKeypointDict[joint]!!][0] * imageHeight
            val x = keypoints[movenetKeypointDict[joint]!!][1] * imageWidth
            targetKeypoints[joint] = listOf(y, x)
        }

        if (torsoVisible(keypoints)) {
            val centerY = (targetKeypoints["left_hip"]!![0] + targetKeypoints["right_hip"]!![0]) / 2
            val centerX = (targetKeypoints["left_hip"]!![1] + targetKeypoints["right_hip"]!![1]) / 2

            val range = determineTorsoAndBodyRange(keypoints, targetKeypoints, centerY, centerX)

            val a = listOf(range[0] * 1.9, range[1] * 1.9, range[2] * 1.2, range[3] * 1.2).maxOrNull()!!
            val b = listOf(centerX, imageWidth - centerX, centerY, imageHeight - centerY).maxOrNull()!!
            val cropLengthHalf = kotlin.math.min(a, b)

            val cropCornerY = centerY - cropLengthHalf
            val cropCornerX = centerX - cropLengthHalf

            if (cropLengthHalf > kotlin.math.max(imageWidth, imageHeight) / 2.0) {
                return initCropRegion(imageHeight, imageWidth)
            }

            val cropLength = cropLengthHalf * 2
            return mapOf(
                "y_min" to (cropCornerY / imageHeight),
                "x_min" to (cropCornerX / imageWidth),
                "y_max" to ((cropCornerY + cropLength) / imageHeight),
                "x_max" to ((cropCornerX + cropLength) / imageWidth),
                "height" to (cropLength / imageHeight),
                "width" to (cropLength / imageWidth)
            )
        } else {
            return initCropRegion(imageHeight, imageWidth)
        }
    }

    /**
     * Resize RGB bytes to square with padding if necessary
     */
    private fun resizeRgbBytesToSquare(rgbBytes: ByteArray, width: Int, height: Int, targetSize: Int): ByteArray {
        // If already square, just resize
        if (width == height) {
            return resizeRgbBytes(rgbBytes, width, height, targetSize, targetSize)
        }
        
        // Create a square with padding
        val size = maxOf(width, height)
        val squareRgbBytes = ByteArray(size * size * 3)
        
        // Fill with black background (0, 0, 0)
        for (i in squareRgbBytes.indices) {
            squareRgbBytes[i] = 0
        }
        
        // Calculate position to center the image
        val left = (size - width) / 2
        val top = (size - height) / 2
        
        // Copy the original image centered
        for (y in 0 until height) {
            for (x in 0 until width) {
                val sourceIndex = (y * width + x) * 3
                val targetIndex = ((top + y) * size + (left + x)) * 3
                
                squareRgbBytes[targetIndex] = rgbBytes[sourceIndex]     // R
                squareRgbBytes[targetIndex + 1] = rgbBytes[sourceIndex + 1] // G
                squareRgbBytes[targetIndex + 2] = rgbBytes[sourceIndex + 2] // B
            }
        }
        
        // Resize to target size
        return resizeRgbBytes(squareRgbBytes, size, size, targetSize, targetSize)
    }

    /**
     * Resize RGB bytes using nearest neighbor interpolation
     */
    private fun resizeRgbBytes(rgbBytes: ByteArray, srcWidth: Int, srcHeight: Int, dstWidth: Int, dstHeight: Int): ByteArray {
        val resizedRgbBytes = ByteArray(dstWidth * dstHeight * 3)
        
        for (y in 0 until dstHeight) {
            for (x in 0 until dstWidth) {
                val srcX = (x * srcWidth) / dstWidth
                val srcY = (y * srcHeight) / dstHeight
                
                val srcIndex = (srcY * srcWidth + srcX) * 3
                val dstIndex = (y * dstWidth + x) * 3
                
                resizedRgbBytes[dstIndex] = rgbBytes[srcIndex]     // R
                resizedRgbBytes[dstIndex + 1] = rgbBytes[srcIndex + 1] // G
                resizedRgbBytes[dstIndex + 2] = rgbBytes[srcIndex + 2] // B
            }
        }
        
        return resizedRgbBytes
    }


}
