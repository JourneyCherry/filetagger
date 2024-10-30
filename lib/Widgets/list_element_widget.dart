import 'package:filetagger/DataStructures/object.dart';
import 'package:flutter/widgets.dart';

class ListElementWidget extends StatefulWidget {
  final TrackedObject initialObject;
  const ListElementWidget({super.key, required this.initialObject});

  @override
  State<ListElementWidget> createState() => _ListElementWidgetState();
}

class _ListElementWidgetState extends State<ListElementWidget> {
  late final TrackedObject trackedObject;

  @override
  void initState() {
    super.initState();
    trackedObject = widget.initialObject;
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
