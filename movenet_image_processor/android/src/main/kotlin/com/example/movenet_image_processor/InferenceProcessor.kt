package com.example.movenet_image_processor

import java.nio.ByteBuffer
import java.nio.ByteOrder
import org.tensorflow.lite.DataType

object InferenceProcessor {
    // Constants
    private const val INPUT_SIZE = 110592 // 192*192*3 bytes for UINT8 input
    private const val OUTPUT_SIZE = 204    // 17*3*4 bytes for FLOAT32 output (51 floats)
    private const val KEYPOINT_COUNT = 17
    private const val VALUES_PER_KEYPOINT = 3
    private const val TARGET_SIZE = 192
    private val ZERO_KEYPOINTS = Array(17) { FloatArray(3) { 0f } }

    // Buffers
    private var yuvBuffer: ByteArray? = null
    private var rgbBuffer: ByteArray? = null
    private val keypointsListBuffer: ArrayList<ArrayList<Double>> =
        ArrayList<ArrayList<Double>>(KEYPOINT_COUNT).also { outer ->
            repeat(KEYPOINT_COUNT) {
                outer.add(ArrayList<Double>(VALUES_PER_KEYPOINT).also { inner ->
                    repeat(VALUES_PER_KEYPOINT) { inner.add(0.0) }
                })
            }
        }

    fun processFrame(
        planeBytes: List<ByteArray>,
        bytesPerRow: List<Int>,
        bytesPerPixel: List<Int>,
        width: Int,
        height: Int,
        sensorOrientation: Int,
    ): ArrayList<ArrayList<Double>> {
        // Initialize buffers
        initFrameBuffers(width, height)

        // 1. Extract YUV data with proper stride handling
        val localYuv = yuvBuffer!!
        extractYuvDataWithStride(
            planeBytes,
            bytesPerRow,
            bytesPerPixel,
            width,
            height,
            localYuv,
        )

        // 2. Convert YUV to RGB bytes
        val localRgb = rgbBuffer!!
        yuv420ToRgb(localYuv, width, height, localRgb)

        // 3. Rotate RGB based on sensor orientation
        val rotatedRgbBytes = rotateRgbBytes(localRgb, width, height, sensorOrientation)
        val rotatedWidth =
            if (sensorOrientation == 90 || sensorOrientation == 270) height else width
        val rotatedHeight =
            if (sensorOrientation == 90 || sensorOrientation == 270) width else height

        // 4. Resize to 192x192 (add padding if necessary) and get padding info
        val (resizedRgb, paddingRatio) =
            resizeRgbBytesToSquare(rotatedRgbBytes, rotatedWidth, rotatedHeight, TARGET_SIZE)

        // 5. Run inference on processed image
        val keypoints = runInferenceOnResizedRgb(resizedRgb)

        // 6. Flip keypoints horizontally in-place (front camera mirroring)
        if (sensorOrientation == 270) {
            flipKeypointsHorizontally(keypoints)
        }

        // 7. Apply inverse padding
        removeHorizontalPadding(keypoints, paddingRatio)

        // 8. Convert Array<FloatArray> to List<List<Double>> for Dart
        floatArrayToListDouble(keypoints)

        return keypointsListBuffer
    }

    private fun initFrameBuffers(width: Int, height: Int) {
        val ySize = width * height
        val uvSize = ySize / 4
        val expectedYuvSize = ySize + uvSize * 2
        val expectedRgbSize = width * height * 3
        if (yuvBuffer == null || yuvBuffer!!.size != expectedYuvSize) {
            yuvBuffer = ByteArray(expectedYuvSize)
        }
        if (rgbBuffer == null || rgbBuffer!!.size != expectedRgbSize) {
            rgbBuffer = ByteArray(expectedRgbSize)
        }

        println("DEBUG: Initialized Frame Buffers")
    }

    private fun extractYuvDataWithStride(
        planeBytes: List<ByteArray>,
        bytesPerRow: List<Int>,
        bytesPerPixel: List<Int>,
        width: Int,
        height: Int,
        outYuv: ByteArray,
    ) {
        if (planeBytes.size < 3) {
            // Fallback: concatenate into outYuv if provided
            var dst = 0
            for (plane in planeBytes) {
                val len = minOf(plane.size, outYuv.size - dst)
                System.arraycopy(plane, 0, outYuv, dst, len)
                dst += len
                if (dst >= outYuv.size) break
            }
            return
        }

        val yPlane = planeBytes[0]
        val uPlane = planeBytes[1]
        val vPlane = planeBytes[2]

        var offset = 0
        offset += extractPlaneData(
            yPlane,
            width,
            height,
            bytesPerRow[0],
            bytesPerPixel[0],
            outYuv,
            offset,
        )
        offset += extractPlaneData(
            uPlane,
            width / 2,
            height / 2,
            bytesPerRow[1],
            bytesPerPixel[1],
            outYuv,
            offset,
        )
        extractPlaneData(
            vPlane,
            width / 2,
            height / 2,
            bytesPerRow[2],
            bytesPerPixel[2],
            outYuv,
            offset,
        )
    }

