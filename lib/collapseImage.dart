import 'package:flutter/material.dart';

class ExpandableImageList extends StatelessWidget {
  final double size;
  final Axis axis;
  final List<String> images;
  final String Function(int) titleFn;
  ExpandableImageList(
      {this.size, this.images, this.titleFn, this.axis = Axis.horizontal});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        // shrinkWrap: false,
        shrinkWrap: true,
        scrollDirection: this.axis,
        itemCount: images.length,
        itemBuilder: (context, i) {
          return ExpandableImage(
            title: this.titleFn(i),
            src: this.images[i],
            axis: this.axis,
            size: this.size,
          );
        });
  }
}

class ExpandableImage extends StatefulWidget {
  // final Widget child;
  final String title;
  final String src;
  final double size;
  final Axis axis;
  final BoxFit fit;
  // void Function(double, bool, Animation<double>) notify;
  // final ValueNotifier<double> currentSize = ValueNotifier<double>(20);

  ExpandableImage(
      {this.size,
      this.src,
      this.title,
      this.axis = Axis.horizontal,
      this.fit = BoxFit.contain,
      // this.notify
      });

  setNotifier(void Function(double, bool, Animation<double>) notifier) {
    this
  }

  @override
  _ExpandableImageState createState() => _ExpandableImageState();
}

class _ExpandableImageState extends State<ExpandableImage> {
  // final bool isHorizontal = widget.axis == Axis.horizontal;
  bool isHorizontal;
  bool expanded = true;
  // Image img;
  ValueListenableBuilder<Animation<double>> expandable;
  Container container;
  RotatedBox underlay;
  double aspectRatio;
  ValueNotifier<Animation<double>> animation;
  //  = ValueNotifier<Animation<double>>(Animation<double>());

  @override
  void initState() {
    super.initState();
    this.isHorizontal = widget.axis == Axis.horizontal;
    this.expandable = ValueListenableBuilder<Animation<double>>(
        child: Image.asset(
          widget.src,
          height: this.isHorizontal ? widget.size : null,
          width: this.isHorizontal ? null : widget.size,
          fit: widget.fit,
        ),
        valueListenable: this.animation,
        builder:
            (BuildContext context, Animation<double> animation, Widget child) {
          return ExpandableWidget(
              animation: this.animation,
              expand: () => getExpanded(),
              child: child);
        });

    this.container = Container(
        width: this.isHorizontal ? 20 : widget.size,
        height: this.isHorizontal ? widget.size : 20,
        color: Theme.of(context).backgroundColor.withOpacity(0.6));

    this.underlay = RotatedBox(
        quarterTurns: this.isHorizontal ? -1 : 0,
        child: Text(widget.title,
            style: TextStyle(
              // color: Theme.of(context).buttonColor
              color: expanded
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).buttonColor,
            )));

    _getAspectRatio(widget.src);
  }

  Future<void> _getAspectRatio(String src) async {
    File image = new File(widget.src);
    var decodedImage = await decodeImageFromList(image.readAsBytesSync());

    setState(() {
      aspectRatio:
      decodedImage.width / decodedImage.height;
    });
  }

  bool getExpanded() {
    return this.expanded;
  }

  void toggle() {
    //inform the parent that we are triggering an animation
    double fractionLabel;
    if (this.isHorizontal) {
      fractionLabel = 20 / (widget.size * this.aspectRatio);
    } else {
      fractionLabel = 20 / (widget.size / this.aspectRatio);
    }
    //  = 20 / this.aspectRatio;
    widget.notify(
      fractionLabel,
      !this.expanded,
      this.animation.value,
    );
    setState(() {
      expanded = !expanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: toggle,
        child: Stack(alignment: AlignmentDirectional.centerStart, children: [
          // ExpandableWidget(expand: this.expanded, child: this.img),
          // ValueListenableBuilder(valueListenable: this.animation, builder: ())
          this.expandable,
          this.container,
          this.underlay,
        ]));
  }
}

class ExpandableWidget extends StatefulWidget {
  final Widget child;
  final Axis axis;
  final bool Function() expand;
  final bool forward;
  final ValueNotifier<Animation<double>> animation;
  ExpandableWidget(
      {this.expand,
      this.child,
      this.axis = Axis.horizontal,
      this.forward = true,
      this.animation});

  @override
  _ExpandableWidgetState createState() => _ExpandableWidgetState();
}

class _ExpandableWidgetState extends State<ExpandableWidget>
    with SingleTickerProviderStateMixin {
  AnimationController expandController;
  // ValueNotifier<Animation<double>> animation;
  // Animation<double> animation;

  @override
  void initState() {
    super.initState();
    prepareAnimations();
    _runExpandCheck();
  }

  void prepareAnimations() {
    expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    widget.animation.value =
        CurvedAnimation(parent: expandController, curve: Curves.fastOutSlowIn);
  }

  void _runExpandCheck() {
    if (widget.expand()) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  @override
  void didUpdateWidget(ExpandableWidget oldWidget) {
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
      sizeFactor: widget.animation.value,
      child: widget.child,
      axis: widget.axis,
      axisAlignment: widget.forward ? 1.0 : -1.0,
    );
  }
}
