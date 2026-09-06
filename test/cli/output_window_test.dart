import 'package:args/args.dart';
import 'package:filetagger/cli/output_window.dart';
import 'package:filetagger/l10n/console_strings.dart';
import 'package:flutter_test/flutter_test.dart';

final ConsoleStrings _strings = consoleStringsFor(consoleTemplateLanguageCode);

const List<int> _five = [1, 2, 3, 4, 5];

WindowSpec _resolve(List<String> args) {
  final parser = ArgParser();
  addWindowOptions(parser, _strings);
  return resolveWindow(parser.parse(args), _strings);
}

List<T> _window<T>(List<String> args, List<T> items) =>
    (_resolve(args) as WindowResolved).window.apply(items);

void main() {
  group('앞에서 자르기', () {
    test('센 만큼 앞에서 낸다', () {
      expect(_window(['--top', '2'], _five), [1, 2]);
    });

    test('있는 것보다 많이 달라 해도 오류가 아니다', () {
      // 목록의 길이는 부르는 쪽이 미리 알 수 없다 — 못 맞혔다고 명령이 실패하면
      // 스크립트가 늘 개수를 먼저 세어야 한다.
      expect(_window(['--top', '99'], _five), _five);
    });
  });

  group('뒤에서 자르기', () {
    test('센 만큼 뒤에서 낸다', () {
      expect(_window(['--tail', '2'], _five), [4, 5]);
    });

    test('있는 것보다 많이 달라 해도 전부를 낸다', () {
      expect(_window(['--tail', '99'], _five), _five);
    });
  });

  group('범위', () {
    test('1부터 세고 양끝을 포함한다', () {
      expect(_window(['--range', '2:4'], _five), [2, 3, 4]);
    });

    test('끝이 목록을 넘어가면 있는 데까지만 낸다', () {
      expect(_window(['--range', '4:99'], _five), [4, 5]);
    });

    test('시작이 목록을 넘어가면 아무것도 내지 않는다', () {
      expect(_window(['--range', '9:12'], _five), isEmpty);
    });

    test('끝이 시작보다 앞이면 아무것도 내지 않는다', () {
      expect(_window(['--range', '4:2'], _five), isEmpty);
    });

    test('한 자리만 가리킬 수 있다', () {
      expect(_window(['--range', '3:3'], _five), [3]);
    });
  });

  group('잘못 쓴 것', () {
    test('둘을 겹쳐 쓸 수 없다', () {
      // 조용히 한쪽을 고르면 나오지 않은 결과의 이유를 짚을 수 없다.
      expect(_resolve(['--top', '1', '--tail', '1']), isA<WindowUnreadable>());
    });

    test('범위 꼴이 아니면 거부한다', () {
      expect(_resolve(['--range', '3']), isA<WindowUnreadable>());
      expect(_resolve(['--range', '1:2:3']), isA<WindowUnreadable>());
    });

    test('1 미만은 거부한다', () {
      // "아무것도 내지 마라"를 옵션으로 적는 것은 뜻이 없다 — 오타로 본다.
      expect(_resolve(['--top', '0']), isA<WindowUnreadable>());
      expect(_resolve(['--tail', '-1']), isA<WindowUnreadable>());
      expect(_resolve(['--range', '0:2']), isA<WindowUnreadable>());
    });

    test('숫자가 아니면 거부한다', () {
      expect(_resolve(['--top', '두개']), isA<WindowUnreadable>());
    });
  });

  test('아무것도 주지 않으면 자르지 않는다', () {
    expect(_window(<String>[], _five), _five);
  });

  test('빈 목록은 어떤 창으로도 비어 있다', () {
    for (final args in const [
      ['--top', '3'],
      ['--tail', '3'],
      ['--range', '1:3'],
    ]) {
      expect(_window(args, const <int>[]), isEmpty, reason: args.join(' '));
    }
  });
}
