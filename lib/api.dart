import 'dart:collection';
import 'dart:async';
// import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/material.dart' show IconData, debugPrint;

const String socketHostname = 'http://localhost:5001';
// const String mainHostname = 'http://localhost:5000';

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

  Allowable(this.allowed, this.print, {this.range, this.values}); // {
  //   if (!((range == null) ^ (values == null))) {
  //     throw 'Must define exactly 1 of range or values set.';
  //   }
  // }

  bool call(dynamic value) {
    if (!(value is T)) return false;
    return this.allowed(value);
  }

  String toString() {
    return this.print();
  }
}

class RigStatusItem<T> {
  T _current;
  final bool mutable;
  final String category;
  final Allowable<T> allowed;
  bool _isSet = false;

  String toString() =>
      '[${mutable ? "Mutable" : "Immutable"}]{Current value: $_current, Category: $category, Allowed values: $allowed}';

  RigStatusItem(this._current, this.mutable, this.category, this.allowed)
      : assert(allowed(_current));

  RigStatusItem copy() {
    T currentCopy;
    if (_current is RigStatusMap) {
      currentCopy = RigStatusMap._copy(_current as RigStatusMap) as T;
    } else {
      currentCopy = _current;
    }
    return RigStatusItem(currentCopy, mutable, category, allowed);
  }

  T get current => _current;
  set current(dynamic value) {
    if (!(mutable)) throw 'Status is immutable!';
    if (!(allowed(value))) throw 'Value is not allowed.';
    _current = value;
    _isSet = true;
  }

  dynamic _toJSON(bool check) {
    if (_current is RigStatusMap) {
      Map<String, dynamic> result = (_current as RigStatusMap)._toJSON(check);
      if (result.isEmpty) {
        return null;
      } else {
        return result;
      }
    } else {
      if (check && !_isSet) {
        return null;
      } else {
        return _current;
      }
    }
  }
}

class RigStatusMap extends MapBase<String, RigStatusItem> {
  //Member variables
  static final RigStatusMap _globalInstance = RigStatusMap._singleton();
  RigStatusMap _localInstance;
  final Map<String, RigStatusItem> _map = Map<String, RigStatusItem>();
  final bool _isMutable;

  static bool _isInitialized = false;
  static final StreamController<bool> _initializationController =
      StreamController<bool>.broadcast();
  static Stream<bool> get onInitialization => _initializationController.stream;

  static final StreamController<RigStatusMap> _changeController =
      StreamController<RigStatusMap>.broadcast();
  static Stream<RigStatusMap> get onChange => _changeController.stream;

  //constructors
  RigStatusMap()
      : _isMutable = true,
        _localInstance = _globalInstance;
  RigStatusMap._singleton() : _isMutable = false {
    _initializationController.add(false);
    _localInstance = this;
    Api._socket.onDisconnect((_) => _teardown());
    Api._socket.onConnect((_) => _instantiate());
    Api._socket.on('broadcast', (data) => _update(data));
  }
  factory RigStatusMap.live() => _globalInstance;
  RigStatusMap._instance() : _isMutable = false {
    _localInstance = this;
  }
  RigStatusMap._fromInstance(this._localInstance)
      : _isMutable = true,
        assert(!_localInstance._isMutable);

  RigStatusMap._copy(RigStatusMap instance)
      : _isMutable = true,
        _localInstance = instance._localInstance {
    instance._map.forEach((key, value) {
      _map[key] = value.copy();
    });
  }

  //Map implementation
  @override
  get keys => _map.keys;

  @override
  operator [](Object key) {
    if (_map.containsKey(key)) {
      return _map[key];
    } else if (_localInstance.containsKey(key)) {
      _map[key] = _localInstance[key].copy();
      return _map[key];
    } else {
      throw 'Requested status "$key" does not exist in instance $_localInstance.';
    }
  }

  @override
  operator []=(String key, dynamic value) =>
      (_isMutable & _localInstance.containsKey(key))
          ? _map[key] = value
          : throw 'Status map cannot be altered.';

  @override
  clear() => _isMutable ? _map.clear() : throw 'Status map cannot be altered.';

