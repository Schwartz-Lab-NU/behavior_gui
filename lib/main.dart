import 'package:flutter/material.dart';
import 'settings.dart';
// import 'cameras.dart';
import 'collapseImage.dart';
// import 'video2.dart';
import 'api.dart';
// import 'package:flutter/widgets.dart';
// Uncomment lines 7 and 10 to view the visual layout at runtime.
// import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;

void main() async {
  DynamicRigStatus();
  await Future.delayed(Duration(milliseconds: 500));
  // debugPaintSizeEnabled = true;
  runApp(MaterialApp(
      home: MyApp(),
      theme: ThemeData(
        brightness: Brightness.dark,
        backgroundColor: Colors.white,
        primaryColor: Color.fromARGB(255, 50, 50, 50),
        accentColor: Colors.cyan,
        buttonColor: Colors.lightBlue,
        unselectedWidgetColor: Colors.grey,
      )));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MediaQueryData _queryData = MediaQuery.of(context);
    Size mediaSize = MediaQuery.of(context).size;
    // double height = mediaSize.height;
    double mainWidth = mediaSize.width * 0.4;
    double mainHeight = mainWidth / 1280 * 1024;
    double padding = 30;
    // double subWidth = mediaSize.width - mainWidth - padding;
    double subHeight = mainHeight / 2;
    double audioHeight = mainHeight - subHeight;

    double textWidth = mediaSize.width * .6;
    double settingsWidth = mediaSize.width - textWidth - padding;

    Color color = Theme.of(context).buttonColor;

    // Widget buttonSection = ButtonSection(color, mainWidth);

    Widget textSection = ListView(
      reverse: true,
      children: [
        TextField(
          autofocus: true,
          maxLines: null,
          style: TextStyle(color: color),
        )
      ],
    );

    return MaterialApp(
      title: 'Behavior App',
      theme: Theme.of(context),
      home: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Column(
          children: [
            // buttonSection,
            StatusBar(color, mainWidth),
            SizedBox(
              width: mediaSize.width,
              height: mainHeight,
              child: Row(children: [
                SizedBox(width: padding / 4),
                // StreamingImage(0),
                CollapsibleImage(
                  size: mainHeight,
                  streamId: 'video0.display',
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
                        height: subHeight,
                        child: CollapsibleImageList(
                            size: subHeight,
                            axis: Axis.horizontal,
                            streamId: streams,
                            images: sideCameras,
                            titleFn: (i) => 'Side Camera ${i + 1}'),
                      ),
                      CollapsibleImage(
                        size: audioHeight,
                        streamId: 'audio.display',
                        src: 'http://localhost:5000/video/0/stream.m3u8',
                        title: 'Audio Spectrogram',
                        axis: Axis.horizontal,
                        fit: BoxFit.fill,
                      )
                    ])),
                SizedBox(width: padding / 4),
              ]),
            ),
            SizedBox(
                height: 20,
                width: mediaSize.width - 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SESSION NOTES', style: TextStyle(color: color)),
                    Text('SETTINGS PANEL', style: TextStyle(color: color)),
                  ],
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: textWidth,
                  height: mediaSize.height - mainHeight - 85,
                  child: textSection,
                ),
                SizedBox(
                  width: settingsWidth,
                  height: mediaSize.height - mainHeight - 85,
                  child: Container(
                    child: SettingsList(),
                    width: settingsWidth,
                    height: mediaSize.height - mainHeight - 85,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<String> sideCameras = [
  'http://localhost:5000/video/1/stream.m3u8',
  'http://localhost:5000/video/2/stream.m3u8',
  'http://localhost:5000/video/3/stream.m3u8',
  // 'http://localhost:5000/video/4/stream.m3u8',
];

List<String> streams = [
  'video1.display',
  'video2.display',
  'video3.display',
  // 'video4.display',
];
