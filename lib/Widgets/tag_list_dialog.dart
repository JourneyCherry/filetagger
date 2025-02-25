import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/tag_column_name_widget.dart';
import 'package:filetagger/Widgets/tag_edit_widget.dart';
import 'package:filetagger/Widgets/tag_list_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TagListDialog extends StatefulWidget {
  final TagListController controller;

  static const Map<int, int> columnWidths = {
    0: 3, //이름
    1: 2, //타입
    2: 1, //배경색
    3: 1, //글자색
    4: 1, //중복
    5: 1, //필수
    6: 3, //기본값
  };

  const TagListDialog({
    super.key,
    required this.controller,
  });

  @override
  State<TagListDialog> createState() => _TagListDialogState();
}

class _TagListDialogState extends State<TagListDialog> {
  void reset() {
    widget.controller.revertData();
    widget.controller.value.sort((lhs, rhs) => lhs.order.compareTo(rhs.order));
  }

  void reorder() {
    for (int i = 0; i < widget.controller.value.length; ++i) {
      widget.controller.value[i].order = i;
    }
  }

  @override
  void initState() {
    super.initState();
    reset();
    reorder();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      title: Text(
        AppLocalizations.of(context)!.tagList,
      ),
      elevation: 16,
      content: SizedBox(
        width: 500, // 부모 위젯이 해당 크기보다 작은 경우, 알아서 그 크기에 맞게 작아진다.
        height: 500,
        child: Column(
          children: [
            TagColumnNameWidget(),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                physics: ClampingScrollPhysics(),
                itemCount: widget.controller.value.length,
                itemBuilder: (context, index) => TagEditWidget(
                  key: ValueKey(widget.controller.value[index]),
                  index: index,
                  tag: widget.controller.value[index],
                  onChanged: (changedTag) => setState(() {
                    widget.controller.value[index] = changedTag;
                  }),
                ),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    TagData item = widget.controller.value.removeAt(oldIndex);
                    widget.controller.value.insert(newIndex, item);
                    reorder();
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            widget.controller.value
                .add(TagData.partial(order: widget.controller.value.length));
            reorder();
          }),
          child: Text(AppLocalizations.of(context)!.tag_add),
        ),
        TextButton(
          onPressed: () => setState(() {
            reset();
            reorder();
          }),
          child: Text(AppLocalizations.of(context)!.tag_reset),
        ),
      ],
    );
  }
}
