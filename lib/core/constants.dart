/// 프로젝트 전역에서 쓰이는 고정 이름들의 단일 출처.
///
/// 값 자체를 주석/문서에 중복 기재하지 않기 위해(컨벤션 2) 이름 상수는
/// 모두 이 파일에서만 정의한다.
library;

/// 사람에게 보이는 앱 이름(창 제목·정보 다이얼로그·라이선스 화면).
const String appDisplayName = 'File Tagger';

/// 앱 자신의 라이선스 원문(`LICENSE`) 에셋 경로.
///
/// 의존 패키지의 라이선스는 빌드가 자동으로 모으지만 앱 자신의 것은 실리지 않아,
/// 파일을 에셋으로 싣고 라이선스 목록에 직접 등록한다(원문은 그 파일이 단일 출처).
const String appLicenseAssetPath = 'LICENSE';

/// 릴리즈를 게시하는 GitHub 저장소(`소유자/이름`). 업데이트 확인이 이 저장소의
/// 최신 릴리즈를 조회하고, 새 버전이 있으면 그 릴리즈 페이지를 연다.
const String releaseRepositorySlug = 'JourneyCherry/filetagger';

/// 릴리즈 태그에 붙는 접두사. 조회한 태그에서 이걸 떼면 버전 문자열이 된다.
/// 태그를 만드는 릴리즈 워크플로가 같은 접두사를 쓴다.
const String releaseTagPrefix = 'v';

/// GitHub REST API의 응답 형식과 버전 핀. 버전을 고정해 두면 API가 바뀌어도
/// 이 앱의 조회 코드가 조용히 깨지지 않는다.
const String githubApiMediaType = 'application/vnd.github+json';
const String githubApiVersion = '2022-11-28';

/// Microsoft Store 제품 ID(스토어가 발급하는 Store ID).
///
/// **아직 등록 전이라 비어 있다.** 비어 있으면 스토어 링크를 내지 않고 안내만 한다.
/// 등록되면 이 한 줄만 채우면 된다.
const String microsoftStoreProductId = '';

/// Google Play 애플리케이션 ID. Microsoft Store 쪽과 같은 이유로 비어 있다.
const String googlePlayApplicationId = '';

/// 관리 폴더 루트에 생성되는 태그 메타데이터 폴더 이름.
///
/// 폴더 이동·복사 시 태그 DB가 함께 따라오도록 관리 폴더 안에 둔다.
/// 스캔 대상에서는 항상 제외된다.
const String filetaggerDirName = '.filetagger';

/// 태그 DB 파일 이름. [filetaggerDirName] 폴더 안에 생성된다.
const String databaseFileName = 'filetagger.sqlite';

/// 전역 설정(최근 연 폴더 목록 등 머신 단위 설정) 파일 이름.
///
/// 관리 폴더가 아니라 OS 앱데이터 폴더에 저장된다.
const String settingsFileName = 'settings.json';

/// 워크스페이스별 보기 설정(필터·정렬) 파일 이름.
///
/// [filetaggerDirName] 폴더 안에 저장되어 폴더 이동·복사 시 함께 따라온다.
const String viewSettingsFileName = 'view.json';

/// 워크스페이스별 조건 프리셋(이름 붙인 필터·정렬·그룹 한 벌) 파일 이름.
///
/// [filetaggerDirName] 폴더 안에 저장되어 폴더 이동·복사 시 함께 따라온다. 보기
/// 설정([viewSettingsFileName])과 파일을 가르는 이유는, 그쪽이 zoom·펼침처럼 잦은
/// 조작마다 통째로 다시 쓰이는 자리라 사용자가 손으로 만든 자산을 얹지 않기 위함이다.
const String queryPresetsFileName = 'presets.json';

/// 외부 앱이 명령 파일을 떨궈 두는 드롭인 큐 폴더 이름.
///
/// [filetaggerDirName] 폴더 안에 둔다 — 폴더 이동·복사 시 대기 중인 명령이 함께
/// 따라오고, 스캔 제외도 그대로 물려받는다. **항목당 파일 하나**이며 외부 앱은
/// 임시 이름으로 쓴 뒤 rename해 반쯤 쓰인 파일이 읽히지 않게 한다.
const String commandQueueDirName = 'queue';

/// 커스텀 이미지 태그가 등록한 외부 이미지의 캐시 폴더 이름.
///
/// [filetaggerDirName] 폴더 안에 두어 폴더 이동·복사 시 함께 따라온다. 내용 해시를
/// 파일명으로 써 동일 이미지를 중복 저장하지 않는다. 스캔 대상이 아니며(캐시는 노드가
/// 아니다) 사용자가 직접 다루지 않는다.
const String thumbnailCacheDirName = 'thumbnails';
