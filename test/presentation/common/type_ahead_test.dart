import 'package:filetagger/presentation/common/type_ahead.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextTypeAheadQuery', () {
    test('빈 검색어는 친 글자로 시작한다', () {
      expect(nextTypeAheadQuery('', 'a'), 'a');
    });

    test('다른 글자는 이어 붙인다', () {
      expect(nextTypeAheadQuery('a', 'b'), 'ab');
      expect(nextTypeAheadQuery('ab', 'c'), 'abc');
    });

    test('한 글자짜리 검색어에 같은 글자를 이어 치면 늘리지 않는다', () {
      // 늘리지 않아야 "그 글자로 시작하는 항목들을 차례로 돌기"가 된다.
      expect(nextTypeAheadQuery('a', 'a'), 'a');
      expect(nextTypeAheadQuery('a', 'A'), 'a');
    });

    test('두 글자 이상이면 같은 글자도 이어 붙인다', () {
      expect(nextTypeAheadQuery('ab', 'b'), 'abb');
    });
  });

  group('typeAheadSearchStart', () {
    test('한 글자 검색어는 다음 항목부터 훑는다', () {
      expect(typeAheadSearchStart('a', 3), 4);
    });

    test('두 글자 이상은 제자리부터 훑는다(맞으면 머문다)', () {
      expect(typeAheadSearchStart('ab', 3), 3);
    });

    test('커서가 없으면 처음부터', () {
      expect(typeAheadSearchStart('a', -1), 0);
      expect(typeAheadSearchStart('ab', -1), -1); // 음수는 검색이 0으로 본다
    });
  });

  group('findTypeAheadMatch', () {
    const names = ['apple', 'Banana', 'avocado', 'cherry'];

    test('시작 위치부터 훑어 첫 매치를 낸다', () {
      expect(findTypeAheadMatch(names, 'a', 0), 0);
      expect(findTypeAheadMatch(names, 'a', 1), 2);
    });

    test('끝에 닿으면 처음으로 돌아 한 바퀴를 다 돈다', () {
      expect(findTypeAheadMatch(names, 'a', 3), 0);
    });

    test('대소문자를 가리지 않는다', () {
      expect(findTypeAheadMatch(names, 'b', 0), 1);
      expect(findTypeAheadMatch(names, 'BAN', 0), 1);
    });

    test('시작이 아니라 가운데에 있는 글자는 맞지 않는다', () {
      expect(findTypeAheadMatch(names, 'nana', 0), isNull);
    });

    test('빈 이름은 결코 맞지 않는다(검색 대상이 아닌 자리)', () {
      expect(findTypeAheadMatch(const ['', 'a', ''], 'a', 0), 1);
      expect(findTypeAheadMatch(const ['', ''], 'a', 0), isNull);
    });

    test('빈 목록·빈 검색어·없는 이름은 null', () {
      expect(findTypeAheadMatch(const [], 'a', 0), isNull);
      expect(findTypeAheadMatch(names, '', 0), isNull);
      expect(findTypeAheadMatch(names, 'z', 0), isNull);
    });

    test('시작 위치가 음수거나 목록을 넘어도 셈이 무너지지 않는다', () {
      expect(findTypeAheadMatch(names, 'a', -1), 0);
      expect(findTypeAheadMatch(names, 'a', names.length), 0);
    });
  });

  group('이어 치기(세 규칙을 엮은 순서)', () {
    // 컨트롤러가 하는 일과 같은 조합. 세 함수를 따로 고치다 순서가 어긋나는 것을 막는다.
    const names = ['apple', 'apricot', 'avocado', 'banana'];
    ({String query, int? target}) type(String query, String ch, int current) {
      final next = nextTypeAheadQuery(query, ch);
      return (
        query: next,
        target: findTypeAheadMatch(
          names,
          next,
          typeAheadSearchStart(next, current),
        ),
      );
    }

    test('같은 글자를 이어 치면 그 글자로 시작하는 항목들을 차례로 돈다', () {
      var state = type('', 'a', -1);
      expect(state.target, 0);
      state = type(state.query, 'a', state.target!);
      expect(state.target, 1);
      state = type(state.query, 'a', state.target!);
      expect(state.target, 2);
      // 마지막 뒤에서는 처음으로 돌아온다(banana는 a로 시작하지 않는다).
      state = type(state.query, 'a', state.target!);
      expect(state.target, 0);
    });

    test('글자를 이어 치면 검색어가 좁혀지고, 맞는 동안은 제자리에 머문다', () {
      var state = type('', 'a', -1);
      expect(state.target, 0); // apple
      state = type(state.query, 'p', state.target!);
      expect(state.query, 'ap');
      expect(state.target, 0); // apple이 여전히 맞아 제자리
      state = type(state.query, 'r', state.target!);
      expect(state.query, 'apr');
      expect(state.target, 1); // apricot
    });

    test('맞는 것이 없으면 null이라 커서는 그대로다', () {
      final state = type('ap', 'z', 0);
      expect(state.query, 'apz');
      expect(state.target, isNull);
    });
  });

  group('TypeAheadController', () {
    const names = ['apple', 'banana', 'cherry'];

    ({ProviderContainer container, TypeAheadController controller}) open() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return (
        container: container,
        controller: container.read(typeAheadProvider.notifier),
      );
    }

    test('친 글자가 검색어로 남고 대상 인덱스를 낸다', () {
      final (:container, :controller) = open();
      expect(controller.type('b', names: names, current: -1), 1);
      expect(container.read(typeAheadProvider), 'b');
      controller.clear();
      expect(container.read(typeAheadProvider), '');
    });

    test('첫 글자로 친 공백은 받지 않는다(검색이 시작되지 않는다)', () {
      final (:container, :controller) = open();
      expect(controller.type(' ', names: names, current: -1), isNull);
      expect(container.read(typeAheadProvider), '');
    });

    test('이어 친 글자는 검색어를 좁힌다', () {
      final (:container, :controller) = open();
      controller.type('c', names: names, current: -1);
      expect(controller.type('h', names: names, current: 2), 2);
      expect(container.read(typeAheadProvider), 'ch');
      controller.clear();
    });
  });
}
