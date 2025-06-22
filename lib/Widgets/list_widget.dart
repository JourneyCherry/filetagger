import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:filetagger/DataStructures/path_tag_value_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ListWidget extends StatefulWidget {
  final Set<int> selectedIndices;
  final void Function(int)? onTap;
  final VoidCallback? onValueChanged;
  const ListWidget({
    super.key,
    this.selectedIndices = const {},
    this.onTap,
    this.onValueChanged,
  });

  @override
  State<ListWidget> createState() => _ListWidgetState();
}

class _ListWidgetState extends State<ListWidget> {
  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pidList = context.select<PathTagValueProvider?, List<int>?>(
        (provider) => provider?.getPIDList());
    if (pidList == null || pidList.isEmpty) return getEmptyWidget(context);
    return ListView.builder(
      itemCount: pidList.length,
      itemBuilder: (listViewBuilderContext, index) {
        return ListElementWidget(pid: pidList.elementAt(index));
      },
    );
  }
}
