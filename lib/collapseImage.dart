import 'package:flutter/material.dart';
import 'dart:math';

class CollapsibleImageContainer extends StatefulWidget {
  final List<Widget> children;
  final Axis axis;
  final Size size;
  CollapsibleImageContainer(
      {this.children, this.axis = Axis.horizontal, this.size});

  @override
  _CollapsibleImageContainerState createState() =>
      _CollapsibleImageContainerState();
}

class _CollapsibleImageContainerState extends State<CollapsibleImageContainer> {
  // List<bool> _expanded;
  List<ValueNotifier<double>> _boxSizes;
  List<double> _remainingSpace;

  @override
  void initState() {
    super.initState();
    // _expanded = List<bool>.filled(widget.children.length, false);
    _boxSizes = List<ValueNotifier<double>>.filled(
        widget.children.length, ValueNotifier<double>(0.0));
    _remainingSpace = List<double>.filled(
        widget.children.length,
        widget.axis == Axis.horizontal
            ? widget.size.width
            : widget.size.height);

    _boxSizes.asMap().forEach((index, notifier) {
      notifier.addListener(() => _updateRemaining(index));
    });
  }

  void _updateRemaining(int i) {
    for (int j = i + 1; j < widget.children.length; j++) {
      _remainingSpace[j] = _remainingSpace[j - 1] - _boxSizes[j - 1].value;
    }
    //remainingSpace[i+1] <- remainingSpace[i] - _boxSizes[i]
    //widget.size(axis)
  }

  @override
  Widget build(BuildContext context) {
    List<ValueListenableBuilder<double>> container = [
      for (int i = 0; i < widget.children.length; i++)
        ValueListenableBuilder<double>(
          builder: (BuildContext context, double size, Widget child) {
            return SizeTracker(
                child: SizedBox(
                  width: widget.axis == Axis.horizontal
                      ? min(_boxSizes[i].value, _remainingSpace[i])
                      : widget.size.width,
                  height: widget.axis == Axis.vertical
                      ? min(_boxSizes[i].value, _remainingSpace[i])
                      : widget.size.height,
                  child: widget.children[i],
                ),
                sizeValueNotifier: _boxSizes[i],
                axis: widget.axis);
          },
          valueListenable: _boxSizes[i],
          child: null,
        )
    ];

    if (widget.axis == Axis.horizontal) {
      //wrap within a row
      return Row(
        children: container,
      );
    } else {
      return Column(
        children: container,
      );
      //wrap within a column
    }
    //wrap within a sizedBox?

    //return
  }
}

class SizeTracker extends StatefulWidget {
  final Widget child;
  final Axis axis;
  final ValueNotifier<double> sizeValueNotifier;
  SizeTracker(
      {this.child, this.sizeValueNotifier, this.axis = Axis.horizontal});

  @override
  _SizeTrackerState createState() => _SizeTrackerState();
}

class _SizeTrackerState extends State<SizeTracker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getSize();
    });
  }

  _getSize() {
    RenderBox renderBox = context.findRenderObject();
    if (widget.axis == Axis.horizontal) {
      widget.sizeValueNotifier.value = renderBox.size.width;
    } else {
      widget.sizeValueNotifier.value = renderBox.size.height;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class CollapsibleImageList extends StatelessWidget {
  final double size;
  final Axis axis;
  final List<String> images;
  final String Function(int) titleFn;
  CollapsibleImageList(
      {this.size, this.images, this.titleFn, this.axis = Axis.horizontal});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        scrollDirection: this.axis,
        itemCount: images.length,
        itemBuilder: (context, i) {
          return CollapsibleImage(
            title: this.titleFn(i),
            src: this.images[i],
            axis: this.axis,
            size: this.size,
          );
        });
  }
}

class CollapsibleImage extends StatefulWidget {
  // final Widget child;
  final String title;
  final String src;
  final double size;
  final Axis axis;
  final BoxFit fit;
  CollapsibleImage(
      {this.size,
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
    setState(() {
      expanded = !expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isHorizontal = widget.axis == Axis.horizontal;

    return InkWell(
        onTap: toggle,
        child: Stack(alignment: AlignmentDirectional.centerStart, children: [
          ExpandedImage(
              expand: expanded,
              child: Image.asset(
                widget.src,
                height: isHorizontal ? widget.size : null,
                width: isHorizontal ? null : widget.size,
                fit: widget.fit,
              )),
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
