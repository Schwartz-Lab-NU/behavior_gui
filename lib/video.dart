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
  Future<void> _initializeVideoPlayerFuture;
  Size _size;
  Size _baseSize;
  Matrix4 _rescale = Matrix4.identity();

  @override
  void initState() {
    //default 1.25 AR? TODO: just get the size from the DynamicRigStatus?
    _size = Size(
        widget.size.width == 0 ? widget.size.height * 1.25 : widget.size.width,
        widget.size.height == 0
            ? widget.size.width / 1.25
            : widget.size.height);
    _baseSize = _size;

    _initializeVideoPlayerFuture = initController();
    super.initState();
  }

  Future<void> initController() {
    _controller = VideoPlayerController.network(widget.src);

    return _controller.initialize().then((_) {
      Size baseSize;
      Size size = Size(
          widget.size.width == 0
              ? _controller.value.aspectRatio * widget.size.height
              : widget.size.width,
          widget.size.height == 0
              ? widget.size.width / _controller.value.aspectRatio
              : widget.size.height);
      Matrix4 rescale = Matrix4.identity();
      if ((widget.size.width != 0) & (widget.size.height != 0)) {
        double widgetAR = widget.size.width / widget.size.height;
        if (widgetAR > _controller.value.aspectRatio) {
          rescale[0] = widgetAR / _controller.value.aspectRatio;
          baseSize = Size(_controller.value.aspectRatio * widget.size.height,
              widget.size.height);
        } else {
          rescale[5] = _controller.value.aspectRatio / widgetAR;
          baseSize = Size(widget.size.width,
              widget.size.width / _controller.value.aspectRatio);
        }
      } else {
        baseSize = size;
      }

      setState(() {
        _rescale = rescale;
        _size = size;
        _baseSize = baseSize;
      });
      if (widget.seekTo != null) {
        _controller
            .seekTo(Duration(seconds: widget.seekTo)); //TODO: only for testing
      }
      _controller.play();
    });
  }

  // @override
  // void didChangeDependencies() {
  //   debugPrint('dependency change');
  //   super.didChangeDependencies();
  // }

  @override
  void didUpdateWidget(VideoStream oldStream) {
    debugPrint((oldStream.visible == widget.visible).toString());
    if (oldStream.visible != widget.visible) {
      //we changed the visibility status
      if (widget.visible) {
        setState(() {
          _initializeVideoPlayerFuture = initController();
        });
      } else {
        setState(() {
          _controller.dispose();
          _controller = null;
        });
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
    return FutureBuilder(
        //TODO: change this to streambuilder??
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              widget.visible) {
            Widget child = Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [
                Container(
                    width: _baseSize.width,
                    height: _baseSize.height,
                    child: Transform(
                        transform: _rescale, child: VideoPlayer(_controller))),
                CustomPaint(
                  //TODO: container can be the child of the custompaint class, with the Annotater as foregroundPainter
                  size: Size(1280, 1024), //TODO: what to set this to?
                  painter: Annotater(
                      (widget.size.width != 0) & (widget.size.height != 0)),
                )
              ],
            );

            return SizedBox(
                width: _size.width, height: _size.height, child: child);
          } else if (widget.visible) {
            Widget child = Center(child: CircularProgressIndicator());

            return SizedBox(
                width: _size.width, height: _size.height, child: child);
          } else {
            return SizedBox(
                //TODO: can we capture the last frame to display here??
                width: _size.width,
                height: _size.height,
                child: Container());
          }
        });
  }
}

class Annotater extends CustomPainter {
  final bool addAxes;
  Annotater(this.addAxes) : super();

  @override
  void paint(Canvas canvas, Size size) {
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

    debugPrint('adding axes? $addAxes');
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
