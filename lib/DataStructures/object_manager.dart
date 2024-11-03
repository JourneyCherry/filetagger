import 'dart:collection';

import 'package:filetagger/DataStructures/container_event_handler_mixin.dart';
import 'package:filetagger/DataStructures/object.dart';

class ObjectManager with ContainerEventHandlerMixin<TrackedObject, String> {
  ObjectManager._();

  static final ObjectManager _instance = ObjectManager._();

  factory ObjectManager() => _instance;

  SplayTreeSet<TrackedObject> objects = SplayTreeSet(
    (key1, key2) => (key1.path.compareTo(key2.path)),
  );
}
