// import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
// import 'api.dart';
// import 'video2.dart';
import 'video3.dart';

class CollapsibleImageList extends StatelessWidget {
  final double size;
  final Axis axis;
  final List<String> images;
  final List<String> streamId;
  final String Function(int) titleFn;
  CollapsibleImageList(
      {this.size,
      this.images,
      this.streamId,
      this.titleFn,
      this.axis = Axis.horizontal});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        // shrinkWrap: false,
        shrinkWrap: true,
        scrollDirection: this.axis,
        itemCount: images.length,
        itemBuilder: (context, i) {
          return CollapsibleImage(
            title: this.titleFn(i),
            src: this.images[i],
            streamId: this.streamId[i],
            axis: this.axis,
            size: this.size,
          );
        });
  }
}

class CollapsibleImage extends StatefulWidget {
  // final Widget child;
  final String title;
  final String streamId;
  final String src;
  final double size;
  final Axis axis;
  final BoxFit fit;
  CollapsibleImage(
      {this.size,
      this.streamId,
      this.src,
      this.title,
      this.axis = Axis.horizontal,
      this.fit = BoxFit.contain});

  @override
  _CollapsibleImageState createState() => _CollapsibleImageState();
}

class _CollapsibleImageState extends State<CollapsibleImage> {
  bool expanded = true;

  void toggle() {
    // RigStatus rigStatus = RigStatus.empty();
    // rigStatus[widget.streamId] = false;
    // RigStatus.apply(rigStatus);

    setState(() {
      expanded = !expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('building collapsible image');
    // debugPrint(bmp[32694].toString());
    bool isHorizontal = widget.axis == Axis.horizontal;

    // if (img == null) return Container();

    return InkWell(
        onTap: toggle,
        child: Stack(alignment: AlignmentDirectional.centerStart, children: [
          ExpandedImage(
              expand: expanded,
              // child: Image.memory(
              //   bmp,
              //   // child: Image.asset(
              //   //   'images/image.png',
              //   height: isHorizontal ? widget.size : null,
              //   width: isHorizontal ? null : widget.size,
              //   fit: widget.fit,
              //   gaplessPlayback: true,
              // )
              // child: StreamImage(
              //   videoProvider: VideoProvider(0),
              // ),
              // child: Image(image: VideoProvider(0)),
              child: VideoStream(widget.src,
                  height: isHorizontal ? widget.size : null,
                  width: isHorizontal ? null : widget.size)
              //
              ),
          Container(
              width: isHorizontal ? 20 : widget.size,
              height: isHorizontal ? widget.size : 20,
              color: Theme.of(context).backgroundColor.withOpacity(0.6)),
          RotatedBox(
              quarterTurns: isHorizontal ? -1 : 0,
              child: Text(widget.title,
                  style: TextStyle(
                    // color: Theme.of(context).buttonColor
                    color: expanded
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).buttonColor,
                  ))),
        ]));
  }
}

class ExpandedImage extends StatefulWidget {
  final Widget child;
  final bool expand;
  ExpandedImage({this.expand, this.child});

  @override
  _ExpandedImageState createState() => _ExpandedImageState();
}

class _ExpandedImageState extends State<ExpandedImage>
    with SingleTickerProviderStateMixin {
  AnimationController expandController;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
  }

  void prepareAnimations() {
    expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    animation =
        CurvedAnimation(parent: expandController, curve: Curves.fastOutSlowIn);
  }

  void _runExpandCheck() {
    if (widget.expand) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(ExpandedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _runExpandCheck();
  }

  @override
  void dispose() {
    expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: widget.child,
      axis: Axis.horizontal,
      axisAlignment: 1.0,
    );
  }
}

void main() async {
  // DynamicRigStatus();
  // await Future.delayed(Duration(milliseconds: 500));

  runApp(
      //
      MaterialApp(
          //
          home: Scaffold(
              body: CollapsibleImage(
    //
    size: 500,
    streamId: 'video0.display',
    src: 'http://localhost:5000/video/0/stream.m3u8',
    title: 'Top Camera',
    axis: Axis.horizontal,
  ) //
              ) //
          ) //
      );
}
