import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
// import 'dart:io';

class VideoStream extends StatefulWidget {
  VideoStream(this.src);
  final String src;

  @override
  _VideoStreamState createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  VideoPlayerController _controller;
  Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    _controller = VideoPlayerController.network(widget.src);
    _initializeVideoPlayerFuture =
        _controller.initialize().then((_) => _controller.play());
    // _initializeVideoPlayerFuture = _controller.initialize().then((_) {
    debugPrint('Got video: ' + _controller.value.toString());
    // });
    super.initState();
  }

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
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        });
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
