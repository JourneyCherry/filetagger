import 'package:filetagger/DataStructures/datas.dart';
import 'package:flutter/material.dart';

class TagListController extends ValueNotifier<List<TagData>> {
  final List<TagData> _srcData;

  TagListController(List<TagData> initialValue)
      : _srcData = initialValue, //원본 데이터는 참조로 받고
        super(List<TagData>.from(initialValue
            .map((tag) => TagData.copy(tag)))); //수정되는 데이터는 값복사로 받는다.

  void revertData() {
    value = List<TagData>.from(_srcData.map((tag) => TagData.copy(tag)));
  }
}
