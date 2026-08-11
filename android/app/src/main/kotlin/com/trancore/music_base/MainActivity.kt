package com.trancore.music_base

import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "music_base/audio_spectrum")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "music_base/audio_spectrum/control",
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "start" -> {
                    val sessionId = call.argument<Int>("audioSessionId")
                    if (sessionId == null) {
                        result.error("INVALID_SESSION", "Audio session ID is required.", null)
                    } else {
                        startVisualizer(sessionId)
                        result.success(null)
                    }
                }
                "stop" -> {
                    stopVisualizer()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        stopVisualizer()
        super.onDestroy()
    }

    private fun startVisualizer(audioSessionId: Int) {
        stopVisualizer()
        try {
            val next = Visualizer(audioSessionId)
            val captureSize = Visualizer.getCaptureSizeRange()[1].coerceAtMost(256)
            next.setCaptureSize(captureSize)
            next.setScalingMode(Visualizer.SCALING_MODE_NORMALIZED)
            next.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        visualizer: Visualizer?,
                        waveform: ByteArray?,
                        samplingRate: Int,
                    ) = Unit

                    override fun onFftDataCapture(
                        visualizer: Visualizer?,
                        fft: ByteArray?,
                        samplingRate: Int,
                    ) {
                        if (fft == null || fft.size < 4) return
                        val magnitudes = ArrayList<Double>(32)
                        var index = 2
                        while (index + 1 < fft.size && magnitudes.size < 32) {
                            val real = fft[index].toDouble()
                            val imaginary = fft[index + 1].toDouble()
                            val magnitude = kotlin.math.sqrt(real * real + imaginary * imaginary) / 128.0
                            magnitudes.add(magnitude.coerceIn(0.0, 1.0))
                            index += 2
                        }
                        mainHandler.post { eventSink?.success(magnitudes) }
                    }
                },
                Visualizer.getMaxCaptureRate().coerceAtMost(100000),
                false,
                true,
            )
            next.enabled = true
            visualizer = next
        } catch (_: RuntimeException) {
            stopVisualizer()
        }
    }

    private fun stopVisualizer() {
        visualizer?.setDataCaptureListener(null, 0, false, false)
        visualizer?.enabled = false
        visualizer?.release()
        visualizer = null
    }
}
