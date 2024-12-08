import 'dart:async';
import 'dart:io';

import 'package:filetagger/DataStructures/object.dart';
import 'package:filetagger/DataStructures/tag.dart';
import 'package:flutter/material.dart';

class ListElementWidget extends StatefulWidget {
  final FileSystemEntity file;
  final VoidCallback? onTap;
  final bool isSelected;
  const ListElementWidget({
    super.key,
    required this.file,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<ListElementWidget> createState() => _ListElementWidgetState();
}

class _ListElementWidgetState extends State<ListElementWidget> {
  late final String title;

  late final TrackedObject _trackedObject;
  late final StreamSubscription<TrackedTag> addSubscription;
  late final StreamSubscription<void> delSubscription;

  @override
  void initState() {
    super.initState();
    title = widget
        .file.path; //TODO : widget.file로부터 _trackedObject 정보 가져오기.(LocalDB)
    //addSubscription = _trackedObject.addEvent.listen((_) => setState(() {}));
    //delSubscription = _trackedObject.delEvent.listen((_) => setState(() {}));
  }

  @override
  void dispose() {
    //addSubscription.cancel();
    //delSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: widget.onTap,
      tileColor: widget.isSelected ? Colors.blue.withOpacity(0.3) : null,
    );
  }
}
