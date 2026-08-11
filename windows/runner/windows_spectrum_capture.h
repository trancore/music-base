#ifndef RUNNER_WINDOWS_SPECTRUM_CAPTURE_H_
#define RUNNER_WINDOWS_SPECTRUM_CAPTURE_H_

#include <flutter/event_channel.h>
#include <flutter/encodable_value.h>

#include <atomic>
#include <memory>
#include <thread>

class WindowsSpectrumCapture {
 public:
  using EventSink = flutter::EventSink<flutter::EncodableValue>;

  WindowsSpectrumCapture() = default;
  ~WindowsSpectrumCapture();

  void Start(std::unique_ptr<EventSink> sink);
  void Stop();

 private:
  void Capture(std::unique_ptr<EventSink> sink);

  std::atomic<bool> running_{false};
  std::thread capture_thread_;
};

#endif  // RUNNER_WINDOWS_SPECTRUM_CAPTURE_H_
