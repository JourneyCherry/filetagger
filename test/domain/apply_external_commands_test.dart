import 'package:filetagger/domain/entities/assigned_tag.dart';
import 'package:filetagger/domain/entities/external_tag_command.dart';
import 'package:filetagger/domain/entities/file_node.dart';
import 'package:filetagger/domain/entities/node_kind.dart';
import 'package:filetagger/domain/entities/folder_manage_mode.dart';
import 'package:filetagger/domain/entities/tag_assignment.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/repositories/command_environment.dart';
import 'package:filetagger/domain/repositories/command_queue_repository.dart';
import 'package:filetagger/domain/repositories/file_node_repository.dart';
import 'package:filetagger/domain/repositories/tag_repository.dart';
import 'package:filetagger/domain/usecases/apply_external_commands.dart';
import 'package:filetagger/domain/usecases/keyword_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeQueue queue;
  late _FakeNodes nodes;
  late _FakeTags tags;
  late _FakeEnv env;

  ApplyExternalCommands applier() => ApplyExternalCommands(
    queue: queue,
    nodes: nodes,
    tags: tags,
    environment: env,
    now: () => DateTime(2026, 8, 1),
  );

  /// 루트에 파일 하나(`a.png`)만 있는 워크스페이스.
  void withSingleFile() {
    nodes.index['a.png'] = const FileNode(
      id: 1,
      path: 'a.png',
      kind: NodeKind.file,
    );
    env.onDisk.add('a.png');
  }

  void enqueue(ExternalTagCommand command, {String id = 'q1'}) =>
      queue.pending.add(QueuedCommand(id: id, command: command));

  setUp(() {
    queue = _FakeQueue();
    nodes = _FakeNodes();
    tags = _FakeTags();
    env = _FakeEnv();
  });

  group('부여·수정·제거', () {
    setUp(() {
      withSingleFile();
      tags.define('작가', TagValueType.text, allowMultiple: true);
    });

    test('부여하고 큐에서 지운다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '홍길동',
        ),
      );

      final outcome = await applier()();

      expect(outcome.applied, 1);
      expect(tags.valuesOf(1, '작가'), ['홍길동']);
      expect(queue.removed, ['q1']);
      expect(queue.marked, isEmpty);
    });

    test('이미 같은 값이 붙어 있으면 아무것도 쓰지 않는다', () async {
      tags.assign(1, '작가', '홍길동');
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '홍길동',
        ),
      );

      final outcome = await applier()();

      // 외부 앱의 재시도가 다중값 태그에 중복을 쌓지 않아야 한다.
      expect(outcome.applied, 1);
      expect(tags.valuesOf(1, '작가'), ['홍길동']);
      expect(tags.writes, 0);
    });

    test('수정은 기존 값을 모두 걷어내고 하나로 둔다', () async {
      tags.assign(1, '작가', '홍길동');
      tags.assign(1, '작가', '임꺽정');
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          operation: ExternalCommandOperation.replace,
          value: '장길산',
        ),
      );

      await applier()();

      expect(tags.valuesOf(1, '작가'), ['장길산']);
    });

    test('제거는 값을 주면 그 값만, 주지 않으면 통째로', () async {
      tags.assign(1, '작가', '홍길동');
      tags.assign(1, '작가', '임꺽정');
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          operation: ExternalCommandOperation.remove,
          value: '홍길동',
        ),
      );

      await applier()();
      expect(tags.valuesOf(1, '작가'), ['임꺽정']);

      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          operation: ExternalCommandOperation.remove,
        ),
        id: 'q2',
      );

      await applier()();
      expect(tags.valuesOf(1, '작가'), isEmpty);
    });
  });

  group('없는 태그', () {
    setUp(withSingleFile);

    test('기본은 만들지 않고 실패로 남긴다', () async {
      enqueue(const ExternalTagCommand(targetPath: 'a.png', tagName: '작가'));

      final outcome = await applier()();

      expect(outcome.failed, 1);
      expect(queue.marked['q1']?.reason, CommandFailureReason.tagMissing);
      expect(tags.definitions, isEmpty);
    });

    test('생성 타입인데 값 유형이 없으면 만들지 않는다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          missingTag: MissingTagPolicy.create,
        ),
      );

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.valueTypeMissing);
      expect(tags.definitions, isEmpty);
    });

    test('생성 타입이고 값 유형이 있으면 만들어 부여한다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '홍길동',
          missingTag: MissingTagPolicy.create,
          createValueType: TagValueType.text,
        ),
      );

      final outcome = await applier()();

      expect(outcome.applied, 1);
      expect(tags.definitions['작가']?.valueType, TagValueType.text);
      expect(tags.valuesOf(1, '작가'), ['홍길동']);
    });

    test('기존 태그의 값 유형이 다르면 강제 변환하지 않고 실패한다', () async {
      tags.define('작가', TagValueType.text);
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '3',
          missingTag: MissingTagPolicy.create,
          createValueType: TagValueType.number,
        ),
      );

      await applier()();

      expect(
        queue.marked['q1']?.reason,
        CommandFailureReason.valueTypeMismatch,
      );
      expect(tags.definitions['작가']?.valueType, TagValueType.text);
    });

    test('시스템 태그 이름은 대상이 아니다', () async {
      // 특히 '파일 이름'은 편집이 디스크 rename이라 큐가 파일을 옮기는 통로가 된다.
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '파일 이름',
          value: 'b.png',
          missingTag: MissingTagPolicy.create,
          createValueType: TagValueType.text,
        ),
      );

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.systemTag);
      expect(tags.definitions, isEmpty);
    });
  });

  group('대상 해석', () {
    setUp(() => tags.define('읽음', TagValueType.label));

    test('디스크에 없으면 기다리지 않고 즉시 실패다', () async {
      enqueue(const ExternalTagCommand(targetPath: 'a.png', tagName: '읽음'));

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.targetMissing);
    });

    test('디스크엔 있고 인덱스에만 없으면 손대지 않고 보류한다', () async {
      env.onDisk.add('a.png');
      enqueue(const ExternalTagCommand(targetPath: 'a.png', tagName: '읽음'));

      final outcome = await applier()();

      // 실패로 적으면 이후 건너뛰므로 경합 한 번이 영구 실패로 굳는다.
      expect(outcome.held, 1);
      expect(queue.marked, isEmpty);
      expect(queue.removed, isEmpty);
    });

    test('관리 범위 밖이면 기다려도 소용없으므로 실패다', () async {
      // 루트가 '직속만 관리'라 하위 폴더는 불투명 — 그 안은 인덱싱되지 않는다.
      nodes.index['box'] = const FileNode(
        id: 9,
        path: 'box',
        kind: NodeKind.directory,
      );
      env.onDisk.add('box/a.png');
      enqueue(const ExternalTagCommand(targetPath: 'box/a.png', tagName: '읽음'));

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.targetNotManaged);
    });

    test('연결 끊김으로 보존된 노드는 대상이 아니다', () async {
      nodes.index['a.png'] = FileNode(
        id: 1,
        path: 'a.png',
        kind: NodeKind.file,
        missingSince: DateTime(2026),
      );
      enqueue(const ExternalTagCommand(targetPath: 'a.png', tagName: '읽음'));

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.targetMissing);
    });

    test('구분자·군더더기가 섞인 경로도 찾고, 루트 밖은 형식 오류다', () async {
      withSingleFile();
      enqueue(const ExternalTagCommand(targetPath: r'.\a.png', tagName: '읽음'));
      enqueue(
        const ExternalTagCommand(targetPath: '../a.png', tagName: '읽음'),
        id: 'q2',
      );

      await applier()();

      expect(queue.removed, ['q1']);
      expect(queue.marked['q2']?.reason, CommandFailureReason.malformed);
    });
  });

  group('값 해석', () {
    setUp(withSingleFile);

    test('숫자로 읽히지 않는 값은 실패다', () async {
      tags.define('점수', TagValueType.number);
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '점수',
          value: '다섯',
        ),
      );

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.invalidValue);
    });

    test('날짜는 저장 형식으로 정규화한다', () async {
      tags.define('발매일', TagValueType.date);
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '발매일',
          value: '2026-07-04T13:30:00',
        ),
      );

      await applier()();

      // 날짜 태그는 시각을 담지 않는다.
      expect(tags.valuesOf(1, '발매일'), [DateTime(2026, 7, 4).toIso8601String()]);
    });

    test('링크는 대상의 상대 경로를 노드 id로 바꾼다', () async {
      nodes.index['b.png'] = const FileNode(
        id: 7,
        path: 'b.png',
        kind: NodeKind.file,
      );
      tags.define('다음 화', TagValueType.link);
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '다음 화',
          value: 'b.png',
        ),
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '다음 화',
          value: 'zzz.png',
        ),
        id: 'q2',
      );

      await applier()();

      expect(tags.valuesOf(1, '다음 화'), ['7']);
      expect(queue.marked['q2']?.reason, CommandFailureReason.invalidValue);
    });

    test('missingLink: keep이면 없는 대상의 경로를 미해결로 남긴다', () async {
      tags.define('다음 화', TagValueType.link);
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '다음 화',
          value: './없는/zzz.png',
          missingLink: MissingLinkPolicy.keep,
        ),
      );

      await applier()();

      expect(queue.marked, isEmpty);
      // 원문은 인덱스 키와 같은 꼴로 정리해 둔다 — 나중에 그 경로가 생기면 사람이
      // 눈으로 짝을 맞출 수 있다.
      expect(tags.valuesOf(1, '다음 화'), ['없는/zzz.png']);
      expect(tags.unresolvedOf(1, '다음 화'), [isTrue]);
    });

    test('미해결로 남긴 뒤 다시 같은 명령이 와도 덧쓰지 않는다', () async {
      tags.define('다음 화', TagValueType.link);
      const command = ExternalTagCommand(
        targetPath: 'a.png',
        tagName: '다음 화',
        value: 'zzz.png',
        missingLink: MissingLinkPolicy.keep,
      );
      enqueue(command);
      await applier()();
      final writes = tags.writes;

      enqueue(command, id: 'q2');
      await applier()();

      expect(tags.writes, writes);
      expect(tags.valuesOf(1, '다음 화'), ['zzz.png']);
    });

    test('이미지는 외부 경로를 캐시 키로 바꾸고, 등록에 실패하면 실패다', () async {
      env.images['/밖/cover.png'] = 'cafe01';
      tags.define('표지', TagValueType.image);
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '표지',
          value: '/밖/cover.png',
        ),
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '표지',
          value: '/밖/없음.png',
        ),
        id: 'q2',
      );

      await applier()();

      expect(tags.valuesOf(1, '표지'), ['cafe01']);
      expect(queue.marked['q2']?.reason, CommandFailureReason.invalidValue);
    });

    test('이미지 제거는 값을 등록하지 않고 태그를 통째로 뗀다', () async {
      tags.define('표지', TagValueType.image);
      tags.assign(1, '표지', 'cafe01');
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '표지',
          operation: ExternalCommandOperation.remove,
          value: '/밖/cover.png',
        ),
      );

      await applier()();

      // 저장값이 불투명한 해시라 외부 앱은 지울 값을 지목할 수 없다.
      expect(tags.valuesOf(1, '표지'), isEmpty);
      expect(env.registered, isEmpty);
    });
  });

  group('키워드 대상', () {
    setUp(() {
      withSingleFile();
      tags.define('국적', TagValueType.text);
    });

    test('이름으로 키워드를 찾아 태그를 붙인다', () async {
      nodes.keywords['작가 A'] = const FileNode(
        id: 50,
        path: '작가 A',
        kind: NodeKind.keyword,
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: '작가 A',
          targetKind: ExternalNodeKind.keyword,
          tagName: '국적',
          value: '일본',
        ),
      );

      await applier()();

      expect(tags.valuesOf(50, '국적'), ['일본']);
      expect(queue.removed, ['q1']);
    });

    test('같은 이름의 파일이 있어도 키워드를 지목한다(키 공간이 다르다)', () async {
      // 디스크에 '작가 A'라는 파일이 있고, 이름이 같은 키워드도 있다.
      nodes.index['작가 A'] = const FileNode(
        id: 3,
        path: '작가 A',
        kind: NodeKind.file,
      );
      env.onDisk.add('작가 A');
      nodes.keywords['작가 A'] = const FileNode(
        id: 50,
        path: '작가 A',
        kind: NodeKind.keyword,
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: '작가 A',
          targetKind: ExternalNodeKind.keyword,
          tagName: '국적',
          value: '일본',
        ),
      );

      await applier()();

      expect(tags.valuesOf(50, '국적'), ['일본']);
      expect(tags.valuesOf(3, '국적'), isEmpty);
    });

    test('없는 키워드는 기본적으로 즉시 실패다(보류가 아니다)', () async {
      // 키워드는 앱이 만들어야만 존재하므로 스캔과 경합할 일이 없다 — 기다릴 이유가
      // 없어 보류로 두지 않는다(보류는 표식이 없어 나이로도 지워지지 않는다).
      enqueue(
        const ExternalTagCommand(
          targetPath: '없는 작가',
          targetKind: ExternalNodeKind.keyword,
          tagName: '국적',
          value: '일본',
        ),
      );

      final outcome = await applier()();

      expect(outcome.held, 0);
      expect(queue.marked['q1']?.reason, CommandFailureReason.targetMissing);
      expect(nodes.createdKeywords, isEmpty);
    });

    test('missingKeyword: create면 본문 없이 만들어 진행한다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: '작가 B',
          targetKind: ExternalNodeKind.keyword,
          missingKeyword: MissingKeywordPolicy.create,
          tagName: '국적',
          value: '한국',
        ),
      );

      await applier()();

      expect(nodes.createdKeywords, ['작가 B']);
      expect(tags.valuesOf(100, '국적'), ['한국']);
      expect(queue.removed, ['q1']);
    });

    test('경로 구분자가 든 이름은 정규화하지 않고 형식 오류로 거절한다', () async {
      // 키워드 이름은 경로가 아니다 — 'a/작가'를 접어 받으면 뜻이 달라진다.
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a/작가',
          targetKind: ExternalNodeKind.keyword,
          missingKeyword: MissingKeywordPolicy.create,
          tagName: '국적',
          value: '일본',
        ),
      );

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.malformed);
      expect(nodes.createdKeywords, isEmpty);
    });

    test('키워드의 이름 시스템 태그도 외부에서 바꿀 수 없다', () async {
      nodes.keywords['작가 A'] = const FileNode(
        id: 50,
        path: '작가 A',
        kind: NodeKind.keyword,
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: '작가 A',
          targetKind: ExternalNodeKind.keyword,
          tagName: '파일 이름',
          value: '다른 이름',
        ),
      );

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.systemTag);
    });
  });

  group('키워드를 가리키는 링크 값', () {
    setUp(() {
      withSingleFile();
      tags.define('작가', TagValueType.link);
    });

    test('파일에 키워드를 링크로 걸 수 있다(대상과 값의 종류가 다르다)', () async {
      nodes.keywords['작가 A'] = const FileNode(
        id: 50,
        path: '작가 A',
        kind: NodeKind.keyword,
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '작가 A',
          valueKind: ExternalNodeKind.keyword,
        ),
      );

      await applier()();

      expect(tags.valuesOf(1, '작가'), ['50']);
    });

    test('링크 값의 키워드도 missingKeyword: create면 만들어 건다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '작가 B',
          valueKind: ExternalNodeKind.keyword,
          missingKeyword: MissingKeywordPolicy.create,
        ),
      );

      await applier()();

      expect(nodes.createdKeywords, ['작가 B']);
      expect(tags.valuesOf(1, '작가'), ['100']);
    });

    test('없는 키워드를 가리키면(기본 정책) 값 오류다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '없는 작가',
          valueKind: ExternalNodeKind.keyword,
        ),
      );

      await applier()();

      expect(queue.marked['q1']?.reason, CommandFailureReason.invalidValue);
      expect(nodes.createdKeywords, isEmpty);
    });

    test('missingLink: keep이면 키워드 이름을 원문 그대로 미해결로 남긴다', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '없는 작가',
          valueKind: ExternalNodeKind.keyword,
          missingLink: MissingLinkPolicy.keep,
        ),
      );

      await applier()();

      expect(queue.marked, isEmpty);
      expect(tags.valuesOf(1, '작가'), ['없는 작가']);
      expect(tags.unresolvedOf(1, '작가'), [isTrue]);
      // 생성은 missingKeyword가 정한다 — keep은 만들지 않고 남기기만 한다.
      expect(nodes.createdKeywords, isEmpty);
    });

    test('missingKeyword: create가 있으면 생성이 먼저다(미해결로 남지 않는다)', () async {
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: '작가 C',
          valueKind: ExternalNodeKind.keyword,
          missingKeyword: MissingKeywordPolicy.create,
          missingLink: MissingLinkPolicy.keep,
        ),
      );

      await applier()();

      expect(nodes.createdKeywords, ['작가 C']);
      expect(tags.unresolvedOf(1, '작가'), [isFalse]);
    });

    test('valueKind를 주지 않으면 예전처럼 경로로 읽는다', () async {
      nodes.index['b.png'] = const FileNode(
        id: 7,
        path: 'b.png',
        kind: NodeKind.file,
      );
      nodes.keywords['b.png'] = const FileNode(
        id: 60,
        path: 'b.png',
        kind: NodeKind.keyword,
      );
      enqueue(
        const ExternalTagCommand(
          targetPath: 'a.png',
          tagName: '작가',
          value: 'b.png',
        ),
      );

      await applier()();

      // 판별이 없으면 경로 — 이름이 같은 키워드가 있어도 파일을 가리킨다.
      expect(tags.valuesOf(1, '작가'), ['7']);
    });
  });

  test('루트가 재귀 관리면 하위 폴더 안도 대상이 된다', () async {
    nodes.index['box'] = const FileNode(
      id: 9,
      path: 'box',
      kind: NodeKind.directory,
    );
    nodes.index['box/a.png'] = const FileNode(
      id: 10,
      path: 'box/a.png',
      kind: NodeKind.file,
    );
    env.onDisk.add('box/a.png');
    tags.define('읽음', TagValueType.label);
    enqueue(const ExternalTagCommand(targetPath: 'box/a.png', tagName: '읽음'));

    final outcome = await applier()(
      rootManageMode: FolderManageMode.managedRecursive,
    );

    expect(outcome.applied, 1);
    expect(tags.valuesOf(10, '읽음'), [null]);
  });
}

