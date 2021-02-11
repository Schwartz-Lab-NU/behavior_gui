// import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
// import 'api.dart';
// import 'video2.dart';
import 'video.dart';

class CollapsibleImageList extends StatelessWidget {
  final Size size;
  final Axis axis;
  final List<int> images;
  final String Function(int) titleFn;
  final bool Function(int) visible;
  final void Function(bool, int) callbacks;
  CollapsibleImageList(
      {this.size,
      this.visible = _evalTrue,
      this.images,
      this.titleFn,
      this.axis = Axis.horizontal,
      this.callbacks});

  static bool _evalTrue(int index) => true;

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
              visible: this.visible(i),
              axis: this.axis,
              callback: (visible) => this.callbacks(visible, i));
        });
  }
}

class CollapsibleImage extends StatefulWidget {
  // final Widget child;
  final String title;
  final int src;
  final Axis axis;
  final bool visible;
  final void Function(bool) callback;
  final bool startExpanded;
  final Size size;
  CollapsibleImage(
      {@required this.src,
      @required this.size,
      this.visible = true,
      this.title,
      this.axis = Axis.horizontal,
      this.callback,
      this.startExpanded = false});

  @override
  _CollapsibleImageState createState() => _CollapsibleImageState();
}

class _CollapsibleImageState extends State<CollapsibleImage> {
  bool expanded;
  bool visible;
  void Function() doneAnimation = () {};

  @override
  void initState() {
    super.initState();

    expanded = widget.visible && widget.startExpanded;
    visible = expanded;
  }

  void toggle() {
    // RigStatus rigStatus = RigStatus.empty();
    // rigStatus['video# displaying'] = expanded;
    // RigStatus.apply(rigStatus);

    // widget.callback(expanded);

    setState(() {
      if (expanded) {
        expanded = false;
        doneAnimation = () => setState(() {
              visible = false;
              doneAnimation = () {};
            });
      } else {
        expanded = true;
        visible = true;
        doneAnimation = () {};
      }

      widget.callback(expanded);
    });
  }

  @override
  void didUpdateWidget(CollapsibleImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.visible && !widget.visible) {
      //if the video was closed and then opened without user input, keep it closed
      //but if the video was open and is now forced close, close it here
      setState(() {
        expanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint(bmp[32694].toString());
    bool isHorizontal = widget.axis == Axis.horizontal;
    debugPrint(
        'building collapsible image "${widget.title}" with state visible=${widget.visible} and expanded=$expanded');

    // if (img == null) return Container();

    return InkWell(
        onTap: toggle,
        child: Stack(alignment: AlignmentDirectional.centerStart, children: [
          ExpandedImage(
            expand: expanded,
            isHorizontal: isHorizontal,
            child: SizedBox(
                width: widget.size.width == 0 ? null : widget.size.width,
                height: widget.size.height == 0 ? null : widget.size.height,
                child: VideoStream(widget.src, visible)),
            callback: doneAnimation,
            //
          ),
          LayoutBuilder(builder: (BuildContext _, BoxConstraints constraints) {
            return Container(
              width: isHorizontal ? 20 : constraints.maxWidth,
              height: isHorizontal ? constraints.maxHeight : 20,
              color: Theme.of(context).backgroundColor.withOpacity(0.6),
            );
          }),
          RotatedBox(
              quarterTurns: isHorizontal ? -1 : 0,
              child: Text(widget.title,
                  style: TextStyle(
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
  final bool isHorizontal;
  final int duration;
  final int delayForward;
  final int delayReverse;
  final void Function() callback;
  ExpandedImage(
      {this.expand,
      this.child,
      this.isHorizontal = true,
      this.duration = 500,
      this.delayForward = 0,
      this.delayReverse = 0,
      this.callback});

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
    int duration = widget.duration + widget.delayForward + widget.delayReverse;
    // double delay = widget.delay / duration;
    expandController = AnimationController(
        vsync: this, duration: Duration(milliseconds: duration));
    // expandController.addStatusListener((status) {
    //   if (status == AnimationStatus.completed) widget.callback();
    // });
    animation = CurvedAnimation(
        parent: expandController,
        curve: Interval(widget.delayForward / duration,
            1.0 - widget.delayReverse / duration,
            curve: Curves.fastOutSlowIn));
  }

  void _runExpandCheck() {
    if (widget.expand) {
      expandController.forward().whenComplete(widget.callback);
    } else {
      expandController.reverse().whenComplete(widget.callback);
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
      axis: widget.isHorizontal ? Axis.horizontal : Axis.vertical,
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
              body: SizedBox(
                  width: 800,
                  height: 300,
                  // child: CollapsibleImageList(
                  //     size: Size(800, 0),
                  //     visible: (i) => true,
                  //     images: [0, 0, 0],
                  //     titleFn: (i) => 'camera $i',
                  //     axis: Axis.horizontal,
                  //     callbacks: (exp, res) => print('expanded? $exp $res'))
                  child: Row(
                    children: [
                      CollapsibleImage(
                          //
                          visible: true,
                          src: 0,
                          title: 'Top Camera',
                          axis: Axis.horizontal,
                          callback: (res) => print('expanded? $res'),
                          startExpanded: false,
                          size: Size(375, 0)),
                      CollapsibleImage(
                          //
                          visible: true,
                          src: 0,
                          title: 'Top Camera',
                          axis: Axis.horizontal,
                          callback: (res) => print('expanded? $res'),
                          startExpanded: false,
                          size: Size(375, 0)),
                      Expanded(child: Container()),
                    ],
                  )) //
              ) //
          ));
}
