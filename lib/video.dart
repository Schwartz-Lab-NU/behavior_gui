import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
// import 'dart:io';

class VideoStream extends StatefulWidget {
  VideoStream(this.src, this.visible,
      {@required this.width, @required this.height, this.seekTo});
  final String src;
  final bool visible;
  final double width;
  final double height;
  final int
      seekTo; //optional, start this many seconds relative to video start (for debugging)

  @override
  _VideoStreamState createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  Size _size;

  @override
  void initState() {
    //default 1.25 AR? TODO: just get the size from the DynamicRigStatus
    _size = Size(widget.width == null ? widget.height * 1.25 : widget.width,
        widget.height == null ? widget.width / 1.25 : widget.height);

    _initializeVideoPlayerFuture = initController();
    super.initState();
  }

  Future<void> initController() {
    _controller = VideoPlayerController.network(widget.src);
    return _controller.initialize().then((_) {
      _size = Size(
          widget.width == null
              ? _controller.value.aspectRatio * widget.height
              : widget.width,
          widget.height == null
              ? widget.width / _controller.value.aspectRatio
              : widget.height); //TODO: wrap in setState? probably not
      if (widget.seekTo != null) {
        _controller
            .seekTo(Duration(seconds: widget.seekTo)); //TODO: only for testing
      }
      _controller.play();
      // debugPrint('Got video: ' + _controller.value.toString());
      // _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      // });
      // _controller.addListener(() {
      //   debugPrint('controller changed');
      // });
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
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              widget.visible) {
            return SizedBox(
              // aspectRatio: _controller.value.aspectRatio,
              width: _size.width,
              height: _size.height,
              child: Stack(
                alignment: AlignmentDirectional.centerStart,
                children: [
                  VideoPlayer(_controller),
                  // Container(
                  //     width: _controller.value.size.width,
                  //     height: _controller.value.size.height,
                  //     color: Colors.cyan.withOpacity(.3),
                  //     child: Expanded(
                  //         child: Text(
                  //       'testing',
                  //       style: TextStyle(color: Colors.white),
                  //     ))),
                  CustomPaint(
                    // size: _controller.value.size,
                    size: Size(1280, 1024),
                    painter: Annotater(),
                  )
                ],
              ),
            );
          } else if (widget.visible) {
            return SizedBox(
                width: _size.width,
                height: _size.height,
                child: Center(child: CircularProgressIndicator()));
          } else {
            return SizedBox(
                width: _size.width, height: _size.height, child: Container());
          }
        });
  }
}

class Annotater extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint marker = Paint();
    marker.color = Colors.white;
    marker.style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), marker);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 4, marker);
  }

  bool shouldRepaint(CustomPainter old) {
    //TODO: we should update when we've received new data?
    return false;
  }
}

void main() {
  runApp(MaterialApp(
      home: Scaffold(
          body: GridView.count(crossAxisCount: 2, children: [
    VideoStream('http://localhost:5000/video/0/stream.m3u8', true,
        width: 200, height: null),
    VideoStream('http://localhost:5000/video/1/stream.m3u8', true,
        width: 200, height: null),
    VideoStream('http://localhost:5000/video/2/stream.m3u8', true,
        width: 200, height: null),
    VideoStream('http://localhost:5000/video/3/stream.m3u8', true,
        width: 200, height: null),
    VideoStream('http://localhost:5000/video/4/stream.m3u8', true,
        width: 200, height: null),
    VideoStream('http://localhost:5000/video/5/stream.m3u8', true,
        width: 200, height: null),
  ]))));
}
