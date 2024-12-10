import 'dart:io';

import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ListWidget extends StatelessWidget {
  final List<FileSystemEntity> files;
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  const ListWidget({
    super.key,
    required this.files,
    this.selectedIndices = const {},
    this.onTap,
  });

  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        return ListElementWidget(
          file: files[index],
          onTap: () => onTap?.call(index),
          isSelected: selectedIndices.contains(index),
        );
      },
    );
  }
}