// ── 가짜 저장소 ──

class _FakeQueue implements CommandQueueRepository {
  final List<QueuedCommand> pending = [];
  final List<String> removed = [];
  final Map<String, CommandFailure> marked = {};

  /// [commit]이 불린 횟수. 패스가 결과를 반영하고 끝나는지 확인한다.
  int commits = 0;

  @override
  Future<List<QueuedCommand>> takePending() async {
    final taken = [...pending];
    pending.clear();
    return taken;
  }

  @override
  Future<void> markApplied(String id) async => removed.add(id);

  @override
  Future<void> markFailed(String id, CommandFailure failure) async {
    marked[id] = failure;
  }

  @override
  Future<void> commit() async => commits++;
}

class _FakeNodes implements FileNodeRepository {
  final Map<String, FileNode> index = {};
  final Map<String, FileNode> keywords = {};

  /// 만들어 준 키워드에 붙일 다음 id(실제 저장소의 autoIncrement 대역).
  int nextKeywordId = 100;

  /// `createKeyword`가 실제로 불린 이름들(정책이 지켜지는지 확인용).
  final List<String> createdKeywords = [];

  @override
  Future<Map<String, FileNode>> indexByPath() async => index;

  @override
  Future<Map<String, FileNode>> keywordIndexByName() async => keywords;

