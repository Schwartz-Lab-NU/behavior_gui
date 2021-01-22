// import 'dart:io';

// import 'package:flutter/material.dart';
import 'dart:typed_data';

// import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'dart:ui';
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
  Allowable<T> allowed;
  String category;
  T current;
  String toString() =>
      '{Current value: $current, Allowed values: $allowed, Category: $category}';

  RigStatusValue(this.allowed, this.category, this.current) {
    if (!allowed(current)) {
      throw 'Can\'t create status type with invalid current value';
    }
  }

  RigStatusValue.copy(RigStatusValue value)
      : allowed = value.allowed,
        category = value.category,
        current = value.current;

  void set(dynamic value) {
    if (this.allowed(value)) {
      current = value;
    } else {
      throw 'Unallowed status value';
    }
  }
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
  bool initialized = false;
  final StreamController<RigStatus> _changeController =
      StreamController<RigStatus>.broadcast();
  Stream<RigStatus> get onChange => _changeController.stream;

  @override
  void operator []=(Object key, RigStatusValue value) =>
      throw 'Can\'t set dynamic RigStatusValue.';

  DynamicRigStatusValues() : super() {
    this._get();
    Api._socket
        .on('broadcast', (data) => this._update(RigStatus.fromJSON(data)));
  }

  void _get() async {
    //each json result has following form:
    // {
    //// typeName1: {'allowedValues': [status1a, status1b, ...], 'category': RigStatusCategory, 'current': status1b},
    //// typeName2: ...
    //// ...
    // }
    // debugPrint('requesting allowed settings dictionary');
    final Map<String, dynamic> json = await Api._get('allowed');
    // debugPrint('got allowed settings dictionary');
    RigStatus newStatus = RigStatus.empty();
    json.forEach((status, value) {
      Allowable thisAllowable;

      if (value['current'] is String) {
        Set<String> thisSet = Set<String>.from(value['allowedValues']);
        thisAllowable = Allowable<String>(
            (String value) => thisSet.contains(value), () => thisSet.toString(),
            values: thisSet);

        this._map[status] = RigStatusValue<String>(
            thisAllowable, value['category'], value['current']);
      } else if (value['current'] is bool) {
        thisAllowable = Allowable<bool>(
            (bool value) => value is bool, () => [true, false].toString(),
            values: Set.from([true, false]));

        this._map[status] = RigStatusValue<bool>(
            thisAllowable, value['category'], value['current']);
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
              () => [thisMin, thisMax].toString(),
              range: Range<num>(thisMin, thisMax));
        } else {
          throw 'Incomprehensible allowed status types';
        }

        this._map[status] = RigStatusValue<num>(
            thisAllowable, value['category'], value['current']);
      } else {
        throw 'Incomprehensible status type';
      }
      newStatus[status] = value['current'];
    });
    this._changeController.add(newStatus);
    initialized = true;
  }

  void _update(RigStatus update) {
    // debugPrint('received broadcast event');
    if (!initialized) return;
    update.forEach((status, value) {
      this._map[status].current = value;
    });
    this._changeController.add(update);
  }
}

class RigStatus extends MapBase<String, dynamic> {
  Map<String, dynamic> _map;
  // Iterable<RigStatusItem> get entries => Iterable.castFrom(_map.entries);

  String toString() {
    return this._map.toString();
  }

  get keys => _map.keys;
  dynamic operator [](Object key) => _map[key];
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
    // return (status is RigStatus) &&
    //     (status.keys == this._map.keys) &&
    //     (status.values) == this.values;
    // debugPrint('Testing one rig status against another...');
    if (!(status is RigStatus)) return false;
    return this.isSameStatus(status);
    // status = status as RigStatus;
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

  RigStatus()
      : this._map =
            _statuses.map<String, dynamic>((String type, RigStatusValue value) {
          return RigStatusItem(type, value.current);
        });

  RigStatus.empty() : this._map = Map<String, dynamic>();

  RigStatus.fromJSON(Map<String, dynamic> json) : this._map = json;

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
    _statuses._update(RigStatus.fromJSON(json));
    return RigStatus();
  }
}

class DynamicRigStatus extends RigStatus {
  final StreamController<bool> _changeController =
      StreamController<bool>.broadcast();
  Stream<bool> get onChange => _changeController.stream;

  @override
  void operator []=(Object key, dynamic value) =>
      throw 'Couldn\'t set RigStatus';

  @override
  dynamic remove(Object key) =>
      throw 'Can\'t remove values from dynamic rig status';

  @override
  void clear() => throw 'Can\'t remove values from dynamic rig status';

  DynamicRigStatus() : super() {
    RigStatus._statuses.onChange.listen(this._handleUpdates);
  }

  void _handleUpdates(RigStatus updates) {
    this._map.addAll(updates);
    this._changeController.add(true);
  }
}

class RigStatusItem implements MapEntry<String, dynamic> {
  final String key;
  dynamic value;
  get type => this.key;
  set type(dynamic value) => throw 'RigStatusItem keys may not be changed';
  // set key(dynamic value) => throw 'RigStatusItem keys may not be changed';
  get category => RigStatus._statuses[key].category;
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
    _socket.emitWithAck('post', status, ack: (data) {
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
  RigStatus firstStatus = RigStatus();
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
