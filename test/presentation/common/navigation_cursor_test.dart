import 'package:filetagger/presentation/common/navigation_cursor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stepNodeCursor', () {
    final ids = [10, 20, 30];

    test('빈 목록은 null', () {
      expect(stepNodeCursor(const [], 10, 1), isNull);
    });

    test('커서 없음: 아래로면 처음, 위로면 끝', () {
      expect(stepNodeCursor(ids, null, 1), 10);
      expect(stepNodeCursor(ids, null, -1), 30);
    });

    test('현재 위치에서 한 칸 이동', () {
      expect(stepNodeCursor(ids, 20, 1), 30);
      expect(stepNodeCursor(ids, 20, -1), 10);
    });

    test('끝에서 더 가려 하면 제자리', () {
      expect(stepNodeCursor(ids, 30, 1), 30);
      expect(stepNodeCursor(ids, 10, -1), 10);
    });

    test('목록에 없는 커서는 진입점으로 되돌린다', () {
      expect(stepNodeCursor(ids, 999, 1), 10);
      expect(stepNodeCursor(ids, 999, -1), 30);
    });
  });

  group('stepTagColumn', () {
    test('추가 슬롯 없음: 태그 사이만 오간다', () {
      // 태그 2개(0,1), 추가 슬롯 없음.
      expect(stepTagColumn(null, 2, false, 1), 0); // 진입
      expect(stepTagColumn(0, 2, false, 1), 1);
      expect(stepTagColumn(1, 2, false, 1), 1); // 마지막에서 멈춤
      expect(stepTagColumn(1, 2, false, -1), 0);
      expect(stepTagColumn(0, 2, false, -1), null); // 행 레벨로
      expect(stepTagColumn(null, 2, false, -1), null);
    });

    test('추가 슬롯 있음: 마지막 정지는 슬롯(=태그 수)', () {
      expect(stepTagColumn(1, 2, true, 1), 2); // 슬롯 진입
      expect(stepTagColumn(2, 2, true, 1), 2); // 슬롯에서 멈춤
      expect(stepTagColumn(2, 2, true, -1), 1); // 슬롯에서 태그로
    });

    test('태그 없음 + 추가 슬롯: 오른쪽이 슬롯(0), 왼쪽은 행 레벨', () {
      expect(stepTagColumn(null, 0, true, 1), 0);
      expect(stepTagColumn(0, 0, true, -1), null);
    });

    test('태그도 슬롯도 없으면 갈 곳이 없다', () {
      expect(stepTagColumn(null, 0, false, 1), null);
      expect(stepTagColumn(null, 0, false, -1), null);
    });
  });

  group('stepGridCursor', () {
    // 7개 항목, 한 줄 3칸 →  0 1 2 / 3 4 5 / 6
    const count = 7;
    const cols = 3;

    test('빈 격자는 -1', () {
      expect(stepGridCursor(-1, 0, cols, 1, horizontal: true), -1);
    });

    test('커서 없음: 진입점(오른쪽/아래=처음, 왼쪽/위=끝)', () {
      expect(stepGridCursor(-1, count, cols, 1, horizontal: true), 0);
      expect(stepGridCursor(-1, count, cols, -1, horizontal: true), count - 1);
    });

    test('가로: ±1 연속(줄 경계도 이어짐)', () {
      expect(stepGridCursor(2, count, cols, 1, horizontal: true), 3);
      expect(stepGridCursor(3, count, cols, -1, horizontal: true), 2);
      expect(stepGridCursor(6, count, cols, 1, horizontal: true), 6); // 끝
      expect(stepGridCursor(0, count, cols, -1, horizontal: true), 0);
    });

    test('세로: ±열수, 목록 밖이면 제자리', () {
      expect(stepGridCursor(1, count, cols, 1, horizontal: false), 4);
      expect(stepGridCursor(4, count, cols, -1, horizontal: false), 1);
      // 4 아래(7)는 범위 밖 → 제자리.
      expect(stepGridCursor(4, count, cols, 1, horizontal: false), 4);
      // 0 위는 범위 밖 → 제자리.
      expect(stepGridCursor(0, count, cols, -1, horizontal: false), 0);
    });
  });
}
