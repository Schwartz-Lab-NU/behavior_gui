import 'package:flutter/material.dart';
import 'api.dart';
import 'dart:async';
import 'messageLog.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

RigStatusMap _rigStatus = RigStatusMap.live();

class SettingsList extends StatefulWidget {
  _SettingsListState createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  RigStatusMap _rigStatus = RigStatusMap.live();
  List<String> _ignoreList = [
    'initialization',
    'recording',
    'calibration',
    'alert',
    'rootfilename',
    'notes'
  ];
  Map<String, List<String>> _categories = {};
  Map<String, TextEditingController> _text = {};
  int _numUpdates = 0;

  @override
  void initState() {
    _handleStateChange();
    RigStatusMap.onChange.listen((event) => _handleStateChange());
    super.initState();
  }

  void _handleStateChange() {
    if (_numUpdates == 0) {
      // debugPrint('setting RSVs');
      _rigStatus.forEach((key, value) {
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

  // void updateRig(String status, dynamic value, List<String> stack) {
  void updateRig(
      String status, dynamic value, RigStatusMap stack, RigStatusMap nested) {
    // debugPrint('stack: $stack');
    // Map<String, dynamic> json = {status: value};
    // while (stack.isNotEmpty) {
    //   json = {stack.removeLast(): json};
    // }

    // debugPrint(
    //     'aiming to update status $status with value $value using json: $json');

    // // RigStatus newStatus = RigStatus.empty();
    // // newStatus[status] = value;
    // RigStatusMap newStatus = RigStatusMap.fromJSON(json);

    // debugPrint('resulting status: $newStatus');
    // RigStatusMap.apply(newStatus);
    nested[status].current = value;
    RigStatusMap.apply(stack);
  }

  @override
  Widget build(BuildContext context) {
    List<String> keys = _categories.keys.toList();
    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, i) {
        RigStatusMap rigStatusMap = RigStatusMap();
        return ExpansionTile(
            title: Text(keys[i],
                style: TextStyle(color: Theme.of(context).buttonColor)),
            children: <Widget>[
              Column(
                  children: _categories[keys[i]]
                      .map((item) => _buildSettingItem(context, item, keys[i],
                          0.0, rigStatusMap, rigStatusMap))
                      .toList())
            ]);
      },
    );
  }

  Widget _buildSettingItem(BuildContext context, String item, String key,
      double indent, RigStatusMap statuses, RigStatusMap nested) {
    {
      RigStatusItem status = nested[item];
      // String currentString = status.current.toString();
      Widget child;
      if (status.current is bool) {
        child = Switch(
          activeColor: Theme.of(context).buttonColor,
          inactiveThumbColor: Theme.of(context).buttonColor,
          inactiveTrackColor: Theme.of(context).unselectedWidgetColor,
          value: status.current,
          onChanged: (newValue) => updateRig(item, newValue, statuses, nested),
        );
      } else if (status.allowed.values != null) {
        child = DropdownButtonHideUnderline(
            child: DropdownButton(
                value: status.current,
                onChanged: status.mutable
                    ? (newValue) => updateRig(item, newValue, statuses, nested)
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
                                  : Theme.of(context).unselectedWidgetColor)));
                }).toList()));
      } else if (status.allowed.range != null) {
        //TODO: this assumes that if not values we have a range, not the case for a nested map
        child = SizedBox(
            width: 100,
            child: TextField(
                textAlign: TextAlign.right,
                controller: _text[item],
                enabled: status.mutable,
                onSubmitted: (newValue) {
                  if (status.current is double) {
                    updateRig(item, double.parse(newValue), statuses, nested);
                  } else {
                    updateRig(item, int.parse(newValue), statuses, nested);
                  }
                  _text[item].text = '';
                },
                decoration: InputDecoration(
                    hintText: status.current.toString(),
                    hintStyle: TextStyle(
                        fontSize: 12,
                        color: status.mutable
                            ? Theme.of(context).buttonColor
                            : Theme.of(context).unselectedWidgetColor)),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: status.mutable
                        ? Theme.of(context).buttonColor
                        : Theme.of(context).unselectedWidgetColor)));
      } else {
        // List<String> newStack = List<String>.from(stack);
        // newStack.add(item);
        nested = nested[item].current;

        return ExpansionTile(
          title: Text('${item[0].toUpperCase()}${item.substring(1)}',
              style: TextStyle(color: Theme.of(context).buttonColor)),
          leading: Padding(
              padding: EdgeInsets.fromLTRB(indent, 0, 0, 0),
              child: Icon(icons[key], color: Theme.of(context).buttonColor)),
          children: <Widget>[
            Column(
              children: status.current.keys
                  .map<Widget>((subitem) => _buildSettingItem(
                      context,
                      subitem,
                      key,
                      indent + 20.0,
                      statuses,
                      nested)) //TODO: currently this ignores the child categories... probably fine but weird
                  .toList(),
            )
          ],
        );
      }

      return Tooltip(
          message:
              '${status.mutable ? "Mutable" : "Immutable"}. Allowed values: ${status.allowed.toString()}',
          preferBelow: false,
          verticalOffset: -15,
          child: ListTile(
              title: Row(children: [
                Expanded(
                    child: Text('${item[0].toUpperCase()}${item.substring(1)}',
                        style:
                            TextStyle(color: Theme.of(context).primaryColor))),
                child,
              ]),
              leading: Padding(
                  padding: EdgeInsets.fromLTRB(indent, 0, 0, 0),
                  child: Icon(icons[key],
                      color: Theme.of(context).primaryColor))));
    }
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
  MapEntry<DateTime, String> _lastMessage;
  StreamSubscription<void> statusSub;
  StreamSubscription<MapEntry<DateTime, String>> messageSub;

  AnimationController _controllerStatus;
  Animation<double> _animationStatus;

  bool _showCalibratePanel = false;
  AnimationController _controllerCalib;
  Animation<double> _animationCalib;

  TextEditingController _textAnimal = TextEditingController();
  TextEditingController _textAnimalType = TextEditingController();
  TextEditingController _textExperimentType = TextEditingController();
  TextEditingController _textWindowA = TextEditingController();
  TextEditingController _textWindowB = TextEditingController();
  TextEditingController _textWindowC = TextEditingController();
  TextEditingController _textWindowA_DJID = TextEditingController();
  TextEditingController _textWindowB_DJID = TextEditingController();
  TextEditingController _textWindowC_DJID = TextEditingController();
  TextEditingController _textUserName = TextEditingController(text: 'Devon');
  TextEditingController _textNotes = TextEditingController();

  DatabaseStatus _databaseStatus = DatabaseStatus();
  // String path = 'assets/namespace/namespace_test.json';

  bool _showPopup = false;
  String _lastAlert = _rigStatus['alert'].current;

  @override
  void initState() {
    super.initState();
    // _expanded = _rigStatus['initialization'] == 'initialized';

    _prepareAnimations();
    // _readNameSpace(path).whenComplete(() {
    // setState(() {});
    // });
    statusSub = RigStatusMap.onChange.listen((didChange) {
      if (_rigStatus['initialization'].current == 'initialized') {
        _controllerStatus.forward();
      } else {
        _controllerStatus.reverse();
        _controllerCalib.reverse();
      }
      if (!_rigStatus['calibration'].mutable) {
        _controllerCalib.reverse(); //TODO: can we do this better?
      }

      //if alert, show dialog
      debugPrint('lastAlert was: $_lastAlert');
      debugPrint('newAlert is: ${_rigStatus['alert'].current}');

      bool showPopup = (_rigStatus['alert'].current != _lastAlert) &&
          (_rigStatus['alert'].current != '');
      debugPrint('showing popup?? $showPopup');

      setState(() {
        _lastUpdate = DateTime.now();
        _showPopup = showPopup;
        _lastAlert = _rigStatus['alert'].current;
        // _expanded = _rigStatus['initialization'] == 'initialized';
      });
    });

    try {
      _lastMessage = Api.messageQueue.first;
    } catch (_) {
      _lastMessage = MapEntry<DateTime, String>(null, '');
    }

    messageSub = Api.onMessage.listen((message) {
      setState(() {
        _lastMessage = message;
      });
    });
    if (_rigStatus['initialization'].current == 'initialized') {
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
    RigStatusMap rigStatus = RigStatusMap(); //empty
    rigStatus['initialization'].current =
        (_rigStatus['initialization'].current == 'initialized')
            ? 'deinitialized'
            : 'initialized';
    RigStatusMap.apply(rigStatus);
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

  void _toggleAnalyze() {
    RigStatusMap rigStatus = RigStatusMap();
    rigStatus['analyzing'].current = !rigStatus['analyzing'].current;
    RigStatusMap.apply(rigStatus);
  }

  void _toggleLED() {
    RigStatusMap rigStatus = RigStatusMap();
    rigStatus['LED'].current = !rigStatus['LED'].current;
    RigStatusMap.apply(rigStatus);
  }

  void _doCalibration(int ind, CalibrationType type) {
    RigStatusMap rigStatus = RigStatusMap();
    rigStatus['calibration'].current['is calibrating'].current = true;
    rigStatus['calibration'].current['camera serial number'].current =
        _rigStatus['camera $ind'].current['serial number'].current;
    rigStatus['calibration'].current['calibration type'].current =
        type.toString().split('.').last;
    RigStatusMap.apply(rigStatus);
    _toggleCalibrate();
  }

  void _stopCalibration() {
    RigStatusMap rigStatus = RigStatusMap();
    rigStatus['calibration'].current['is calibrating'].current = false;
    RigStatusMap.apply(rigStatus);
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

  // Future<Map> _readNameSpace(String path) async {
  //   // var jsonText = await rootBundle.loadString(path);
  //   var jsonText = await File(path).readAsString();
  //   return json.decode(jsonText);
  // }

  bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    return double.tryParse(s) != null;
  }

  String _mergeText(List names) {
    String filename = '';
    for (TextEditingController item in names) {
      filename = '$filename&${item.text}';
    }
    return filename;
  }

  void _showDialog(BuildContext context, doRecording) async {
    String oldTextAnimal = _textAnimal.text;
    String oldTextAnimalType = _textAnimalType.text;
    String oldTextExperimentType = _textExperimentType.text;
    String oldTextWindowA = _textWindowA.text;
    String oldTextWindowB = _textWindowB.text;
    String oldTextWindowC = _textWindowC.text;
    String oldTextWindowA_DJID = _textWindowA.text;
    String oldTextWindowB_DJID = _textWindowB.text;
    String oldTextWindowC_DJID = _textWindowC.text;
    String oldTextUserName = _textUserName.text;

    bool _allow_windows = true;
    bool _allow_windowA_DJID = true;
    bool _allow_windowB_DJID = true;
    bool _allow_windowC_DJID = true;

    // get name space from .json file
    // Map nameSpace = await _readNameSpace(path);

    List _animalID = _databaseStatus['recent_test_animals'];
    List _stimAnimalID = _databaseStatus['recent_stim_animals'];
    List _animalType = _databaseStatus['animal_types'];
    List _windows = _databaseStatus['stimulus_types'];
    List _experimentType = _databaseStatus['experiment_types'];

    // List _animalType = nameSpace['animalType'];
    // List _windows = nameSpace['windows'];
    // List _experimentType = nameSpace['experimentType'];

    List disabled_experiment = ['habituation'];
    List enabled_window = ['cagemate', 'juvenile', 'stranger'];

    List<String> animalID = _animalID.map((item) {
      return item.toString();
    }).toList();
    List<String> stimAnimalID = _stimAnimalID.map((item) {
      return item.toString();
    }).toList();
    List<String> animalType = _animalType.map((item) {
      return item.toString();
    }).toList();
    List<String> windows = _windows.map((item) {
      return item.toString();
    }).toList();
    List<String> experimentType = _experimentType.map((item) {
      return item.toString();
    }).toList();
    bool _record = false;

    await showDialog(
        context: context,
        builder: (BuildContext context) {
          ThemeData theme = Theme.of(context);
          TextStyle buttonStyle = TextStyle(color: theme.buttonColor);
          return AlertDialog(
            content: Container(
              width: 600.0,
              height: 430.0,
              child: Column(children: [
                Text(
                  'Filename and Datajoint Entry',
                  style: TextStyle(color: Colors.lightBlue),
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textAnimal,
                        style: TextStyle(color: Colors.lightBlue),
                        decoration: InputDecoration(
                            labelText: 'Animal ID',
                            labelStyle: TextStyle(color: Colors.lightBlue),
                            hintText: 'e.g., 2045',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5.0),
                                borderSide: BorderSide(
                                  color: Colors.lightBlue,
                                  style: BorderStyle.solid,
                                )),
                            suffixIcon: PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              onSelected: (String value) {
                                _textAnimal.text = value;
                              },
                              itemBuilder: (BuildContext context) {
                                return animalID
                                    .map<PopupMenuItem<String>>((String value) {
                                  return new PopupMenuItem(
                                    child: new Text(value),
                                    value: value,
                                  );
                                }).toList();
                              },
                            )),
                      ),
                    ),
                    SizedBox(width: 100.0),
                    Expanded(
                        child: TextField(
                      controller: _textUserName,
                      style: TextStyle(color: Colors.lightBlue),
                      decoration: InputDecoration(
                          labelText: 'User Name',
                          labelStyle: TextStyle(color: Colors.lightBlue),
                          hintText: 'Devon',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                color: Colors.amber,
                                style: BorderStyle.solid,
                              ))),
                    ))
                  ],
                ),
                SizedBox(height: 10.0),
                TextField(
                  controller: _textAnimalType,
                  style: TextStyle(color: Colors.lightBlue),
                  decoration: InputDecoration(
                      labelText: 'Test Animal Type',
                      labelStyle: TextStyle(color: Colors.lightBlue),
                      hintText: 'e.g., female/dominant male/unknown male',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.amber,
                            style: BorderStyle.solid,
                          )),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (String value) {
                          _textAnimalType.text = value;
                        },
                        itemBuilder: (BuildContext context) {
                          return animalType
                              .map<PopupMenuItem<String>>((String value) {
                            return new PopupMenuItem(
                              child: new Text(value),
                              value: value,
                            );
                          }).toList();
                        },
                      )),
                ),
                SizedBox(height: 10.0),
                TextField(
                  controller: _textExperimentType,
                  style: TextStyle(color: Colors.lightBlue),
                  decoration: InputDecoration(
                      labelText: 'Experiment Type',
                      labelStyle: TextStyle(color: Colors.lightBlue),
                      hintText: 'e.g."cagemate_2_strangers" ',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.amber,
                            style: BorderStyle.solid,
                          )),
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (String value) {
                          _textExperimentType.text = value;
                          if (disabled_experiment.contains(value)) {
                            _allow_windows = false;
                          } else {
                            _allow_windows = true;
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return experimentType
                              .map<PopupMenuItem<String>>((String value) {
                            return new PopupMenuItem(
                              child: new Text(value),
                              value: value,
                            );
                          }).toList();
                        },
                      )),
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            enabled: _allow_windows,
                            controller: _textWindowA,
                            style: TextStyle(color: Colors.lightBlue),
                            decoration: InputDecoration(
                                labelText: 'WindowA',
                                labelStyle: TextStyle(color: Colors.lightBlue),
                                hintText: '',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(
                                      color: Colors.amber,
                                      style: BorderStyle.solid,
                                    )),
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String value) {
                                    _textWindowA.text = value;
                                    if (enabled_window.contains(value)) {
                                      _allow_windowA_DJID = true;
                                    } else {
                                      _allow_windowA_DJID = false;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return windows.map<PopupMenuItem<String>>(
                                        (String value) {
                                      return new PopupMenuItem(
                                        child: new Text(value),
                                        value: value,
                                      );
                                    }).toList();
                                  },
                                )))),
                    SizedBox(width: 5.0),
                    Expanded(
                        child: TextField(
                            enabled: _allow_windows,
                            controller: _textWindowB,
                            style: TextStyle(color: Colors.lightBlue),
                            decoration: InputDecoration(
                                labelText: 'Window B',
                                labelStyle: TextStyle(color: Colors.lightBlue),
                                hintText: '',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(
                                      color: Colors.amber,
                                      style: BorderStyle.solid,
                                    )),
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String value) {
                                    _textWindowB.text = value;
                                    if (enabled_window.contains(value)) {
                                      _allow_windowB_DJID = true;
                                    } else {
                                      _allow_windowB_DJID = false;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return windows.map<PopupMenuItem<String>>(
                                        (String value) {
                                      return new PopupMenuItem(
                                        child: new Text(value),
                                        value: value,
                                      );
                                    }).toList();
                                  },
                                )))),
                    SizedBox(width: 5.0),
                    Expanded(
                        child: TextField(
                            enabled: _allow_windows,
                            controller: _textWindowC,
                            style: TextStyle(color: Colors.lightBlue),
                            decoration: InputDecoration(
                                labelText: 'Window C',
                                labelStyle: TextStyle(color: Colors.lightBlue),
                                hintText: '',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(
                                      color: Colors.amber,
                                      style: BorderStyle.solid,
                                    )),
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String value) {
                                    _textWindowC.text = value;
                                    if (enabled_window.contains(value)) {
                                      _allow_windowC_DJID = true;
                                    } else {
                                      _allow_windowC_DJID = false;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return windows.map<PopupMenuItem<String>>(
                                        (String value) {
                                      return new PopupMenuItem(
                                        child: new Text(value),
                                        value: value,
                                      );
                                    }).toList();
                                  },
                                )))),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            enabled: _allow_windowA_DJID,
                            controller: _textWindowA_DJID,
                            style: TextStyle(color: Colors.lightBlue),
                            decoration: InputDecoration(
                                labelText: 'DJID',
                                labelStyle: TextStyle(color: Colors.lightBlue),
                                hintText: '',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(
                                      color: Colors.amber,
                                      style: BorderStyle.solid,
                                    )),
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String value) {
                                    _textWindowA_DJID.text = value;
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return stimAnimalID
                                        .map<PopupMenuItem<String>>(
                                            (String value) {
                                      return new PopupMenuItem(
                                        child: new Text(value),
                                        value: value,
                                      );
                                    }).toList();
                                  },
                                )))),
                    SizedBox(width: 5.0),
                    Expanded(
                        child: TextField(
                            enabled: _allow_windowB_DJID,
                            controller: _textWindowB_DJID,
                            style: TextStyle(color: Colors.lightBlue),
                            decoration: InputDecoration(
                                labelText: 'DJID',
                                labelStyle: TextStyle(color: Colors.lightBlue),
                                hintText: '',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(
                                      color: Colors.amber,
                                      style: BorderStyle.solid,
                                    )),
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String value) {
                                    _textWindowB_DJID.text = value;
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return stimAnimalID
                                        .map<PopupMenuItem<String>>(
                                            (String value) {
                                      return new PopupMenuItem(
                                        child: new Text(value),
                                        value: value,
                                      );
                                    }).toList();
                                  },
                                )))),
                    SizedBox(width: 5.0),
                    Expanded(
                        child: TextField(
                            enabled: _allow_windowC_DJID,
                            controller: _textWindowC_DJID,
                            style: TextStyle(color: Colors.lightBlue),
                            decoration: InputDecoration(
                                labelText: 'DJID',
                                labelStyle: TextStyle(color: Colors.lightBlue),
                                hintText: '',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5.0),
                                    borderSide: BorderSide(
                                      color: Colors.amber,
                                      style: BorderStyle.solid,
                                    )),
                                suffixIcon: PopupMenuButton<String>(
                                  icon: const Icon(Icons.arrow_drop_down),
                                  onSelected: (String value) {
                                    _textWindowC_DJID.text = value;
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return stimAnimalID
                                        .map<PopupMenuItem<String>>(
                                            (String value) {
                                      return new PopupMenuItem(
                                        child: new Text(value),
                                        value: value,
                                      );
                                    }).toList();
                                  },
                                )))),
                  ],
                ),
                TextField(
                  controller: _textNotes,
                  style: TextStyle(color: Colors.lightBlue),
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Colors.lightBlue),
                    hintText: 'no need to put window information ~',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                        borderSide: BorderSide(
                          color: Colors.amber,
                          style: BorderStyle.solid,
                        )),
                  ),
                )
              ]),
            ),
            actions: [
              TextButton(
                  child: Text('CANCEL', style: buttonStyle),
                  onPressed: () {
                    // TODO: what's the use for the following?
                    _textAnimal.text = oldTextAnimal;
                    _textAnimalType.text = oldTextAnimalType;
                    _textExperimentType.text = oldTextExperimentType;
                    _textWindowA.text = oldTextWindowA;
                    _textWindowB.text = oldTextWindowB;
                    _textWindowC.text = oldTextWindowC;
                    _textWindowA_DJID.text = oldTextWindowA_DJID;
                    _textWindowB_DJID.text = oldTextWindowB_DJID;
                    _textWindowC_DJID.text = oldTextWindowC_DJID;
                    _textUserName.text = oldTextUserName;
                    Navigator.pop(context);
                  }),
              TextButton(
                  child: Text(doRecording ? 'RECORD' : 'APPLY',
                      style: buttonStyle),
                  onPressed: () {
                    if (doRecording) {
                      List<TextEditingController> _allText = [
                        _textAnimal,
                        _textAnimalType,
                        _textExperimentType,
                        _textWindowA,
                        _textWindowA_DJID,
                        _textWindowB,
                        _textWindowB_DJID,
                        _textWindowC,
                        _textWindowC_DJID,
                        _textUserName,
                        _textNotes
                      ];
                      String text = _mergeText(_allText);
                      _record = true;
                      //String alertText='testing';
                      //_showAlert(context, alertText);
                      widget.recordCallback(text);
                    }
                    Navigator.pop(context);
                  }),
            ],
            elevation: 25.0,
          );
        });
    // if (_record){
    //     // _showAlert(context);}
  }

  void _showAlert(BuildContext context) async {
    //_rigStatus['datajoint_success'].current ?
    //_rigStatus['dj_error_msg'].current
    //_rigStatus['dj_event_id'].current //the event id for this session?

    String alertText =
        _rigStatus['alert'].current; //could get other rig statuses
    debugPrint('got alert: $alertText');
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          ThemeData theme = Theme.of(context);
          TextStyle buttonStyle = TextStyle(color: theme.buttonColor);
          return AlertDialog(
            content: Container(
                width: 300.0,
                height: 150.0,
                child: Center(
                    child: Text(alertText,
                        style: TextStyle(
                            color: Colors.lightBlue, fontSize: 10.0)))),
            actions: [
              TextButton(
                child: Text('OK', style: buttonStyle),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    //if (_showPopup) _showAlert(context);
    if (_showPopup) Future.delayed(Duration.zero, () => _showAlert(context));

    void Function(dynamic) callback = (arg) => debugPrint('registered tap');

    Widget recordButton;
    Color inactive = Theme.of(context).unselectedWidgetColor;
    Color active = Theme.of(context).buttonColor;

    if (_rigStatus['recording'].current) {
      //List<TextEditingController> _allText=[_textAnimal,_textAnimalType,_textWindowA,_textWindowB,_textWindowC];
      //String text = _mergeText(_allText);
      // don't know what's the point ot this text
      recordButton = _buildButtonColumn(widget.width / 4, true, context,
          Icons.pause, 'PAUSE', (data) => widget.recordCallback(''));
    } else {
      recordButton = _buildButtonColumn(
          widget.width / 4,
          true,
          context, //TODO: assumes we can always stop recording...
          Icons.circle,
          'RECORD',
          (data) => _showDialog(context, true));
    }

    bool isCalibrating =
        _rigStatus['calibration'].current['is calibrating'].current;

    bool isAnalyzing = _rigStatus['analyzing'].current;
    bool isLEDing = _rigStatus['LED'].current;

    Widget calibrationButton = _buildButtonColumn(
        widget.width / 4,
        _rigStatus['calibration'].mutable,
        context,
        isCalibrating ? Icons.not_interested : Icons.build,
        isCalibrating ? 'STOP' : 'CALIBRATE',
        isCalibrating
            ? (arg) => _stopCalibration()
            : (arg) => _toggleCalibrate());

    Widget processButton = _buildButtonColumn(
        widget.width / 4,
        true,
        context,
        isAnalyzing ? Icons.near_me_outlined : Icons.near_me,
        isAnalyzing ? 'DLC on' : 'DLC off',
        (data) => _toggleAnalyze());

    Widget ledButton = _buildButtonColumn(
        widget.width / 4,
        true,
        context,
        isLEDing ? Icons.light_mode : Icons.light_mode_outlined,
        isLEDing ? 'LED on' : 'LED off',
        (data) => _toggleLED());

    Widget logsButton = _buildButtonColumn(widget.width / 4, true, context,
        Icons.info, 'LOGS', (arg) => showMessageLog(context));

    Widget postButton = _buildButtonColumn(
        widget.width / 4, true, context, Icons.computer, 'POST', callback);

    List<Widget> children;
    children = [
      recordButton,
      calibrationButton,
      processButton,
      ledButton,
    ];

    Widget initButton;
    if (_rigStatus['initialization'].current == 'initialized') {
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

    List<int> camList =
        Iterable<int>.generate(_rigStatus['camera count'].current).toList();

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
            ),
            postButton,
            logsButton,
            SizedBox(
                width: widget.width,
                child: Text(
                  _lastMessage.value,
                  style: TextStyle(color: active),
                )),
          ])),
      SizeTransition(
        sizeFactor: _animationCalib,
        axis: Axis.vertical,

        child: SizedBox(
            height: 300,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              SizedBox(width: 10),
              Container(
                  // color: Colors.red,
                  width: 500,
                  child: _CalibrationBox(
                      'Intrinsic Calibration',
                      'Determines the undistortion parameters of each camera by collecting images of a calibration board.',
                      camList,
                      CalibrationType.intrinsic,
                      _doCalibration)),
              SizedBox(width: 10),
              Container(
                  // color: Colors.red,
                  width: 500,
                  child: _CalibrationBox(
                      'Top Camera Alignment',
                      'Aligns the top camera to the arena by detecting the location of the fixed calibration markers.',
                      [0],
                      CalibrationType.alignment,
                      _doCalibration)),
              SizedBox(width: 10),
              Container(
                  // color: Colors.red,
                  width: 500,
                  child: _CalibrationBox(
                      'Side Camera Alignment',
                      'Aligns a side camera to the top camera by detecting the location of a calibration board visible to both.',
                      camList.sublist(1),
                      CalibrationType.extrinsic,
                      _doCalibration)),
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

class CustomPopup extends StatefulWidget {
  CustomPopup({
    @required this.show,
    @required this.items,
    @required this.builderFunction,
  });

  final bool show;
  final List<dynamic> items;
  final Function(BuildContext context, dynamic item) builderFunction;

  @override
  _CustomPopupState createState() => _CustomPopupState();
}

class _CustomPopupState extends State<CustomPopup> {
  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !widget.show,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: widget.show ? MediaQuery.of(context).size.height / 3 : 0,
        width: MediaQuery.of(context).size.width / 3,
        child: Card(
          elevation: 3,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                Widget item = widget.builderFunction(
                  context,
                  widget.items[index],
                );
                return item;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CalibrationBox extends StatelessWidget {
  _CalibrationBox(this.title, this.subtitle, this.cameraIndex,
      this.calibrationType, this.callback);
  final String title;
  final String subtitle;
  final List<int> cameraIndex;
  final CalibrationType calibrationType;
  final void Function(int, CalibrationType) callback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title,
            style:
                TextStyle(fontSize: 16, color: Theme.of(context).buttonColor)),
        Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(subtitle,
                style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).unselectedWidgetColor))),
        Expanded(
          child: ListView.builder(
              // shrinkWrap: true,
              // physics: ScrollPhysics(),
              itemCount: cameraIndex.length,
              itemBuilder: (context, ind) {
                RigStatusMap camera = _rigStatus['camera ${ind}'].current;
                DateTime lastCalibrated = DateTime.fromMillisecondsSinceEpoch(
                    camera['last ${calibrationType.toString().split(".").last}']
                            .current *
                        1000);
                return ListTile(
                  leading: Icon(Icons.videocam,
                      color: Theme.of(context).primaryColor),
                  title: Text('Camera ${cameraIndex[ind]}',
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                  subtitle: Text(
                      'Last calibrated: ${lastCalibrated.year}-${lastCalibrated.month}-${lastCalibrated.day}',
                      style: TextStyle(
                          color: Theme.of(context).unselectedWidgetColor)),
                  // trailing: Icon(Icons.play_arrow),
                  trailing: _buildButtonColumn(
                      150,
                      true,
                      context,
                      Icons.play_arrow,
                      'CALIBRATE',
                      (arg) => this.callback(ind, calibrationType)),
                );
              }),
        )
      ],
    );
  }
}

