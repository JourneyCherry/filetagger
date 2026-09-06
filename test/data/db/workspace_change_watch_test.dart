import 'package:filetagger/data/db/workspace_change_watch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<int?> versions;
  late int notified;

  /// 값을 [versions]에서 하나씩 꺼내 주는 감시. 다 떨어지면 마지막 값을 그대로 준다
  /// (실제 DB도 아무도 고치지 않으면 같은 값을 계속 낸다).
  WorkspaceChangeWatch watch() {
    var i = 0;
    return WorkspaceChangeWatch(
      readVersion: () async {
        final value = versions[i < versions.length - 1 ? i++ : i];
        return value;
      },
      onChanged: () => notified++,
    );
  }

  setUp(() => notified = 0);

  test('처음 본 값은 기준일 뿐 변경이 아니다', () async {
    versions = [7];
    final w = watch();

    await w.checkNow();

    // 폴더를 연 순간을 남이 고친 것으로 읽으면 열 때마다 헛되이 다시 묻는다.
    expect(notified, 0);
  });

  test('값이 그대로면 알리지 않는다', () async {
    versions = [7, 7, 7];
    final w = watch();

    await w.checkNow();
    await w.checkNow();
    await w.checkNow();

    expect(notified, 0);
  });

  test('값이 달라지면 그때 한 번 알린다', () async {
    versions = [7, 8, 8];
    final w = watch();

    await w.checkNow();
    await w.checkNow();
    await w.checkNow();

    expect(notified, 1);
  });

  test('값을 읽지 못해도 기준을 잃지 않는다', () async {
    // 폴더를 닫는 중이라 연결이 없을 수 있다. 그때 기준을 비우면 다음 확인이 그것을
    // 첫 값으로 보아 **실제 변경을 놓친다**.
    versions = [7, null, 8];
    final w = watch();

    await w.checkNow();
    await w.checkNow();
    await w.checkNow();

    expect(notified, 1);
  });

  test('멈췄다 다시 시작해도 본 값을 이어 쓴다', () async {
    versions = [7, 8];
    final w = watch();
    await w.checkNow();

    w.pause();
    expect(w.isRunning, isFalse);
    await w.checkNow();

    expect(notified, 1);
    w.dispose();
  });
}