  @override
  remove(Object key) =>
      _isMutable ? _map.remove(key) : throw 'Status map cannot be altered.';

  //extras
  static void _instantiate() async {
    RigStatusMap parse(Map<String, dynamic> json, RigStatusMap instance) {
      RigStatusMap result = RigStatusMap._fromInstance(instance);

      json.forEach((key, value) {
        Allowable allowable;
        if (value['current'] is String) {
          Set<String> thisSet = Set<String>.from(value['allowedValues']);
          if (thisSet.isEmpty) {
            allowable = Allowable<String>(
                (value) => value is String, () => 'Any string',
                values: Set.from(['']));
          } else {
            allowable = Allowable<String>(
                (value) => thisSet.contains(value), () => thisSet.toString(),
                values: thisSet);
          }
          result._map[key] = RigStatusItem<String>(
              value['current'], value['mutable'], value['category'], allowable);
        } else if (value['current'] is bool) {
          allowable = Allowable<bool>(
              (value) => value is bool, () => 'True or False',
              values: Set.from([true, false]));
          result._map[key] = RigStatusItem<bool>(
              value['current'], value['mutable'], value['category'], allowable);
        } else if (value['current'] is num) {
          if (value['allowedValues'] is List) {
            Set<num> thisSet = Set<num>.from(value['allowedValues']);
            allowable = Allowable<num>(
                (value) => thisSet.contains(value), () => thisSet.toString(),
                values: thisSet);
          } else if (value['allowedValues'] is Map) {
            num thisMin = value['allowedValues']['min'];
            num thisMax = value['allowedValues']['max'];
            allowable = Allowable<num>(
                (value) => (thisMin <= value) && (value <= thisMax),
                () => '$thisMin to $thisMax',
                range: Range<num>(thisMin, thisMax));
          } else {
            throw 'Could not create rig status item of type num.';
          }
          result._map[key] = RigStatusItem<num>(
              value['current'], value['mutable'], value['category'], allowable);
        } else if (value['current'] is Map) {
          RigStatusMap subInstance = RigStatusMap._instance();
          allowable = Allowable<RigStatusMap>(
              (value) => true, () => 'A RigStatusMap with allowable children');
          result._map[key] = RigStatusItem<RigStatusMap>(
              parse(value['current'], subInstance),
              value['mutable'],
              value['category'],
              allowable);
        } else {
          throw 'Could not create rig status item.';
        }
        instance._map[key] = result._map[key].copy();
      });
      return result;
    }

    _changeController.add(parse(await Api._get('allowed'), _globalInstance));
    _isInitialized = true;
    _initializationController.add(true);
  }

  static void _teardown() async {
    _globalInstance._map.clear();
    _isInitialized = false;
    _initializationController.add(false);
    _changeController.add(_globalInstance);
  }

  static RigStatusMap _update(Map<String, dynamic> update) {
    if (!_isInitialized) return null;
    RigStatusMap result = _parse(update, _globalInstance);
    _changeController.add(result);
    return result;
  }

  static RigStatusMap _parse(Map<String, dynamic> json, RigStatusMap instance) {
    RigStatusMap result = RigStatusMap._copy(instance);
    json.forEach((key, value) {
      if (value['current'] is Map) {
        result._map[key] = RigStatusItem<RigStatusMap>(
            _parse(value['current'], instance[key]._current._localInstance),
            value['mutable'],
            instance[key].category,
            instance[key].allowed);
      } else if (value['current'] is String) {
        result._map[key] = RigStatusItem<String>(value['current'],
            value['mutable'], instance[key].category, instance[key].allowed);
      } else if (value['current'] is bool) {
        result._map[key] = RigStatusItem<bool>(value['current'],
            value['mutable'], instance[key].category, instance[key].allowed);
      } else if (value['current'] is num) {
        result._map[key] = RigStatusItem<num>(value['current'],
            value['mutable'], instance[key].category, instance[key].allowed);
      }

      instance._map[key] = result[key].copy();
    });
    return result;
  }

  static Future<RigStatusMap> apply(RigStatusMap update) async {
    if (!update._isMutable)
      throw 'Cannot apply update to immutable status item';

    return _update(await Api._post(update._toJSON(true)));
  }

