// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'dart:typed_data';

// import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'dart:convert';
import 'dart:async';
import 'dart:collection';
// import 'dart:ui';
// import 'package:flutter/material.dart';

const String socketHostname = 'http://localhost:5001';
const String mainHostname = 'http://localhost:5000';

// enum RigStatusCategory { Video, Audio, Acquisition, Processing }

class Range<T> {
  T min;
  T max;
  Range(this.min, this.max);
}

class Allowable<T> {
  final bool Function(T) allowed;
  final String Function() print;
  final Range<T> range;
  final Set<T> values;

  Allowable(this.allowed, this.print, {this.range, this.values}) {
    if (!((range == null) ^ (values == null))) {
      throw 'Must define exactly 1 of range or values set.';
    }
  }

  bool call(dynamic value) {
    if (!(value is T)) return false;
    return this.allowed(value);
  }

  String toString() {
    return this.print();
  }
}

class RigStatusValue<T> {
  final Allowable<T> allowed;
  final String category;
  T current;
  bool mutable;
  String toString() =>
      '${mutable ? "Mutable" : "Immutable"} rig status value: {Current value: $current, Allowed values: $allowed, Category: $category}';

  RigStatusValue(this.allowed, this.category, this.current, this.mutable) {
    if (!allowed(current)) {
      throw 'Can\'t create status type with invalid current value';
    }
  }

  RigStatusValue.copy(RigStatusValue value)
      : allowed = value.allowed,
        category = value.category,
        current = value.current,
        mutable = value.mutable;

  void set(dynamic value) {
    if (this.mutable && this.allowed(value)) {
      current = value;
    } else {
      throw 'Cannot change rig status value.';
    }
  }

  // void
}

class RigStatusValues extends UnmodifiableMapBase<String, RigStatusValue> {
  Map<String, RigStatusValue> _map = Map<String, RigStatusValue>();
  get keys => _map.keys;
  RigStatusValue operator [](Object key) => _map[key];
  void operator []=(Object key, RigStatusValue value) => _map[key] = value;

  // bool _isDynamic = false;
  RigStatusValues();
}

class DynamicRigStatusValues extends RigStatusValues {
  // bool initialized = false;

  static final StreamController<RigStatus> _changeController =
      StreamController<RigStatus>.broadcast();
  static Stream<RigStatus> get onChange => _changeController.stream;
  static Completer<void> initialized = Completer();
  static DynamicRigStatusValues _instance;

  // static Map<String, RigStatusValue> __map = RigStatusValues()._map;

  @override
  void operator []=(Object key, RigStatusValue value) =>
      throw 'Can\'t set dynamic RigStatusValue.';

  factory DynamicRigStatusValues() {
    if (_instance == null) {
      _instance = DynamicRigStatusValues._singleton();
    }
    return _instance;
  }

  DynamicRigStatusValues._singleton() : super() {
    _get();
    Api._socket.on('broadcast', (data) => _update(data));
  }

  static void _get() async {
    //each json result has following form:
    // {
    //// typeName1: {'allowedValues': [status1a, status1b, ...], 'category': RigStatusCategory, 'current': status1b},
    //// typeName2: ...
    //// ...
    // }
    final Map<String, dynamic> json = await Api._get('allowed');
    RigStatus newStatus = RigStatus.empty();

    json.forEach((status, value) {
      Allowable thisAllowable;

      if (value['current'] is String) {
        Set<String> thisSet = Set<String>.from(value['allowedValues']);
        if (thisSet.isEmpty) {
          thisAllowable = Allowable<String>(
              (String value) => true, () => 'Any string',
              values: Set.from(['']));
        } else {
          thisAllowable = Allowable<String>(
              (String value) => thisSet.contains(value),
              () => thisSet.toString(),
              values: thisSet);
        }
        _instance._map[status] = RigStatusValue<String>(thisAllowable,
            value['category'], value['current'], value['mutable']);
      } else if (value['current'] is bool) {
        thisAllowable = Allowable<bool>(
            (bool value) => value is bool, () => '{True, False}',
            values: Set.from([true, false]));

        _instance._map[status] = RigStatusValue<bool>(thisAllowable,
            value['category'], value['current'], value['mutable']);
      } else if (value['current'] is num) {
        if (value['allowedValues'] is List) {
          Set<num> thisSet = Set<num>.from(value['allowedValues']);
          thisAllowable = Allowable<num>(
              (num value) => thisSet.contains(value), () => thisSet.toString(),
              values: thisSet);
        } else if (value['allowedValues'] is Map &&
            value['allowedValues'].containsKey('min') &&
            value['allowedValues'].containsKey('max')) {
          num thisMin = value['allowedValues']['min'];
          num thisMax = value['allowedValues']['max'];

          thisAllowable = Allowable<num>(
              (num value) => (thisMin <= value) && (value <= thisMax),
              () => '$thisMin to $thisMax',
              range: Range<num>(thisMin, thisMax));
        } else {
          throw 'Incomprehensible allowed status types';
        }

        _instance._map[status] = RigStatusValue<num>(thisAllowable,
            value['category'], value['current'], value['mutable']);
      } else {
        throw 'Incomprehensible status type';
      }
      newStatus[status] = value['current'];
    });
    _changeController.add(newStatus);
    initialized.complete();
  }

