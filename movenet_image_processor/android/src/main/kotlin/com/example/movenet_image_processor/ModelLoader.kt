package com.example.movenet_image_processor

import android.content.Context
import java.io.FileInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.gpu.GpuDelegate
import java.util.concurrent.locks.ReentrantLock

object ModelLoader {
    // Interpreter constants
    private const val ASSET_NAME: String = "movenet_singlepose_lightning.tflite"
    private const val GPU_NUM_THREADS: Int = 2
    private const val CPU_NUM_THREADS: Int = 4

    @Volatile
    private var interpreter: Interpreter? = null

    @Volatile
    private var gpuDelegate: GpuDelegate? = null

    @Volatile
    private var inputBuffer: ByteBuffer? = null

    @Volatile
    private var outputBuffer: ByteBuffer? = null

    private val initLock = Any()
    private val inferenceLock = ReentrantLock()

    val isInitialized: Boolean
        get() = interpreter != null

    fun initializeModel(
        context: Context,
    ) {
        if (interpreter != null) {
            return
        }
        synchronized(initLock) {
            if (interpreter != null) return

            val appContext = context.applicationContext
            val buffer = try {
                loadModelFromAssets(appContext, ASSET_NAME)
            } catch (e: IOException) {
                throw RuntimeException(
                    "Failed to load TFLite model from Android assets: $ASSET_NAME",
                    e
                )
            }

            interpreter = try {
                gpuDelegate = GpuDelegate(GpuDelegate.Options().apply {
                    setInferencePreference(GpuDelegate.Options.INFERENCE_PREFERENCE_SUSTAINED_SPEED)
                    setPrecisionLossAllowed(true)
                })

                val gpuOptions = Interpreter.Options().apply {
                    addDelegate(gpuDelegate)
                    setNumThreads(CPU_NUM_THREADS)
                }

                println("DEBUG: GPU delegate enabled.")
                Interpreter(buffer, gpuOptions)
            } catch (e: Exception) {
                // Fallback to CPU if GPU initialization fails
                println("DEBUG: GPU delegate initialization failed, falling back to CPU.")
                println("DEBUG: Error: ${e.message}")
                gpuDelegate?.close()
                gpuDelegate = null

                val cpuOptions = Interpreter.Options().apply {
                    setNumThreads(CPU_NUM_THREADS)
                }
                println("DEBUG: Using CPU with $CPU_NUM_THREADS threads.")
                Interpreter(buffer, cpuOptions)
            }

            // Allocate persistent input/output buffers sized by actual tensors
            interpreter?.let { interp ->
                val inputBytes = interp.getInputTensor(0).numBytes()
                val outputBytes = interp.getOutputTensor(0).numBytes()

                inputBuffer =
                    ByteBuffer.allocateDirect(inputBytes).apply { order(ByteOrder.nativeOrder()) }
                outputBuffer =
                    ByteBuffer.allocateDirect(outputBytes).apply { order(ByteOrder.nativeOrder()) }

            }
            println("DEBUG: ModelLoader initialization complete!")
        }
    }

    fun getInterpreter(): Interpreter =
        interpreter ?: throw IllegalStateException("ModelLoader is not initialized.")

    fun <T> withInterpreterBuffers(block: (Interpreter, ByteBuffer, ByteBuffer) -> T): T? {
        val interp = interpreter ?: return null
        val inBuf = inputBuffer ?: return null
        val outBuf = outputBuffer ?: return null
        return if (inferenceLock.tryLock()) {
            try {
                block(interp, inBuf, outBuf)
            } finally {
                inferenceLock.unlock()
            }
        } else null
    }

    fun closeModel() {
        synchronized(initLock) {
            interpreter?.close()
            interpreter = null

            gpuDelegate?.close()
            gpuDelegate = null

            inputBuffer = null
            outputBuffer = null
        }
    }

    @Throws(IOException::class)
    private fun loadModelFromAssets(context: Context, assetName: String): ByteBuffer {
        try {
            context.assets.openFd(assetName).use { afd ->
                FileInputStream(afd.fileDescriptor).channel.use { channel ->
                    val startOffset = afd.startOffset
                    val declaredLength = afd.declaredLength
                    println("DEBUG: Memory-mapped I/O used.")
                    return channel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
                }
            }
        } catch (_: IOException) {
            context.assets.open(assetName).use { inputStream ->
                val bytes = inputStream.readBytes()
                val directBuffer = ByteBuffer.allocateDirect(bytes.size)
                directBuffer.order(ByteOrder.nativeOrder())
                directBuffer.put(bytes)
                directBuffer.rewind()
                println("DEBUG: Stream copy used.")
                return directBuffer
            }
        }
    }
}
