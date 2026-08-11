#include "windows_spectrum_capture.h"

#include <audioclient.h>
#include <ksmedia.h>
#include <mmdeviceapi.h>
#include <windows.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <vector>

namespace {
constexpr size_t kFrameSize = 256;

float ReadSample(const BYTE* data, size_t index, const WAVEFORMATEX* format,
                 bool is_float) {
  if (is_float) {
    return reinterpret_cast<const float*>(data)[index];
  }
  if (format->wBitsPerSample == 16) {
    return reinterpret_cast<const int16_t*>(data)[index] / 32768.0f;
  }
  if (format->wBitsPerSample == 32) {
    return reinterpret_cast<const int32_t*>(data)[index] / 2147483648.0f;
  }
  return 0.0f;
}
}  // namespace

WindowsSpectrumCapture::~WindowsSpectrumCapture() { Stop(); }

void WindowsSpectrumCapture::Start(std::unique_ptr<EventSink> sink) {
  Stop();
  running_ = true;
  capture_thread_ = std::thread(&WindowsSpectrumCapture::Capture, this,
                                std::move(sink));
}

void WindowsSpectrumCapture::Stop() {
  running_ = false;
  if (capture_thread_.joinable()) {
    capture_thread_.join();
  }
}

void WindowsSpectrumCapture::Capture(std::unique_ptr<EventSink> sink) {
  CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  IMMDeviceEnumerator* enumerator = nullptr;
  IMMDevice* device = nullptr;
  IAudioClient* client = nullptr;
  IAudioCaptureClient* capture = nullptr;
  WAVEFORMATEX* format = nullptr;

  auto cleanup = [&]() {
    if (client) client->Stop();
    if (format) CoTaskMemFree(format);
    if (capture) capture->Release();
    if (client) client->Release();
    if (device) device->Release();
    if (enumerator) enumerator->Release();
    CoUninitialize();
  };

  if (FAILED(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr,
                              CLSCTX_ALL, IID_PPV_ARGS(&enumerator))) ||
      FAILED(enumerator->GetDefaultAudioEndpoint(eRender, eConsole, &device)) ||
      FAILED(device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                              reinterpret_cast<void**>(&client))) ||
      FAILED(client->GetMixFormat(&format))) {
    cleanup();
    return;
  }

  constexpr REFERENCE_TIME kBufferDuration = 100000;
  if (FAILED(client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                AUDCLNT_STREAMFLAGS_LOOPBACK, kBufferDuration,
                                0, format, nullptr)) ||
      FAILED(client->GetService(IID_PPV_ARGS(&capture))) ||
      FAILED(client->Start())) {
    cleanup();
    return;
  }

  const bool is_float =
      format->wFormatTag == WAVE_FORMAT_IEEE_FLOAT ||
      (format->wFormatTag == WAVE_FORMAT_EXTENSIBLE &&
       IsEqualGUID(
           reinterpret_cast<WAVEFORMATEXTENSIBLE*>(format)->SubFormat,
           KSDATAFORMAT_SUBTYPE_IEEE_FLOAT));
  const size_t channels = std::max<WORD>(format->nChannels, 1);
  std::vector<double> samples;
  samples.reserve(kFrameSize);

  while (running_) {
    UINT32 packet_length = 0;
    if (FAILED(capture->GetNextPacketSize(&packet_length))) break;
    if (packet_length == 0) {
      std::this_thread::sleep_for(std::chrono::milliseconds(5));
      continue;
    }

    BYTE* data = nullptr;
    UINT32 frames = 0;
    DWORD flags = 0;
    if (FAILED(capture->GetBuffer(&data, &frames, &flags, nullptr, nullptr))) {
      break;
    }
    for (UINT32 frame = 0; frame < frames; frame++) {
      double mono = 0;
      for (size_t channel = 0; channel < channels; channel++) {
        mono += ReadSample(data, frame * channels + channel, format, is_float);
      }
      samples.push_back((flags & AUDCLNT_BUFFERFLAGS_SILENT)
                            ? 0.0
                            : std::clamp(mono / channels, -1.0, 1.0));
      if (samples.size() >= kFrameSize) {
        flutter::EncodableList values;
        values.reserve(samples.size());
        for (double sample : samples) values.emplace_back(sample);
        sink->Success(flutter::EncodableValue(values));
        samples.clear();
      }
    }
    capture->ReleaseBuffer(frames);
  }

  cleanup();
}
