import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
// import 'dart:io';

class VideoStream extends StatefulWidget {
  VideoStream(this.src, {@required this.width, @required this.height});
  final String src;
  final double width;
  final double height;

  @override
  _VideoStreamState createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;
  Size _size = Size(128, 128);

  @override
  void initState() {
    _controller = VideoPlayerController.network(widget.src);
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      _size = Size(
          widget.width == null
              ? _controller.value.aspectRatio * widget.height
              : widget.width,
          widget.height == null
              ? widget.width / _controller.value.aspectRatio
              : widget.height);
      _controller.seekTo(Duration(seconds: 0)); //TODO: only for testing
      _controller.play();
      debugPrint('Got video: ' + _controller.value.toString());
    });
    // _initializeVideoPlayerFuture = _controller.initialize().then((_) {
    // });
    _controller.addListener(() {
      debugPrint('controller changed');
    });
    super.initState();
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
          if (snapshot.connectionState == ConnectionState.done) {
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
          } else {
            return Center(child: CircularProgressIndicator());
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
  // floatingActionButton: FloatingActionButton(
  //     onPressed: () {
  //       setState(() {
  //         if (_controller.value.isPlaying) {
  //           debugPrint(_controller.value.toString());
  //           _controller.pause();
  //         } else {
  //           debugPrint(_controller.value.toString());
  //           _controller.play();
  //         }
  //       });
  //     },
  //     child: Icon(
  //         _controller.value.isPlaying ? Icons.pause : Icons.play_arrow)),

  runApp(MaterialApp(
      home: Scaffold(
          body: GridView.count(crossAxisCount: 2, children: [
    VideoStream('http://localhost:5000/video/0/stream.m3u8'),
    VideoStream('http://localhost:5000/video/1/stream.m3u8'),
    VideoStream('http://localhost:5000/video/2/stream.m3u8'),
    VideoStream('http://localhost:5000/video/3/stream.m3u8'),
    VideoStream('http://localhost:5000/video/4/stream.m3u8'),
    VideoStream('http://localhost:5000/video/5/stream.m3u8'),
  ]))));
}
