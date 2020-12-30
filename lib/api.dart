import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String hostname = 'localhost:3001';

enum RigStatusCategory { Video, Audio, Acquisition, Processing }

class Allowable<T> {
  final bool Function(T) allowed;
  final String Function() print;
  Allowable(this.allowed, this.print);

  bool call(T) {
    return this.allowed(T);
  }

  String toString() {
    return this.print();
  }
}

class RigStatusValue<T> {
  final Allowable<T> allowed;
  final RigStatusCategory category;
  T current;

  RigStatusValue(this.allowed, this.category, this.current)
      : assert(allowed(current));

  RigStatusValue.copy(RigStatusValue value)
      : allowed = value.allowed,
        category = value.category,
        current = value.current;

  // RigStatusValue operator +(dynamic newValues) {
  //   if (newValues is Set<String>) {
  //     return RigStatusValue(values.union(newValues), category,
  //         current: current);
  //   } else if (newValues is RigStatusValue) {
  //     assert(newValues.category == category);
  //     return RigStatusValue(values.union(newValues.values), category,
  //         current: newValues.current);
  //   } else {
  //     throw 'Unable to add rig status values';
  //   }
  // }

  void set(T value) {
    assert(this.allowed(value));
    current = value;
  }

  // void insert(RigStatusValue newValues) {
  //   assert(newValues.category == category);
  //   values = values.union(newValues.values);
  //   if (newValues.current != null) {
  //     current = newValues.current;
  //   }
  // }

  // Map toJSON() => {
  //       'allowedValues': this.values,
  //       'category': this.category,
  //       'status': this.current,
  //     };
}

abstract class RigStatusValues extends Map<String, RigStatusValue> {
  // bool _isReady;

  factory RigStatusValues() {
    RigStatusValues rigStatusValues =
        <String, RigStatusValue>{} as RigStatusValues;

    // rigStatusValues._isReady = true;
    return rigStatusValues;
  }

  factory RigStatusValues.fromRig() {
    RigStatusValues rigStatusValues =
        <String, RigStatusValue>{} as RigStatusValues;

    // rigStatusValues._isReady = false;
    rigStatusValues._get();
    return rigStatusValues;
  }

  void _get() async {
    //each json result has following form:
    // {
    //// typeName1: {'allowedValues': [status1a, status1b, ...], 'category': RigStatusCategory, 'current': status1b},
    //// typeName2: ...
    //// ...
    // }
    final Map<String, dynamic> json = await Api._get('allowed');
    json.forEach((status, value) {
      //get the type of this statusValue
      // for now just use strings

      Set<String> thisSet = Set<String>.from(value['allowedValues']);
      Allowable<String> thisAllowable = Allowable<String>(
          (String value) => thisSet.contains(value), () => thisSet.toString());

      this[status] = RigStatusValue<String>(
          thisAllowable, value['category'], value['current']);
    });
    // this._isReady = true;
  }

  // static RigStatus _handleJSON(Map<String, dynamic> json) {
  //   //each json result has following form:
  //   // {
  //   //// [typeName1]: status1a,
  //   //// [typeName2]: status2c,
  //   //// ...
  //   // }

  //   json.forEach((status, current) {
  //     _statuses[status].current = current;
  //   });
  //   return RigStatus();
  // }
}

abstract class RigStatus extends Map<String, String> {
  static final RigStatusValues _statuses = RigStatusValues.fromRig();
  factory RigStatus() {
    return _statuses.map<String, String>((String type, RigStatusValue value) {
      return RigStatusItem(type, value.current);
    }) as RigStatus;
  }

  // factory RigStatus._empty() {
  //   return <String, String>{} as RigStatus;
  // }

  static Future<RigStatus> apply(dynamic status) {
    if ((status is RigStatus) || status is RigStatusItem) {
      return status._post();
    } else {
      throw 'Could not update rig status';
    }
  }

  // static void _modify(String status, dynamic value,
  //     {String current, RigStatusCategory category}) {
  //   if (_statuses.containsKey(status)) {
  //     if (value is RigStatusValue) {
  //       assert((current == null) && (category == null));
  //       _statuses[status].insert(value);
  //     } else if (value is Set<String>) {
  //       assert(category != null);
  //       _statuses[status]
  //           .insert(RigStatusValue(value, category, current: current));
  //     } else {
  //       throw 'Could not modify rig status values';
  //     }
  //   } else {
  //     if (value is RigStatusValue) {
  //       assert((current == null) && (category == null));
  //       _statuses[status] = value;
  //     } else if (value is Set<String>) {
  //       assert(category != null);
  //       _statuses[status] = RigStatusValue(value, category, current: current);
  //     } else {
  //       throw 'Could not modify rig status values';
  //     }
  //   }
  // }

