import 'dart:async';

import 'package:filetagger/DataStructures/object.dart';
import 'package:filetagger/DataStructures/object_manager.dart';
import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:flutter/material.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<StatefulWidget> createState() => ListWidgetState();
}

class ListWidgetState extends State<ListWidget> {
  final List<TrackedObject> _objects = [];
  late final StreamSubscription<TrackedObject> addSubscription;
  late final StreamSubscription<String> delSubscription;

  @override
  void initState() {
    super.initState();
    addSubscription = ObjectManager().addEvent.listen(addObjects);
    delSubscription = ObjectManager().delEvent.listen(removeObjects);
  }

  @override
  void dispose() {
    addSubscription.cancel();
    delSubscription.cancel();
    super.dispose();
  }

  void addObjects(TrackedObject object) {
    setState(() {
      _objects.add(object);
    });
  }

  void removeObjects(String path) {
    setState(() {
      _objects.removeWhere((object) => (object.path == path));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('Widgets/list_widget'),
      itemCount: _objects.length,
      itemBuilder: (context, index) => ListElementWidget(
        item: _objects[index],
      ),
    );
  }
}
