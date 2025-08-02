package com.example.image_processing_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ImageProcessingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    // Cache for rotation indices to improve performance
    private data class RotationCacheKey(val width: Int, val height: Int, val orientation: Int)

    private val rotationIndicesCache = mutableMapOf<RotationCacheKey, IntArray>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "image_processing_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "processYUVPlanes") {
            val yuvBytes = call.argument<ByteArray>("yuvBytes")!!
            val width = call.argument<Int>("width")!!
            val height = call.argument<Int>("height")!!
            val sensorOrientation = call.argument<Int>("sensorOrientation") ?: 0

            println("DEBUG: Processing ${width}x${height} image with ${sensorOrientation}° orientation")
            println("DEBUG: YUV data size: ${yuvBytes.size}")
            println("DEBUG: Expected YUV size: ${width * height * 3 / 2}")
            println("DEBUG: Expected RGB size: ${width * height * 3}")

            try {
                // 1. Convert YUV to RGB bytes (with rotation and flip) - no cropping
                val rgbBytes = yuv420ToRgbBytes(yuvBytes, width, height, sensorOrientation)

                // 2. Resize to 192x192 (square with padding if necessary)
                val finalRgbBytes = resizeRgbBytesToSquare(rgbBytes, width, height, 192)

                result.success(finalRgbBytes)
            } catch (e: Exception) {
                println("DEBUG: Error processing image: ${e.message}")
                e.printStackTrace()
                result.error("PROCESSING_ERROR", "Failed to process YUV image: ${e.message}", null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Clear cache to prevent memory leaks
        rotationIndicesCache.clear()
    }

    /**
     * Clear rotation indices cache to free memory
     * Call this when memory usage becomes a concern
     */
    fun clearRotationCache() {
        rotationIndicesCache.clear()
    }

    /**
     * Convert YUV420 to RGB bytes
     */
    private fun yuv420ToRgbBytes(
        yuvBytes: ByteArray,
        width: Int,
        height: Int,
        sensorOrientation: Int
    ): ByteArray {
        // ROTATION LOGIC COMMENTED OUT FOR TESTING
        // // Determine rotated dimensions
        // val (rotatedWidth, rotatedHeight) = when (sensorOrientation) {
        //     90, 270 -> Pair(height, width)  // Dimensions swap for 90° and 270°
        //     else -> Pair(width, height)     // Dimensions stay the same for 0° and 180°
        // }

        // Use original dimensions without rotation
        val rotatedWidth = width
        val rotatedHeight = height

        val rgbBytes = ByteArray(rotatedWidth * rotatedHeight * 3)
        val ySize = width * height
        val uvSize = ySize / 4

        println("DEBUG: YUV data size: ${yuvBytes.size}")
        println("DEBUG: Expected YUV size for ${width}x${height}: ${ySize + uvSize * 2}")
        println("DEBUG: Using original dimensions: ${rotatedWidth}x${rotatedHeight} (rotation disabled)")

        // For YUV420, the data is typically: Y plane + U plane + V plane
        // Add bounds checking to prevent ArrayIndexOutOfBoundsException
        val expectedYuvSize = ySize + uvSize * 2
        if (yuvBytes.size != expectedYuvSize) {
            println("DEBUG: YUV size mismatch - expected: $expectedYuvSize, actual: ${yuvBytes.size}")
            // If the YUV data is smaller than expected, we need to handle this gracefully
            if (yuvBytes.size < expectedYuvSize) {
                throw IllegalArgumentException("YUV data too small - expected: $expectedYuvSize, actual: ${yuvBytes.size}")
            }
        }

        // ROTATION LOGIC COMMENTED OUT FOR TESTING
        // // Get or compute rotation indices from cache for performance
        // val cacheKey = RotationCacheKey(width, height, sensorOrientation)
        // val rotatedIndices = rotationIndicesCache.getOrPut(cacheKey) {
        //     IntArray(rotatedWidth * rotatedHeight) { i ->
        //         val rotatedY = i / rotatedWidth
        //         val rotatedX = i % rotatedWidth
        //         when (sensorOrientation) {
        //             270 -> {
        //                 // Rotate 270° clockwise: (x, y) -> (y, width-1-x)
        //                 val originalY = rotatedX
        //                 val originalX = width - 1 - rotatedY
        //                 originalY * width + originalX
        //             }
        //
        //             90 -> {
        //                 // Rotate 90° clockwise: (x, y) -> (height-1-y, x)
        //                 val originalY = height - 1 - rotatedX
        //                 val originalX = rotatedY
        //                 originalY * width + originalX
        //             }
        //
        //             180 -> {
        //                 // Rotate 180°: (x, y) -> (height-1-y, width-1-x)
        //                 val originalY = height - 1 - rotatedY
        //                 val originalX = width - 1 - rotatedX
        //                 originalY * width + originalX
        //             }
        //
        //             else -> {
        //                 // No rotation: (x, y) -> (x, y)
        //                 val originalY = rotatedY
        //                 val originalX = rotatedX
        //                 originalY * width + originalX
        //             }
        //         }
        //     }
        // }

        // ROTATION LOGIC COMMENTED OUT FOR TESTING
        // // Process each pixel using precomputed indices - OPTIMIZED for performance
        // for (rotatedIndex in 0 until rotatedWidth * rotatedHeight) {
        //     val originalPixelIndex = rotatedIndices[rotatedIndex]
        //     val originalY = originalPixelIndex / width
        //     val originalX = originalPixelIndex % width
        //
        //     // Ensure bounds checking for safety
        //     if (originalY >= height || originalX >= width) {
        //         println("DEBUG: Out of bounds - originalY: $originalY, originalX: $originalX, height: $height, width: $width")
        //         continue
        //     }
        //
        //     val yIndex = originalY * width + originalX
        //     val uvIndex = (originalY / 2) * (width / 2) + (originalX / 2)
        //
        //     // Ensure UV indices are within bounds
        //     if (yIndex >= ySize || uvIndex >= uvSize) {
        //         println("DEBUG: UV bounds check failed - yIndex: $yIndex, uvIndex: $uvIndex, ySize: $ySize, uvSize: $uvSize")
        //         continue
        //     }
        //
        //     val yVal = yuvBytes[yIndex].toInt() and 0xFF
        //     val uVal = yuvBytes[ySize + uvIndex].toInt() and 0xFF
        //     val vVal = yuvBytes[ySize + uvSize + uvIndex].toInt() and 0xFF
        //
        //     // YUV to RGB conversion - OPTIMIZED with precomputed constants
        //     val yValF = yVal.toFloat()
        //     val uValF = (uVal - 128).toFloat()
        //     val vValF = (vVal - 128).toFloat()
        //
        //     var r = (yValF + 1.370705f * vValF).toInt()
        //     var g = (yValF - 0.698001f * vValF - 0.337633f * uValF).toInt()
        //     var b = (yValF + 1.732446f * uValF).toInt()
        //
        //     // Clamp values
        //     r = r.coerceIn(0, 255)
        //     g = g.coerceIn(0, 255)
        //     b = b.coerceIn(0, 255)
        //
        //     // Write to rotated position using precomputed index
        //     val finalIndex = rotatedIndex * 3
        //     rgbBytes[finalIndex] = r.toByte()
        //     rgbBytes[finalIndex + 1] = g.toByte()
        //     rgbBytes[finalIndex + 2] = b.toByte()
        // }

        // SIMPLE DIRECT CONVERSION WITHOUT ROTATION
        for (y in 0 until height) {
            for (x in 0 until width) {
                val yIndex = y * width + x
                val uvIndex = (y / 2) * (width / 2) + (x / 2)

                // Ensure UV indices are within bounds
                if (yIndex >= ySize || uvIndex >= uvSize) {
                    println("DEBUG: UV bounds check failed - yIndex: $yIndex, uvIndex: $uvIndex, ySize: $ySize, uvSize: $uvSize")
                    continue
                }

                val yVal = yuvBytes[yIndex].toInt() and 0xFF
                val uVal = yuvBytes[ySize + uvIndex].toInt() and 0xFF
                val vVal = yuvBytes[ySize + uvSize + uvIndex].toInt() and 0xFF

                // YUV to RGB conversion
                val yValF = yVal.toFloat()
                val uValF = (uVal - 128).toFloat()
                val vValF = (vVal - 128).toFloat()

                var r = (yValF + 1.370705f * vValF).toInt()
                var g = (yValF - 0.698001f * vValF - 0.337633f * uValF).toInt()
                var b = (yValF + 1.732446f * uValF).toInt()

                // Clamp values
                r = r.coerceIn(0, 255)
                g = g.coerceIn(0, 255)
                b = b.coerceIn(0, 255)

                // Write to RGB array
                val rgbIndex = (y * width + x) * 3
                rgbBytes[rgbIndex] = r.toByte()
                rgbBytes[rgbIndex + 1] = g.toByte()
                rgbBytes[rgbIndex + 2] = b.toByte()
            }
        }

        return rgbBytes
    }





    /**
     * Resize RGB bytes to square with padding if necessary
     */
    private fun resizeRgbBytesToSquare(
        rgbBytes: ByteArray,
        width: Int,
        height: Int,
        targetSize: Int
    ): ByteArray {
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
    private fun resizeRgbBytes(
        rgbBytes: ByteArray,
        srcWidth: Int,
        srcHeight: Int,
        dstWidth: Int,
        dstHeight: Int
    ): ByteArray {
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
