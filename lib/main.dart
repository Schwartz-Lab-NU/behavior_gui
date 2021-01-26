import 'package:flutter/material.dart';
import 'settings.dart';
// import 'cameras.dart';
// import 'collapseImage.dart';
// import 'video2.dart';
import 'api.dart';
import 'videoSection.dart';
// import 'package:flutter/widgets.dart';
// Uncomment lines 7 and 10 to view the visual layout at runtime.
// import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;

void main() {
  // debugPaintSizeEnabled = true;
  DynamicRigStatusValues();
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

// class VideoStream extends StatefulWidget {
//   VideoStream(this.src, {@required this.width, @required this.height});
//   final String src;
//   final double width;
//   final double height;

//   @override
//   _VideoStreamState createState() => _VideoStreamState();
// }

// class _VideoStreamState extends State<VideoStream> {

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        initialData: false,
        future: DynamicRigStatusValues.initialized.future,
        builder: (context, snapshot) {
          if (DynamicRigStatusValues.initialized.isCompleted) {
            // debugPrint('loaded RSV');
            return LoadedApp();
          } else {
            // debugPrint('failed to load RSV: ' +
            //     DynamicRigStatusValues.initialized.isCompleted.toString());
            return Scaffold(
                body: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Connecting to python engine...',
                      style: TextStyle(
                          color: Theme.of(context).accentColor, fontSize: 12))
                ])));
          }
        });
  }
}

class LoadedApp extends StatefulWidget {
  LoadedApp();

  @override
  _LoadedAppState createState() => _LoadedAppState();
}

class _LoadedAppState extends State<LoadedApp> {
  int _updateCount = 0;
  DynamicRigStatus _rigStatus = DynamicRigStatus();
  bool _isInitialized;
  final TextEditingController _text = TextEditingController();

  @override
  void initState() {
    // debugPrint('initing loaded app, init status: ' +
    //     _rigStatus['initialization'].toString());
    _isInitialized = _rigStatus['initialization'] == 'initialized';
    DynamicRigStatus.onChange.listen((event) => _handleStateChange());
    super.initState();
  }

  void _handleStateChange() {
    // debugPrint('got statusChange');
    setState(() {
      _updateCount += 1;
      _isInitialized = _rigStatus['initialization'] == 'initialized';
    });
  }

  void _toggleRecord(String rootfilename) {
    //we want to update the state of the status list and the notes when the record button is pushed

    RigStatus rigStatus = RigStatus.empty();
    rigStatus['recording'] = !_rigStatus['recording'];
    rigStatus['notes'] = _text.text;
    rigStatus['rootfilename'] = rootfilename;
    RigStatus.apply(rigStatus);
    _text.text = '';
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

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
          controller: _text,
          autofocus: true,
          maxLines: null,
          style: TextStyle(color: color),
        )
      ],
    );

    // debugPrint(
    //     'rebuilding main app, _isInitialized = ' + _isInitialized.toString());

    return MaterialApp(
      title: 'Behavior App',
      theme: Theme.of(context),
      home: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: Column(
          children: [
            // buttonSection,
            StatusBar(color, mainWidth, recordCallback: _toggleRecord),
            VideoSection(_isInitialized, mediaSize.width, mainHeight, padding,
                subHeight, audioHeight),
            SizedBox(
                height: 30,
                width: mediaSize.width - 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SESSION NOTES', style: TextStyle(color: color)),
                    Text('SETTINGS PANEL', style: TextStyle(color: color)),
                  ],
                )),
            Expanded(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: textWidth,
                  // height: mediaSize.height - mainHeight - 85,
                  child: textSection,
                ),
                SizedBox(
                  width: settingsWidth,
                  // height: mediaSize.height - mainHeight - 85,
                  // child: Container(
                  child: SettingsList(),
                  // width: settingsWidth,
                  // height: mediaSize.height - mainHeight - 85,
                  // ),
                ),
              ],
            )),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
