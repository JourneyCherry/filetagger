import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/queue/command_queue_store.dart';
import '../../data/queue/file_command_environment.dart';
import '../../data/watcher/command_queue_watcher.dart';
import '../../domain/repositories/command_queue_repository.dart';
import '../../domain/usecases/apply_external_commands.dart';
import 'file_node_provider.dart';
import 'tag_provider.dart';
import 'workspace_provider.dart';

/// 현재 워크스페이스의 드롭인 큐 저장소. 열린 폴더가 없으면 null.
final commandQueueRepositoryProvider = Provider<CommandQueueRepository?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null) return null;
  return FileCommandQueueStore(root);
});

/// 큐 적용 유즈케이스. 저장소가 하나라도 없으면(폴더 미개방) null.
final applyExternalCommandsProvider = Provider<ApplyExternalCommands?>((ref) {
  final root = ref.watch(workspaceRootProvider);
  final queue = ref.watch(commandQueueRepositoryProvider);
  final nodes = ref.watch(fileNodeRepositoryProvider);
  final tags = ref.watch(tagRepositoryProvider);
  if (root == null || queue == null || nodes == null || tags == null) {
    return null;
  }
  return ApplyExternalCommands(
    queue: queue,
    nodes: nodes,
    tags: tags,
    environment: FileCommandEnvironment(root),
  );
});

/// 큐 폴더만 보는 감시자. 워크스페이스 감시자와 **다른 스트림**이며, 이 신호는
/// 재스캔이 아니라 큐 처리로 간다(자세한 이유는 [CommandQueueWatcher]).
final commandQueueChangesProvider = StreamProvider<void>((ref) {
  final root = ref.watch(workspaceRootProvider);
  if (root == null) return const Stream.empty();
  return const CommandQueueWatcher().watch(root);
});

/// 무언가 바뀐 마지막 큐 패스의 결과. 상태표시줄이 이것만 조용히 표시한다.
///
/// 성공을 다이얼로그로 알리지 않는 대칭을 지키면서도, **사용자가 하지 않은 태그
/// 변경**과 **조용한 실패**는 알 수 있어야 해서 두는 최소한이다. 아무 일도 없던
/// 패스는 담지 않아(직전 결과가 그대로 남는다) 표시가 깜빡이지 않는다.
class LastCommandOutcomeNotifier extends Notifier<ExternalCommandOutcome?> {
  @override
  ExternalCommandOutcome? build() {
    // 워크스페이스를 닫거나 바꾸면 지난 결과를 버린다 — 열린 워크스페이스의 것만 보인다.
    ref.watch(workspaceRootProvider);
    return null;
  }

  void record(ExternalCommandOutcome outcome) {
    if (outcome.applied == 0 && outcome.failed == 0) return;
    state = outcome;
  }
}

final lastCommandOutcomeProvider =
    NotifierProvider<LastCommandOutcomeNotifier, ExternalCommandOutcome?>(
      LastCommandOutcomeNotifier.new,
    );
