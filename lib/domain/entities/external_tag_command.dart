import 'tag_value_type.dart';

/// 외부 앱(브라우저 확장·스크립트 등)이 드롭인 큐에 떨궈 둔 명령 하나.
///
/// 큐 항목은 **파일 하나에 명령 하나**이며, 앱은 스캔이 끝난 뒤 이를 읽어 적용한다.
/// 성공한 항목은 파일째 지우고, 실패한 항목은 그 자리에 [CommandFailure]를 적어
/// 둔다 — 외부 앱은 자기가 만든 경로를 그대로 다시 읽어 원인을 알 수 있고, 다시
/// 시도하려면 그 필드 없이 같은 파일을 덮어쓰면 된다.
///
/// 이 엔티티는 **표현**일 뿐 유효성을 판정하지 않는다. 대상 노드·태그 정의를 실제로
/// 찾아보는 판정(시스템 태그 제외, 값 유형 대조, 없는 태그 처리 등)은 적용 유즈케이스가
/// 한다 — 여기서 알 수 있는 것은 형식뿐이다.
class ExternalTagCommand {
  const ExternalTagCommand({
    required this.targetPath,
    required this.tagName,
    this.operation = ExternalCommandOperation.add,
    this.value,
    this.missingTag = MissingTagPolicy.fail,
    this.createValueType,
    this.targetKind = ExternalNodeKind.file,
    this.valueKind = ExternalNodeKind.file,
    this.missingKeyword = MissingKeywordPolicy.fail,
    this.missingLink = MissingLinkPolicy.fail,
    this.createAllowMultiple,
    this.createColor,
  });

  /// 대상의 **워크스페이스 루트 기준 상대 경로**(또는 [targetKind]가 키워드면 그
  /// 키워드의 이름). 절대 경로를 쓰지 않는 이유는 관리 폴더가 통째로 이동·복사되기
  /// 때문이다(그때 절대 경로는 모두 깨진다).
  ///
  /// 디스크 노드를 지목하는 수단은 이 경로뿐이다 — 크기·해시 같은 대조 필드를 두지
  /// 않는다. 그 대가로 "지워진 파일 자리에 생긴 새 파일에 태그가 붙는" 오적용은
  /// 감수한다.
  final String targetPath;

  /// 태그를 **이름으로** 지목한다. 외부 앱은 DB의 정의 id를 알 수 없다.
  final String tagName;

  final ExternalCommandOperation operation;

  /// 태그값. 값 없는 태그(label)이거나 태그 전체를 제거할 때는 null이다.
  ///
  /// 해석은 태그의 값 유형에 달렸고 적용 시점에 이뤄진다 — 특히 image는 **외부
  /// 이미지 파일의 경로**(앱이 캐시에 등록해 캐시 키로 바꾼다), link는 **대상의
  /// 워크스페이스 상대 경로**(앱이 노드 id로 해석한다)다. 외부 앱은 캐시 키도 노드
  /// id도 모르기 때문이다.
  final String? value;

  /// 지목한 이름의 태그가 없을 때의 처리. **전역 설정이 아니라 명령별**로 가르는
  /// 이유는, 규율 있는 확장과 아무 확장이 한 워크스페이스에 섞일 수 있어서다.
  final MissingTagPolicy missingTag;

  /// [MissingTagPolicy.create]로 태그를 만들 때 쓸 값 유형. 기본값을 두지 않는
  /// 이유는 오타 하나가 유령 태그를 만들기 때문이다(없으면 생성이 실패한다).
  ///
  /// 태그가 이미 있다면 대조에 쓰인다 — 다르면 강제 변환하지 않고 실패한다.
  final TagValueType? createValueType;

  /// [targetPath]를 무엇으로 읽을지. 키워드는 디스크에 없어 경로로 지목할 수 없으므로,
  /// 경로와 이름을 가르는 판별이 필요하다(생략하면 경로).
  final ExternalNodeKind targetKind;

  /// link 값([value])이 가리키는 대상을 무엇으로 읽을지. **[targetKind]와 따로 두는
  /// 이유**는 둘이 대개 다르기 때문이다 — 그림 **파일**에 작가 **키워드**를 링크로
  /// 거는 것이 이 값의 주 용도다.
  final ExternalNodeKind valueKind;

  /// 지목한 키워드가 없을 때의 처리. 대상([targetPath])과 링크 값 **양쪽에 함께**
  /// 적용된다 — 두 자리에서 뜻이 같아 필드를 나눌 이유가 없다.
  final MissingKeywordPolicy missingKeyword;

