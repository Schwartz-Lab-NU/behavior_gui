// import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'api.dart';
import 'video2.dart';

class CollapsibleImageList extends StatelessWidget {
  final double size;
  final Axis axis;
  final List<int> images;
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
  final int src;
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
  // int updates = 0;
  // Uint8List bmp = Uint8List(66614);
  // Widget img;
  // ImageDescriptor id;
  // Uint8List pix = Uint8List(65536);

  void initState() {
    super.initState();

    // bmp.setRange(0, 54, [
    //   66, 77, //BM
    //   54, 4, 1, 0, //256x256 uint8 image + 54 byte header +4*256byte palette
    //   0, 0, 0, 0, //reserved
    //   54, 4, 0, 0, //offset to beginning of bitmap
    //   40, 0, 0, 0, //size of `infoheader` = 40bytes
    //   0, 1, 0, 0, //width of image = 256 pixels
    //   0, 1, 0, 0, //height of image = 256 pixels
    //   1, 0, //number of z planes == 1
    //   8, 0, //bits per pixel == 8
    //   0, 0, 0, 0, //compression type == none
    //   0, 0, 1, 0, //compressed size = 256px x 256px x 8bits/px
    //   196, 14, 0, 0, //horizontal resolution... pixels/meter
    //   196, 14, 0, 0, //vertical resolution... pixels/meter
    //   0, 1, 0, 0, //number of colors used == 256
    //   0, 1, 0, 0 //number of important colors, 0 = all (or 8?)
    // ]);
    // for (int i = 0; i < 256; i++) {
    //   bmp.fillRange(54 + 4 * i, 54 + 4 * (i + 1), i); //defines a gray ramp
    // }
    // debugPrint('finished setting bmp header');
    // bool isHorizontal = widget.axis == Axis.horizontal;
    // img = null;
    // img = Image.memory(
    //   bmp,
    //   // key: Key(updates.toString()),
    //   height: isHorizontal ? widget.size : null,
    //   width: isHorizontal ? null : widget.size,
    //   fit: widget.fit,
    //   gaplessPlayback: true,
    // );
    // debugPrint('made image.memory object');

    // Api.video(widget.src).then((response) {
    //   if (response.statusCode == 200) {
    //     response.stream.listen(handleNewFrame);
    //   }
    // });
  }

  // void handleNewFrame(List<int> data) {
  //   bool isHorizontal = widget.axis == Axis.horizontal;
  //   if (data.length > 7) {
  //     bmp.setRange(1078, 1071 + data.length, data.sublist(7));
  //     // bmp.fillRange(1078, 66614, 128);
  //     setState(() {
  //       // updates += 1;
  //       img = Image.memory(
  //         bmp,
  //         // key: Key(updates.toString()),
  //         height: isHorizontal ? widget.size : null,
  //         width: isHorizontal ? null : widget.size,
  //         fit: widget.fit,
  //         gaplessPlayback: true,
  //       );
  //       debugPrint('updated image.memory object');
  //     });
  //   }
  // }

  void toggle() {
    RigStatus rigStatus = RigStatus.empty();
    rigStatus[widget.streamId] = false;
    RigStatus.apply(rigStatus);

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
              child: StreamingImage(0)
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
  DynamicRigStatus();
  await Future.delayed(Duration(milliseconds: 500));

  runApp(
      //
      MaterialApp(
          //
          home: Scaffold(
              body: CollapsibleImage(
    //
    size: 500,
    streamId: 'video0.display',
    src: 0,
    title: 'Top Camera',
    axis: Axis.horizontal,
  ) //
              ) //
          ) //
      );
}
