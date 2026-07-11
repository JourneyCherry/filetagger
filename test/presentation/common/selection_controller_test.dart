import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:filetagger/presentation/common/selection_controller.dart';

void main() {
  late ProviderContainer container;
  SelectionController controller() =>
      container.read(selectionControllerProvider.notifier);
  SelectionState state() => container.read(selectionControllerProvider);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('초기 상태는 비어 있다', () {
    expect(state().isEmpty, isTrue);
    expect(state().anchorId, isNull);
  });

  test('단일 선택은 하나만 남기고 앵커로 삼는다', () {
    controller().selectSingle(1);
    controller().selectSingle(2);
    expect(state().selectedIds, {2});
    expect(state().anchorId, 2);
    expect(state().singleOrNull, 2);
  });

  test('토글은 개별 추가/제거하고 앵커를 옮긴다', () {
    controller()
      ..selectSingle(1)
      ..toggle(2)
      ..toggle(3);
    expect(state().selectedIds, {1, 2, 3});
    controller().toggle(2);
    expect(state().selectedIds, {1, 3});
    expect(state().anchorId, 2);
  });

  test('범위 선택은 앵커~대상 사이를 표시 순서로 채운다', () {
    final order = [10, 20, 30, 40, 50];
    controller().selectSingle(20); // 앵커=20
    controller().selectRange(order, 40);
    expect(state().selectedIds, {20, 30, 40});
    expect(state().anchorId, 20); // 앵커 유지

    // 역방향도 같은 구간.
    controller().selectRange(order, 10);
    expect(state().selectedIds, {10, 20});
    expect(state().anchorId, 20);
  });

  test('앵커가 없거나 목록에서 사라지면 범위는 단일 선택으로 대체된다', () {
    controller().selectRange([1, 2, 3], 2); // 앵커 없음
    expect(state().selectedIds, {2});
    expect(state().anchorId, 2);
  });

  test('전체 선택은 표시 순서 전부, 앵커는 마지막', () {
    controller().selectAll([3, 1, 2]);
    expect(state().selectedIds, {1, 2, 3});
    expect(state().anchorId, 2);
    controller().selectAll(const []);
    expect(state().isEmpty, isTrue);
  });

  test('해제는 선택과 앵커를 모두 비운다', () {
    controller()
      ..selectSingle(1)
      ..clear();
    expect(state().isEmpty, isTrue);
    expect(state().anchorId, isNull);
  });
}
