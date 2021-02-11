import 'package:flutter/material.dart';
import 'collapseImage.dart';
import 'api.dart';
// import 'video.dart';

class VideoSection extends StatelessWidget {
  VideoSection(
    this.visible,
    this.width,
    this.height,
    this.padding,
    this.heightUpper,
    this.heightLower,
    this.rigStatus,
  );
  final bool visible;
  final double width;
  final double height;
  final double padding;

  final double heightUpper;
  final double heightLower;

  final RigStatusMap rigStatus;

  @override
  Widget build(BuildContext context) {
    debugPrint('rebuilding videosection, visible = ' + visible.toString());

    return ExpandedImage(
        expand: visible,
        isHorizontal: false,
        duration: 1000,
        delayForward: 500,
        delayReverse: 0,
        child: SizedBox(
          width: width,
          height: height,
          child: Row(children: [
            SizedBox(width: padding / 4),
            CollapsibleImage(
              size: Size(
                  rigStatus['camera 0'].current['aspect ratio'].current *
                      height,
                  0),
              visible: visible,
              src: rigStatus['camera 0'].current['port'].current,
              title: 'Top Camera',
              axis: Axis.horizontal,
              // callback: (visible) => callback(visible, 0),
            ),
            SizedBox(width: padding / 2),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  SizedBox(
                      height: heightUpper,
                      child: CollapsibleImageList(
                        visible: (i) => visible,
                        sizes: (i) => Size(
                            rigStatus['camera ${i + 1}']
                                    .current['aspect ratio']
                                    .current *
                                heightUpper,
                            0),
                        axis: Axis.horizontal,
                        images: (i) => rigStatus['camera ${i + 1}']
                            .current['port']
                            .current,
                        titleFn: (i) => 'Side Camera ${i + 1}',
                        // callbacks: (visible, i) => callback(visible, i + 1)),
                      )),
                  LayoutBuilder(
                      builder: //TODO: should we rebuild this whenever video0 is collapsed/expanded?
                          (BuildContext context, BoxConstraints constraints) {
                    return CollapsibleImage(
                      size: Size(constraints.maxWidth, 0),
                      visible: visible,
                      src: rigStatus['spectrogram'].current['port'].current,
                      title: 'Audio Spectrogram',
                      axis: Axis.horizontal,
                      // callback: (visible) => callback(visible, 4),
                    );
                  }),
                ])),
            SizedBox(width: padding / 4),
          ]),
        ));
  }
}

// void main() {
//   runApp(MaterialApp(
//       home: Scaffold(
//           body: VideoSection(
//     true,
//     1800,
//     500,
//     10,
//     250,
//     250,
//     null,
//     List<bool>.filled(5, true),
//     [0, 1, 2, 3],
//   ))));
// }
