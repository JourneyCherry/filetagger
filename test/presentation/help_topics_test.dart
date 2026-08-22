import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:filetagger/presentation/help_topics.dart';
import 'package:filetagger/presentation/usage_tips.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/l10n.dart';

void main() {
  group('기능·단축키 표', () {
    test('모든 명령이 정확히 한 묶음에만 실린다', () {
      // 도움말은 카탈로그에서 라벨·단축키를 읽지만 묶음 배치는 손으로 적으므로,
      // 명령을 추가하고 도움말에 넣는 것을 잊으면 여기서 잡힌다.
      final listed = [
        for (final group in helpCommandGroupsOf(koL10n)) ...group.commands,
      ];
      expect(listed.toSet().length, listed.length, reason: '두 묶음에 실린 명령이 있다');
      expect(
        listed.toSet(),
        AppCommandId.values.toSet(),
        reason: '도움말에서 빠졌거나 없는 명령을 가리키는 항목이 있다',
      );
    });
  });

  // 아래 검사는 **지원하는 모든 언어**에서 돈다. 번역이 빠진 키는 원문으로 되돌아가
  // 화면이 깨지지는 않지만, 언어를 늘렸을 때 어느 글월이 비었는지는 여기서 잡힌다.
  for (final l10n in allL10n) {
    final tag = l10n.localeName;

    group('묶음 제목 · $tag', () {
      test('제목이 비어 있지 않고 묶음도 비지 않는다', () {
        for (final group in helpCommandGroupsOf(l10n)) {
          expect(group.title.trim(), isNotEmpty);
          expect(group.commands, isNotEmpty, reason: '${group.title}: 빈 묶음');
        }
      });
    });

    group('탭 이름 · $tag', () {
      test('탭마다 이름이 있고 서로 겹치지 않는다', () {
        final labels = [for (final t in HelpTab.values) t.label(l10n)];
        for (final label in labels) {
          expect(label.trim(), isNotEmpty);
        }
        expect(labels.toSet().length, labels.length);
      });
    });

    group('개념 설명 · $tag', () {
      test('제목·본문이 비어 있지 않고 제목이 겹치지 않는다', () {
        final topics = helpTopicsOf(l10n);
        expect(topics, isNotEmpty);
        for (final topic in topics) {
          expect(topic.title.trim(), isNotEmpty);
          expect(topic.body.trim(), isNotEmpty);
        }
        final titles = [for (final t in topics) t.title];
        expect(titles.toSet().length, titles.length);
      });
    });

    group('시스템 태그 설명 · $tag', () {
      test('모든 시스템 태그에 설명이 있다', () {
        for (final t in SystemTag.values) {
          expect(
            systemTagDescription(l10n, t).trim(),
            isNotEmpty,
            reason: t.name,
          );
        }
      });

      test('설명이 서로 겹치지 않는다', () {
        final texts = [
          for (final t in SystemTag.values) systemTagDescription(l10n, t),
        ];
        expect(texts.toSet().length, texts.length, reason: '복사해 붙인 설명이 있다');
      });
    });

    group('사용 팁 · $tag', () {
      test('제목·본문이 비어 있지 않고 제목이 겹치지 않는다', () {
        final tips = usageTipsOf(l10n);
        expect(tips, isNotEmpty);
        for (final tip in tips) {
          expect(tip.title.trim(), isNotEmpty);
          expect(tip.body.trim(), isNotEmpty);
        }
        final titles = [for (final t in tips) t.title];
        expect(titles.toSet().length, titles.length);
      });

      test('팁이 가리키는 명령은 카탈로그에 있다', () {
        // commandOf는 없는 id에서 던진다. 명령을 지워도 팁이 조용히 깨지지 않게 잡는다.
        for (final tip in usageTipsOf(l10n)) {
          final id = tip.command;
          if (id == null) continue;
          expect(() => commandOf(id), returnsNormally, reason: tip.title);
        }
      });
    });

    group('명령 라벨 · $tag', () {
      test('명령마다 라벨이 있고 서로 겹치지 않는다', () {
        // 라벨이 겹치면 메뉴·도움말에서 어느 조작인지 가릴 수 없다.
        final labels = [for (final c in appCommands) c.label(l10n)];
        for (final label in labels) {
          expect(label.trim(), isNotEmpty);
        }
        expect(labels.toSet().length, labels.length, reason: '라벨이 겹치는 명령이 있다');
      });
    });
  }
}