  @override
  Future<({FileNode? node, KeywordNameError? error})> createKeyword(
    String name,
  ) async {
    createdKeywords.add(name);
    final node = FileNode(
      id: nextKeywordId++,
      path: name,
      kind: NodeKind.keyword,
    );
    keywords[name] = node;
    return (node: node, error: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeEnv implements CommandEnvironment {
  final Set<String> onDisk = {};

  /// 외부 이미지 경로 → 등록되면 돌려줄 캐시 키.
  final Map<String, String> images = {};
  final List<String> registered = [];

  @override
  Future<bool> targetExists(String relPath) async => onDisk.contains(relPath);

  @override
  Future<String?> registerImage(String externalPath) async {
    registered.add(externalPath);
    return images[externalPath];
  }
}

class _FakeTags implements TagRepository {
  final Map<String, TagDefinition> definitions = {};
  final List<TagAssignment> assignments = [];

  /// 부여를 실제로 바꾼 횟수(멱등 확인용).
  int writes = 0;
  int _nextId = 1;

  void define(String name, TagValueType type, {bool allowMultiple = false}) {
    definitions[name] = TagDefinition(
      id: _nextId++,
      name: name,
      valueType: type,
      allowMultiple: allowMultiple,
    );
  }

  void assign(int fileNodeId, String name, String? value) {
    assignments.add(
      TagAssignment(
        id: _nextId++,
        fileNodeId: fileNodeId,
        tagDefinitionId: definitions[name]!.id!,
        value: value,
      ),
    );
  }

  List<String?> valuesOf(int fileNodeId, String name) => [
    for (final a in assignments)
      if (a.fileNodeId == fileNodeId &&
          a.tagDefinitionId == definitions[name]?.id)
        a.value,
  ];

  List<bool> unresolvedOf(int fileNodeId, String name) => [
    for (final a in assignments)
      if (a.fileNodeId == fileNodeId &&
          a.tagDefinitionId == definitions[name]?.id)
        a.valueUnresolved,
  ];

  @override
  Future<TagDefinition?> definitionByName(String name) async =>
      definitions[name];

  @override
  Future<TagDefinition> createDefinition({
    required String name,
    required TagValueType valueType,
    int? color,
    required bool allowMultiple,
  }) async {
    define(name, valueType, allowMultiple: allowMultiple);
    return definitions[name]!;
  }

  @override
  Future<List<AssignedTag>> assignmentsOfFile(int fileNodeId) async => [
    for (final a in assignments)
      if (a.fileNodeId == fileNodeId)
        AssignedTag(
          assignment: a,
          definition: definitions.values.firstWhere(
            (d) => d.id == a.tagDefinitionId,
          ),
        ),
  ];

  @override
  Future<void> assignToFiles({
    required List<int> fileNodeIds,
    required int tagDefinitionId,
    String? value,
    bool valueUnresolved = false,
  }) async {
    writes++;
    final def = definitions.values.firstWhere((d) => d.id == tagDefinitionId);
    for (final fileNodeId in fileNodeIds) {
      if (!def.allowMultiple) {
        assignments.removeWhere(
          (a) =>
              a.fileNodeId == fileNodeId &&
              a.tagDefinitionId == tagDefinitionId,
        );
      }
      assignments.add(
        TagAssignment(
          id: _nextId++,
          fileNodeId: fileNodeId,
          tagDefinitionId: tagDefinitionId,
          value: value,
          valueUnresolved: valueUnresolved,
        ),
      );
    }
  }

  @override
  Future<void> unassign(int assignmentId) async {
    writes++;
    assignments.removeWhere((a) => a.id == assignmentId);
  }

  @override
  Future<void> unassignFromFiles({
    required List<int> fileNodeIds,
    required int tagDefinitionId,
  }) async {
    writes++;
    assignments.removeWhere(
      (a) =>
          fileNodeIds.contains(a.fileNodeId) &&
          a.tagDefinitionId == tagDefinitionId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
