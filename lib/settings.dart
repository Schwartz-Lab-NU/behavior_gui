import 'package:flutter/material.dart';
import 'api.dart';
import 'dart:async';

// ValueNotifier<_rigStatus> __rigStatusNotifier = ValueNotifier(Dynamic_rigStatus());
DynamicRigStatus _rigStatus = DynamicRigStatus();

class SettingsList extends StatefulWidget {
  _SettingsListState createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  // DynamicRigStatus _rigStatus = DynamicRigStatus();
  DynamicRigStatusValues _rigStatusValues = DynamicRigStatusValues();
  List<String> _ignoreList = [
    'initialization',
    'recording',
    'calibration',
    'rootfilename',
    'notes'
  ];
  Map<String, List<String>> _categories = {};
  Map<String, TextEditingController> _text = {}; //=TextEditingController();
  int _numUpdates = 0;

  @override
  void initState() {
    _handleStateChange();
    DynamicRigStatusValues.onChange.listen((event) => _handleStateChange());
    super.initState();
  }

  void _handleStateChange() {
    if (_numUpdates == 0) {
      debugPrint('setting RSVs');
      // Map<String, List<String>> categories = {};
      // Map<String, TextEditingController> text;

      _rigStatusValues.forEach((key, value) {
        //exclude: initialized, recording, calibration, filename, notes?
        if (!_ignoreList.contains(key)) {
          //value.category is owner
          if (!_categories.containsKey(value.category)) {
            _categories[value.category] = [];
          }
          _categories[value.category].add(key);

          if (value.allowed.range != null) {
            _text[key] = TextEditingController();
          }
        }
      });
      _numUpdates = 1;
      // _categories = categories;
      // _text = text;
    } else {
      setState(() {
        _numUpdates = _numUpdates + 1;
      });
    }
  }

  void updateRig(String status, dynamic value) {
    RigStatus newStatus = RigStatus.empty();
    newStatus[status] = value;
    debugPrint('attempting to change $status to $value');
    RigStatus.apply(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    List<String> keys = _categories.keys.toList();
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        return ExpansionTile(
            // backgroundColor: Colors.black,
            title: Text(keys[i],
                style: TextStyle(color: Theme.of(context).buttonColor)),
            children: <Widget>[
              Column(
                  children: _categories[keys[i]].map((item) {
                RigStatusValue status = _rigStatusValues[item];
                String currentString = status.current.toString();
                Widget child;
                if (status is RigStatusValue<bool>) {
                  child = Switch(
                    activeColor: Theme.of(context).buttonColor,
                    inactiveThumbColor: Theme.of(context).buttonColor,
                    inactiveTrackColor: Theme.of(context).unselectedWidgetColor,
                    value: status.current,
                    onChanged: (newValue) => updateRig(item, newValue),
                  );
                } else if (status.allowed.values != null) {
                  child = DropdownButtonHideUnderline(
                      child: DropdownButton(
                          value: status.current,
                          onChanged: status.mutable
                              ? (newValue) => updateRig(item, newValue)
                              : null,
                          // iconSize: status.mutable ? 20 : 0,
                          // icon: status.mutable
                          //     ? Icon(Icons.arrow_drop_down,
                          //         color: Theme.of(context).buttonColor)
                          //     : null,
                          icon: null,
                          iconSize: 0,
                          items: status.allowed.values
                              .map<DropdownMenuItem>((dynamic value) {
                            return DropdownMenuItem(
                                value: value,
                                child: Text(value.toString(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: status.mutable
                                            ? Theme.of(context).buttonColor
                                            : Theme.of(context)
                                                .unselectedWidgetColor)));
                          }).toList()));
                } else {
                  child = SizedBox(
                      width: 100,
                      child: TextField(
                          textAlign: TextAlign.right,
                          controller: _text[item],
                          enabled: status.mutable,
                          onSubmitted: (newValue) {
                            if (status.current is double) {
                              updateRig(item, double.parse(newValue));
                            } else {
                              updateRig(item, int.parse(newValue));
                            }
                            _text[item].text = '';
                          },
                          decoration: InputDecoration(
                              hintText: status.current.toString(),
                              hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: status.mutable
                                      ? Theme.of(context).buttonColor
                                      : Theme.of(context)
                                          .unselectedWidgetColor)),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: status.mutable
                                  ? Theme.of(context).buttonColor
                                  : Theme.of(context).unselectedWidgetColor)));
                }

                return Tooltip(
                    message:
                        '${status.mutable ? "Mutable" : "Immutable"}. Allowed values: ${status.allowed.toString()}',
                    preferBelow: false,
                    verticalOffset: -15,
                    child: ListTile(
                        title: Row(children: [
                          Expanded(
                              child: Text(
                                  '${item[0].toUpperCase()}${item.substring(1)}',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor))),
                          child,
                        ]),
                        leading: Icon(icons[keys[i]],
                            color: Theme.of(context).primaryColor)));
                // trailing: child);
                // );
              }).toList())
            ]);
      },
    );
  }
}