    private fun extractPlaneData(
        src: ByteArray,
        planeWidth: Int,
        planeHeight: Int,
        rowStrideBytes: Int,
        bytesPerPixel: Int,
        dst: ByteArray,
        dstOffset: Int,
    ): Int {
        var writeIndex = dstOffset
        val maxWrite = dst.size
        for (row in 0 until planeHeight) {
            val rowStart = row * rowStrideBytes
            for (col in 0 until planeWidth) {
                val srcIndex = rowStart + col * bytesPerPixel
                if (srcIndex < src.size && writeIndex < maxWrite) {
                    dst[writeIndex++] = src[srcIndex]
                }
            }
        }
        return writeIndex - dstOffset
    }

    private fun yuv420ToRgb(
        yuvBytes: ByteArray,
        width: Int,
        height: Int,
        outRgb: ByteArray,
    ) {
        val ySize = width * height
        val uvSize = ySize / 4
        val expectedYuvSize = ySize + uvSize * 2

        if (yuvBytes.size != expectedYuvSize) {
            if (yuvBytes.size < expectedYuvSize) {
                // Fill with zeros if source too small
                java.util.Arrays.fill(outRgb, 0.toByte())
                return
            }
            if (yuvBytes.size > expectedYuvSize) {
                val truncated = ByteArray(expectedYuvSize)
                System.arraycopy(yuvBytes, 0, truncated, 0, expectedYuvSize)
                yuv420ToRgb(truncated, width, height, outRgb)
                return
            }
        }

        for (y in 0 until height) {
            for (x in 0 until width) {
                val yIndex = y * width + x
                val uvIndex = (y / 2) * (width / 2) + (x / 2)
                if (yIndex >= ySize || uvIndex >= uvSize) continue

                val yVal = yuvBytes[yIndex].toInt() and 0xFF
                val uVal = yuvBytes[ySize + uvIndex].toInt() and 0xFF
                val vVal = yuvBytes[ySize + uvSize + uvIndex].toInt() and 0xFF

                val yF = yVal.toFloat()
                val uF = (uVal - 128).toFloat()
                val vF = (vVal - 128).toFloat()

                var r = (yF + 1.370705f * vF).toInt()
                var g = (yF - 0.698001f * vF - 0.337633f * uF).toInt()
                var b = (yF + 1.732446f * uF).toInt()

                r = r.coerceIn(0, 255)
                g = g.coerceIn(0, 255)
                b = b.coerceIn(0, 255)

                val rgbIndex = (y * width + x) * 3
                outRgb[rgbIndex] = r.toByte()
                outRgb[rgbIndex + 1] = g.toByte()
                outRgb[rgbIndex + 2] = b.toByte()
            }
        }
    }

    private fun rotateRgbBytes(
        rgbBytes: ByteArray,
        width: Int,
        height: Int,
        sensorOrientation: Int,
    ): ByteArray {
        if (sensorOrientation == 0) return rgbBytes
        val swap = sensorOrientation == 90 || sensorOrientation == 270
        val rotatedWidth = if (swap) height else width
        val rotatedHeight = if (swap) width else height
        val rotated = ByteArray(rotatedWidth * rotatedHeight * 3)

        for (y in 0 until height) {
            for (x in 0 until width) {
                val srcIndex = (y * width + x) * 3
                val (dstX, dstY) = when (sensorOrientation) {
                    90 -> Pair(height - 1 - y, x)
                    180 -> Pair(width - 1 - x, height - 1 - y)
                    270 -> Pair(y, width - 1 - x)
                    else -> Pair(x, y)
                }
                val dstIndex = (dstY * rotatedWidth + dstX) * 3
                if (dstIndex + 2 < rotated.size) {
                    rotated[dstIndex] = rgbBytes[srcIndex]
                    rotated[dstIndex + 1] = rgbBytes[srcIndex + 1]
                    rotated[dstIndex + 2] = rgbBytes[srcIndex + 2]
                }
            }
        }
        return rotated
    }

