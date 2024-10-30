import 'package:filetagger/DataStructures/object.dart';
import 'package:flutter/material.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<StatefulWidget> createState() => ListWidgetState();
}

class ListWidgetState extends State<ListWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<TrackedObject> _objects = [];

  void addObjects(Iterable<TrackedObject> objects) {
    setState(() {
      _objects.addAll(objects);
    });
  }

  void removeObjects(Iterable<String> paths) {
    setState(() {
      _objects.removeWhere((object) => paths.contains(object.path));
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (index < _objects.length) {
                return ListTile(title: Text(_objects[index].getName()));
              } else {
                return null;
              }
            },
            childCount: _objects.length,
          ),
        ),
      ],
    );
  }
}