// class Setting {
//   final String title;
//   List<String> contents = [];
//   final IconData icon;

//   Setting(this.title, this.contents, this.icon);
// }

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
  final void Function(String) recordCallback;

  StatusBar(this.color, this.width, {this.recordCallback});

  @override
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar>
    with SingleTickerProviderStateMixin {
  DateTime _lastUpdate = DateTime.now();
  // bool _expanded;
  String _lastMessage = '';
  StreamSubscription<void> statusSub;
  StreamSubscription<String> messageSub;

  AnimationController _expandController;
  Animation<double> _animation;

  TextEditingController _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _expanded = _rigStatus['initialization'] == 'initialized';

    _prepareAnimations();
    statusSub = DynamicRigStatus.onChange.listen((didChange) {
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

  // void _toggleRecord() {
  //   RigStatus rigStatus = RigStatus.empty();
  //   rigStatus['recording'] = !_rigStatus['recording'];
  //   RigStatus.apply(rigStatus);
  // }

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

  void _showDialog(BuildContext context, doRecording) async {
    String oldText = _text.text;
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _text,
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: 'Input root file name',
                          hintText: 'e.g., 01012021_mouse666')))
            ]),
            actions: [
              FlatButton(
                  child: Text('CANCEL'),
                  onPressed: () {
                    _text.text = oldText;
                    Navigator.pop(context);
                  }),
              FlatButton(
                  child: Text(doRecording ? 'RECORD' : 'APPLY'),
                  onPressed: () {
                    if (doRecording) {
                      widget.recordCallback(_text.text);
                    }
                    Navigator.pop(context);
                  }),
            ],
          );
        });
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
          Icons.pause, 'PAUSE', (data) => widget.recordCallback(_text.text));
      inactive = Theme.of(context).unselectedWidgetColor;
    } else {
      inactive = calibration.contains('calibrating')
          ? Theme.of(context).unselectedWidgetColor
          : widget.color;
      recordButton = _buildButtonColumn(widget.width / 4, true, inactive,
          Icons.circle, 'RECORD', (data) => _showDialog(context, true));
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
      // isRecording
      //     ? _buildButtonColumn(widget.width / 4, false, inactive, Icons.folder,
      //         'FILE NAME', (data) => _showDialog(context))
      //     : _buildInputColumn(
      //         widget.width / 4,
      //         !isRecording,
      //         inactive,
      //         Theme.of(context).backgroundColor,
      //         Icons.folder,
      //         ['FILE NAME', '/path/to/root/\$file', 'Input root file name:'],
      //         callback),
      _buildButtonColumn(widget.width / 4, !isRecording, inactive, Icons.folder,
          'FILE NAME', (data) => _showDialog(context, false)),
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
// List<Setting> settings = [
//   Setting('Acquisition', ['nCameras', 'nMicrophones'], Icons.work),
//   Setting(
//       'Video', ['Frame Capture Rate', 'Frame Display Rate'], Icons.videocam),
//   Setting('Audio', ['Sensitivity', 'Gain'], Icons.mic),
//   Setting('Post-Processing', ['waitTime', 'nWorkers'], Icons.computer)
// ];

Map<String, IconData> icons = {
  'Acquisition': Icons.work,
  'Video': Icons.videocam,
  'Audio': Icons.mic,
  // 'Post-Processing': Icons.computer
};
