// import 'dart:async';

import 'package:behavior_app/api.dart';
// import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:sprintf/sprintf.dart';
// import 'package:vector_math/vector_math.dart';
// import 'dart:io';
import 'dart:math';

import 'package:windows_texture_test/windows_texture_test.dart';

class VideoStream extends StatefulWidget {
  VideoStream(
    this.src,
    this.visible, {
    this.audio = false,
  });
  final RigStatusMap src;
  final bool visible;
  final bool audio;

  @override
  _VideoStreamState createState() => _VideoStreamState();
}

class _VideoStreamState extends State<VideoStream> {
  PlayerController _controller;
  // Future<void> _initializeVideoPlayerFuture;
  // StreamController<bool> _isDisplaying = StreamController<bool>();
  // bool _isDisplaying = false;
  // Size _size;
  // Size _baseSize;
  // Matrix4 _rescale = Matrix4.identity();
  Annotater _annotater;

  @override
  void initState() {
    //default 1.25 AR? TODO: just get the size from the DynamicRigStatus?
    // _size = Size(
    //     widget.size.width == 0 ? widget.size.height * 1.25 : widget.size.width,
    //     widget.size.height == 0
    //         ? widget.size.width / 1.25
    //         : widget.size.height);
    // _baseSize = _size;

    if (widget.audio) {
      ValueNotifier changedAudioSettings = ValueNotifier(null);
      // RigStatusMap rigStatus = RigStatusMap.live();

      Function updateAudio = (_) {
        debugPrint('updating audio settings for axes');
        changedAudioSettings.value = {
          'fMin': widget.src['minimum frequency'].current,
          'fMax': widget.src['maximum frequency'].current,
          'isLogScaled': widget.src['log scaling'].current,
          'readRate': widget.src['read rate'].current
        };
      };
      updateAudio(null);
      RigStatusMap.onChange.listen(updateAudio);

      _annotater = Annotater(listenable: changedAudioSettings);
    } else {
      _annotater = Annotater();
    }

    // _initializeVideoPlayerFuture = initController();
    initController();
    super.initState();
  }

  void initController() {
    PlayerController controller = PlayerController();
    controller
        .initialize(widget.src['width'].current, widget.src['height'].current,
            port: widget.src['port'].current)
        .then((_) {
      // //TODO: init values from rigStatus
      // double ar = 1280 / 1024;
      // controller.initialize(1280, 1024, port: widget.src + 5002).then((_) {
      //   debugPrint('initialized controller: ${controller.value}');
      //   Size baseSize;
      //   Size size = Size(
      //       widget.size.width == 0 ? ar * widget.size.height : widget.size.width,
      //       widget.size.height == 0
      //           ? widget.size.width / ar
      //           : widget.size.height);
      //   Matrix4 rescale = Matrix4.identity();
      //   if ((widget.size.width != 0) & (widget.size.height != 0)) {
      //     double widgetAR = widget.size.width / widget.size.height;
      //     if (widgetAR > ar) {
      //       rescale[0] = widgetAR / ar;
      //       baseSize = Size(ar * widget.size.height, widget.size.height);
      //       // rescale[12] = -widget.size.width / 2 + _baseSize.width / 2;
      //     } else {
      //       // rescale[5] = controller.value.aspectRatio / widgetAR;
      //       //TODO: fixed?
      //       rescale[5] = ar / widgetAR;
      //       baseSize = Size(widget.size.width, widget.size.width / ar);
      //     }
      //   } else {
      //     baseSize = size;
      //   }
      if (widget.visible) controller.play();

      setState(() {
        // _rescale = rescale;
        // _size = size;
        // _baseSize = baseSize;
        // _isDisplaying = true;
        _controller = controller;
      });
    });
  }

