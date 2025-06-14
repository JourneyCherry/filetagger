import 'package:filetagger/DataStructures/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void typeTest() {
  test('Data Convert Test', () {
    DateTime parsedDateTime = DateTime.now();
    final timeMargin = 1000; //오차 허용값(ms)
    expect(Types.bool2int(true), 1);
    expect(Types.bool2int(false), 0);

    expect(Types.int2bool(1), true);
    expect(Types.int2bool(0), false);
    expect(Types.int2bool(2), false);
    expect(Types.int2bool(null), false);

    expect(Types.color2int(Colors.black), 0xFF000000);
    expect(Types.color2int(Colors.lightBlue), 0xFF03A9F4);

    dynamic value;
    String? str;
    expect(Types.verify(ValueType.label, value), true);
    expect(Types.verify(ValueType.numeric, value), false);
    expect(Types.verify(ValueType.string, value), false);
    expect(Types.verify(ValueType.datetime, value), false);
    expect(Types.isParsable(ValueType.label, str), true);
    expect(Types.isParsable(ValueType.numeric, str), false);
    expect(Types.isParsable(ValueType.string, str), true);
    expect(Types.isParsable(ValueType.datetime, str), false);
    expect(Types.parseString(ValueType.label, str), value);
    expect(Types.parseString(ValueType.numeric, str), 0); //기본값
    expect(Types.parseString(ValueType.string, str), ''); //기본값
    parsedDateTime = Types.parseString(ValueType.datetime, str);
    expect(
        DateTime.now().difference(parsedDateTime).abs().inMilliseconds, //기본값
        lessThan(timeMargin)); //오차범위

    value = 123;
    str = value.toString();
    expect(Types.verify(ValueType.label, value), false);
    expect(Types.verify(ValueType.numeric, value), true);
    expect(Types.verify(ValueType.string, value), false);
    expect(Types.verify(ValueType.datetime, value), false);
    expect(Types.isParsable(ValueType.label, str), false);
    expect(Types.isParsable(ValueType.numeric, str), true);
    expect(Types.isParsable(ValueType.string, str), true); //예외
    expect(Types.isParsable(ValueType.datetime, str), false);
    expect(Types.parseString(ValueType.label, str), null);
    expect(Types.parseString(ValueType.numeric, str), value);
    expect(Types.parseString(ValueType.string, str), str);
    parsedDateTime = Types.parseString(ValueType.datetime, str);
    expect(
        DateTime.now().difference(parsedDateTime).abs().inMilliseconds, //기본값
        lessThan(timeMargin)); //기본값

    value = 'text';
    str = value.toString();
    expect(Types.verify(ValueType.label, value), false);
    expect(Types.verify(ValueType.numeric, value), false);
    expect(Types.verify(ValueType.string, value), true);
    expect(Types.verify(ValueType.datetime, value), false);
    expect(Types.isParsable(ValueType.label, str), false);
    expect(Types.isParsable(ValueType.numeric, str), false);
    expect(Types.isParsable(ValueType.string, str), true);
    expect(Types.isParsable(ValueType.datetime, str), false);
    expect(Types.parseString(ValueType.label, str), null);
    expect(Types.parseString(ValueType.numeric, str), 0); //기본값
    expect(Types.parseString(ValueType.string, str), value);
    parsedDateTime = Types.parseString(ValueType.datetime, str);
    expect(
        DateTime.now().difference(parsedDateTime).abs().inMilliseconds, //기본값
        lessThan(timeMargin)); //기본값

    value = DateTime(2025, 3, 2, 15, 45, 59); //2025년 3월 2일 15시 45분 59초
    str = value.toString();
    expect(Types.verify(ValueType.label, value), false);
    expect(Types.verify(ValueType.numeric, value), false);
    expect(Types.verify(ValueType.string, value), false);
    expect(Types.verify(ValueType.datetime, value), true);
    expect(Types.isParsable(ValueType.label, str), false);
    expect(Types.isParsable(ValueType.numeric, str), false);
    expect(Types.isParsable(ValueType.string, str), true); //예외
    expect(Types.isParsable(ValueType.datetime, str), true);
    expect(Types.parseString(ValueType.label, str), null);
    expect(Types.parseString(ValueType.numeric, str), 0); //기본값
    expect(Types.parseString(ValueType.string, str), str);
    expect(Types.parseString(ValueType.datetime, str), value);
  });
}

void main() {
  group('Type Test', () => typeTest());
}
