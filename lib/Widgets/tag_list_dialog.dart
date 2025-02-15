import 'package:filetagger/DataStructures/datas.dart';
import 'package:filetagger/Widgets/tag_edit_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TagListDialog extends StatefulWidget {
  final GlobalData globalData;
  final void Function(List<TagData>)? onSaveTag;

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
    required this.globalData,
    this.onSaveTag,
  });

  @override
  State<TagListDialog> createState() => _TagListDialogState();
}

class _TagListDialogState extends State<TagListDialog> {
  final List<TagData> _curData = []; //order 순서로 정렬된 태그 순서 리스트

  void reset() {
    widget.globalData.tagData.forEach((key, value) => _curData.add(value));
    _curData.sort((lhs, rhs) => lhs.order.compareTo(rhs.order));
  }

  @override
  void initState() {
    super.initState();
    reset();
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
        //TODO : ListView 위에 Column이름 표시용으로 TagEditWidget과 동일한 요소 수, 비율을 갖지만 수정이 불가능한 Widget을 하나 놓자.
        child: ListView.builder(
          physics: ClampingScrollPhysics(),
          //TODO : 각 요소의 순서를 변경할 수 있는 방법 필요
          itemCount: _curData.length,
          itemBuilder: (context, index) => TagEditWidget(
            tag: _curData[index],
            onChanged: (changedTag) => setState(() {
              _curData[index] = changedTag;
            }),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _curData.add(TagData.empty());
          }),
          child: Text(AppLocalizations.of(context)!.tag_add),
        ),
        TextButton(
          onPressed: () => setState(() {
            reset();
          }),
          child: Text(AppLocalizations.of(context)!.tag_reset),
        ),
      ],
    );
  }
}
