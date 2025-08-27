package com.example.movenet_image_processor

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.cancel
import kotlinx.coroutines.SupervisorJob

class MovenetImageProcessorPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "movenet_image_processor")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            // Initialize the persistent TFLite interpreter
            "initializeModel" -> {
                pluginScope.launch {
                    try {
                        ModelLoader.initializeModel(applicationContext)
                        withContext(Dispatchers.Main) {
                            result.success(true)
                        }
                    } catch (e: Throwable) {
                        withContext(Dispatchers.Main) {
                            result.error("INIT_FAILED", e.message, null)
                        }
                    }
                }
            }

            // Returns whether the interpreter is initialized
            "isInitialized" -> result.success(ModelLoader.isInitialized)

            // Initialize exercise model
            "initExerciseModel" -> {
                pluginScope.launch {
                    try {
                        val exercise: String? = call.argument("exercise")
                        if (exercise == null) {
                            withContext(Dispatchers.Main) {
                                result.error("BAD_ARGS", "Missing exercise argument.", null)
                            }
                            return@launch
                        }
                        
                        println("DEBUG: initExerciseModel called with exercise=$exercise")

                        ExerciseInference.initExerciseModel(applicationContext, exercise)
                        val ok = ExerciseInference.isInitialized

                        println("DEBUG: initExerciseModel result for $exercise -> $ok")

                        withContext(Dispatchers.Main) {
                            result.success(ok)
                        }
                    } catch (e: Throwable) {
                        println("DEBUG: initExerciseModel failed: ${e.message}")
                        
                        withContext(Dispatchers.Main) {
                            result.error("EXERCISE_INIT_FAILED", e.message, null)
                        }
                    }
                }
            }

            // Returns whether the exercise model is initialized
            "isExerciseInitialized" -> result.success(ExerciseInference.isInitialized)

            // Close and release interpreter resources
            "closeModel" -> {
                pluginScope.launch {
                    try {
                        ModelLoader.closeModel()
                        ExerciseInference.closeExerciseModel()
                        withContext(Dispatchers.Main) {
                            result.success(null)
                        }
                    } catch (e: Throwable) {
                        withContext(Dispatchers.Main) {
                            result.error("CLOSE_FAILED", e.message, null)
                        }
                    }
                }
            }

            // Runs the full frame processing and inference pipeline
            "processFrame" -> {
                pluginScope.launch {
                    try {
                        if (!ModelLoader.isInitialized) {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "NOT_INITIALIZED",
                                    "MoveNet model has not been initialized.",
                                    null
                                )
                            }
                            return@launch
                        }

                        if (!ExerciseInference.isInitialized) {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "EXERCISE_NOT_INITIALIZED",
                                    "Exercise model has not been initialized.",
                                    null
                                )
                            }
                            return@launch
                        }

                        val planes: ArrayList<ByteArray>? = call.argument("planes")
                        val bytesPerRow: ArrayList<Int>? = call.argument("bytesPerRow")
                        val bytesPerPixel: ArrayList<Int>? = call.argument("bytesPerPixel")
                        val width: Int? = call.argument("width")
                        val height: Int? = call.argument("height")
                        val sensorOrientation: Int? = call.argument("sensorOrientation")

                        if (planes == null || bytesPerRow == null || bytesPerPixel == null ||
                            width == null || height == null || sensorOrientation == null
                        ) {
                            withContext(Dispatchers.Main) {
                                result.error(
                                    "BAD_ARGS",
                                    "Missing one or more required arguments.",
                                    null
                                )
                            }
                            return@launch
                        }

                        val out: List<Any> = InferenceProcessor.processFrame(
                            planeBytes = planes,
                            bytesPerRow = bytesPerRow,
                            bytesPerPixel = bytesPerPixel,
                            width = width,
                            height = height,
                            sensorOrientation = sensorOrientation,
                        )

                        withContext(Dispatchers.Main) {
                            result.success(out)
                        }
                    } catch (e: Throwable) {
                        withContext(Dispatchers.Main) {
                            result.error("PROCESS_FAILED", e.message, null)
                        }
                    }
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginScope.cancel()
        try {
            ModelLoader.closeModel()
            ExerciseInference.closeExerciseModel()
        } catch (e: Throwable) {
            Log.e("MoveNetPlugin", "Error closing models on engine detach", e)
        }
    }
}
