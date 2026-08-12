import Cocoa
import FlutterMacOS
import AudioToolbox
import CoreMedia
import ScreenCaptureKit

@main
@available(macOS 14.2, *)
class AppDelegate: FlutterAppDelegate {
  private let spectrumCapture = MacosSpectrumCapture()
  private var channelsRegistered = false

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    guard let controller = MainFlutterWindow.flutterViewController else {
      return
    }
    registerPlatformChannels(with: controller)
  }

  func registerPlatformChannels(with controller: FlutterViewController) {
    guard !channelsRegistered else { return }
    channelsRegistered = true
    let messenger = controller.engine.binaryMessenger

    let fileChannel = FlutterMethodChannel(
      name: "music_base/macos_file_access",
      binaryMessenger: messenger
    )
    fileChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "macOS bridge is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "prepareAccess":
        guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
          result(FlutterError(code: "INVALID_PATH", message: "A directory path is required.", details: nil))
          return
        }
        result(self.prepareDirectoryAccess(path: path))
      case "saveAccess":
        guard let path = (call.arguments as? [String: Any])?["path"] as? String else {
          result(FlutterError(code: "INVALID_PATH", message: "A directory path is required.", details: nil))
          return
        }
        result(self.saveDirectoryAccess(path: path))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let spectrumEvents = FlutterEventChannel(
      name: "music_base/macos_spectrum",
      binaryMessenger: messenger
    )
    spectrumEvents.setStreamHandler(spectrumCapture)

    let spectrumControl = FlutterMethodChannel(
      name: "music_base/macos_spectrum/control",
      binaryMessenger: messenger
    )
    spectrumControl.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Spectrum capture is unavailable.", details: nil))
        return
      }
      switch call.method {
      case "start":
        self.spectrumCapture.start()
        result(nil)
      case "stop":
        self.spectrumCapture.stop()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func prepareDirectoryAccess(path: String) -> Any? {
    let defaults = UserDefaults.standard
    let url: URL
    if let bookmark = defaults.data(forKey: "library.directory.bookmark") {
      var stale = false
      do {
        url = try URL(
          resolvingBookmarkData: bookmark,
          options: [.withSecurityScope, .withoutUI],
          relativeTo: nil,
          bookmarkDataIsStale: &stale
        )
      } catch {
        return FlutterError(code: "BOOKMARK_INVALID", message: "The saved music directory is no longer available.", details: nil)
      }
    } else {
      url = URL(fileURLWithPath: path)
    }

    guard url.path == URL(fileURLWithPath: path).path else {
      return FlutterError(code: "BOOKMARK_MISMATCH", message: "The saved music directory does not match the configured path.", details: nil)
    }
    _ = url.startAccessingSecurityScopedResource()
    return nil
  }

  private func saveDirectoryAccess(path: String) -> Any? {
    let url = URL(fileURLWithPath: path)
    do {
      let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(bookmark, forKey: "library.directory.bookmark")
      return nil
    } catch {
      return FlutterError(code: "BOOKMARK_CREATE_FAILED", message: "Unable to save access to the selected music directory.", details: error.localizedDescription)
    }
  }
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}

@available(macOS 14.2, *)
private final class MacosSpectrumCapture: NSObject, FlutterStreamHandler, SCStreamOutput, SCStreamDelegate {
  private var eventSink: FlutterEventSink?
  private var stream: SCStream?
  private let queue = DispatchQueue(label: "music_base.macos_spectrum")
  private var pendingSamples = [Double]()

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    stop()
    return nil
  }

  func start() {
    stop()
    Task { [weak self] in
      guard let self else { return }
      do {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: false)
        guard let display = content.displays.first else { return }
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = false
        configuration.sampleRate = 44_100
        configuration.channelCount = 1
        configuration.width = 2
        configuration.height = 2

        let next = SCStream(filter: filter, configuration: configuration, delegate: self)
        try next.addStreamOutput(self, type: .audio, sampleHandlerQueue: queue)
        try await next.startCapture()
        stream = next
      } catch {
        stop()
      }
    }
  }

  func stop() {
    let current = stream
    stream = nil
    pendingSamples.removeAll(keepingCapacity: true)
    guard let current else { return }
    Task { try? await current.stopCapture() }
  }

  func stream(_ stream: SCStream, didStopWithError error: Error) {
    DispatchQueue.main.async { [weak self] in self?.eventSink?(FlutterError(code: "CAPTURE_STOPPED", message: error.localizedDescription, details: nil)) }
  }

  func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
    guard outputType == .audio, let samples = pcmSamples(from: sampleBuffer), !samples.isEmpty else { return }
    pendingSamples.append(contentsOf: samples)
    while pendingSamples.count >= 256 {
      let frame = Array(pendingSamples.prefix(256))
      pendingSamples.removeFirst(256)
      DispatchQueue.main.async { [weak self] in self?.eventSink?(frame) }
    }
  }

  private func pcmSamples(from sampleBuffer: CMSampleBuffer) -> [Double]? {
    guard let format = CMSampleBufferGetFormatDescription(sampleBuffer),
          let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format),
          let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
    var length = 0
    var data: UnsafeMutablePointer<Int8>?
    guard CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &data) == noErr,
          let data else { return nil }
    let channels = max(Int(asbd.pointee.mChannelsPerFrame), 1)
    let sampleCount = min(CMSampleBufferGetNumSamples(sampleBuffer), length / max(Int(asbd.pointee.mBytesPerFrame), 1))
    let isFloat = (asbd.pointee.mFormatFlags & kAudioFormatFlagIsFloat) != 0
    let isSigned = (asbd.pointee.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0
    let bytesPerSample = max(Int(asbd.pointee.mBitsPerChannel) / 8, 1)
    var output = [Double]()
    output.reserveCapacity(sampleCount)
    for frame in 0..<sampleCount {
      var sum = 0.0
      for channel in 0..<channels {
        let offset = frame * Int(asbd.pointee.mBytesPerFrame) + channel * bytesPerSample
        if isFloat && bytesPerSample == 4 {
          sum += Double(data.withMemoryRebound(to: Float.self, capacity: length / 4) { $0[offset / 4] })
        } else if isSigned && bytesPerSample == 2 {
          sum += Double(data.withMemoryRebound(to: Int16.self, capacity: length / 2) { $0[offset / 2] }) / 32768.0
        }
      }
      output.append((sum / Double(channels)).clamped(to: -1.0...1.0))
    }
    return output
  }
}

private extension Double {
  func clamped(to range: ClosedRange<Double>) -> Double {
    min(max(self, range.lowerBound), range.upperBound)
  }
}
