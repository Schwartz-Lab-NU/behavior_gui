#include "include/windows_texture_test/windows_texture_test_plugin.h"

// #include <WinSock2.h>
#include <WS2tcpip.h>
// This must be included before many other Windows headers.
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
//
#include <tchar.h>

// #include <array>
#include <bitset>
#include <iostream>
#include <map>
#include <memory>
#include <sstream>
#include <string>
#include <system_error>
#include <thread>

namespace {
void FillBlack(FlutterDesktopPixelBuffer *buffer) {
    uint32_t *word = (uint32_t *)buffer->buffer;

    auto width = buffer->width;
    auto height = buffer->height;

    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            *(word++) = 0xFF000000;
        }
    }
}
void FillRGB(FlutterDesktopPixelBuffer *buffer, uint8_t R, uint8_t G,
             uint8_t B) {
    uint32_t *word = (uint32_t *)buffer->buffer;

    auto width = buffer->width;
    auto height = buffer->height;

    auto color =
        0xFF000000 + R + ((uint32_t)G << 8) + ((uint32_t)B << 16);  // ABGR

    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            *(word++) = color;
        }
    }
}

void StartTimer(int interval, std::function<int(void)> func) {
    std::thread([=]() {
        int running = 1;
        while (running) {
            running = func();
            std::this_thread::sleep_for(std::chrono::milliseconds(interval));
        }
    }).detach();
}

class WSASession {
   private:
    WSAData data;

   public:
    WSASession() {
        int ret = WSAStartup(MAKEWORD(2, 2), &data);
        if (ret != 0) {
            int lastErr = WSAGetLastError();
            std::wcout << "Error starting up with code: " << lastErr
                       << std::endl;
            throw std::system_error(lastErr, std::system_category(),
                                    "WSAStartup failed.");
        }
    }
    ~WSASession() { WSACleanup(); }
};

class UDPSocket {
   private:
    SOCKET sock;
    int size;

   public:
    UDPSocket() {
        sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if (sock == INVALID_SOCKET) {
            int lastErr = WSAGetLastError();
            std::wcout << "Error opening socket with code: " << lastErr
                       << std::endl;
            throw std::system_error(lastErr, std::system_category(),
                                    "Error opening socket.");
        }
        size = sizeof(sockaddr_in);
    }
    ~UDPSocket() { closesocket(sock); }

    void SendTo(const LPCWSTR address, unsigned short port, const char *buffer,
                int len, int flags = 0) {
        sockaddr_in addr;
        addr.sin_family = AF_INET;
        InetPton(AF_INET, address, &(addr.sin_addr.s_addr));
        addr.sin_port = htons(port);
        int ret = sendto(sock, buffer, len, flags,
                         reinterpret_cast<SOCKADDR *>(&addr), size);
        std::wcout << "Sent message : '" << buffer << "' to address: '"
                   << address << ":" << port << "' with result: " << ret
                   << std::endl;
        if (ret < 0) {
            int lastErr = WSAGetLastError();
            std::wcout << "Error sending message with code: " << lastErr
                       << std::endl;
            throw std::system_error(lastErr, std::system_category(),
                                    "sendto failed.");
        }
    }

    sockaddr_in RecvFrom(char *buffer, int len, int flags = 0) {
        sockaddr_in from;
        int ret = recvfrom(sock, buffer, len, flags,
                           reinterpret_cast<SOCKADDR *>(&from), &size);
        // std::wcout << "Received message with result: " << ret << std::endl;
        if (ret < 0) {
            int lastErr = WSAGetLastError();
            std::wcout << "Error receiving message with code: " << lastErr
                       << std::endl;
            throw std::system_error(lastErr, std::system_category(),
                                    "recvfrom failed.");
        }
        buffer[ret] = 0;  // TODO: what happens if it fills the buffer?
        return from;
    }
};

class TCPSocket {
   private:
    SOCKET sock;
    int size;
    LPCWSTR address;
    unsigned short port;

