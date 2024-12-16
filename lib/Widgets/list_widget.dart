import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ListWidget extends StatelessWidget {
  final GlobalData globalData;
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  const ListWidget({
    super.key,
    required this.globalData,
    this.selectedIndices = const {},
    this.onTap,
  });

  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  Widget build(BuildContext context) {
    if (globalData.pathData.isEmpty) return getEmptyWidget(context);
    return ListView.builder(
      itemCount: globalData.pathData.length,
      itemBuilder: (context, index) {
        final data = globalData.pathData.values.elementAt(index);
        return ListElementWidget(
          pid: data.pid,
          globalData: globalData,
          onTap: () => onTap?.call(data.pid),
          isSelected: selectedIndices.contains(data.pid),
          isNotExist: !globalData.trackingPath.contains(data.path),
        );
      },
    );
  }
}
