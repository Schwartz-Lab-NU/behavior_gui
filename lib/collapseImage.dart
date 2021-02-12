// import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
// import 'api.dart';
// import 'video2.dart';
// import 'video.dart';

class CollapsibleImageList extends StatelessWidget {
  final Size Function(int) sizes;
  final Axis axis;
  final int numImages;
  // final dynamic Function(int) sources;
  final Widget Function(bool, int) builders;
  final String Function(int) titleFn;
  final bool Function(int) visible;
  final void Function(bool, int) callbacks;
  CollapsibleImageList(
      {@required this.sizes,
      this.numImages = 1,
      this.visible = _evalTrue,
      @required this.builders,
      this.titleFn,
      this.axis = Axis.horizontal,
      this.callbacks = _defaultCallbacks});

  static bool _evalTrue(int index) => true;

  static void _defaultCallbacks(bool expanded, int camera) {}

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        // shrinkWrap: false,
        shrinkWrap: true,
        scrollDirection: this.axis,
        itemCount: numImages,
        itemBuilder: (context, i) {
          return CollapsibleImage(
              size: this.sizes(i),
              title: this.titleFn(i),
              builder: (visible) => this.builders(visible, i),
              visible: this.visible(i),
              axis: this.axis,
              callback: (visible) => this.callbacks(visible, i));
        });
  }
}

class CollapsibleImage extends StatefulWidget {
  // final Widget child;
  final String title;
  // final dynamic src;
  final Widget Function(bool) builder;
  final Axis axis;
  final bool visible;
  final void Function(bool) callback;
  // final bool startExpanded;
  final Size size;
  CollapsibleImage({
    @required this.builder,
    @required this.size,
    this.visible = true,
    this.title,
    this.axis = Axis.horizontal,
    this.callback = _defaultCallback,
    // this.startExpanded = true,
  });

  static void _defaultCallback(bool expanded) {}

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

    // expanded = widget.visible && widget.startExpanded;
    expanded = widget.visible;
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

    if (oldWidget.visible != widget.visible) {
      setState(() {
        expanded = widget.visible;
        visible = widget.visible;
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
                child: widget.builder(visible)),
            callback: doneAnimation,
            //
          ),
          Container(
            width: isHorizontal ? 20 : widget.size.width,
            height: isHorizontal ? widget.size.height : 20,
            color: Theme.of(context).backgroundColor.withOpacity(0.6),
          ),
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

// void main() async {
//   runApp(
//       //
//       MaterialApp(
//           //
//           home: Scaffold(
//               body: SizedBox(
//                   // width: 800,
//                   height: 300,
//                   child: CollapsibleImageList(
//                       numImages: 5,
//                       sizes: (i) => Size(375, 0),
//                       visible: (i) => true,
//                       images: (i) => 5002,
//                       titleFn: (i) => 'camera $i',
//                       axis: Axis.horizontal,
//                       callbacks: (exp, res) => print('expanded? $exp $res'))) //
//               ) //
//           ));
// }
