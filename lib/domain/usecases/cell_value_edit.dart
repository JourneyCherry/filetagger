/// 자세히 테이블 셀의 **인라인 편집 텍스트 ↔ 저장값 목록** 변환.
///
/// 셀을 더블클릭하면 그 자리에 텍스트 입력이 떠서 값을 고친다. 다중 부여 태그는
/// 여러 값을 한 줄에 담아야 하므로 값을 콤마로 가른다. 텍스트 값은 공백을 품을 수
/// 있어(콤마와 헷갈리지 않게) 쌍따옴표로 감싸고, 그 안의 쌍따옴표는 겹쳐(`""`)
/// 표기한다(CSV 규약). 숫자·날짜는 공백이 없어 인용 없이 콤마로만 가른다.
///
/// 필터·정렬 텍스트의 조각 문법(공백 구분·역슬래시 이스케이프)과는 **다른 문법**
/// 이다 — 그쪽은 한 줄에 서로 다른 태그의 조건을 늘어놓지만, 여기선 한 셀 안의 한
/// 태그에 대한 여러 값만 담으므로 콤마 구분이 더 읽기 쉽다.
library;

import '../entities/tag_value_format.dart';
import '../entities/tag_value_type.dart';

/// 저장값 목록을 편집용 한 줄 텍스트로 만든다(입력창의 초기 내용).
String formatCellEditText(
  TagValueType type,
  bool allowMultiple,
  List<String> storedValues,
) {
  final shown = [for (final v in storedValues) _display(type, v)];
  // 단일 값 태그는 인용 없이 그 값만 둔다(콤마도 값의 일부로 남는다).
  if (!allowMultiple) return shown.isEmpty ? '' : shown.first;
  if (type == TagValueType.text) return shown.map(_quote).join(', ');
  return shown.join(', ');
}

/// 편집 텍스트를 저장할 값 목록으로 해석한다. 유형에 맞지 않는(숫자가 아닌 수,
/// 못 읽는 날짜) 조각과 빈 조각은 버린다 — 빈 입력은 곧 태그 제거다.
List<String> parseCellEditText(
  TagValueType type,
  bool allowMultiple,
  String text,
) {
  // 단일 값 태그는 콤마를 값의 일부로 두어 통째로 한 조각이다.
  final rawParts = !allowMultiple
      ? [text]
      : type == TagValueType.text
      ? _splitQuotedCsv(text)
      : text.split(',');
  final values = <String>[];
  for (final raw in rawParts) {
    final stored = _toStored(type, raw.trim());
    if (stored != null) values.add(stored);
  }
  return values;
}

/// 저장값 하나를 편집창에 보일 문자열로. 날짜만 사람이 읽는 형식으로 자르고,
/// 나머지는 저장값 그대로다.
String _display(TagValueType type, String value) {
  if (type == TagValueType.date) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      final m = parsed.month.toString().padLeft(2, '0');
      final d = parsed.day.toString().padLeft(2, '0');
      return '${parsed.year}-$m-$d';
    }
  }
  return value;
}

/// 편집창 조각 하나를 저장값으로. 유형에 맞지 않거나 비면 null(버린다).
String? _toStored(TagValueType type, String raw) {
  if (raw.isEmpty) return null;
  switch (type) {
    case TagValueType.text:
    // link 셀은 인라인 텍스트 편집 대상이 아니라(노드 선택기로 고른다) 이 경로를
    // 타지 않지만, 저장값(대상 id)을 통째로 보존하도록 text처럼 그대로 둔다.
    case TagValueType.link:
      return raw;
    case TagValueType.number:
      return num.tryParse(raw) == null ? null : raw;
    case TagValueType.date:
      final parsed = DateTime.tryParse(raw);
      return parsed == null ? null : dateToStoredValue(parsed);
    case TagValueType.label:
      return null; // label은 값이 없어 텍스트 편집 대상이 아니다.
  }
}

String _quote(String value) =>
    '"${value.replaceAll('"', '""')}"';

/// 쌍따옴표로 감싼 값들을 콤마로 가른다. 따옴표 밖의 콤마에서만 자르고, 따옴표
/// 안의 `""`는 한 개의 따옴표로 되돌린다. 따옴표 없이 쓴 조각도 그대로 받는다.
List<String> _splitQuotedCsv(String text) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var inQuote = false;
  var i = 0;
  while (i < text.length) {
    final ch = text[i];
    if (inQuote) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          buffer.write('"');
          i += 2;
          continue;
        }
        inQuote = false;
        i++;
        continue;
      }
      buffer.write(ch);
      i++;
    } else {
      if (ch == '"') {
        inQuote = true;
        i++;
      } else if (ch == ',') {
        parts.add(buffer.toString());
        buffer.clear();
        i++;
      } else {
        buffer.write(ch);
        i++;
      }
    }
  }
  parts.add(buffer.toString());
  return parts;
}