  /// link 값이 가리키는 대상을 찾지 못했을 때의 처리. [missingKeyword]와 자리가
  /// 겹치지 않는다 — 그쪽은 "없으면 만들까"이고 이쪽은 **만들지 않기로 한 뒤**
  /// "그래도 값을 남길까"라, 키워드 링크에서는 생성이 먼저 판정되고 이 정책이 뒤를
  /// 받는다. 파일 링크에는 생성이라는 선택지가 없어 이 정책만 걸린다.
  final MissingLinkPolicy missingLink;

  /// [MissingTagPolicy.create]로 태그를 만들 때의 다중 부여 허용. null이면 단일값
  /// 태그로 만든다.
  ///
  /// **적으면 그대로 존중한다** — 오타가 유령 태그를 만드는 것을 막는 가드는 "필드를
  /// 안 받는 것"이 아니라 [createValueType]처럼 "기본값을 두지 않는 것"이다. 받지
  /// 않으면 다중값 태그를 내보내 되받을 때 값 여럿이 마지막 하나로 조용히 접힌다
  /// (단일값 태그는 재부여가 갱신이므로).
  final bool? createAllowMultiple;

  /// [MissingTagPolicy.create]로 태그를 만들 때의 표시 색상(ARGB). null이면 미지정.
  final int? createColor;

  @override
  bool operator ==(Object other) =>
      other is ExternalTagCommand &&
      other.targetPath == targetPath &&
      other.tagName == tagName &&
      other.operation == operation &&
      other.value == value &&
      other.missingTag == missingTag &&
      other.createValueType == createValueType &&
      other.targetKind == targetKind &&
      other.valueKind == valueKind &&
      other.missingKeyword == missingKeyword &&
      other.missingLink == missingLink &&
      other.createAllowMultiple == createAllowMultiple &&
      other.createColor == createColor;

  @override
  int get hashCode => Object.hash(
    targetPath,
    tagName,
    operation,
    value,
    missingTag,
    createValueType,
    targetKind,
    valueKind,
    missingKeyword,
    missingLink,
    createAllowMultiple,
    createColor,
  );
}

/// 외부 명령이 노드를 지목하는 방식.
///
/// 앱 안의 [NodeKind]와 이름을 맞추되 **별개의 열거**다 — 이쪽은 공개 계약이라
/// 내부 열거를 고쳐도 형식이 따라 흔들리면 안 되고, 파일과 폴더를 가르지도 않는다.
enum ExternalNodeKind {
  /// 워크스페이스 루트 기준 상대 경로로 찾는다(기본값).
  file,

  /// [file]과 같다. 인덱스는 경로 하나로 파일·폴더를 함께 찾으므로 앱은 둘을
  /// 구분하지 않지만, 외부 앱이 뜻을 적어 두고 싶을 때를 위해 받는다.
  directory,

  /// 키워드의 **이름**으로 찾는다.
  keyword,
}

/// 지목한 키워드가 없을 때 어떻게 할지.
enum MissingKeywordPolicy {
  /// 만들지 않고 실패로 남긴다(기본값).
  fail,

  /// 그 이름의 키워드를 만들어 진행한다. 키워드는 이름이 전부라 만들 때 더 받을
  /// 것이 없다.
  create,
}

/// link 값이 가리키는 대상을 찾지 못했을 때 어떻게 할지.
enum MissingLinkPolicy {
  /// 부여하지 않고 실패로 남긴다(기본값 — 오타 난 경로가 조용히 값으로 굳지 않게).
  fail,

  /// 적어 보낸 원문(상대 경로·키워드 이름)을 값으로 두고 **미해결 링크**로 표시한다
  /// ([TagAssignment.valueUnresolved]). 태그 묶음을 통째로 옮길 때 대상이 아직(또는
  /// 영영) 없는 링크를 버리지 않기 위한 것 — 버리면 사용자가 나중에 재연결할 기회가
  /// 사라진다.
  keep,
}

/// 큐에 들어 있는 명령 하나와, 그것을 다시 가리킬 손잡이.
///
/// [id]가 무엇인지는 저장 구현이 정한다 — 도메인은 "성공했으니 지워라 / 실패했으니
/// 표식을 남겨라"를 이 손잡이로만 지시한다.
class QueuedCommand {
  const QueuedCommand({required this.id, required this.command});

  final String id;
  final ExternalTagCommand command;
}

