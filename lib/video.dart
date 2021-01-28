import 'dart:async';

import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
// import 'package:vector_math/vector_math.dart';
// import 'dart:io';
import 'dart:math';

class VideoStream extends StatefulWidget {
  VideoStream(
    this.src,
    this.visible, {
    @required this.size,
    this.seekTo,
  });
  final String src;
  final bool visible;
  final Size size;
  final int
      seekTo; //optional, start this many seconds relative to video start (for debugging)

  @override
  _VideoStreamState createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  VideoPlayerController _controller;
  // Future<void> _initializeVideoPlayerFuture;
  // StreamController<bool> _isDisplaying = StreamController<bool>();
  bool _isDisplaying = false;
  Size _size;
  Size _baseSize;
  Matrix4 _rescale = Matrix4.identity();
  Annotater _annotater;

  @override
  void initState() {
    //default 1.25 AR? TODO: just get the size from the DynamicRigStatus?
    _size = Size(
        widget.size.width == 0 ? widget.size.height * 1.25 : widget.size.width,
        widget.size.height == 0
            ? widget.size.width / 1.25
            : widget.size.height);
    _baseSize = _size;
    _annotater =
        Annotater((widget.size.width != 0) & (widget.size.height != 0));
    // _initializeVideoPlayerFuture = initController();
    initController();
    super.initState();
  }

  void initController() {
    VideoPlayerController controller =
        VideoPlayerController.network(widget.src);

    controller.initialize().then((_) {
      debugPrint('initialized controller: ${controller.value}');
      Size baseSize;
      Size size = Size(
          widget.size.width == 0
              ? controller.value.aspectRatio * widget.size.height
              : widget.size.width,
          widget.size.height == 0
              ? widget.size.width / controller.value.aspectRatio
              : widget.size.height);
      Matrix4 rescale = Matrix4.identity();
      if ((widget.size.width != 0) & (widget.size.height != 0)) {
        double widgetAR = widget.size.width / widget.size.height;
        if (widgetAR > controller.value.aspectRatio) {
          rescale[0] = widgetAR / controller.value.aspectRatio;
          baseSize = Size(controller.value.aspectRatio * widget.size.height,
              widget.size.height);
          // rescale[12] = -widget.size.width / 2 + _baseSize.width / 2;
        } else {
          // rescale[5] = controller.value.aspectRatio / widgetAR;
          baseSize = Size(widget.size.width,
              widget.size.width / controller.value.aspectRatio);
        }
      } else {
        baseSize = size;
      }
      if (widget.seekTo != null) {
        controller.seekTo(Duration(seconds: widget.seekTo)).then((_) {
          controller.play().then((_) {
            debugPrint('controller did play? $controller');
          });
        }); //TODO: only for testing
      } else {
        controller.play().then((_) {
          debugPrint('controller did play? $controller');
        });
      }

      setState(() {
        _rescale = rescale;
        _size = size;
        _baseSize = baseSize;
        _isDisplaying = true;
        _controller = controller;
      });

      // _controller.play();
    });
  }

  // @override
  // void didChangeDependencies() {
  //   debugPrint('dependency change');
  //   super.didChangeDependencies();
  // }

  @override
  void didUpdateWidget(VideoStream oldStream) {
    if (oldStream.visible != widget.visible) {
      //we changed the visibility status
      if (widget.visible) {
        // setState(() {
        // _initializeVideoPlayerFuture = initController();
        // });
        initController();
      } else {
        // setState(() {
        // _controller.dispose();
        // _controller = null;
        // });
        setState(() {
          _isDisplaying = false;
        });
        _controller.dispose();
      }
    }
    //TODO: if widget size changes, we also want to update but without tearing down the controller

    super.didUpdateWidget(oldStream);
  }

  //TODO: need something like a component_should_update... if not visible, kill the controller, otherwise re-open it

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_isDisplaying) {
      child = CustomPaint(
          size: Size(1280, 1024), //TODO: what to set this to?
          foregroundPainter: _annotater,
          child: Container(
              width: _baseSize.width,
              height: _baseSize.height,
              child: Transform(
                  origin: Offset(_size.width / 2, _size.height / 2),
                  transform: _rescale,
                  child: VideoPlayer(_controller))));
    } else if (widget.visible) {
      child = Center(child: CircularProgressIndicator());
    } else {
      child = Container();
    }
    return SizedBox(width: _size.width, height: _size.height, child: child);
  }
}

class Annotater extends CustomPainter {
  final bool addAxes;
  Annotater(this.addAxes) : super();

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('repainting');

    Paint marker = Paint();
    marker.color = Colors.white;
    marker.style = PaintingStyle.stroke;
    TextStyle style = TextStyle(color: Colors.white, fontSize: 10);

    // canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), marker);
    // canvas.drawCircle(
    //     Offset(size.width / 2, size.height / 2), size.width / 4, marker);
    const double readRate = 2;
    double fMin = 10;
    double fMax = 1000;
    const bool isLogScaled = true;

    if (addAxes) {
      //x axis will go from -1/readRate to 0
      for (int i = 1; i < 10; i++) {
        double x = size.width / 10 * i;
        canvas.drawLine(
            Offset(x, size.height), Offset(x, size.height - 8), marker);
        canvas.drawLine(Offset(x, 0), Offset(x, 8), marker);
        TextSpan span = TextSpan(
            style: style,
            text: sprintf('-%0.02fs', [(1 - (i / 10)) / readRate]));
        TextPainter tp =
            TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x - 2 - tp.width, size.height - tp.height));
        tp.paint(canvas, Offset(x - 2 - tp.width, 0));
      }

      //y axis will go from fMin to fMax
      //if logscaled...
      // go from 10^(log10(fMin)) to 10^(log10(fMax))
      if (isLogScaled) {
        fMin = log(fMin) * log10e;
        fMax = log(fMax) * log10e;
      }
      double fRange = fMax - fMin;
      for (int i = 1; i <= 5; i++) {
        double y = size.height / 5 * i;
        // canvas.drawLine(Offset(0, y), Offset(8, y), marker);
        canvas.drawLine(
            Offset(size.width, y), Offset(size.width - 8, y), marker);
        double freq = fMin + i / 5 * fRange;
        if (isLogScaled) {
          freq = pow(10, freq);
        }
        TextSpan span =
            TextSpan(style: style, text: sprintf('%0.01fkHz', [freq]));
        TextPainter tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right);
        tp.layout();
        tp.paint(canvas, Offset(size.width - tp.width, y - tp.height - 2));
      }
    }
  }

  bool shouldRepaint(CustomPainter old) {
    //TODO: we should update when we've received new data?
    return false;
  }

  bool shouldRebuildSemantics(CustomPainter old) => false;
}

void main() {
  runApp(MaterialApp(
      home: Scaffold(
          body: SizedBox(
              width: 800,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.red),
                child: VideoStream(
                    'http://localhost:5000/video/0/stream.m3u8', true,
                    size: Size(800, 300)),
              )))));
}
