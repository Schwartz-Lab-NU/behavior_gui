import 'package:flutter/material.dart';
import 'collapseImage.dart';
// import 'video.dart';

class VideoSection extends StatelessWidget {
  VideoSection(this.visible, this.width, this.height, this.padding,
      this.heightUpper, this.heightLower);
  final bool visible;
  final double width;
  final double height;
  final double padding;

  final double heightUpper;
  final double heightLower;

//   @override
//   _VideoSectionState createState() => _VideoSectionState();
// }

// class _VideoSectionState extends State<VideoSection> {
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
            // StreamingImage(0),
            CollapsibleImage(
              visible: visible,
              size: height,
              src: 'http://localhost:5000/video/0/stream.m3u8',
              title: 'Top Camera',
              axis: Axis.horizontal,
            ),
            SizedBox(width: padding / 2),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  SizedBox(
                    height: heightUpper,
                    child: CollapsibleImageList(
                        visible: visible,
                        size: heightUpper,
                        axis: Axis.horizontal,
                        images: sideCameras,
                        titleFn: (i) => 'Side Camera ${i + 1}'),
                  ),
                  CollapsibleImage(
                    visible: visible,
                    size: heightLower,
                    src: 'http://localhost:5000/video/0/stream.m3u8',
                    title: 'Audio Spectrogram',
                    axis: Axis.horizontal,
                    fit: BoxFit.fill,
                  )
                ])),
            SizedBox(width: padding / 4),
          ]),
        ));
  }
}

List<String> sideCameras = [
  'http://localhost:5000/video/1/stream.m3u8',
  'http://localhost:5000/video/2/stream.m3u8',
  'http://localhost:5000/video/3/stream.m3u8',
  // 'http://localhost:5000/video/4/stream.m3u8',
];

// List<String> streams = [
//   'video1.display',
//   'video2.display',
//   'video3.display',
//   // 'video4.display',
// ];