/// 명령이 태그 부여에 가하는 조작.
///
/// 다중 부여를 허용하지 않는 태그에서는 [add]와 [replace]가 같은 결과가 된다
/// (부여 저장소가 upsert로 처리한다). 둘을 가르는 것은 다중값 태그다.
///
/// 이름으로 저장해 값 순서가 바뀌어도 영향받지 않는다(태그 유형 저장과 같은 원칙).
enum ExternalCommandOperation {
  /// 값을 부여한다. 다중값 태그면 기존 값을 남긴 채 하나 더 붙는다.
  add,

  /// 그 태그의 기존 부여를 모두 걷어내고 이 값 하나로 둔다.
  replace,

  /// 부여를 제거한다. 값을 주면 그 값의 부여만, 주지 않으면 그 태그의 부여 전부.
  remove,
}

/// 지목한 이름의 태그가 워크스페이스에 없을 때 어떻게 할지.
enum MissingTagPolicy {
  /// 만들지 않고 실패로 남긴다(기본값 — 오타가 유령 태그가 되지 않게).
  fail,

  /// 명령이 지정한 값 유형으로 태그를 만들어 진행한다.
  create,
}

/// 앱이 큐 파일에 적어 두는 실패 표식. 외부 앱은 쓰지 않는 자리다.
///
/// 표식이 있는 항목은 이후 패스에서 적용을 건너뛴다 — 같은 실패를 앱이 켜질 때마다
/// 되풀이하지 않기 위함이다.
class CommandFailure {
  const CommandFailure({required this.reason, required this.at, this.message});

  final CommandFailureReason reason;

  /// 표식을 적은 시각.
  ///
  /// 보존 정리(오래된 실패 항목 삭제)가 파일 수정 시각이 아니라 이 값을 보는 이유는,
  /// 큐가 복사·이관되면(중첩 워크스페이스 흡수 등) 파일 시각이 갈리기 때문이다.
  final DateTime at;

  /// 사유만으로는 짚이지 않는 세부(어느 값이 어긋났는지 등). 사람이 읽는 용도이며
  /// 외부 앱이 분기 판단에 쓰라고 두는 것은 [reason]이다.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is CommandFailure &&
      other.reason == reason &&
      other.at == at &&
      other.message == message;

  @override
  int get hashCode => Object.hash(reason, at, message);
}

/// 큐 항목이 적용되지 못한 이유. 외부 앱이 기계적으로 분기할 수 있도록 이름으로
/// 저장한다(값 순서 변경에 영향받지 않는다).
///
/// **"보류"는 여기 없다** — 디스크에는 있는데 인덱스에만 없는 대상(스캔이 아직 잡지
/// 못한 순간)은 표식 없이 다음 패스로 넘긴다. 실패로 적으면 이후 건너뛰므로 경합
/// 한 번이 영구 실패로 굳는다.
enum CommandFailureReason {
  /// 항목을 명령으로 읽지 못했다(JSON이 아니거나, 필수 필드가 없거나, 모르는 이름).
  malformed,

  /// 대상 경로가 디스크에 없다. 외부 앱은 파일을 먼저 쓴 뒤 큐에 넣기로 약속되어
  /// 있으므로, 곧 나타나기를 기다리지 않고 즉시 실패로 본다.
  ///
  /// 키워드 대상도 이 사유를 쓴다. 키워드는 앱이 만들어야만 존재하므로 **기다릴 경합이
  /// 없어 보류가 아예 없다** — 없으면(그리고 [MissingKeywordPolicy.create]도 아니면)
  /// 곧바로 실패다.
  targetMissing,

  /// 디스크에는 있으나 관리 범위 밖이라(불투명 폴더 안 등) 인덱스에 들어올 수 없다.
  targetNotManaged,

  /// 시스템 태그는 외부 조작 대상이 아니다 — 자동 파생이고, 이름 태그는 편집이
  /// 디스크 rename이라 큐가 파일을 옮기는 통로가 된다.
  systemTag,

  /// 그 이름의 태그가 없고 명령이 [MissingTagPolicy.create]도 아니다.
  tagMissing,

  /// 태그를 만들어야 하는데 값 유형이 없거나 모르는 이름이다.
  valueTypeMissing,

  /// 이미 있는 태그의 값 유형이 명령이 요구한 것과 다르다(강제 변환하지 않는다).
  valueTypeMismatch,

  /// 값을 태그의 값 유형으로 해석하지 못했다(숫자·날짜 형식, 없는 이미지 파일,
  /// 가리키는 노드가 없는 링크 등).
  invalidValue,
}
