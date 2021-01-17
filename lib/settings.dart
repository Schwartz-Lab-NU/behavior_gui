import 'package:flutter/material.dart';
import 'api.dart';
import 'dart:async';

// ValueNotifier<_rigStatus> __rigStatusNotifier = ValueNotifier(Dynamic_rigStatus());
DynamicRigStatus _rigStatus = DynamicRigStatus();

class SettingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: settings.length,
      itemBuilder: (context, i) {
        return ExpansionTile(
            // backgroundColor: Colors.black,
            title: Text(settings[i].title,
                style: TextStyle(color: Theme.of(context).buttonColor)),
            children: <Widget>[
              Column(children: _buildListChildren(settings[i], context))
            ]);
      },
    );
  }

  _buildListChildren(Setting setting, BuildContext context) {
    List<Widget> contents = [];
    for (String content in setting.contents) {
      contents.add(ListTile(
        title: Text(
          content,
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        leading: Icon(setting.icon, color: Theme.of(context).primaryColor),
      ));
    }
    return contents;
  }
}

class Setting {
  final String title;
  List<String> contents = [];
  final IconData icon;

  Setting(this.title, this.contents, this.icon);
}

SizedBox _buildButtonColumn(double width, bool enabled, Color color,
    IconData icon, String label, void Function(dynamic) callback) {
  return SizedBox(
      width: width,
      child: Center(
          child: SizedBox(
              width: width / 2,
              child: InkWell(
                  onTap: enabled ? () => callback(null) : null,
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

SizedBox _buildDropdownColumn(
    double width,
    bool enabled,
    Color color,
    Color background,
    IconData icon,
    List<String> labels,
    void Function(dynamic) callback) {
  Widget button = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Container(
            margin: const EdgeInsets.only(top: 8),
            child: Text(labels[0],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: color,
                )))
      ]);

  return SizedBox(
      width: width,
      child: Center(
          child: SizedBox(
        width: width / 2,
        child: PopupMenuButton<int>(
          offset: Offset(0, 48),
          color: background.withOpacity(.95),
          padding: EdgeInsets.all(6),
          child: button,
          onSelected: (i) => callback(i),
          itemBuilder: (BuildContext context) {
            return labels.sublist(1).asMap().entries.map((entry) {
              return PopupMenuItem(
                  enabled: enabled,
                  height: 26,
                  value: entry.key,
                  child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                          text: entry.value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: color,
                          ))));
              // Text(value,
              //     style: TextStyle(
              //         fontSize: 18,
              //         fontWeight: FontWeight.w400,
              //         color: color)));
            }).toList();
          },
        ),
      )));
}

SizedBox _buildInputColumn(
    double width,
    bool enabled,
    Color color,
    Color background,
    IconData icon,
    List<String> labels,
    void Function(dynamic) callback) {
  Widget button = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        Container(
            margin: const EdgeInsets.only(top: 8),
            child: Text(labels[0],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: color,
                )))
      ]);

  return SizedBox(
      width: width,
      child: Center(
          child: SizedBox(
        width: width / 2,
        child: PopupMenuButton(
          offset: Offset(0, 48),
          color: background.withOpacity(.95),
          padding: EdgeInsets.all(6),
          child: button,
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry>[
              // PopupMenuItem(
              //   enabled: false,
              //   value: 'text label',
              //   child: Text(labels[1],
              //       style: TextStyle(
              //           fontSize: 8,
              //           fontWeight: FontWeight.w400,
              //           color: color)),
              // ),
              PopupMenuItem(
                  enabled: false,
                  value: 'text label',
                  child: SizedBox(
                    width: 400,
                    child: TextField(
                        decoration: InputDecoration(
                            hintText: labels[1],
                            labelText: labels[2],
                            labelStyle: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w400,
                                fontSize: 18),
                            hintStyle: TextStyle(color: color)),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: color)),
                  )),
            ];
            // return PopupMenuItem(
            //     enabled: enabled,
            //     height: 26,
            //     value: value,
            //     child: Text(value,
            //         style: TextStyle(
            //             fontSize: 18,
            //             fontWeight: FontWeight.w400,
            //             color: color)));
            // }).toList();
          },
        ),
      )));
}

class StatusBar extends StatefulWidget {
  final Color color;
  final double width;

  StatusBar(this.color, this.width);