  static RigStatusValue getAllowed(String status) {
    if (_statuses.containsKey(status)) {
      return _statuses[status];
    } else {
      return null;
    }
  }

  Future<RigStatus> _post() async {
    return RigStatus._handleJSON(await Api._post(this));
  }

  static Future<RigStatus> get() async {
    return RigStatus._handleJSON(await Api._get('current'));
  }

  static RigStatus _handleJSON(Map<String, dynamic> json) {
    //each json result has following form:
    // {
    //// [typeName1]: status1a,
    //// [typeName2]: status2c,
    //// ...
    // }

    json.forEach((status, current) {
      _statuses[status].current = current;
    });
    return RigStatus();
  }
}

class RigStatusItem implements MapEntry<String, String> {
  final String key;
  String value;
  get type => this.key;
  get category => RigStatus._statuses[key].category;
  String toString() => this.key;

  RigStatusItem(this.key, this.value)
      : assert(RigStatus._statuses.containsKey(key) &&
            RigStatus._statuses[key].allowed(value));

  Future<RigStatus> _post() async {
    return RigStatus._handleJSON(await Api._post(this));
  }

  // final String key;
  // // static final Api router = Api();
  // static final RigStatusValues _types = RigStatusValues();
  // get type => this.key;
  // get value => _types[key].current;
  // set value(String status) => _types[key].set(status);

  // get values => _types[key];
  // set values(dynamic values) {
  //   if (values is RigStatusValue) {
  //     //preferred since it sets the current status
  //     _types[key] = RigStatusValue.copy(values);
  //   } else if (values is Set<String>) {
  //     _types[key] = RigStatusValue(values);
  //   } else {
  //     throw 'Unable to set rig status values.';
  //   }
  // }

  // RigStatus(this.key, {dynamic values, String current, bool clear = false}) {
  //   assert((clear == false) || (current == null));
  //   if (values is RigStatusValue) {
  //     assert(current == null);
  //     if (_types.containsKey(key) && clear == false) {
  //       _types[key] += values;
  //     } else {
  //       _types[key] = RigStatusValue.copy(values);
  //     }
  //   } else if (values is Set<String>) {
  //     if (_types.containsKey(key) && clear == false) {
  //       _types[key] += RigStatusValue(values, current: current);
  //     } else {
  //       _types[key] = RigStatusValue(values, current: current);
  //     }
  //   } else if (values == null) {
  //     if (!_types.containsKey(key) || clear == false) {
  //       _types[key] = RigStatusValue(Set<String>());
  //     }
  //   } else {
  //     throw 'Unable to set rig status values.';
  //   }
  // }

  // // RigStatus._fromJSON(Map<String, dynamic> json)
  // //     : this(json['type'],
  // //           values: json['allowedValues'],
  // //           current: json['status'],
  // //           clear: true);
  // String toString() => this.key;

  // Future<RigStatuses> post() async {
  //   return RigStatuses._handleJSON(await Api._post(this));
  // }

  // Future<RigStatus> get() async {
  //   return RigStatuses._handleJSON(await Api._get(this)).entries.first;
  // }

  // Map toJson() => {
  //       this.key: this.values
  //     };
}

class Api {
  // const static String hostname = hostname;

  static Future<Map<String, dynamic>> _post(dynamic status) async {
    final response = await http.post('$hostname/api',
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(status));

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('post request failed');
    }
  }

  static Future<Map<String, dynamic>> _get(dynamic status) async {
    final response = await http.get('$hostname/api/${status.toString()}');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('get request failed');
    }
  }
}

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

List<Setting> settings = [
  Setting('Acquisition', ['nCameras', 'nMicrophones'], Icons.work),
  Setting(
      'Video', ['Frame Capture Rate', 'Frame Display Rate'], Icons.videocam),
  Setting('Audio', ['Sensitivity', 'Gain'], Icons.mic),
  Setting('Post-Processing', ['waitTime', 'nWorkers'], Icons.computer)
];