  static void _update(Map<String, dynamic> update) {
    //each json result has following form:
    // {
    //// [typeName1]: {'current':[status1a], 'mutable':[isMutable1a]},
    //// [typeName2]: {'current':[status2c], 'mutable':[isMutable2c]},
    //// ...

    RigStatus newRigStatus = RigStatus.empty();
    if (!initialized.isCompleted) return;
    update.forEach((status, value) {
      newRigStatus[status] = value['current'];
      _instance._map[status].current = value['current'];
      _instance._map[status].mutable = value['mutable'];
    });
    _changeController.add(newRigStatus);
  }
}

class RigStatus extends MapBase<String, dynamic> {
  Map<String, dynamic> _map;
  // Iterable<RigStatusItem> get entries => Iterable.castFrom(_map.entries);

  String toString() {
    return this._map.toString();
  }

  get keys => _map.keys;
  RigStatusItem operator [](Object key) => RigStatusItem(key, _map[key]);
  void operator []=(Object type, dynamic value) {
    if ((type is String) &&
        _statuses.containsKey(type) &&
        _statuses[type].allowed(value)) {
      _map[type] = value;
      // this._changeController.add(true);//but only needed if dynamic??
    } else {
      throw 'Couldn\'t set RigStatus';
    }
  }

  dynamic remove(Object key) => _map.remove(key);

  void clear() => _map.clear();

  bool operator ==(Object status) {
    if (!(status is RigStatus)) return false;
    return this.isSameStatus(status);
  }

  bool isSameStatus(RigStatus status) {
    if (status.length != this.length) return false;
    return !status.entries.any((statusItem) {
      return !this.containsKey(statusItem.key) ||
          (this[statusItem.key] != statusItem.value);
    });
  }

  int get hashCode => keys.hashCode ^ values.hashCode;

  static final DynamicRigStatusValues _statuses = DynamicRigStatusValues();
  // bool _isDynamic = false;
  static final Completer initialized = DynamicRigStatusValues.initialized;

  RigStatus.current()
      : this._map =
            _statuses.map<String, dynamic>((String type, RigStatusValue value) {
          return RigStatusItem(type, value.current);
        });

  RigStatus.empty() : this._map = Map<String, dynamic>();

  RigStatus.fromJSON(Map<String, dynamic> json) : this._map = json;

  Map<String, dynamic> toJSON() => _map;

  static Future<RigStatus> apply(dynamic status) {
    //todo: at some point we should remove any applied changes that match the current state?
    if (((status is RigStatus) && !(status is DynamicRigStatus)) ||
        status is RigStatusItem) {
      return status._post();
    } else {
      throw 'Could not update rig status';
    }
  }

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

  static Future<RigStatus> _get() async {
    return RigStatus._handleJSON(await Api._get('current'));
  }

  static RigStatus _handleJSON(Map<String, dynamic> json) {
    //each json result has following form:
    // {
    //// [typeName1]: {'current':[status1a], 'mutable':[isMutable1a]},
    //// [typeName2]: {'current':[status2c], 'mutable':[isMutable2c]},
    //// ...
    // }
    DynamicRigStatusValues._update(json);
    return RigStatus.current();
  }
}

class DynamicRigStatus extends RigStatus {
  static final StreamController<void> _changeController =
      StreamController<void>.broadcast();
  static Stream<void> get onChange => _changeController.stream;
  static DynamicRigStatus _instance;

  @override
  void operator []=(Object key, dynamic value) =>
      throw 'Couldn\'t set RigStatus';

  @override
  dynamic remove(Object key) =>
      throw 'Can\'t remove values from dynamic rig status';

  @override
  void clear() => throw 'Can\'t remove values from dynamic rig status';

  factory DynamicRigStatus() {
    if (_instance == null) {
      _instance = DynamicRigStatus._singleton();
    }
    return _instance;
  }

