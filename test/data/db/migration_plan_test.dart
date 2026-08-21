import 'package:drift/drift.dart';
import 'package:filetagger/data/db/app_database.dart';
import 'package:filetagger/data/db/migration_plan.dart';
import 'package:flutter_test/flutter_test.dart';

/// 노드 종류가 들어오기 전, 폴더 여부를 불리언으로 담고 이미지 크기를 한 문자열로
/// 합쳐 담던 모양.
const Set<String> _beforeNodeKind = {
  'id',
  'path',
  'is_directory',
  'size',
  'modified_at',
  'content_hash_prefix',
  'manage_mode',
  'child_signature',
  'image_dimensions',
  'last_seen_at',
  'missing_since',
};

/// 노드 종류가 막 들어와, 그 뒤에 생긴 컬럼은 아직 없던 모양.
const Set<String> _afterNodeKind = {
  'id',
  'path',
  'kind',
  'size',
  'modified_at',
  'content_hash_prefix',
  'manage_mode',
  'child_signature',
  'image_dimensions',
  'last_seen_at',
  'missing_since',
};

/// 이미지 크기를 가르기 직전, 나머지는 다 갖춰진 모양.
const Set<String> _beforeSplitDimensions = {
  'id',
  'path',
  'kind',
  'size',
  'modified_at',
  'content_hash_prefix',
  'manage_mode',
  'child_signature',
  'child_file_count',
  'image_dimensions',
  'last_seen_at',
  'missing_since',
};

/// 합쳐 담겼던 옛 이미지 크기를 가르는 변환 — 모든 재작성 단계가 함께 건다.
const Map<String, String> _dimensionSources = {
  'image_width': 'image_dimensions',
  'image_height': 'image_dimensions',
};

/// 재작성 단계들이 거는 변환(코드의 단계 순서와 같다).
const List<Map<String, String>> _rewriteSteps = [
  {'kind': 'is_directory', ..._dimensionSources},
  {'kind': 'kind', ..._dimensionSources},
  _dimensionSources,
];

