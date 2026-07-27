import 'package:filetagger/domain/entities/system_tag.dart';
import 'package:filetagger/presentation/commands/app_commands.dart';
import 'package:filetagger/presentation/help_topics.dart';
import 'package:filetagger/presentation/usage_tips.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('기능·단축키 표', () {
    test('모든 명령이 정확히 한 묶음에만 실린다', () {
      // 도움말은 카탈로그에서 라벨·단축키를 읽지만 묶음 배치는 손으로 적으므로,
      // 명령을 추가하고 도움말에 넣는 것을 잊으면 여기서 잡힌다.
      final listed = [for (final group in helpCommandGroups) ...group.commands];
      expect(listed.toSet().length, listed.length, reason: '두 묶음에 실린 명령이 있다');
      expect(
        listed.toSet(),
        AppCommandId.values.toSet(),
        reason: '도움말에서 빠졌거나 없는 명령을 가리키는 항목이 있다',
      );
    });

    test('묶음 제목이 비어 있지 않다', () {
      for (final group in helpCommandGroups) {
        expect(group.title.trim(), isNotEmpty);
        expect(group.commands, isNotEmpty, reason: '${group.title}: 빈 묶음');
      }
    });
  });

  group('개념 설명', () {
    test('제목·본문이 비어 있지 않다', () {
      expect(helpTopics, isNotEmpty);
      for (final topic in helpTopics) {
        expect(topic.title.trim(), isNotEmpty);
        expect(topic.body.trim(), isNotEmpty);
      }
    });
  });

  group('시스템 태그 설명', () {
    test('모든 시스템 태그에 설명이 있다', () {
      for (final tag in SystemTag.values) {
        expect(systemTagDescription(tag).trim(), isNotEmpty, reason: tag.name);
      }
    });

    test('설명이 서로 겹치지 않는다', () {
      final texts = [for (final t in SystemTag.values) systemTagDescription(t)];
      expect(texts.toSet().length, texts.length, reason: '복사해 붙인 설명이 있다');
    });
  });

  group('사용 팁', () {
    test('제목·본문이 비어 있지 않고 제목이 겹치지 않는다', () {
      expect(usageTips, isNotEmpty);
      for (final tip in usageTips) {
        expect(tip.title.trim(), isNotEmpty);
        expect(tip.body.trim(), isNotEmpty);
      }
      final titles = usageTips.map((t) => t.title).toList();
      expect(titles.toSet().length, titles.length);
    });

    test('팁이 가리키는 명령은 카탈로그에 있다', () {
      // commandOf는 없는 id에서 던진다. 명령을 지워도 팁이 조용히 깨지지 않게 잡는다.
      for (final tip in usageTips) {
        final id = tip.command;
        if (id == null) continue;
        expect(() => commandOf(id), returnsNormally, reason: tip.title);
      }
    });
  });
}
