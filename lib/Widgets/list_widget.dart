import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ListWidget extends StatelessWidget {
  final Map<String, PathData> pathData;
  final Map<int, TagInfoData> tagData;
  final Set<String> trackingPath;
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  const ListWidget({
    super.key,
    required this.pathData,
    required this.tagData,
    required this.trackingPath,
    this.selectedIndices = const {},
    this.onTap,
  });

  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  Widget build(BuildContext context) {
    if (pathData.isEmpty) return getEmptyWidget(context);
    return ListView.builder(
      itemCount: pathData.length,
      itemBuilder: (context, index) {
        final pData = pathData.values.elementAt(index);
        final pid = pData.pid;
        return ListElementWidget(
          pathData: pData,
          onTap: () => onTap?.call(pid),
          isSelected: selectedIndices.contains(pid),
          isNotExist: !trackingPath.contains(pData.path),
        );
      },
    );
  }
}