void main() {
  // 실행기는 건드리지 않는다 — 컬럼 정의만 읽으므로 DB를 열 일이 없다
  // (호스트 sqlite3 의존 회피).
  final db = AppDatabase(_UnopenedExecutor());
  final target = db.fileNodes.$columns.map((column) => column.name).toSet();
  final required = db.fileNodes.$columns
      .where((column) => column.requiredDuringInsert)
      .map((column) => column.name)
      .toSet();

  /// 재작성 단계들을 [from] 모양에서부터 차례로 돌린다. 재작성은 새 테이블을 지금의
  /// 정의로 만들므로, 한 번 거치고 나면 모양은 언제나 [target]이 된다.
  ///
  /// 어디서부터 도는지는 DB에 적힌 버전이 정한다 — 이미 지난 단계는 건너뛰므로
  /// [firstStep]으로 그 자리를 고른다.
  List<TableRewritePlan> runChain(Set<String> from, {int firstStep = 0}) {
    var onDisk = from;
    final plans = <TableRewritePlan>[];
    for (final sources in _rewriteSteps.skip(firstStep)) {
      plans.add(
        planTableRewrite(
          onDisk: onDisk,
          target: target,
          transformSources: sources,
        ),
      );
      onDisk = target;
    }
    return plans;
  }

  group('노드 종류 도입 이전 모양에서 출발할 때', () {
    test('그 뒤에 생긴 컬럼을 옛 테이블에서 읽지 않는다', () {
      final first = runChain(_beforeNodeKind).first;

      // 이 셋이 복사 목록에 들면 없는 컬럼을 읽어 그 자리에서 마이그레이션이 끊긴다.
      expect(
        first.newColumns,
        containsAll(['child_file_count', 'image_width', 'image_height']),
      );
      expect(first.copied, isNot(contains('child_file_count')));
    });

    test('폴더 여부를 종류로 옮긴다', () {
      expect(
        runChain(_beforeNodeKind).first.transformed['kind'],
        'is_directory',
      );
    });

    test('합쳐 담긴 이미지 크기를 첫 재작성에서 갈라 담는다', () {
      // 첫 재작성이 옛 컬럼을 떨어뜨리므로, 여기서 안 가르면 값이 사라진다.
      final plans = runChain(_beforeNodeKind);

      expect(
        plans.first.transformed,
        containsPair('image_width', 'image_dimensions'),
      );
      expect(
        plans.first.transformed,
        containsPair('image_height', 'image_dimensions'),
      );
      // 뒤 단계는 이미 갈라 담긴 값을 그대로 옮기기만 한다.
      expect(plans.last.copied, containsAll(['image_width', 'image_height']));
    });

    test('옛 모양에만 있던 컬럼은 옮기지 않는다', () {
      final first = runChain(_beforeNodeKind).first;

      expect(first.copied, isNot(contains('is_directory')));
      expect(first.copied, isNot(contains('image_dimensions')));
    });
  });

  group('노드 종류가 막 들어온 모양에서 출발할 때', () {
    // 이 모양은 종류를 옮기는 단계를 이미 지났으므로 그 다음 재작성부터 돈다.
    List<TableRewritePlan> chain() => runChain(_afterNodeKind, firstStep: 1);

    test('그 뒤에 생긴 컬럼을 옛 테이블에서 읽지 않는다', () {
      expect(chain().first.newColumns, contains('child_file_count'));
      expect(chain().first.copied, isNot(contains('child_file_count')));
    });

    test('종류는 이미 들어와 있어 옛 이름만 손본다', () {
      expect(chain().first.transformed['kind'], 'kind');
    });

    test('합쳐 담긴 이미지 크기를 그 자리에서 갈라 담는다', () {
      expect(
        chain().first.transformed,
        containsPair('image_width', 'image_dimensions'),
      );
    });
  });

  group('이미지 크기를 가르기 직전 모양에서 출발할 때', () {
    // 앞선 재작성은 모두 지났고 크기를 가르는 단계만 남았다.
    List<TableRewritePlan> chain() =>
        runChain(_beforeSplitDimensions, firstStep: 2);

    test('합쳐 담긴 옛 컬럼을 읽어 가른다', () {
      expect(
        chain().single.transformed,
        containsPair('image_width', 'image_dimensions'),
      );
      expect(
        chain().single.newColumns,
        containsAll(['image_width', 'image_height']),
      );
    });

    test('나머지는 이름 그대로 옮긴다', () {
      expect(chain().single.copied, contains('kind'));
      expect(chain().single.copied, contains('child_file_count'));
    });
  });

  group('재작성만 앞서 끝나고 버전이 뒤에 남은 모양에서 출발할 때', () {
    test('단계를 다시 돌아도 바뀌는 것이 없다', () {
      for (final plan in runChain(target)) {
        expect(plan.newColumns, isEmpty);
        expect(plan.leftEmpty, isEmpty);
      }
    });

    test('이미 사라진 옛 컬럼을 읽지 않고, 갈라 담긴 값도 지우지 않는다', () {
      // 없는 컬럼을 읽으면 실패하고, 빈 값으로 덮으면 멀쩡한 크기가 지워진다.
      for (final plan in runChain(target)) {
        expect(plan.transformed.values, isNot(contains('image_dimensions')));
        expect(plan.copied, containsAll(['image_width', 'image_height']));
      }
    });
  });

  group('어느 모양에서 출발해도 수렴한다', () {
    test('비워 두는 컬럼은 널을 허용하는 것뿐이다', () {
      // 널을 허용하지 않는 컬럼이 비워지면 재작성 자체가 성립하지 않는다. 뒤에 그런
      // 컬럼이 추가되면 여기서 걸린다.
      const starts = {
        _beforeNodeKind: 0,
        _afterNodeKind: 1,
        _beforeSplitDimensions: 2,
      };
      for (final entry in starts.entries) {
        for (final plan in runChain(entry.key, firstStep: entry.value)) {
          expect(plan.leftEmpty.intersection(required), isEmpty);
        }
      }
      // 버전만 뒤에 남아 단계를 처음부터 다시 도는 경우까지 본다.
      for (final plan in runChain(target)) {
        expect(plan.leftEmpty.intersection(required), isEmpty);
      }
    });
  });

  group('변환식이 읽을 옛 컬럼이 없을 때', () {
    test('같은 이름 컬럼이 있으면 복사로 물러선다', () {
      final plan = planTableRewrite(
        onDisk: {'a', 'b'},
        target: {'a', 'b'},
        transformSources: {'a': 'gone'},
      );

      expect(plan.transformed, isEmpty);
      expect(plan.copied, {'a', 'b'});
    });

    test('같은 이름 컬럼도 없으면 비워 둔다', () {
      final plan = planTableRewrite(
        onDisk: {'b'},
        target: {'a', 'b'},
        transformSources: {'a': 'gone'},
      );

      expect(plan.newColumns, {'a'});
      expect(plan.leftEmpty, {'a'});
    });
  });
}

/// 열리지 않는 실행기. 컬럼 정의만 읽는 테스트라 질의가 나갈 일이 없고, 나간다면
/// 그것 자체가 테스트의 잘못이므로 곧바로 터뜨린다.
class _UnopenedExecutor implements QueryExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('마이그레이션 계획 테스트는 DB를 열지 않는다');
}
