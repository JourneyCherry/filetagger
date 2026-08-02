import 'package:filetagger/domain/usecases/apply_external_commands.dart';
import 'package:filetagger/presentation/providers/command_queue_provider.dart';
import 'package:filetagger/presentation/providers/workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  LastCommandOutcomeNotifier notifier() =>
      container.read(lastCommandOutcomeProvider.notifier);

  ExternalCommandOutcome? shown() => container.read(lastCommandOutcomeProvider);

  test('아무 일도 없던 패스는 담지 않는다', () {
    notifier().record(const ExternalCommandOutcome());

    // 보류만 있는 패스도 마찬가지다 — 다음 패스가 처리할 것이라 알릴 일이 아니다.
    notifier().record(const ExternalCommandOutcome(held: 3));

    expect(shown(), isNull);
  });

  test('바뀐 것이 있으면 담고, 뒤이은 빈 패스가 지우지 않는다', () {
    notifier().record(const ExternalCommandOutcome(applied: 2, failed: 1));
    notifier().record(const ExternalCommandOutcome());

    // 표시가 깜빡이지 않도록 마지막 "무언가 있었던" 결과가 남는다.
    expect(shown()?.applied, 2);
    expect(shown()?.failed, 1);
  });

  test('워크스페이스를 닫거나 바꾸면 지난 결과를 버린다', () {
    container.read(workspaceRootProvider.notifier).state = '/ws/a';
    notifier().record(const ExternalCommandOutcome(applied: 2));

    container.read(workspaceRootProvider.notifier).state = '/ws/b';

    // 열린 워크스페이스의 것만 보여야 한다.
    expect(shown(), isNull);
  });
}