enum CalibrationType { intrinsic, alignment, extrinsic }

void main() async {
  RigStatusMap.live();
  await Future.delayed(Duration(seconds: 1));

  runApp(MaterialApp(
      home: Scaffold(
          body: SizedBox(
              width: 1000,
              height: 300,
              child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.yellow),
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    SizedBox(width: 10),
                    Container(
                        color: Colors.red,
                        width: 500,
                        child: _CalibrationBox(
                            'Intrinsic Calibration',
                            'Determines the undistortion parameters of each camera by collecting images of a calibration board.',
                            [0, 1, 2, 3],
                            CalibrationType.intrinsic,
                            (ind, type) =>
                                print('setting camera $ind to $type'))),
                    SizedBox(width: 10),
                    Container(
                        color: Colors.red,
                        width: 500,
                        child: _CalibrationBox(
                            'Top Camera Alignment',
                            'Aligns the top camera to the arena by detecting the location of the fixed calibration markers.',
                            [0],
                            CalibrationType.alignment,
                            (ind, type) =>
                                print('setting camera $ind to $type'))),
                    SizedBox(width: 10),
                    Container(
                        color: Colors.red,
                        width: 500,
                        child: _CalibrationBox(
                            'Side Camera Alignment',
                            'Aligns a side camera to the top camera by detecting the location of a mobile calibration board visible to both cameras.',
                            [1, 2, 3],
                            CalibrationType.extrinsic,
                            (ind, type) =>
                                print('setting camera $ind to $type'))),
                  ]))))));
}