  @override
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar>
    with SingleTickerProviderStateMixin {
  DateTime _lastUpdate = DateTime.now();
  // bool _expanded;
  String _lastMessage = '';
  StreamSubscription<bool> statusSub;
  StreamSubscription<String> messageSub;

  AnimationController _expandController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // _expanded = _rigStatus['initialization'] == 'initialized';

    _prepareAnimations();
    statusSub = _rigStatus.onChange.listen((didChange) {
      if (_rigStatus['initialization'] == 'initialized') {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
      debugPrint('registered rig status change');
      setState(() {
        _lastUpdate = DateTime.now();
        // _expanded = _rigStatus['initialization'] == 'initialized';
      });
    });
    messageSub = Api.onMessage.listen((message) {
      setState(() {
        _lastMessage = message;
      });
    });
    if (_rigStatus['initialization'] == 'initialized') {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  void dispose() {
    statusSub.cancel();
    messageSub.cancel();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleRecord() {
    RigStatus rigStatus = RigStatus.empty();
    rigStatus['recording'] = !_rigStatus['recording'];
    RigStatus.apply(rigStatus);
  }

  void _toggleInit() {
    RigStatus rigStatus = RigStatus.empty();
    rigStatus['initialization'] = _rigStatus['initialization'] == 'initialized'
        ? 'deinitialized'
        : 'initialized';
    RigStatus.apply(rigStatus);
  }

  void _toggleCalibrate(int i) {
    RigStatus rigStatus = RigStatus.empty();
    if (i == 0) {
      rigStatus['calibration'] =
          _rigStatus['calibration'] == 'calibrating intrinsic'
              ? 'uncalibrated'
              : 'calibrating intrinsic';
    } else {
      rigStatus['calibration'] =
          _rigStatus['calibration'] == 'calibrating extrinsic'
              ? 'uncalibrated'
              : 'calibrating extrinsic';
    }
    RigStatus.apply(rigStatus);
  }

  // @override
  // void didUpdateWidget(StatusBar oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   _runExpandCheck();
  // }

  void _prepareAnimations() {
    _expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animation =
        CurvedAnimation(parent: _expandController, curve: Curves.fastOutSlowIn);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('rebuilding status bar');
    debugPrint(_rigStatus.toString());
    Widget initButton;
    List<Widget> children;
    void Function(dynamic) callback = (arg) => debugPrint('registered tap');

    String intrinsic;
    String extrinsic;
    String calibration = _rigStatus['calibration'];

    if (calibration != null) {
      intrinsic = (calibration == 'calibrated' || calibration == 'intrinsic'
              ? '☑'
              : '☐') +
          ' intrinsic';
      extrinsic = (calibration == 'calibrated' || calibration == 'extrinsic'
              ? '☑'
              : '☐') +
          ' extrinsic';
    } else {
      calibration = '';
    }

    // if (_rigStatus['initialization'] == 'initialized') {
    Widget recordButton;
    Color inactive;
    bool isRecording = _rigStatus['recording'] == true;
    if (isRecording) {
      recordButton = _buildButtonColumn(widget.width / 4, true, widget.color,
          Icons.pause, 'PAUSE', (arg) => _toggleRecord());
      inactive = Theme.of(context).unselectedWidgetColor;
    } else {
      inactive = calibration.contains('calibrating')
          ? Theme.of(context).unselectedWidgetColor
          : widget.color;
      recordButton = _buildButtonColumn(widget.width / 4, true, inactive,
          Icons.circle, 'RECORD', (arg) => _toggleRecord());
    }

    children = [
      recordButton,
      isRecording
          ? _buildButtonColumn(widget.width / 4, false, inactive, Icons.build,
              'CALIBRATE', (i) => _toggleCalibrate(i))
          : _buildDropdownColumn(
              widget.width / 4,
              !isRecording,
              calibration.contains('calibrating') ? widget.color : inactive,
              Theme.of(context).backgroundColor,
              Icons.build,
              ['CALIBRATE', intrinsic, extrinsic],
              (i) => _toggleCalibrate(i)),
      isRecording
          ? _buildButtonColumn(widget.width / 4, false, inactive, Icons.folder,
              'FILE NAME', callback)
          : _buildInputColumn(
              widget.width / 4,
              !isRecording,
              inactive,
              Theme.of(context).backgroundColor,
              Icons.folder,
              ['FILE NAME', '/path/to/root/\$file', 'Input root file name:'],
              callback),
      _buildButtonColumn(widget.width / 4, false, widget.color, Icons.info,
          'STATUS', callback),
      SizedBox(
          width: widget.width,
          child: Text(
            _lastMessage,
            style: TextStyle(color: widget.color),
          )),
    ];

    if (_rigStatus['initialization'] == 'initialized') {
      initButton = _buildButtonColumn(widget.width / 4, !isRecording, inactive,
          Icons.not_interested, 'STOP', (arg) => _toggleInit());
    } else {
      initButton = _buildButtonColumn(widget.width / 4, true, widget.color,
          Icons.play_arrow, 'START', (arg) => _toggleInit());
    }

    return SizedBox(
        height: 50,
        child: Row(children: [
          initButton,
          SizeTransition(
            sizeFactor: _animation,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.start, children: children),
            // child: widget.child,
            axis: Axis.horizontal,
            axisAlignment: 1.0,
          )
        ]));
  }
}

//build this dynamically from current rig status
List<Setting> settings = [
  Setting('Acquisition', ['nCameras', 'nMicrophones'], Icons.work),
  Setting(
      'Video', ['Frame Capture Rate', 'Frame Display Rate'], Icons.videocam),
  Setting('Audio', ['Sensitivity', 'Gain'], Icons.mic),
  Setting('Post-Processing', ['waitTime', 'nWorkers'], Icons.computer)
];