  Map<String, dynamic> _toJSON(bool check) {
    Map<String, dynamic> json = {};
    _map.forEach((key, value) {
      dynamic result = value._toJSON(check);
      if (result != null) {
        json[key] = result;
      }
    });

    // return _map.map<String, dynamic>((key, value) {
    //   return MapEntry<String, dynamic>(key, value._toJSON(check));
    // });
    return json;
  }

  String toString() {
    return _toJSON(false).toString();
  }
}

class ProcessTag {
  final String name;
  final String description;
  final IconData icon;
  ProcessTag(Map<String, dynamic> tags)
      : name = tags['name'],
        description = tags['description'],
        icon = IconData(tags['icon'], fontFamily: 'MaterialIcons');
}

class DatabaseStatus extends MapBase<String, dynamic> {
  static final Map<String, dynamic> _map = Map();
  static final DatabaseStatus _instance = DatabaseStatus._singleton();
  static final StreamController<DatabaseStatus> _changeController =
      StreamController<DatabaseStatus>.broadcast();
  static Stream<DatabaseStatus> get onChange => _changeController.stream;

  //
  static final StreamController<bool> _initializationController =
      StreamController<bool>.broadcast();
  static Stream<bool> get onInitialization => _initializationController.stream;

  @override
  operator [](Object key) {
    return _map[key];
  }

  @override
  get keys => _map.keys;

  @override
  operator []=(String key, dynamic value) =>
      throw 'Database status cannot be altered.';

  @override
  clear() => throw 'Status map cannot be altered.';

  @override
  remove(Object key) => throw 'Status map cannot be altered.';

  DatabaseStatus._singleton() {
    debugPrint('got to database singleton constructor');
    Api._socket.onDisconnect((_) => _teardown());
    Api._socket.onConnect((_) => _instantiate());
    Api._socket.on('database', (data) => _update(data));
    _map['tested'] = 'done';
    if (Api._socket.connected) _instantiate();
  }

  void _teardown() {
    _map.clear();
    _changeController.add(DatabaseStatus());
    _initializationController.add(false);
  }

  void _instantiate() async {
    debugPrint('instantiating!');
    Future.wait([
      Api._get('database')
          .then(_update, onError: (_) => "error getting database entries.")
          .then((_) => _changeController.add(DatabaseStatus()))
    ]).then((_) => _initializationController.add(true));
  }

  static void _update(Map<String, dynamic> json) {
    print('got database update: ');
    print(json);
    _map['testing'] = 'tested';
  }

  factory DatabaseStatus() {
    debugPrint('got to factory method for database');
    return _instance;
  }
}

class ProcessingStatus extends UnmodifiableListView {
  //Member variables
  static final ProcessingStatus _instance = ProcessingStatus._singleton();
  static final List<MapEntry<String, List<List<bool>>>> _list = [];
  static final List<String> columns = [];
  static List<List<ProcessTag>> processTags = [];

  // static bool _isInitialized = false;
  static final StreamController<bool> _initializationController =
      StreamController<bool>.broadcast();
  static Stream<bool> get onInitialization => _initializationController.stream;

  static final StreamController<ProcessingStatus> _changeController =
      StreamController<ProcessingStatus>.broadcast();
  static Stream<ProcessingStatus> get onChange => _changeController.stream;

  //constructors
  factory ProcessingStatus() {
    return _instance;
  }

  ProcessingStatus._singleton() : super(_list) {
    _initializationController.add(false);
    Api._socket.onDisconnect((_) => _teardown());
    // Api._socket.onDisconnect((_) => _list.clear());
    Api._socket.onConnect((_) => _instantiate());
    // Api._socket.onConnect((_) => _list.clear());
    Api._socket.on('processed', (data) => _update(data));
  }

  void _teardown() {
    _list.clear();
    _changeController.add(ProcessingStatus());
    _initializationController.add(false);
  }

  void _instantiate() async {
    Future.wait([
      Api._get('processing categories').then(_updateColumns),
      next(15).then((_) => _changeController.add(ProcessingStatus()))
    ]).then((_) => _initializationController.add(true));
  }

