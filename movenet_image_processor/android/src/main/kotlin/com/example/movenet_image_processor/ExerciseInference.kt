package com.example.movenet_image_processor

import android.content.Context
import java.io.FileInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import org.tensorflow.lite.Interpreter
import java.util.concurrent.locks.ReentrantLock

object ExerciseInference {
    // Interpreter constants
    private val CPU_NUM_THREADS: Int = 4

    @Volatile
    private var interpreter: Interpreter? = null

    @Volatile
    private var inputBuffer: ByteBuffer? = null

    @Volatile
    private var jointMaskBuffer: ByteBuffer? = null
    
    @Volatile
    private var formScoreBuffer: ByteBuffer? = null
    
    @Volatile
    private var instructionIdBuffer: ByteBuffer? = null

    private val initLock = Any()
    private val inferenceLock = ReentrantLock()
    
    private var currentExercise: String? = null

    val isInitialized: Boolean
        get() = interpreter != null

    fun initExerciseModel(
        context: Context,
        exercise: String
    ) {
        // Map exercise name to asset file name
        val assetName = when (exercise.lowercase()) {
            "overhead presses" -> "overhead_pose_float16.tflite"
            "bicep curls" -> "bicep_pose_float16.tflite"
            "squats" -> "squat_pose_float16.tflite"
            else -> throw IllegalArgumentException("Unsupported exercise: $exercise")
        }
        
        // If already initialized with the same exercise, return early
        if (interpreter != null && currentExercise == exercise) {
            return
        }
        
        // If initialized with different exercise, close current model first
        if (interpreter != null && currentExercise != exercise) {
            closeExerciseModel()
        }
        
        synchronized(initLock) {
            if (interpreter != null && currentExercise == exercise) return

            val appContext = context.applicationContext
            val buffer = try {
                loadModelFromAssets(appContext, assetName)
            } catch (e: IOException) {
                throw RuntimeException(
                    "Failed to load TFLite exercise model from Android assets: $assetName for exercise: $exercise",
                    e
                )
            }

            // Always use CPU for exercise models
            interpreter = run {
                val cpuOptions = Interpreter.Options().apply {
                    setNumThreads(CPU_NUM_THREADS)
                }
                println("DEBUG: ExerciseInference using CPU with $CPU_NUM_THREADS threads for $exercise.")
                Interpreter(buffer, cpuOptions)
            }

            // Allocate persistent input/output buffers sized by actual tensors
            interpreter?.let { interp ->
                val inputBytes = interp.getInputTensor(0).numBytes()
                
                // Input buffer for keypoints
                inputBuffer =
                    ByteBuffer.allocateDirect(inputBytes).apply { order(ByteOrder.nativeOrder()) }
                
                // Output buffers for the three outputs: [1,17,3], [1,1], [1]
                val jointMaskedKeypointsBytes = 1 * 17 * 3 * 4 // 51 floats * 4 bytes
                val formScoreBytes = 1 * 1 * 4 // 1 float * 4 bytes  
                val instructionIdBytes = 1 * 4 // 1 int * 4 bytes
                
                jointMaskBuffer = ByteBuffer.allocateDirect(jointMaskedKeypointsBytes).apply { 
                    order(ByteOrder.nativeOrder()) 
                }
                formScoreBuffer = ByteBuffer.allocateDirect(formScoreBytes).apply { 
                    order(ByteOrder.nativeOrder()) 
                }
                instructionIdBuffer = ByteBuffer.allocateDirect(instructionIdBytes).apply { 
                    order(ByteOrder.nativeOrder()) 
                }
            }
            
            currentExercise = exercise
            println("DEBUG: ExerciseInference initialization complete for $exercise!")
        }
    }

    fun getInterpreter(): Interpreter =
        interpreter ?: throw IllegalStateException("ExerciseInference is not initialized.")

    
    fun <T> withExerciseInferenceBuffers(block: (Interpreter, ByteBuffer, ByteBuffer, ByteBuffer, ByteBuffer) -> T): T? {
        val interp = interpreter ?: return null
        val inBuf = inputBuffer ?: return null
        val jointMaskBuf = jointMaskBuffer ?: return null
        val formScoreBuf = formScoreBuffer ?: return null
        val instructionIdBuf = instructionIdBuffer ?: return null
        return if (inferenceLock.tryLock()) {
            try {
                block(interp, inBuf, jointMaskBuf, formScoreBuf, instructionIdBuf)
            } finally {
                inferenceLock.unlock()
            }
        } else null
    }

    fun closeExerciseModel() {
        synchronized(initLock) {
            interpreter?.close()
            interpreter = null

            inputBuffer = null
            jointMaskBuffer = null
            formScoreBuffer = null
            instructionIdBuffer = null
            currentExercise = null
        }
    }

    @Throws(IOException::class)
    private fun loadModelFromAssets(context: Context, assetName: String): ByteBuffer {
        try {
            context.assets.openFd(assetName).use { afd ->
                FileInputStream(afd.fileDescriptor).channel.use { channel ->
                    val startOffset = afd.startOffset
                    val declaredLength = afd.declaredLength
                    println("DEBUG: ExerciseInference memory-mapped I/O used for $assetName.")
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
                println("DEBUG: ExerciseInference stream copy used for $assetName.")
                return directBuffer
            }
        }
    }
}
