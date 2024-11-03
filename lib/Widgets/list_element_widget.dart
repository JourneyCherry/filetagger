import 'dart:async';

import 'package:filetagger/DataStructures/object.dart';
import 'package:filetagger/DataStructures/tag.dart';
import 'package:flutter/material.dart';

class ListElementWidget extends StatefulWidget {
  final TrackedObject item;
  const ListElementWidget({super.key, required this.item});

  @override
  State<ListElementWidget> createState() => _ListElementWidgetState();
}

class _ListElementWidgetState extends State<ListElementWidget> {
  late final TrackedObject _trackedObject;
  late final StreamSubscription<TrackedTag> addSubscription;
  late final StreamSubscription<void> delSubscription;

  @override
  void initState() {
    super.initState();
    _trackedObject = widget.item;
    addSubscription = _trackedObject.addEvent.listen((_) => setState(() {}));
    delSubscription = _trackedObject.delEvent.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    addSubscription.cancel();
    delSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const ListTile();
  }
}
