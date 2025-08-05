package com.example.image_processing_plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ImageProcessingPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "image_processing_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "processYUVPlanesWithStride" -> {
                val planeBytes = call.argument<List<ByteArray>>("planeBytes")!!
                val bytesPerRow = call.argument<List<Int>>("bytesPerRow")!!
                val bytesPerPixel = call.argument<List<Int>>("bytesPerPixel")!!
                val width = call.argument<Int>("width")!!
                val height = call.argument<Int>("height")!!
                val sensorOrientation = call.argument<Int>("sensorOrientation") ?: 0

                println("DEBUG: Orientation: $sensorOrientation")

                try {
                    // 1. Extract YUV data with proper stride handling
                    val yuvBytes = extractYUVDataWithStride(planeBytes, bytesPerRow, bytesPerPixel, width, height)

                    // 2. Convert YUV to RGB bytes
                    val rgbBytes = yuv420ToRgbBytes(yuvBytes, width, height)

                    // 3. Rotate RGB based on sensor orientation
                    val rotatedRgbBytes = rotateRgbBytes(rgbBytes, width, height, sensorOrientation)
                    val rotatedWidth = if (sensorOrientation == 90 || sensorOrientation == 270) height else width
                    val rotatedHeight = if (sensorOrientation == 90 || sensorOrientation == 270) width else height

                    // 4. Resize to 192x192 (square with padding if necessary)
                    val finalRgbBytes = resizeRgbBytesToSquare(rotatedRgbBytes, rotatedWidth, rotatedHeight, 192)

                    result.success(finalRgbBytes)
                } catch (e: Exception) {
                    result.error("PROCESSING_ERROR", "Failed to process YUV image with stride: ${e.message}", null)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }



    /**
     * Convert YUV420 to RGB bytes
     */
    private fun yuv420ToRgbBytes(
        yuvBytes: ByteArray,
        width: Int,
        height: Int
    ): ByteArray {
        val rgbBytes = ByteArray(width * height * 3)
        val ySize = width * height
        val uvSize = ySize / 4

        // For YUV420, the data is typically: Y plane + U plane + V plane
        // Add bounds checking to prevent ArrayIndexOutOfBoundsException
        val expectedYuvSize = ySize + uvSize * 2
        if (yuvBytes.size != expectedYuvSize) {
            // If the YUV data is smaller than expected, we need to handle this gracefully
            if (yuvBytes.size < expectedYuvSize) {
                // Return a black image instead of throwing an exception
                return ByteArray(width * height * 3) { 0 }
            }
            // If larger, truncate to expected size
            if (yuvBytes.size > expectedYuvSize) {
                val truncatedYuvBytes = ByteArray(expectedYuvSize)
                System.arraycopy(yuvBytes, 0, truncatedYuvBytes, 0, expectedYuvSize)
                return yuv420ToRgbBytes(truncatedYuvBytes, width, height)
            }
        }

        // SIMPLE DIRECT CONVERSION WITHOUT ROTATION
        for (y in 0 until height) {
            for (x in 0 until width) {
                val yIndex = y * width + x
                val uvIndex = (y / 2) * (width / 2) + (x / 2)

                // Ensure UV indices are within bounds
                if (yIndex >= ySize || uvIndex >= uvSize) {
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
     * Extract YUV data with proper stride handling
     */
    private fun extractYUVDataWithStride(
        planeBytes: List<ByteArray>,
        bytesPerRow: List<Int>,
        bytesPerPixel: List<Int>,
        width: Int,
        height: Int
    ): ByteArray {
        if (planeBytes.size < 3) {
            // Fallback to simple concatenation if not enough planes
            return planeBytes.fold(ByteArray(0)) { acc, plane ->
                acc + plane
            }
        }

        val yPlane = planeBytes[0]
        val uPlane = planeBytes[1]
        val vPlane = planeBytes[2]

        val yBytesPerRow = bytesPerRow[0]
        val uBytesPerRow = bytesPerRow[1]
        val vBytesPerRow = bytesPerRow[2]

        val yBytesPerPixel = bytesPerPixel[0]
        val uBytesPerPixel = bytesPerPixel[1]
        val vBytesPerPixel = bytesPerPixel[2]

        // Extract Y plane data (remove stride padding)
        val yBytes = extractPlaneData(yPlane, width, height, yBytesPerRow, yBytesPerPixel)

        // Extract U and V plane data (remove stride padding)
        val uBytes = extractPlaneData(uPlane, width / 2, height / 2, uBytesPerRow, uBytesPerPixel)
        val vBytes = extractPlaneData(vPlane, width / 2, height / 2, vBytesPerRow, vBytesPerPixel)

        // Combine Y, U, V planes
        val result = yBytes + uBytes + vBytes
        return result
    }

    /**
     * Extract plane data removing stride padding
     */
    private fun extractPlaneData(
        bytes: ByteArray,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        bytesPerPixel: Int
    ): ByteArray {
        // If no stride padding, return the bytes as is
        if (bytesPerRow == width * bytesPerPixel) {
            return bytes
        }

        println("DEBUG: Stride padding detected - bytesPerRow: $bytesPerRow, expected: ${width * bytesPerPixel}")
        
        // Remove stride padding by copying only the valid data
        val result = ByteArray(width * height)
        var resultIndex = 0

        for (row in 0 until height) {
            val rowStart = row * bytesPerRow
            for (col in 0 until width) {
                val sourceIndex = rowStart + col * bytesPerPixel
                if (sourceIndex < bytes.size) {
                    result[resultIndex++] = bytes[sourceIndex]
                }
            }
        }

        return result
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

    /**
     * Rotate RGB bytes based on sensor orientation
     * sensorOrientation: 0, 90, 180, or 270 degrees clockwise
     */
    private fun rotateRgbBytes(
        rgbBytes: ByteArray,
        width: Int,
        height: Int,
        sensorOrientation: Int
    ): ByteArray {
        // Handle 0 degrees (no rotation)
        if (sensorOrientation == 0) {
            return rgbBytes
        }

        // For 90 and 270 degrees, dimensions are swapped
        val isDimensionSwap = sensorOrientation == 90 || sensorOrientation == 270
        val rotatedWidth = if (isDimensionSwap) height else width
        val rotatedHeight = if (isDimensionSwap) width else height
        
        val rotatedRgbBytes = ByteArray(rotatedWidth * rotatedHeight * 3)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val srcIndex = (y * width + x) * 3
                
                // Calculate destination coordinates based on rotation
                val dstX: Int
                val dstY: Int
                when (sensorOrientation) {
                    90 -> {
                        dstX = height - 1 - y
                        dstY = x
                    }
                    180 -> {
                        dstX = width - 1 - x
                        dstY = height - 1 - y
                    }
                    270 -> {
                        dstX = y
                        dstY = width - 1 - x
                    }
                    else -> {
                        dstX = x
                        dstY = y
                    }
                }
                
                val dstIndex = (dstY * rotatedWidth + dstX) * 3

                // Ensure we don't write beyond the bounds
                if (dstIndex + 2 < rotatedRgbBytes.size) {
                    rotatedRgbBytes[dstIndex] = rgbBytes[srcIndex]     // R
                    rotatedRgbBytes[dstIndex + 1] = rgbBytes[srcIndex + 1] // G
                    rotatedRgbBytes[dstIndex + 2] = rgbBytes[srcIndex + 2] // B
                }
            }
        }

        return rotatedRgbBytes
    }

}
