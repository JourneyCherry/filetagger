import 'package:args/args.dart';
import 'package:filetagger/cli/query_options.dart';
import 'package:filetagger/domain/entities/file_filter.dart';
import 'package:filetagger/domain/entities/file_grouping.dart';
import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/domain/entities/tag_definition.dart';
import 'package:filetagger/domain/entities/tag_value_type.dart';
import 'package:filetagger/domain/usecases/filter_query_text.dart';
import 'package:filetagger/domain/usecases/group_query_text.dart';
import 'package:filetagger/domain/usecases/sort_query_text.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:filetagger/l10n/system_tag_names.dart';
import 'package:flutter_test/flutter_test.dart';

const String _locale = 'ko';

final List<TagDefinition> _definitions = [
  const TagDefinition(id: 1, name: '작가', valueType: TagValueType.text),
  const TagDefinition(id: 2, name: '별점', valueType: TagValueType.number),
  ...systemTagLookupDefinitions(_locale),
];

QuerySpec _resolve(List<String> args) {
  final parser = ArgParser();
  addFilterOption(parser, consoleStringsFor(_locale));
  addSortGroupOptions(parser, consoleStringsFor(_locale));
  return resolveQuery(
    parser.parse(args),
    definitions: _definitions,
    localeName: _locale,
  );
}

void main() {
  group('읽지 못한 조각', () {
    test('조건에 오타가 있으면 통째로 거부한다', () {
      final spec = _resolve(['--filter', '없는태그==1']);

      // 조용히 버리면 고르는 집합이 뒤집힌 채 명령이 돈다.
      expect(spec, isA<QueryUnreadable>());
      expect((spec as QueryUnreadable).problems.single, contains('없는태그'));
    });

    test('어긋난 조각이 어느 옵션의 것인지 말한다', () {
      final spec = _resolve(['--sort', '없는태그']);

      expect((spec as QueryUnreadable).problems.single, contains('--sort'));
    });

    test('성한 조각이 섞여 있어도 거부한다', () {
      final spec = _resolve(['--filter', '작가==김 없는태그']);

      expect(spec, isA<QueryUnreadable>());
    });
  });

  group('선 조건', () {
    test('주지 않은 조건은 비어 있다', () {
      final spec = _resolve([]) as QueryResolved;

      expect(spec.filter.isEmpty, isTrue);
      expect(spec.sort.isEmpty, isTrue);
      expect(spec.grouping.isEmpty, isTrue);
      // 조건이 빈 것과 아예 주지 않은 것은 다르다 — 앞은 "전부", 뒤는 "다른 방법으로
      // 지목한다"는 뜻이다.
      expect(spec.hasFilter, isFalse);
    });

    test('빈 조건을 주면 전부를 뜻한다', () {
      final spec = _resolve(['--filter', '']) as QueryResolved;

      expect(spec.filter.isEmpty, isTrue);
      expect(spec.hasFilter, isTrue);
    });

    test('태그 조건이 정의 id로 풀린다', () {
      final spec = _resolve(['--filter', '작가==김']) as QueryResolved;

      expect(spec.filter.conditions.single.tagDefinitionId, 1);
    });

    test('정렬은 적은 차례를 지킨다', () {
      final spec = _resolve(['--sort', '별점 작가']) as QueryResolved;

      expect([for (final k in spec.sort.keys) k.tagDefinitionId], [2, 1]);
    });
  });

  group('시스템 태그', () {
    test('조건이 시스템 태그를 이름으로 짚는다', () {
      final name = systemTagNamesFor(_locale)[SystemTag.extension]!;

      final spec = _resolve(['--filter', '$name==jpg']) as QueryResolved;

      // 이것이 서지 않으면 콘솔의 필터는 반만 도는 셈이다.
      expect(
        spec.filter.conditions.single.tagDefinitionId,
        SystemTag.extension.id,
      );
    });

    test('다른 언어로 적힌 이름도 읽는다', () {
      final english = systemTagNamesFor('en')[SystemTag.extension]!;

      final spec = _resolve(['--filter', '$english==jpg']) as QueryResolved;

      // 남이 적어 준 스크립트가 어느 언어로 쓰였는지 알 수 없다.
      expect(
        spec.filter.conditions.single.tagDefinitionId,
        SystemTag.extension.id,
      );
    });
  });

  group('폴더 계층', () {
    /// 이름에 공백이 있으면 조건 문법의 인용이 필요하다(화면이 캡슐을 되펼칠 때 쓰는
    /// 것과 같은 토큰).
    String token() => groupTagToken(
      folderHierarchyDefinition(folderHierarchyNameFor(_locale)),
    );

    test('그룹에서는 폴더 계층 키가 선다', () {
      final spec = _resolve(['--group', token()]) as QueryResolved;

      expect(spec.grouping.hasFolderHierarchy, isTrue);
      expect(spec.grouping.keys.single, isA<FolderHierarchyGroupKey>());
    });

    test('필터에서는 폴더 계층이 태그로 풀리지 않는다', () {
      final spec = _resolve(['--filter', token()]);

      // 풀리면 있지도 않은 태그를 가리키는 조건이 조용히 선다.
      expect(spec, isA<QueryUnreadable>());
    });
  });

  group('이름의 공백', () {
    test('인용하면 여러 낱말짜리 이름도 한 조각이다', () {
      final name = systemTagNamesFor(_locale)[SystemTag.modifiedTime]!;

      final spec =
          _resolve(['--filter', '"$name">2026-01-01']) as QueryResolved;

      expect(
        spec.filter.conditions.single.tagDefinitionId,
        SystemTag.modifiedTime.id,
      );
    });

    test('인용하지 않으면 낱말마다 조각이 되어 어긋난다', () {
      final name = systemTagNamesFor(_locale)[SystemTag.modifiedTime]!;

      // 화면의 조건 줄과 같은 문법이라, 공백이 든 이름은 콘솔에서도 인용해야 한다.
      expect(_resolve(['--filter', name]), isA<QueryUnreadable>());
    });
  });

  group('문법 안내', () {
    final help = filterHelpText(
      consoleStringsFor(_locale),
      localeName: _locale,
    );

    test('연산자 토큰을 하나도 빠뜨리지 않는다', () {
      // 안내가 토큰 표에서 뽑아 쓰는지를 지킨다 — 손으로 적기 시작하면 문법을
      // 고쳤을 때 안내만 옛것으로 남는다.
      for (final op in FilterOperator.values) {
        final token = filterOperatorToken(op);
        if (token == null) continue;
        expect(help, contains(token));
      }
    });

    test('제외·정렬 방향·별칭도 코드가 쥔 기호 그대로 낸다', () {
      expect(help, contains(kFilterExcludePrefix));
      expect(help, contains(kSortDescendingPrefix));
      expect(help, contains(kSortRandomPrefix));
      for (final alias in filterOperatorAliases.keys) {
        expect(help, contains(alias));
      }
    });

    test('폴더 계층 키를 그 언어의 이름으로 낸다', () {
      expect(help, contains(folderHierarchyNameFor(_locale)));
    });
  });
}