  static Future<ProcessingStatus> next(int n) async {
    return Api._get(['processing', _list.length, n]).then((json) {
      return _fromJSON(json);
    });
  }

  static ProcessingStatus _fromJSON(Map<String, dynamic> json) {
    int index = json['first'];
    int count = json['sessions'].length;
    int excess = index + count - _list.length;
    print(
        'currently at ${_list.length} items. Adding $count from $index (excess of $excess)');
    if (excess > 0) {
      _list.addAll(
          List.filled(excess, MapEntry<String, List<List<bool>>>(null, null)));
    }
    for (int i = 0; i < count; i++) {
      Map<String, dynamic> session = json['sessions'][i];
      _list[index++] = MapEntry(
          session['name'],
          session['status'].map<List<bool>>((column) {
            return (column as List).map<bool>((done) => done as bool).toList();
          }).toList());
    }
    ProcessingStatus ret = ProcessingStatus();
    _changeController.add(ret);
    return ret;
  }

  static void _updateColumns(Map<String, dynamic> json) {
    columns.clear();
    columns.addAll(json['headers'].map<String>((header) {
      return (header as String).toUpperCase();
    }));

    processTags = (json['info'] as List).map<List<ProcessTag>>((processTags) {
      return (processTags as List)
          .map<ProcessTag>(
              (processTag) => ProcessTag(processTag as Map<String, dynamic>))
          .toList();
    }).toList();
  }

  static void _update(Map<String, dynamic> json) {
    int index = json['index'];
    if (index == -1) {
      _list.insert(
          0,
          MapEntry<String, List<List<bool>>>(
              json['session'],
              processTags
                  .map<List<bool>>((processTag) =>
                      processTag.map<bool>((_) => false).toList())
                  .toList()));
    } else {
      _list[index].value[json['column']][json['item']] = json['status'];
    }
  }
}

class Api {
  static final IO.Socket _socket = IO.io(socketHostname, <String, dynamic>{
    'transports': ['websocket']
  });

  static final StreamController<MapEntry<DateTime, String>> _changeController =
      StreamController<MapEntry<DateTime, String>>.broadcast();
  static bool _hasSetupMessage = false;
  static ListQueue<MapEntry<DateTime, String>> messageQueue =
      ListQueue<MapEntry<DateTime, String>>();

  static Stream<MapEntry<DateTime, String>> get onMessage {
    if (!Api._hasSetupMessage) {
      Api._socket.on('message', (message) {
        MapEntry<DateTime, String> entry =
            MapEntry<DateTime, String>(DateTime.now(), message);
        Api.messageQueue.addFirst(entry);
        Api._changeController.add(entry);
      });
      Api._hasSetupMessage = true;
    }
    return _changeController.stream;
  }

  static Future<Map<String, dynamic>> _post(Map<String, dynamic> update) async {
    Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    _socket.emitWithAck('post', update, ack: (data) {
      c.complete(data);
    });
    return c.future;
  }

  static Future<Map<String, dynamic>> _get(dynamic message) async {
    Completer<Map<String, dynamic>> c = Completer<Map<String, dynamic>>();
    _socket.emitWithAck('get', message, ack: (data) {
      c.complete(data);
    });
    return c.future;
  }
}

void main() async {
  // print('awaiting connection');
  // RigStatusMap dynamicmap = RigStatusMap.live();
  // await for (bool init in RigStatusMap.onInitialization) {
  //   if (init) break;
  // }
  // print('got dynamic map: $dynamicmap');

  // RigStatusMap staticmap = RigStatusMap();

  // staticmap['camera 3'].current['displaying'].current =
  //     !dynamicmap['camera 3'].current['displaying'].current;

  // // RigStatusMap.onChange
  // //     .listen((statusmap) => print('got map update: $statusmap'));
  // RigStatusMap updated = await RigStatusMap.apply(staticmap);
  // print('got update as return value: $updated');

  var ps = ProcessingStatus();
  await for (bool init in ProcessingStatus.onInitialization) {
    if (init) break;
  }
  print('got processing status');
  print(ps);

  return;
}
