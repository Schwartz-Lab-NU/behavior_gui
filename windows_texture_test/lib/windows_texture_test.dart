import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final MethodChannel _channel = const MethodChannel('windows_texture_test');

class PlayerValue {
  PlayerValue({
    required this.isInitialized,
  });

  final bool isInitialized;

  PlayerValue copyWith({
    bool? isInitialized,
  }) {
    return PlayerValue(
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  PlayerValue.uninitialized()
      : this(
          isInitialized: false,
        );
}

class PlayerController extends ValueNotifier<PlayerValue> {
  late Completer<void> _creatingCompleter;
  static final Completer<void> _disposingCompleter = Completer<void>();
  static final Completer<void> _disposedCompleter = Completer<void>();
  int _textureId = 0;
  bool _isDisposed = false;
  bool playing = false; //TODO: this should live on PlayerValue?

  PlayerController() : super(PlayerValue.uninitialized());

  Future<void> initialize(int width, int height, {int port = 5002}) async {
    if (_isDisposed) {
      return Future<void>.value();
    }
    try {
      _creatingCompleter = Completer<void>();

      if (!_disposingCompleter.isCompleted) {
        _disposingCompleter.complete();
        debugPrint('Calling dispose from init');
        //inform plugin that we've reset the state and can no longer guarantee which players are visible
        await _channel.invokeMapMethod<String, dynamic>('dispose');
        _disposedCompleter.complete();
      }

      await _disposedCompleter.future;

      final reply = await _channel.invokeMapMethod<String, dynamic>(
          'initialize', (port << 32) + (width << 16) + height);

      if (reply != null) {
        _textureId = reply['textureId'];
        value = value.copyWith(isInitialized: true);
      }
    } on PlatformException catch (e) {}

    _creatingCompleter.complete();
    return _creatingCompleter.future;
  }

  Future<void> play() async {
    debugPrint(
        'attempting to play. isDisposed: $_isDisposed. isInit: ${value.isInitialized}');
    if (_isDisposed || !value.isInitialized) return Future<void>.value();

    Completer<void> completer = Completer<void>();
    try {
      final reply =
          await _channel.invokeMapMethod<String, dynamic>('play', _textureId);
      debugPrint('awaited method');
      if (reply != null) {
        playing = reply['playing'];
      }
    } on PlatformException catch (e) {}
    completer.complete();
    return completer.future;
  }

  Future<void> pause() async {
    if (_isDisposed || !value.isInitialized) return Future<void>.value();
    Completer<void> completer = Completer<void>();
    try {
      final reply =
          await _channel.invokeMapMethod<String, dynamic>('pause', _textureId);
      if (reply != null) {
        playing = reply['playing'];
      }
    } on PlatformException catch (e) {}
    completer.complete();
    return completer.future;
  }

  @override
  void dispose() {
    print('Disposing of player controller');
    if (!_isDisposed && value.isInitialized)
      _channel.invokeMapMethod<String, dynamic>('dispose');
    super.dispose();
  }
}

class PlayerView extends StatelessWidget {
  const PlayerView(this.controller);

  final PlayerController controller;

  @override
  Widget build(BuildContext context) {
    return controller.value.isInitialized
        ? Texture(textureId: controller._textureId)
        : Container();
  }
}
