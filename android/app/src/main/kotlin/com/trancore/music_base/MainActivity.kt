package com.trancore.music_base

import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import kotlin.math.sqrt

class MainActivity : AudioServiceActivity() {
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingSamples = ArrayList<Double>(2048)
    private val frameSize = 2048

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
                    if (sessionId == null || sessionId <= 0) {
                        result.error("INVALID_SESSION", "Audio session ID is required.", null)
                    } else {
                        scheduleVisualizerStart(sessionId)
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

    private fun scheduleVisualizerStart(audioSessionId: Int) {
        stopVisualizer()
        mainHandler.post {
            if (startWaveformVisualizer(audioSessionId)) return@post
            if (audioSessionId != 0 && startFftVisualizer(audioSessionId)) return@post
            if (startFftVisualizer(0)) return@post
            Log.w(TAG, "Unable to attach Android visualizer for session $audioSessionId")
        }
    }

    private fun startWaveformVisualizer(audioSessionId: Int): Boolean {
        return try {
            val next = Visualizer(audioSessionId)
            val captureSize = Visualizer.getCaptureSizeRange()[1].coerceAtMost(1024)
            next.captureSize = captureSize
            next.scalingMode = Visualizer.SCALING_MODE_NORMALIZED
            next.setDataCaptureListener(
                object : Visualizer.OnDataCaptureListener {
                    override fun onWaveFormDataCapture(
                        visualizer: Visualizer?,
                        waveform: ByteArray?,
                        samplingRate: Int,
                    ) {
                        if (waveform == null || waveform.isEmpty()) return
                        for (byte in waveform) {
                            pendingSamples.add(
                                ((byte.toInt() and 0xFF) - 128) / 128.0,
                            )
                            if (pendingSamples.size >= frameSize) {
                                val frame = ArrayList(pendingSamples.subList(0, frameSize))
                                pendingSamples.subList(0, frameSize).clear()
                                mainHandler.post { eventSink?.success(frame) }
                            }
                        }
                    }

                    override fun onFftDataCapture(
                        visualizer: Visualizer?,
                        fft: ByteArray?,
                        samplingRate: Int,
                    ) = Unit
                },
                Visualizer.getMaxCaptureRate().coerceAtMost(100000),
                true,
                false,
            )
            next.enabled = true
            visualizer = next
            true
        } catch (error: RuntimeException) {
            Log.w(TAG, "Waveform visualizer failed for session $audioSessionId", error)
            stopVisualizer()
            false
        }
    }

    private fun startFftVisualizer(audioSessionId: Int): Boolean {
        return try {
            val next = Visualizer(audioSessionId)
            val captureSize = Visualizer.getCaptureSizeRange()[1].coerceAtMost(1024)
            next.captureSize = captureSize
            next.scalingMode = Visualizer.SCALING_MODE_NORMALIZED
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
                            val magnitude = sqrt(real * real + imaginary * imaginary) / 128.0
                            magnitudes.add(magnitude.coerceIn(0.0, 1.0))
                            index += 2
                        }
                        if (magnitudes.isEmpty()) return
                        mainHandler.post { eventSink?.success(magnitudes) }
                    }
                },
                Visualizer.getMaxCaptureRate().coerceAtMost(100000),
                false,
                true,
            )
            next.enabled = true
            visualizer = next
            true
        } catch (error: RuntimeException) {
            Log.w(TAG, "FFT visualizer failed for session $audioSessionId", error)
            stopVisualizer()
            false
        }
    }

    private fun stopVisualizer() {
        visualizer?.setDataCaptureListener(null, 0, false, false)
        visualizer?.enabled = false
        visualizer?.release()
        visualizer = null
        pendingSamples.clear()
    }

    companion object {
        private const val TAG = "MusicBaseVisualizer"
    }
}