  @override
  void didChangeDependencies() {
    debugPrint('dependency change');
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(VideoStream oldStream) {
    if (oldStream.visible != widget.visible) {
      debugPrint('visibility changed');
      if (widget.visible) {
        _controller.play();
      } else {
        debugPrint("pausing controller");
        _controller.pause();
      }
      //we changed the visibility status
      // if (widget.visible) {
      //   // setState(() {
      //   // _initializeVideoPlayerFuture = initController();
      //   // });
      //   initController();
      // } else {
      //   // setState(() {
      //   // _controller.dispose();
      //   // _controller = null;
      //   // });
      //   setState(() {
      //     _controller.dispose();
      //     // _isDisplaying = false;
      //     _controller = null;
      //   });
      // }
    }
    //TODO: if widget size changes, we also want to update but without tearing down the controller

    super.didUpdateWidget(oldStream);
  }

  //TODO: need something like a component_should_update... if not visible, kill the controller, otherwise re-open it

  @override
  void dispose() {
    debugPrint('disposing controller');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_controller != null && widget.visible) {
      // _rescale[0] = .5;
      if (widget.audio) {
        child = CustomPaint(
            size: Size(1280, 1024), //TODO: what to set this to?
            foregroundPainter: _annotater,
            child: PlayerView(_controller));
      } else {
        child = PlayerView(_controller);
      }
    } else if (widget.visible) {
      child = Center(child: CircularProgressIndicator());
    } else {
      child = Container();
    }
    // return SizedBox(width: _size.width, height: _size.height, child: child);
    return child;
  }
}

class Annotater extends CustomPainter {
  // final bool addAxes;
  final ValueNotifier listenable;
  Annotater({this.listenable}) : super(repaint: listenable);

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('repainting');

    Paint marker = Paint();
    marker.color = Colors.red;
    marker.style = PaintingStyle.stroke;
    TextStyle style = TextStyle(color: Colors.red, fontSize: 10);

    // canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), marker);
    // canvas.drawCircle(
    //     Offset(size.width / 2, size.height / 2), size.width / 4, marker);

    if (listenable != null) {
      // debugPrint('listenable: ${listenable.value}');
      //x axis will go from -1/readRate to 0
      for (int i = 1; i < 10; i++) {
        double x = size.width / 10 * i;
        canvas.drawLine(
            Offset(x, size.height), Offset(x, size.height - 8), marker);
        canvas.drawLine(Offset(x, 0), Offset(x, 8), marker);
        TextSpan span = TextSpan(
            style: style,
            text: sprintf(
                '-%0.02fs', [(1 - (i / 10)) / listenable.value['readRate']]));
        TextPainter tp =
            TextPainter(text: span, textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(x - 2 - tp.width, size.height - tp.height));
        tp.paint(canvas, Offset(x - 2 - tp.width, 0));
      }

      double fMin = listenable.value['fMin'] / 1000;
      double fMax = listenable.value['fMax'] / 1000;
      //y axis will go from listenable.value['fMin'] to listenable.value['fMax']
      //if logscaled...
      // go from 10^(log10(listenable.value['fMin'])) to 10^(log10(listenable.value['fMax']))
      if (listenable.value['isLogScaled']) {
        fMin = log(fMin) * log10e;
        fMax = log(fMax) * log10e;
      }
      double fRange = fMax - fMin;
      for (int i = 1; i <= 5; i++) {
        double y = size.height / 5 * i;
        // canvas.drawLine(Offset(0, y), Offset(8, y), marker);
        canvas.drawLine(
            Offset(size.width, y), Offset(size.width - 8, y), marker);
        // double freq = fMin + i / 5 * fRange;
        double freq = fMax - i / 5 * fRange;
        if (listenable.value['isLogScaled']) {
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

      canvas.drawLine(Offset(size.width, 0), Offset(size.width - 8, 8), marker);
      TextSpan span = TextSpan(
          style: style,
          text: sprintf('0s,%0.01fkHz', [listenable.value['fMax'] / 1000]));
      TextPainter tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right);
      tp.layout();
      tp.paint(canvas, Offset(size.width - tp.width - 9, 9));
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
              height: 400,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.red),
                  // child: SizedBox(
                  //     width: 700,
                  //     height: 300,
                  //     child: DecoratedBox(
                  //         decoration: BoxDecoration(color: Colors.green),
                  //         child: Container())))))));
                  child: VideoStream(
                    0,
                    true,
                  ))))));
}
