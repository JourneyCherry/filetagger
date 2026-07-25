import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 명령 id가 카탈로그에 정확히 한 번씩 실린다', () {
    final ids = appCommands.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length, reason: '중복된 명령 정의가 있다');
    expect(ids.toSet(), AppCommandId.values.toSet(), reason: '누락/미등록 명령이 있다');
  });

  test('단축키가 명령 간에 겹치지 않는다', () {
    // commandShortcuts()는 activator를 키로 하는 Map이라 충돌 시 조용히 덮인다.
    // 단축키를 가진 명령 수와 맵 크기가 같아야 충돌이 없다.
    final withShortcut = appCommands.where((c) => c.shortcut != null).toList();
    expect(commandShortcuts().length, withShortcut.length,
        reason: '두 명령이 같은 단축키를 공유한다');
  });

  test('본문 포커스 전용 명령만 편집 키(Delete)를 단독으로 쓴다', () {
    // Delete·방향키·Enter처럼 텍스트 입력·버튼 기본동작과 겹치는 키는 스코프
    // 포커스 게이트를 반드시 통과해야 입력을 가로채지 않는다.
    for (final c in appCommands) {
      final s = c.shortcut;
      if (s == null) continue;
      final bare = !s.control && !s.meta && !s.alt;
      if (bare && s.trigger == LogicalKeyboardKey.delete) {
        expect(c.requiresScopeFocus, isTrue,
            reason: '${c.id}: 단독 Delete는 본문 포커스 전용이어야 한다');
      }
    }
  });
}
