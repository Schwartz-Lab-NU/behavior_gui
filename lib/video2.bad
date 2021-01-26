// import 'package:behavior_app/video.dart';
import 'package:flutter/material.dart';
import 'api.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart';
import 'dart:math';

DynamicRigStatus _rigStatus = DynamicRigStatus();

class VideoStream {
  static Map<int, VideoStream> _streams = {};
  final int streamId;
  final StreamController<ui.Image> _outStream =
      StreamController<ui.Image>.broadcast();
  ByteStream _inStream;
  List<int> _intBuffer;
  int _bufferLength;
  int _bufferIndex = 0;
  int width;
  int height;
  // Stream<Uint32List> _inStream;

  factory VideoStream(streamId) {
    //first check if we already have a completer
    if (_streams.containsKey(streamId)) return _streams[streamId];
    VideoStream out = VideoStream._newStream(streamId);
    out.width = _rigStatus['camera$streamId.width'];
    out.height = _rigStatus['camera$streamId.height'];

    out._bufferLength = out.width * out.height * 4;
    out._intBuffer = List<int>.filled(out._bufferLength, 0, growable: false);

    Api.video(streamId).then((response) {
      if (response.statusCode == 200) {
        out._inStream = response.stream;
        // out._inStream =
        //     response.stream.asyncMap<Uint32List>((List<int> intList) {
        //   Uint8List.fromList(intList).buffer;
        // });

        out._inStream.listen(out._getImage, onDone: out._onDone);
      } else {
        //TODO: handle case of display not allowed
      }
    });
    return out;
  }

  VideoStream._newStream(this.streamId) {
    _streams[this.streamId] = this;
  }

  void _onDone() {
    //TODO: handle closed http connection, e.g. when the camera is no longer displaying
  }

  void _getImage(List<int> intList) {
    int oldBufferIndex = _bufferIndex;
    _bufferIndex += intList.length;

    int overflow = _bufferIndex - _bufferLength;
    if (overflow >= 0) {
      // int overflowIndex =
      //     (intList.length - (overflow % _bufferLength)); //index into intList
      int remainingOverflow = overflow % _bufferLength;
      int overflowIndex = intList.length - remainingOverflow;

      int listOffset = max(overflowIndex - _bufferLength, 0);
      if (intList.length > 2 * _bufferLength - oldBufferIndex) {
        oldBufferIndex = 0;
      }
      try {
        _intBuffer.setRange(oldBufferIndex, _bufferLength,
            intList.sublist(listOffset, overflowIndex));
      } catch (e) {
        debugPrint(oldBufferIndex.toString() +
            ' ' +
            _bufferLength.toString() +
            ' ' +
            remainingOverflow.toString() +
            ' ' +
            overflow.toString() +
            ' ' +
            intList.length.toString());
      }
      _addStream(); //finishes the frame
      _intBuffer.setRange(0, remainingOverflow, intList.sublist(overflowIndex));
      _bufferIndex = remainingOverflow;
    } else {
      _intBuffer.setRange(oldBufferIndex, _bufferIndex, intList);
    }
  }

  void _printStreamLength() async {
    int streamEntries = await _outStream.stream.length;
    debugPrint('number of entries in stream: ' + streamEntries.toString());
  }

  void _addStream() {
    // _printStreamLength();

    Uint8List byteList = Uint8List.fromList(
        _intBuffer); //happens synchronously, so no worries about overwrites

    (ui.ImmutableBuffer.fromUint8List(byteList)).then((buffer) {
      return ui.ImageDescriptor.raw(buffer,
              width: width,
              height: height,
              pixelFormat: ui.PixelFormat.rgba8888)
          .instantiateCodec();
    }).then((codec) {
      return codec.getNextFrame();
    }).then((frameInfo) {
      return frameInfo.image;
    }).then((image) {
      _outStream.add(image);
    });
  }
}

class StreamingImage extends StatefulWidget {
  const StreamingImage(this.src);

  final int src;

  @override
  _StreamingImageState createState() => _StreamingImageState();
}

class _StreamingImageState extends State<StreamingImage> {
  ui.Image _frame;
  StreamSubscription<ui.Image> _frameStream;

  @override
  void initState() {
    super.initState();
    _frameStream =
        VideoStream(widget.src)._outStream.stream.listen(_updateImage);
  }

  void _updateImage(ui.Image frame) {
    setState(() {
      _frame = frame;
    });
  }

  void dispose() {
    _frameStream.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('rebuilding image');
    return RawImage(
      fit: BoxFit.contain,
      image: _frame, // this is a dart:ui Image object
      scale: 1.0,
    );
  }
}

void main() async {
  debugPrint('_rigStatus: ' + _rigStatus.toString());
  await Future.delayed(Duration(seconds: 1));
  debugPrint('_rigStatus: ' + _rigStatus.toString());

  runApp(MaterialApp(home: StreamingImage(0)));
}
