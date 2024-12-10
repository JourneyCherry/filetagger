import 'dart:io';
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
  late final FileSystemEntity file;

  @override
  void initState() {
    super.initState();
    file = widget.file; //TODO : widget.file로부터 태그 정보 가져오기.(LocalDB)
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(file.path),
      onTap: widget.onTap,
      tileColor: widget.isSelected ? Colors.blue.withOpacity(0.3) : null,
    );
  }
}
