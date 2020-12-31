import 'package:flutter/material.dart';
import 'settingsPanel.dart';
// import 'cameras.dart';
import 'collapseImage.dart';
// import 'package:flutter/widgets.dart';
// Uncomment lines 7 and 10 to view the visual layout at runtime.
// import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;

void main() {
  // debugPaintSizeEnabled = true;
  runApp(MaterialApp(
      home: MyApp(),
      theme: ThemeData(
        brightness: Brightness.dark,
        backgroundColor: Colors.white,
        primaryColor: Color.fromARGB(255, 50, 50, 50),
        accentColor: Colors.cyan,
        buttonColor: Colors.lightBlue,
        unselectedWidgetColor: Colors.lightBlue,
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

    void Function() callback = () => debugPrint('registered tap');

    Widget buttonSection = SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildButtonColumn(
                mainWidth / 4, color, Icons.not_interested, 'STOP', callback),
            _buildButtonColumn(
                mainWidth / 4, color, Icons.circle, 'RECORD', callback),
            _buildButtonColumn(
                mainWidth / 4, color, Icons.build, 'CALIBRATE', callback),
            _buildButtonColumn(
                mainWidth / 4, color, Icons.folder, 'FILE NAME', callback),
            _buildButtonColumn(
                mainWidth / 4, color, Icons.info, 'STATUS', callback),
            SizedBox(
                width: mainWidth,
                child: Text(
                  '<status text or error message will go here, maybe a loading bar>',
                  style: TextStyle(color: color),
                )),
          ],
        ));

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
            buttonSection,
            SizedBox(
              width: mediaSize.width,
              height: mainHeight,
              child: Row(children: [
                SizedBox(width: padding / 4),
                CollapsibleImage(
                  size: mainHeight,
                  src: 'images/image.png',
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
                            images: sideCameras,
                            titleFn: (i) => 'Side Camera ${i + 1}'),
                      ),
                      CollapsibleImage(
                        size: audioHeight,
                        src: 'images/spect.png',
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

  SizedBox _buildButtonColumn(double width, Color color, IconData icon,
      String label, void Function() callback) {
    return SizedBox(
        width: width,
        child: Center(
            child: SizedBox(
                width: width / 2,
                child: InkWell(
                    onTap: callback,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: color),
                          Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: Text(label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: color,
                                  )))
                        ])))));
  }
}

List<String> sideCameras = [
  'images/image.png',
  'images/image.png',
  'images/image.png',
  'images/image.png',
];