  DynamicRigStatus._singleton() : super.current() {
    DynamicRigStatusValues.onChange.listen(_handleUpdates);
  }

  static void _handleUpdates(RigStatus updates) {
    updates.forEach((key, value) {
      _instance._map[key] = value.value;
    });
    // _instance._map.addAll(updates);
    _changeController.add(null);
  }
}

class RigStatusItem implements MapEntry<String, dynamic> {
  final String key;
  dynamic value;
  get type => this.key;
  set type(dynamic value) => throw 'RigStatusItem keys may not be changed';
  // set key(dynamic value) => throw 'RigStatusItem keys may not be changed';
  String get category => RigStatus._statuses[key].category;
  bool get mutable => RigStatus._statuses[key].mutable;
  String toString() => this.key;

  RigStatusItem(this.key, value) {
    if (RigStatus._statuses.containsKey(this.key) &&
        RigStatus._statuses[this.key].allowed(value)) {
      this.value = value;
    } else {
      throw 'Invalid key-value pair';
    }
  }
  Future<RigStatus> _post() async {
    return RigStatus._handleJSON(await Api._post(this));
  }
}

class Api {
  static final IO.Socket _socket = IO.io(socketHostname, <String, dynamic>{
    'transports': ['websocket']
  });

  static final StreamController<String> _changeController =
      StreamController<String>.broadcast();
  static bool _hasSetupMessage = false;

  static Stream<String> get onMessage {
    if (!Api._hasSetupMessage) {
      Api._socket
          .on('message', (message) => Api._changeController.add(message));
      Api._hasSetupMessage = true;
    }
    return _changeController.stream;
  }

  static Future<Map<String, dynamic>> _post(dynamic status) async {
    Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    _socket.emitWithAck('post', status.toJSON(), ack: (data) {
      c.complete(data);
    });
    return c.future;
  }

  static Future<Map<String, dynamic>> _get(dynamic status) async {
    Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    _socket.emitWithAck('get', status.toString(), ack: (data) {
      c.complete(data);
    });
    return c.future;
  }

  static Future<http.StreamedResponse> video(int id) async {
    http.MultipartRequest request =
        new http.MultipartRequest('GET', Uri.parse('$mainHostname/video/$id'));
    return request.send();
  }
}

void main() async {
  RigStatus firstStatus = RigStatus.current();
  // RigStatus dynamicStatus = DynamicRigStatus();
  // print('Static rig status: ');
  // print(firstStatus);
  // print('Dynamic rig status: ');
  // print(dynamicStatus);

  // print('Waiting 1 second...');
  await Future.delayed(Duration(seconds: 1));

  // print('Old static rig status: ');
  // print(firstStatus);
  // print('Old dynamic rig status: ');
  // print(dynamicStatus);
  // RigStatus secondStatus = RigStatus();
  // print('New static rig status: ');
  // print(secondStatus);

  // // print(RigStatus.getAllowed('recording'));
  // firstStatus['recording'] = !dynamicStatus['recording'];
  // print('Trying to set status as: ');
  // print(firstStatus);

  // Future<RigStatus> futureStatus = RigStatus.apply(firstStatus);
  // print('Future: ');
  // print(futureStatus);

  // print('Waiting for future to complete');
  // RigStatus resolvedStatus = await futureStatus;
  // print('Testing dynamic status vs new status: ');
  // print(dynamicStatus == resolvedStatus);
  // print('Old dynamic rig status: ');
  // print(dynamicStatus);
  // print('Resolved future rig status: ');
  // print(resolvedStatus);

  // print('Waiting 1 second...');
  // await Future.delayed(Duration(seconds: 1));
  // print('Old dynamic rig status: ');
  // print(dynamicStatus);
  // print('Re-testing dynamic status vs new status: ');
  // print(dynamicStatus == resolvedStatus);

  // print('testing video stream');
  // firstStatus['initialization'] = 'initialized';
  // await RigStatus.apply(firstStatus);
  // var data = await Api.video(0);
  // print('got stream with status: ');
  // print(data.statusCode);
  // print('printing stream values: ');

  // int i = 0;

  // data.stream.forEach((chunk) {
  //   if ((chunk.length == 65543) && (i == 0)) {
  //     i = 1;
  //     getImage(chunk);
  //   }
  //   print(
  //       'Chunk length: ${chunk.length}, first 2: ${chunk[0]}, ${chunk[1]}, last 2: ${chunk.reversed.toList()[1]}, ${chunk.reversed.toList()[0]}');
  // });
}