   public:
    TCPSocket(const LPCWSTR address, unsigned short port)
        : address(address), port(port) {
        size = sizeof(sockaddr_in);
        init();
    }
    ~TCPSocket() {
        std::wcout << "Destroying TCP socket." << std::endl;
        // shutdown(sock, SD_SEND);  // TODO: do this earlier since we don't
        // need to send any data???
        closesocket(sock);
    }

    void init() {
        sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if (sock == INVALID_SOCKET) {
            int lastErr = WSAGetLastError();
            std::wcout << "Error opening socket with code: " << lastErr
                       << std::endl;
            throw std::system_error(lastErr, std::system_category(),
                                    "Error opening socket.");
        }
        sockaddr_in addr;
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        InetPton(AF_INET, address, &(addr.sin_addr.s_addr));

        int iResult = connect(sock, (sockaddr *)&addr, sizeof(addr));
        if (iResult == SOCKET_ERROR) {
            std::wcout << "Error connecting to server with code: " << iResult
                       << std::endl;
            throw std::system_error(iResult, std::system_category(),
                                    "Error connecting to server.");
        }
    }

    int RecvFrom(char *buffer, int len, int flags = 0) {
        int ret = -1;

        while (ret < 0) {
            ret = recv(sock, buffer, len, flags);

            if (ret < 0) {
                int lastErr = WSAGetLastError();
                std::wcout << "Error receiving message with code: " << lastErr
                           << std::endl;
                // throw std::system_error(lastErr, std::system_category(),
                //                         "recvfrom failed.");
                // if (lastErr == WSAENOTSOCK) {
                //     std::wcout << "Returning from 10038 status" << std::endl;
                //     return ret;
                // } else if ((lastErr == WSAECONNRESET) ||
                //            lastErr == WSAECONNABORTED) {
                //     closesocket(sock);
                //     init();
                // }
                return ret;
            }
        }

        return ret;
    }
};

class SocketTexture {
   public:
    SocketTexture(size_t width, size_t height, uint16_t port);
    virtual ~SocketTexture();
    const FlutterDesktopPixelBuffer *CopyPixelBuffer(size_t width,
                                                     size_t height);
    int update();

   private:
    std::unique_ptr<FlutterDesktopPixelBuffer> buffer1_;
    std::unique_ptr<FlutterDesktopPixelBuffer> buffer2_;
    std::unique_ptr<uint8_t> pixels1_;
    std::unique_ptr<uint8_t> pixels2_;
    size_t request_count_ = 0;
    size_t recv_count_ = 0;
    size_t size_raw_;
    size_t size_;
    WSASession session_;
    // UDPSocket socket_;
    std::unique_ptr<TCPSocket> socket_;
    std::unique_ptr<char> socket_buffer_;
};

SocketTexture::SocketTexture(size_t width, size_t height, uint16_t port) {
    size_raw_ = width * height;
    size_ = size_raw_ * 4;

    pixels1_.reset(new uint8_t[size_]);
    pixels2_.reset(new uint8_t[size_]);

    buffer1_ = std::make_unique<FlutterDesktopPixelBuffer>();
    buffer1_->buffer = pixels1_.get();
    buffer1_->width = width;
    buffer1_->height = height;

    buffer2_ = std::make_unique<FlutterDesktopPixelBuffer>();
    buffer2_->buffer = pixels2_.get();
    buffer2_->width = width;
    buffer2_->height = height;

    FillBlack(buffer1_.get());
    FillBlack(buffer2_.get());

    socket_.reset(new TCPSocket(L"127.0.0.1", port));
    socket_buffer_.reset(new char[size_raw_]);
    // socket_.SendTo(_T("127.0.0.1"), 5002, "listening", 9);
}

const FlutterDesktopPixelBuffer *SocketTexture::CopyPixelBuffer(size_t width,
                                                                size_t height) {
    if (request_count_++ % 2 == 0) {
        return buffer2_.get();
    }

    return buffer1_.get();
}

