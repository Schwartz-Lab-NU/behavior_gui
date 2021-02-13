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
#include <vector>

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
        std::wcout << "Creating TCP socket." << std::endl;
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
        DWORD timeout = 10;
        iResult = setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO,
                             (const char *)&timeout, sizeof(DWORD));
        if (iResult == SOCKET_ERROR) {
            std::wcout << "Error setting timeout with code: " << iResult
                       << std::endl;
            throw std::system_error(iResult, std::system_category(),
                                    "Error setting timeout.");
        }
    }

    int RecvFrom(char *buffer, int len, int flags = 0) {
        int ret = recv(sock, buffer, len, flags);

        if (ret < 0) {
            int lastErr = WSAGetLastError();
            if (lastErr == 10060) {
                // socket timed out
                return 0;
            }
            std::wcout << "Error receiving message with code: " << lastErr
                       << std::endl;
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
    void connect();
    void disconnect();

   private:
    std::unique_ptr<FlutterDesktopPixelBuffer> buffer1_;
    std::unique_ptr<FlutterDesktopPixelBuffer> buffer2_;
    std::unique_ptr<uint8_t> pixels1_;
    std::unique_ptr<uint8_t> pixels2_;
    uint16_t port;
    // size_t request_count_;
    size_t recv_count_;
    size_t recv_mod_;
    size_t size_raw_;
    size_t size_;
    WSASession session_;
    // UDPSocket socket_;
    TCPSocket *socket_ = NULL;
    std::unique_ptr<char> socket_buffer_;
};

SocketTexture::SocketTexture(size_t width, size_t height, uint16_t port)
    : port(port) {
    std::wcout << "Creating socket texture object." << std::endl;
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

    // socket_.reset(new TCPSocket(L"127.0.0.1", port));
    socket_buffer_.reset(new char[size_raw_]);
    // socket_.SendTo(_T("127.0.0.1"), 5002, "listening", 9);
}

void SocketTexture::connect() {
    disconnect();
    recv_count_ = 0;
    // request_count_ = 0;
    recv_mod_ = 0;
    socket_ = new TCPSocket(L"127.0.0.1", port);
}
void SocketTexture::disconnect() {
    if (socket_ != NULL) {
        delete socket_;
        socket_ = NULL;
        std::wcout << "Socket is disconnected" << std::endl;
    }
};

const FlutterDesktopPixelBuffer *SocketTexture::CopyPixelBuffer(size_t width,
                                                                size_t height) {
    std::wcout << "Reading pixels" << 1 + (recv_count_ % 2) << std::endl;
    if (recv_count_ % 2 == 0) {
        return buffer1_.get();
    }
    return buffer2_.get();
}

int SocketTexture::update() {
    // std::cout << "Doing update" << std::endl;
    char *buffer = socket_buffer_.get();

    int ret = socket_->RecvFrom(buffer, (int)size_raw_);
    if (ret <= 0) return ret;

    uint32_t *pix;

    if (recv_count_ % 2 == 0) {
        pix = (uint32_t *)pixels2_.get() + recv_mod_;
    } else {
        pix = (uint32_t *)pixels1_.get() + recv_mod_;
    }

    for (size_t i = 0; i < ret; i++) {
        uint32_t v = (uint32_t)*buffer;
        *(pix++) = (v << 16) + (v << 8) + v + 0xFF000000;
        buffer++;
    }

    recv_mod_ = (recv_mod_ + ret) % size_raw_;
    if (recv_mod_ == 0) {
        // we've completed the frame
        std::wcout << "Flushing pixels" << 2 - (recv_count_ % 2) << std::endl;
        recv_count_++;
        return 1;
    } else {
        return 0;
    }
}

SocketTexture::~SocketTexture() {
    // TODO: this seems to be sent out of order
    disconnect();
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
    void initialize(
        uint16_t width, uint16_t height, uint16_t port,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    void clearTextures();

    flutter::TextureRegistrar *registrar_;
    // std::unique_ptr<flutter::TextureVariant> texture_;
    // std::unique_ptr<SocketTexture> socket_texture_;
   public:
    struct TextureItem {
        flutter::TextureVariant *texture;
        SocketTexture *socket;
        std::thread *runner;
        int64_t texture_id;
        int listener_count;
        uint16_t width, height, port;
    };
    std::vector<TextureItem> textures_;
    //  std::vector<flutter::TextureVariant *> textures_;
    // std::vector<SocketTexture *> sockets_;
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
    flutter::TextureRegistrar *registrar)
    : registrar_(registrar) {}

WindowsTextureTestPlugin::~WindowsTextureTestPlugin() { clearTextures(); }

void WindowsTextureTestPlugin::clearTextures() {
    std::wcout << "Clearing textures" << std::endl;
    for (auto texture = textures_.begin(); texture < textures_.end();
         texture++) {
        texture->listener_count = 0;

        if (texture->runner->joinable()) texture->runner->join();
        delete texture->runner;
        delete texture->texture;
        delete texture->socket;
    }
    textures_.clear();
}

void WindowsTextureTestPlugin::initialize(
    uint16_t width, uint16_t height, uint16_t port,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    // check if texture already exists
    for (auto texture = textures_.begin(); texture < textures_.end();
         texture++) {
        if (texture->port == port) {
            std::wcout << "Texture already exists as #" << texture->texture_id
                       << std::endl;
            // python should guarantee that the texture height and width are the
            // same
            auto response = flutter::EncodableValue(flutter::EncodableMap{
                {flutter::EncodableValue("textureId"),
                 flutter::EncodableValue(texture->texture_id)},
            });
            result->Success(response);
            return;
        }
    }

    TextureItem texture;
    texture.width = width;
    texture.height = height;
    texture.port = port;
    texture.listener_count = 0;
    texture.socket = new SocketTexture(width, height, port);
    texture.texture = new flutter::TextureVariant(flutter::PixelBufferTexture(
        [texture](size_t width,
                  size_t height) -> const FlutterDesktopPixelBuffer * {
            return texture.socket->CopyPixelBuffer(width, height);
        }));
    texture.runner = new std::thread();
    texture.texture_id = registrar_->RegisterTexture(texture.texture);

    auto response = flutter::EncodableValue(flutter::EncodableMap{
        {flutter::EncodableValue("textureId"),
         flutter::EncodableValue(texture.texture_id)},
    });
    textures_.push_back(texture);
    result->Success(response);
}

void WindowsTextureTestPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    const std::string &method_name = method_call.method_name();

    if (method_name.compare("clearedinitialize") == 0) {
        uint16_t *args = (uint16_t *)method_call.arguments();

        clearTextures();
        initialize(args[0], args[1], args[2], std::move(result));

    } else if (method_name.compare("initialize") == 0) {
        uint16_t *args = (uint16_t *)method_call.arguments();
        initialize(args[0], args[1], args[2], std::move(result));

    } else if (method_name.compare("play") == 0) {
        int64_t *texture_id = (int64_t *)method_call.arguments();

        auto response = flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("playing"), flutter::EncodableValue(NULL)},
        });
        for (size_t i = 0; i < textures_.size(); i++) {
            // for (TextureItem texture : textures_) {
            // TextureItem texture = textures_[i];
            if (textures_[i].texture_id == *texture_id) {
                textures_[i].listener_count += 1;

                if (!textures_[i].runner->joinable()) {
                    delete textures_[i].runner;
                    textures_[i].socket->connect();
                    textures_[i].runner = new std::thread([this, i]() {
                        while (true) {
                            int update = textures_[i].socket->update();
                            if ((update < 0) ||
                                textures_[i].listener_count == 0)
                                return;  // we had an error or we're closing the
                                         // socket
                            else if (update > 0) {
                                std::wcout << "Marking available" << std::endl;
                                registrar_->MarkTextureFrameAvailable(
                                    textures_[i].texture_id);
                            }
                            // std::this_thread::sleep_for(
                            //     std::chrono::milliseconds(16));
                        }
                    });
                }

                response = flutter::EncodableValue(flutter::EncodableMap{
                    {flutter::EncodableValue("playing"),
                     flutter::EncodableValue(true)},
                });
                break;
            }
        }
        result->Success(response);

    } else if (method_name.compare("pause") == 0) {
        int64_t *texture_id = (int64_t *)method_call.arguments();
        std::wcout << "Attempting to pause texture #" << *texture_id
                   << std::endl;
        auto response = flutter::EncodableValue(flutter::EncodableMap{
            {flutter::EncodableValue("playing"), flutter::EncodableValue(NULL)},
        });

        for (size_t i = 0; i < textures_.size(); i++) {
            if (textures_[i].texture_id == *texture_id) {
                if (textures_[i].listener_count > 1) {
                    textures_[i].listener_count -= 1;
                } else if (textures_[i].listener_count == 1) {
                    std::wcout << "Texture has no more listeners, so "
                                  "disconnecting socket. "
                               << std::endl;
                    textures_[i].listener_count = 0;
                    textures_[i].runner->join();
                    std::wcout << "Thread terminated." << std::endl;
                    textures_[i].socket->disconnect();
                }

                response = flutter::EncodableValue(
                    flutter::EncodableMap{{flutter::EncodableValue("playing"),
                                           flutter::EncodableValue(false)}});
                break;
            }
        }
        result->Success(response);

    } else if (method_name.compare("dispose") == 0) {
        clearTextures();
        result->Success();
    } else {
        std::wcout << "Not implemented method: " << method_name.c_str()
                   << std::endl;
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
