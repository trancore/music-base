#include "windows_spectrum_capture.h"

#include <audioclient.h>
#include <audioclientactivationparams.h>
#include <ksmedia.h>
#include <mmdeviceapi.h>
#include <propidl.h>
#include <windows.h>

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <vector>

namespace {
constexpr size_t kFrameSize = 256;

class ProcessLoopbackActivationHandler final
    : public IActivateAudioInterfaceCompletionHandler {
 public:
  ProcessLoopbackActivationHandler() : completed_(CreateEvent(nullptr, FALSE, FALSE, nullptr)) {}

  ~ProcessLoopbackActivationHandler() {
    if (client_) client_->Release();
    if (completed_) CloseHandle(completed_);
  }

  HRESULT Activate(DWORD process_id) {
    AUDIOCLIENT_ACTIVATION_PARAMS params{};
    params.ActivationType = AUDIOCLIENT_ACTIVATION_TYPE_PROCESS_LOOPBACK;
    params.ProcessLoopbackParams.TargetProcessId = process_id;
    params.ProcessLoopbackParams.ProcessLoopbackMode =
        PROCESS_LOOPBACK_MODE_INCLUDE_TARGET_PROCESS_TREE;
    PROPVARIANT activation_params{};
    activation_params.vt = VT_BLOB;
    activation_params.blob.cbSize = sizeof(params);
    activation_params.blob.pBlobData = reinterpret_cast<BYTE*>(&params);

    IActivateAudioInterfaceAsyncOperation* operation = nullptr;
    const HRESULT result = ActivateAudioInterfaceAsync(
        VIRTUAL_AUDIO_DEVICE_PROCESS_LOOPBACK, __uuidof(IAudioClient),
        &activation_params, this, &operation);
    if (FAILED(result)) return result;
    const DWORD wait_result = WaitForSingleObject(completed_, 10000);
    operation->Release();
    if (wait_result != WAIT_OBJECT_0) {
      return HRESULT_FROM_WIN32(ERROR_TIMEOUT);
    }
    return activation_result_;
  }

  IAudioClient* DetachClient() {
    IAudioClient* client = client_;
    client_ = nullptr;
    return client;
  }

  HRESULT STDMETHODCALLTYPE ActivateCompleted(
      IActivateAudioInterfaceAsyncOperation* operation) override {
    IUnknown* activated = nullptr;
    HRESULT activation_result = E_UNEXPECTED;
    HRESULT result = operation->GetActivateResult(&activation_result, &activated);
    if (SUCCEEDED(result)) result = activation_result;
    if (SUCCEEDED(result)) {
      result = activated->QueryInterface(IID_PPV_ARGS(&client_));
    }
    if (activated) activated->Release();
    activation_result_ = result;
    SetEvent(completed_);
    return S_OK;
  }

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** object) override {
    if (!object) return E_POINTER;
    if (iid == __uuidof(IUnknown) ||
        iid == __uuidof(IActivateAudioInterfaceCompletionHandler) ||
        iid == __uuidof(IAgileObject)) {
      *object = static_cast<IActivateAudioInterfaceCompletionHandler*>(this);
      AddRef();
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }

  ULONG STDMETHODCALLTYPE AddRef() override { return ++references_; }
  ULONG STDMETHODCALLTYPE Release() override {
    const ULONG references = --references_;
    if (references == 0) delete this;
    return references;
  }

 private:
  std::atomic<ULONG> references_{1};
  HANDLE completed_ = nullptr;
  HRESULT activation_result_ = E_UNEXPECTED;
  IAudioClient* client_ = nullptr;
};

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
  IAudioClient* client = nullptr;
  IAudioCaptureClient* capture = nullptr;
  WAVEFORMATEX format{};

  auto cleanup = [&]() {
    if (client) client->Stop();
    if (capture) capture->Release();
    if (client) client->Release();
    CoUninitialize();
  };

  auto* activation = new ProcessLoopbackActivationHandler();
  const HRESULT activation_result = activation->Activate(GetCurrentProcessId());
  if (SUCCEEDED(activation_result)) client = activation->DetachClient();
  activation->Release();
  if (FAILED(activation_result) || !client) {
    cleanup();
    return;
  }

  format.wFormatTag = WAVE_FORMAT_PCM;
  format.nChannels = 2;
  format.nSamplesPerSec = 44100;
  format.wBitsPerSample = 16;
  format.nBlockAlign =
      format.nChannels * format.wBitsPerSample / 8;
  format.nAvgBytesPerSec = format.nSamplesPerSec * format.nBlockAlign;

  if (FAILED(client->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                AUDCLNT_STREAMFLAGS_LOOPBACK |
                                    AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM,
                                0, 0, &format, nullptr)) ||
      FAILED(client->GetService(IID_PPV_ARGS(&capture))) ||
      FAILED(client->Start())) {
    cleanup();
    return;
  }

  const bool is_float = false;
  const size_t channels = std::max<WORD>(format.nChannels, 1);
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
        mono += ReadSample(data, frame * channels + channel, &format, is_float);
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
