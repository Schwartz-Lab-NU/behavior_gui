import 'package:flutter/material.dart';
import 'api.dart';
import 'dart:async';

DynamicRigStatus _rigStatus = DynamicRigStatus();

class SettingsList extends StatefulWidget {
  _SettingsListState createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  DynamicRigStatusValues _rigStatusValues = DynamicRigStatusValues();
  List<String> _ignoreList = [
    'initialization',
    'recording',
    'calibration',
    'rootfilename',
    'notes'
  ];
  Map<String, List<String>> _categories = {};
  Map<String, TextEditingController> _text = {};
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
    } else {
      setState(() {
        _numUpdates = _numUpdates + 1;
      });
    }
  }

  void updateRig(String status, dynamic value) {
    RigStatus newStatus = RigStatus.empty();
    newStatus[status] = value;
    RigStatus.apply(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    List<String> keys = _categories.keys.toList();
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        return ExpansionTile(
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
              }).toList())
            ]);
      },
    );
  }
}

SizedBox _buildButtonColumn(double width, bool enabled, BuildContext context,
    IconData icon, String label, void Function(dynamic) callback) {
  Color color = enabled
      ? Theme.of(context).buttonColor
      : Theme.of(context).unselectedWidgetColor;
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
          },
        ),
      )));
}

class StatusBar extends StatefulWidget {
  final double width;
  final void Function(String) recordCallback;

  StatusBar(this.width, {this.recordCallback});

  @override
  _StatusBarState createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> with TickerProviderStateMixin {
  DateTime _lastUpdate = DateTime.now();
  // bool _expanded;
  String _lastMessage = '';
  StreamSubscription<void> statusSub;
  StreamSubscription<String> messageSub;

  AnimationController _controllerStatus;
  Animation<double> _animationStatus;

  bool _showCalibratePanel = false;
  AnimationController _controllerCalib;
  Animation<double> _animationCalib;

  TextEditingController _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    // _expanded = _rigStatus['initialization'] == 'initialized';

    _prepareAnimations();
    statusSub = DynamicRigStatus.onChange.listen((didChange) {
      if (_rigStatus['initialization'].value == 'initialized') {
        _controllerStatus.forward();
      } else {
        _controllerStatus.reverse();
        _controllerCalib.reverse();
      }
      if (!_rigStatus['calibration'].mutable) {
        _controllerCalib.reverse(); //TODO: can we do this better?
      }

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
    if (_rigStatus['initialization'].value == 'initialized') {
      _controllerStatus.forward();
    } else {
      _controllerStatus.reverse();
    }
    _controllerCalib.reverse();
  }

  @override
  void dispose() {
    statusSub.cancel();
    messageSub.cancel();
    _controllerStatus.dispose();
    _controllerCalib.dispose();
    super.dispose();
  }

  void _toggleInit() {
    RigStatus rigStatus = RigStatus.empty();
    rigStatus['initialization'] =
        (_rigStatus['initialization'].value == 'initialized')
            ? 'deinitialized'
            : 'initialized';
    debugPrint(rigStatus.toString());
    RigStatus.apply(rigStatus);
  }

  void _toggleCalibrate() {
    if (_showCalibratePanel) {
      _controllerCalib.reverse();
    } else {
      _controllerCalib.forward();
    }
    setState(() {
      _showCalibratePanel = !_showCalibratePanel;
    });
  }

  void _prepareAnimations() {
    _controllerStatus =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animationStatus =
        CurvedAnimation(parent: _controllerStatus, curve: Curves.fastOutSlowIn);

    _controllerCalib =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animationCalib =
        CurvedAnimation(parent: _controllerCalib, curve: Curves.fastOutSlowIn);
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
    void Function(dynamic) callback = (arg) => debugPrint('registered tap');

    Widget recordButton;
    Color inactive = Theme.of(context).unselectedWidgetColor;
    Color active = Theme.of(context).buttonColor;

    if (_rigStatus['recording'].value) {
      recordButton = _buildButtonColumn(widget.width / 4, true, context,
          Icons.pause, 'PAUSE', (data) => widget.recordCallback(_text.text));
    } else {
      recordButton = _buildButtonColumn(
          widget.width / 4,
          true,
          context, //TODO: assumes we can always stop recording...
          Icons.circle,
          'RECORD',
          (data) => _showDialog(context, true));
    }

    Widget calibrationButton = _buildButtonColumn(
        widget.width / 4,
        _rigStatus['calibration'].mutable,
        context,
        Icons.build,
        'CALIBRATE',
        (arg) => _toggleCalibrate());

    Widget processButton = _buildButtonColumn(widget.width / 4, true, context,
        Icons.leaderboard, 'ANALYSIS', callback);

    Widget logsButton = _buildButtonColumn(
        widget.width / 4, true, context, Icons.info, 'LOGS', callback);

    List<Widget> children;
    children = [
      recordButton,
      calibrationButton,
      processButton,
      logsButton,
      SizedBox(
          width: widget.width,
          child: Text(
            _lastMessage,
            style: TextStyle(color: active),
          )),
    ];

    Widget initButton;
    if (_rigStatus['initialization'].value == 'initialized') {
      initButton = _buildButtonColumn(
          widget.width / 4,
          _rigStatus['initialization'].mutable,
          context,
          Icons.not_interested,
          'STOP',
          (arg) => _toggleInit());
    } else {
      initButton = _buildButtonColumn(
          widget.width / 4,
          true,
          context, //TODO: assumes we can always init?
          Icons.play_arrow,
          'START',
          (arg) => _toggleInit());
    }

    return Column(children: [
      SizedBox(
          height: 50,
          child: Row(children: [
            initButton,
            SizeTransition(
              sizeFactor: _animationStatus,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: children),
              // child: widget.child,
              axis: Axis.horizontal,
              axisAlignment: 1.0,
            )
          ])),
      SizeTransition(
        sizeFactor: _animationCalib,
        axis: Axis.vertical,

        child: SizedBox(
            height: 150,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              SizedBox(width: 10),
              Container(color: Colors.red, width: 500),
              SizedBox(width: 10),
              Container(color: Colors.green, width: 500),
              SizedBox(width: 10),
              Container(color: Colors.blue, width: 500),
              SizedBox(width: 10),
            ])),
        // axisAlignment: 1.0,
      ),
    ]);
  }
}

Map<String, IconData> icons = {
  'Acquisition': Icons.work,
  'Video': Icons.videocam,
  'Audio': Icons.mic,
  // 'Post-Processing': Icons.computer
};
