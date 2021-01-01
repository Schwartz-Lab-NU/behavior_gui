// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'dart:async';
import 'dart:collection';

const String hostname = 'http://localhost:5000';

// enum RigStatusCategory { Video, Audio, Acquisition, Processing }

class Allowable<T> {
  final bool Function(T) allowed;
  final String Function() print;
  Allowable(this.allowed, this.print);

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
  void operator []=(Object key, RigStatusValue value) {
    if (_isDynamic) {
      throw 'Can\'t set dynamic RigStatusValue.';
    } else {
      _map[key] = value;
    }
  }

  bool _isDynamic = false;

  final StreamController<RigStatus> _changeController =
      StreamController<RigStatus>();
  Stream<RigStatus> get onChange => _changeController.stream;

  RigStatusValues();

  factory RigStatusValues.dynamic() {
    RigStatusValues rigStatusValues = RigStatusValues();

    rigStatusValues._isDynamic = true;

    rigStatusValues._get();
    Api.socket.on('broadcast', (data) => rigStatusValues._update(data));
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
    RigStatus newStatus = RigStatus.empty();
    json.forEach((status, value) {
      Allowable thisAllowable;

      if (value['current'] is String) {
        Set<String> thisSet = Set<String>.from(value['allowedValues']);
        thisAllowable = Allowable<String>(
            (String value) => thisSet.contains(value),
            () => thisSet.toString());

        this._map[status] = RigStatusValue<String>(
            thisAllowable, value['category'], value['current']);
      } else if (value['current'] is bool) {
        thisAllowable = Allowable<bool>(
            (bool value) => value is bool, () => [true, false].toString());

        this._map[status] = RigStatusValue<bool>(
            thisAllowable, value['category'], value['current']);
      } else if (value['current'] is num) {
        if (value['allowedValues'] is List) {
          Set<num> thisSet = Set<num>.from(value['allowedValues']);
          thisAllowable = Allowable<num>(
              (num value) => thisSet.contains(value), () => thisSet.toString());
        } else if (value['allowedValues'] is Map &&
            value['allowedValues'].containsKey('min') &&
            value['allowedValues'].containsKey('max')) {
          num thisMin = value['allowedValues']['min'];
          num thisMax = value['allowedValues']['max'];

          thisAllowable = Allowable<num>(
              (num value) => (thisMin <= value) && (value <= thisMax),
              () => [thisMin, thisMax].toString());
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
  }

  void _update(RigStatus update) {
    update.forEach((status, value) {
      this._map[status].current = value;
    });
    this._changeController.add(update);
  }
}

class RigStatus extends MapBase<String, dynamic> {
  Map<String, dynamic> _map;
  get keys => _map.keys;
  dynamic operator [](Object key) => _map[key];
  void operator []=(Object type, dynamic value) {
    if ((type is String) &&
        !this._isDynamic &&
        _statuses.containsKey(type) &&
        _statuses[type].allowed(value)) {
      _map[type] = value;
    } else {
      throw 'Couldn\'t set RigStatus';
    }
  }

  dynamic remove(Object key) {
    if (_isDynamic) {
      throw 'Can\'t remove values from dynamic rig status';
    }
    return _map.remove(key);
  }

  void clear() {
    if (_isDynamic) {
      throw 'Can\'t remove values from dynamic rig status';
    }
    _map.clear();
  }

  static final RigStatusValues _statuses = RigStatusValues.dynamic();
  bool _isDynamic = false;

  RigStatus()
      : this._map =
            _statuses.map<String, dynamic>((String type, RigStatusValue value) {
          return RigStatusItem(type, value.current);
        });

  RigStatus.empty() : this._map = Map<String, dynamic>();

  RigStatus.dynamic()
      : this._map =
            _statuses.map<String, dynamic>((String type, RigStatusValue value) {
          return RigStatusItem(type, value.current);
        }) {
    this._isDynamic = true;
    _statuses.onChange.listen(this._handleUpdates);
  }

  RigStatus.fromJSON(Map<String, dynamic> json) : this._map = json;

  void _handleUpdates(RigStatus updates) {
    this._map.addAll(updates);
  }

  static Future<RigStatus> apply(dynamic status) {
    if ((status is RigStatus) || status is RigStatusItem) {
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
  static final IO.Socket socket = IO.io(hostname, <String, dynamic>{
    'transports': ['websocket']
  });

  static Future<Map<String, dynamic>> _post(dynamic status) async {
    Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    socket.emitWithAck('post', status, ack: (data) {
      c.complete(data);
    });
    return c.future;
  }

  static Future<Map<String, dynamic>> _get(dynamic status) async {
    Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    socket.emitWithAck('get', status.toString(), ack: (data) {
      c.complete(data);
    });
    return c.future;
  }
}

void main() async {
  RigStatus firstStatus = RigStatus();
  RigStatus dynamicStatus = RigStatus.dynamic();
  print('Static rig status: ');
  print(firstStatus);
  print('Dynamic rig status: ');
  print(dynamicStatus);

  print('Waiting 1 second...');
  await Future.delayed(Duration(seconds: 1));

  print('Old static rig status: ');
  print(firstStatus);
  print('Old dynamic rig status: ');
  print(dynamicStatus);
  RigStatus secondStatus = RigStatus();
  print('New static rig status: ');
  print(secondStatus);

  // print(RigStatus.getAllowed('recording'));
  firstStatus['recording'] = true;
  print('Trying to set status as: ');
  print(firstStatus);

  Future<RigStatus> futureStatus = RigStatus.apply(firstStatus);
  print('Future: ');
  print(futureStatus);

  print('Waiting for future to complete');
  RigStatus resolvedStatus = await futureStatus;
  print('Old dynamic rig status: ');
  print(dynamicStatus);
  print('Resolved future rig status: ');
  print(resolvedStatus);

  print('Waiting 1 second...');
  await Future.delayed(Duration(seconds: 1));
  print('Old dynamic rig status: ');
  print(dynamicStatus);
}
