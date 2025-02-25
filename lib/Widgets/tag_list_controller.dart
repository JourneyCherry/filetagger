import 'package:filetagger/DataStructures/datas.dart';
import 'package:flutter/material.dart';

class TagListController extends ValueNotifier<List<TagData>> {
  final List<TagData> _srcData;

  TagListController(List<TagData> initialValue)
      : _srcData = initialValue, //원본 데이터는 참조로 받고
        super(List.from(initialValue)); //수정되는 데이터는 값복사로 받는다.

  void revertData() {
    value = List.from(_srcData);
  }
}
