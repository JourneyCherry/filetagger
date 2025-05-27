import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:filetagger/DataStructures/path_tag_value_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ListWidget extends StatelessWidget {
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  final VoidCallback? onValueChanged;
  const ListWidget({
    super.key,
    this.selectedIndices = const {},
    this.onTap,
    this.onValueChanged,
  });

  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  Widget build(BuildContext context) {
    final pathList = context.select<PathTagValueProvider, List<PathData>>(
        (provider) => provider.getPathAll());
    if (pathList.isEmpty) return getEmptyWidget(context);
    return ListView.builder(
      itemCount: pathList.length,
      itemBuilder: (context, index) {
        final data = pathList.elementAt(index);
        return ListElementWidget(
          pid: data.pid,
          onTap: () => onTap?.call(data.pid),
          onSuccess: onValueChanged,
          isSelected: selectedIndices.contains(data.pid),
          isNotExist: false, //TODO : PathManager에서 트래킹 중인지 확인
        );
      },
    );
  }
}