    private fun resizeRgbBytesToSquare(
        rgbBytes: ByteArray,
        width: Int,
        height: Int,
        targetSize: Int,
    ): Pair<ByteArray, Float> {
        if (width == height) {
            return Pair(resizeRgbBytes(rgbBytes, width, height, targetSize, targetSize), 0.0f)
        }

        val squareSize = maxOf(width, height)
        val square = ByteArray(squareSize * squareSize * 3) { 0 }
        val left = (squareSize - width) / 2
        val top = (squareSize - height) / 2

        for (y in 0 until height) {
            for (x in 0 until width) {
                val srcIndex = (y * width + x) * 3
                val dstIndex = ((top + y) * squareSize + (left + x)) * 3
                square[dstIndex] = rgbBytes[srcIndex]
                square[dstIndex + 1] = rgbBytes[srcIndex + 1]
                square[dstIndex + 2] = rgbBytes[srcIndex + 2]
            }
        }

        val resized = resizeRgbBytes(square, squareSize, squareSize, targetSize, targetSize)
        val paddingRatio = left.toFloat() / squareSize
        return Pair(resized, paddingRatio)
    }

    private fun resizeRgbBytes(
        rgbBytes: ByteArray,
        srcWidth: Int,
        srcHeight: Int,
        dstWidth: Int,
        dstHeight: Int,
    ): ByteArray {
        val resized = ByteArray(dstWidth * dstHeight * 3)
        for (y in 0 until dstHeight) {
            for (x in 0 until dstWidth) {
                val srcX = (x * srcWidth) / dstWidth
                val srcY = (y * srcHeight) / dstHeight
                val srcIndex = (srcY * srcWidth + srcX) * 3
                val dstIndex = (y * dstWidth + x) * 3
                resized[dstIndex] = rgbBytes[srcIndex]
                resized[dstIndex + 1] = rgbBytes[srcIndex + 1]
                resized[dstIndex + 2] = rgbBytes[srcIndex + 2]
            }
        }
        return resized
    }

    private fun runInferenceOnResizedRgb(resizedRgb: ByteArray): Array<FloatArray> {
        return ModelLoader.withInterpreterBuffers { interpreter, inBuf, outBuf ->
            try {
                require(resizedRgb.size == INPUT_SIZE) {
                    "Invalid input size. Expected $INPUT_SIZE bytes, got ${resizedRgb.size}"
                }

                // Prepare input buffer
                inBuf.clear()
                inBuf.put(resizedRgb)
                inBuf.rewind()

                // Prepare output buffer
                outBuf.clear()

                // Run inference
                interpreter.run(inBuf, outBuf)

                // Parse output
                outBuf.rewind()
                FloatArray(KEYPOINT_COUNT * VALUES_PER_KEYPOINT).let { outArray ->
                    outBuf.asFloatBuffer().get(outArray)
                    parseMovenetOutputFloat(outArray)
                }
            } catch (e: Exception) {
                println("Inference failed: ${e.message}")
                ZERO_KEYPOINTS
            }
        } ?: ZERO_KEYPOINTS
    }

    // Returns Array<FloatArray> [17][3] (y, x, score).
    private fun parseMovenetOutputFloat(flatOutput: FloatArray): Array<FloatArray> {
        val result = Array(17) { FloatArray(3) }
        var inputIdx = 0
        for (i in 0..16) {
            result[i][0] = flatOutput[inputIdx++] // y
            result[i][1] = flatOutput[inputIdx++] // x
            result[i][2] = flatOutput[inputIdx++] // confidence
        }
        return result
    }

    private fun flipKeypointsHorizontally(keypoints: Array<FloatArray>) {
        for (i in keypoints.indices) {
            keypoints[i][1] = (1f - keypoints[i][1]).coerceIn(0f, 1f)
        }
    }

    private fun removeHorizontalPadding(
        keypoints: Array<FloatArray>,
        paddingRatio: Float,
    ) {
        if (paddingRatio == 0f) return
        val denom = 1f - 2f * paddingRatio
        if (denom <= 0f) return
        for (i in keypoints.indices) {
            val x = keypoints[i][1]
            val xTransformed = (x - paddingRatio) / denom
            keypoints[i][1] = xTransformed.coerceIn(0f, 1f)
        }
    }

    fun floatArrayToListDouble(keypoints: Array<FloatArray>) {
        for (i in 0 until KEYPOINT_COUNT) {
            val kp = keypoints[i]
            val row = keypointsListBuffer[i]
            row[0] = kp[0].toDouble()
            row[1] = kp[1].toDouble()
            row[2] = kp[2].toDouble()
        }
    }

}


