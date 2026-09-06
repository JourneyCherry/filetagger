/// 표시 언어별로, **화면 밖에서도 필요한 이름**의 단일 출처.
///
/// **ARB가 아니라 여기 있는 이유**는 이름이 화면 밖에서도 쓰이기 때문이다. 외부에서
/// 들어온 명령은 태그를 이름으로 가리키는데, 그 앱이 어느 언어의 이름을 적었는지 알 수
/// 없어 **모든 언어의 시스템 태그 이름**과 대조해야 한다(그러지 않으면 다른 언어로 적힌
/// 시스템 태그 이름이 일반 태그로 새로 만들어진다). ARB에서 나온 문자열은 Flutter 위에서만
/// 얻을 수 있어, 콘솔 진입점이 같은 판정을 할 길이 없다.
///
/// 표시 쪽도 이 표를 그대로 읽으므로 출처가 갈라지지는 않는다. 언어를 더할 때 ARB와
/// 함께 여기도 채워야 하며, 빠뜨리면 테스트가 잡는다.
library;

import '../domain/entities/system_tag.dart';
import '../domain/entities/tag_definition.dart';

/// 템플릿 언어(l10n.yaml이 지목한 것과 같아야 한다). 모르는 언어를 만나면 이 언어의
/// 이름표로 되돌아간다.
const String _templateLanguageCode = 'ko';

const Map<String, Map<SystemTag, String>> _byLanguage = {
  'ko': {
    SystemTag.fileSize: '크기',
    SystemTag.modifiedTime: '수정 시각',
    SystemTag.extension: '확장자',
    SystemTag.imageWidth: '이미지 너비',
    SystemTag.imageHeight: '이미지 높이',
    SystemTag.aspectRatio: '화면비',
    SystemTag.fileName: '파일 이름',
    SystemTag.childFileCount: '내부 파일 수량',
    SystemTag.keyword: '키워드',
    SystemTag.unresolvedLink: '미해결 링크',
  },
  'en': {
    SystemTag.fileSize: 'Size',
    SystemTag.modifiedTime: 'Modified',
    SystemTag.extension: 'Extension',
    SystemTag.imageWidth: 'Image width',
    SystemTag.imageHeight: 'Image height',
    SystemTag.aspectRatio: 'Aspect ratio',
    SystemTag.fileName: 'File name',
    SystemTag.childFileCount: 'Files inside',
    SystemTag.keyword: 'Keyword',
    SystemTag.unresolvedLink: 'Unresolved link',
  },
};

/// [localeName]이 가리키는 언어의 이름표.
///
/// `언어_지역` 형태도 받아 **언어 부분만** 본다 — 시스템 태그 이름은 지역에 따라
/// 갈리지 않는다. 모르는 언어면 템플릿 언어의 이름표를 준다.
Map<SystemTag, String> systemTagNamesFor(String localeName) =>
    _byLanguage[_languageOf(localeName)] ?? _byLanguage[_templateLanguageCode]!;

/// 이름표를 가진 언어 코드들. 지원 언어 목록과 어긋나지 않는지 테스트가 대조한다.
Set<String> get systemTagNameLanguages => _byLanguage.keys.toSet();

/// 지원하는 모든 언어에서 시스템 태그를 가리키는 이름 전부.
///
/// 외부에서 들어온 명령이 이 중 하나를 태그 이름으로 쓰면 일반 태그를 새로 만들지
/// 않고 막는 데 쓴다.
final Set<String> allSystemTagNames = {
  for (final names in _byLanguage.values) ...names.values,
};

/// 그룹 키로 쓰는 폴더 계층의 이름. 화면은 ARB에서 같은 문구를 읽고, 이 표는 **ARB를
/// 볼 수 없는 콘솔**을 위해 둔다(둘이 어긋나면 테스트가 잡는다).
const Map<String, String> _folderHierarchyByLanguage = {
  'ko': '폴더 계층',
  'en': 'Folder hierarchy',
};

/// [localeName]이 가리키는 언어의 폴더 계층 이름.
String folderHierarchyNameFor(String localeName) =>
    _folderHierarchyByLanguage[_languageOf(localeName)] ??
    _folderHierarchyByLanguage[_templateLanguageCode]!;

/// [localeName]으로 이름 붙인 시스템 태그의 표시용 정의.
///
/// 화면은 번역본에서 같은 것을 만든다([systemTagDefinitionsByTag]) — 조립은
/// [systemTagDefinitionNamed] 하나에 모여 있어 모양이 갈리지 않는다.
Map<SystemTag, TagDefinition> systemTagDefinitionsFor(String localeName) {
  final names = systemTagNamesFor(localeName);
  return {
    for (final tag in SystemTag.values)
      tag: systemTagDefinitionNamed(tag, names[tag]!),
  };
}

/// 조건 텍스트에서 이름으로 시스템 태그를 찾을 때 쓰는 정의 목록.
///
/// **지원하는 모든 언어의 이름**이 들어 있다 — 콘솔에 치는 조건이나 남이 적어 준
/// 스크립트가 어느 언어로 쓰였는지 알 수 없기 때문이다. 표시 언어의 것을 **뒤에**
/// 두어, 언어끼리 이름이 겹치면 표시 언어가 이긴다(이름 표는 나중 것이 이긴다).
///
/// **폴더 계층 키는 여기 들지 않는다** — 그것은 그룹에만 있는 축이라 필터·정렬에서
/// 이름이 풀리면 있지도 않은 태그를 가리키는 조건이 조용히 서 버린다. 그룹 해석기가
/// 제 몫으로 따로 끼워 넣는다([parseGroupQuery]).
List<TagDefinition> systemTagLookupDefinitions(String localeName) {
  final language = _languageOf(localeName);
  return [
    for (final code in _byLanguage.keys)
      if (code != language) ...systemTagDefinitionsFor(code).values,
    ...systemTagDefinitionsFor(language).values,
  ];
}

String _languageOf(String localeName) => localeName.split(RegExp('[_-]')).first;