int SocketTexture::update() {
    // std::cout << "Doing update" << std::endl;

    char *buffer = socket_buffer_.get();
    int ret = socket_->RecvFrom(buffer, (int)size_raw_);
    if (ret < 0) return 0;

    uint32_t *pix;

    if (recv_count_++ % 2 == 0) {
        pix = (uint32_t *)pixels2_.get();
        //     FillRGB(buffer2_.get(), 0, 0, 255);
    } else {
        pix = (uint32_t *)pixels1_.get();
        // FillRGB(buffer1_.get(), 0, 255, 0);
    }

    // auto color = 0xFF000000 + R + ((uint32_t)G << 8) + ((uint32_t)B << 16);
    // // ABGR

    for (size_t i = 0; i < size_raw_; i++) {
        char v = *buffer;
        *(pix++) = ((uint32_t)v << 16) + ((uint32_t)v << 8) + v + 0xFF000000; //0xFF555555
        // *(pix++) = 0xFF000000 + ((i % 256) << 16) + (((2 * i) % 256) << 8) +
        //            (((4 * i) % 256) << 0);
        buffer++;
    }
    return 1;
}

SocketTexture::~SocketTexture() {
    // TODO: this seems to be setn out of order
    // socket_.SendTo(_T("127.0.0.1"), 5002, "done", 4);
}

class WindowsTextureTestPlugin : public flutter::Plugin {
   public:
    static void RegisterWithRegistrar(
        flutter::PluginRegistrarWindows *registrar);

    WindowsTextureTestPlugin(flutter::TextureRegistrar *textures);

    virtual ~WindowsTextureTestPlugin();

   private:
    // Called when a method is called on this plugin's channel from Dart.
    void HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

    flutter::TextureRegistrar *textures_;
    std::unique_ptr<flutter::TextureVariant> texture_;
    std::unique_ptr<SocketTexture> socket_texture_;
};

// static
void WindowsTextureTestPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
    auto channel =
        std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "windows_texture_test",
            &flutter::StandardMethodCodec::GetInstance());

    auto plugin = std::make_unique<WindowsTextureTestPlugin>(
        registrar->texture_registrar());

    channel->SetMethodCallHandler(
        [plugin_pointer = plugin.get()](const auto &call, auto result) {
            plugin_pointer->HandleMethodCall(call, std::move(result));
        });

    registrar->AddPlugin(std::move(plugin));
}

WindowsTextureTestPlugin::WindowsTextureTestPlugin(
    flutter::TextureRegistrar *textures)
    : textures_(textures) {}

WindowsTextureTestPlugin::~WindowsTextureTestPlugin() {}

void WindowsTextureTestPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const std::string &method_name = method_call.method_name();

    if (method_name.compare("initialize") == 0) {
        uint16_t *args = (uint16_t *)method_call.arguments();
        // std::wcout << "arguments: " << args[0] << "," << args[1] << ","
        //            << args[2] << std::endl;
        socket_texture_ =
            std::make_unique<SocketTexture>(args[0], args[1], args[2]);

        texture_ = std::make_unique<flutter::TextureVariant>(
            flutter::PixelBufferTexture(
                [this](size_t width,
                       size_t height) -> const FlutterDesktopPixelBuffer * {
                    return socket_texture_->CopyPixelBuffer(width, height);
                }));

        int64_t texture_id = textures_->RegisterTexture(texture_.get());

        auto response = flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("textureId"),
             flutter::EncodableValue(texture_id)},
        });

        result->Success(response);

        // Update the texture @ 10 Hz
        // Setting this to 60 Hz might cause epileptic shocks :D
        StartTimer(1000 / 20, [&, texture_id]() {
            int ret = socket_texture_->update();
            textures_->MarkTextureFrameAvailable(texture_id);
            return ret;
        });

    } else {
        result->NotImplemented();
    }
}

}  // namespace

void WindowsTextureTestPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
    WindowsTextureTestPlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
