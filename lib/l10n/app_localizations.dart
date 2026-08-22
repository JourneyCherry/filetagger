import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 보기 메뉴 안, 앱 표시 언어를 고르는 하위 메뉴의 이름
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get menuLanguage;

  /// 표시 언어를 OS 설정에 맡기는 선택지
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get languageSystem;

  /// 표시 언어 선택지. 어느 로케일에서 보든 그 언어가 스스로를 부르는 이름으로 적는다(번역하지 않는다)
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// 표시 언어 선택지. 어느 로케일에서 보든 그 언어가 스스로를 부르는 이름으로 적는다(번역하지 않는다)
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'폴더 열기'**
  String get cmdOpenFolder;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'폴더 닫기'**
  String get cmdCloseFolder;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'다시 스캔'**
  String get cmdRescan;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'전체 선택'**
  String get cmdSelectAll;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get cmdClearSelection;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get cmdOpenNode;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'펼치기 / 접기'**
  String get cmdToggleExpand;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그 부여'**
  String get cmdAssignTags;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'원본 파일 찾기'**
  String get cmdReconnect;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'탐색기에서 열기'**
  String get cmdRevealInFileManager;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그 내보내기…'**
  String get cmdExportSelection;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그 관리'**
  String get cmdManageTags;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'썸네일 태그…'**
  String get cmdManageThumbnailTags;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'이름 태그…'**
  String get cmdManageNameTags;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'부제 태그…'**
  String get cmdManageSubtitleTags;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'키워드 만들기…'**
  String get cmdCreateKeyword;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'키워드 편집…'**
  String get cmdEditKeyword;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'키워드 삭제'**
  String get cmdDeleteKeyword;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'도움말 보기'**
  String get cmdHelp;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'업데이트 확인'**
  String get cmdCheckForUpdates;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get cmdAbout;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'프로그램 종료'**
  String get cmdExitApp;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그 표시 순서'**
  String get cmdTagDisplayOrder;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'필터 조건 보기'**
  String get cmdToggleFilterBar;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'정렬 조건 보기'**
  String get cmdToggleSortBar;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'목록에서 수정 활성화'**
  String get cmdToggleListEdit;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'그룹 기준 보기'**
  String get cmdToggleGrouping;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'프리셋 보기'**
  String get cmdTogglePresetBar;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'프리뷰 보기'**
  String get cmdTogglePreview;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'커서 위로'**
  String get cmdMoveCursorUp;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'커서 아래로'**
  String get cmdMoveCursorDown;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'범위 위로'**
  String get cmdExtendSelectionUp;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'범위 아래로'**
  String get cmdExtendSelectionDown;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'커서만 위로'**
  String get cmdMoveCursorUpNoSelect;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'커서만 아래로'**
  String get cmdMoveCursorDownNoSelect;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'접기 · 상위로 / 태그 왼쪽'**
  String get cmdCursorLeft;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'펼치기 / 태그 오른쪽'**
  String get cmdCursorRight;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그 칸 드나들기'**
  String get cmdToggleTagFocus;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'확정 / 열기'**
  String get cmdConfirmCursor;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'커서 선택 토글'**
  String get cmdToggleCursorSelection;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그 제거'**
  String get cmdDeleteFocusedTag;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'태그값 수정'**
  String get cmdEditFocusedTag;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'보기 모드: 목록'**
  String get cmdViewModeList;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'보기 모드: 아이콘'**
  String get cmdViewModeIcon;

  /// 명령 카탈로그의 라벨 — 메뉴·툴팁·도움말이 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'보기 모드: 자세히'**
  String get cmdViewModeDetail;

  /// 모바일 AppBar에서 필터·정렬 시트를 여는 버튼의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'필터 · 정렬'**
  String get mobileFilterSort;

  /// 모바일 선택 모드 AppBar의 제목 — 고른 항목 수
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String mobileSelectedCount(int count);

  /// 모바일 AppBar의 오버플로 메뉴 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get mobileMore;

  /// 다이얼로그 공통 — 취소 버튼
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// 다이얼로그 공통 — 닫기 버튼
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// 공통 — 삭제 버튼·메뉴 항목
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// 공통 — 저장 버튼
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// 공통 — 이름 입력 칸·열 제목
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get commonName;

  /// 공통 — 고를 것이 하나도 없을 때 자리를 지키는 항목
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get commonNone;

  /// 공통 — 태그 묶음의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get commonTag;

  /// 공통 — 태그를 새로 얹는 자리의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get commonAddTag;

  /// 공통 — 무엇을 얹을지 고르는 칸의 제목
  ///
  /// In ko, this message translates to:
  /// **'추가할 태그'**
  String get commonTagToAdd;

  /// 공통 — 태그 정의를 새로 만드는 자리의 제목
  ///
  /// In ko, this message translates to:
  /// **'새 태그'**
  String get commonNewTag;

  /// 공통 — 목록에서 항목 하나를 빼는 조작(대상 자체는 지우지 않는다)
  ///
  /// In ko, this message translates to:
  /// **'목록에서 빼기'**
  String get commonRemoveFromList;

  /// 정보 다이얼로그의 배포 형태 — 설정을 실행 파일 옆에 두는 형태
  ///
  /// In ko, this message translates to:
  /// **'포터블'**
  String get aboutChannelPortable;

  /// 정보 다이얼로그의 배포 형태 — 설치되어 설정이 OS 앱데이터에 남는 형태
  ///
  /// In ko, this message translates to:
  /// **'설치판'**
  String get aboutChannelPackage;

  /// 정보 다이얼로그 — 버전을 끝내 읽지 못했을 때의 버전 자리
  ///
  /// In ko, this message translates to:
  /// **'버전을 알 수 없음'**
  String get aboutVersionUnknown;

  /// 정보 다이얼로그의 버전 표기
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String aboutVersion(String version);

  /// 정보 다이얼로그·라이선스 화면의 버전 한 줄 — 버전과 배포 형태를 잇는다
  ///
  /// In ko, this message translates to:
  /// **'{version} · {channel}'**
  String aboutVersionLine(String version, String channel);

  /// 주소를 받아 줄 프로그램이 없어 링크를 넘기지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'웹 브라우저를 열지 못했습니다.'**
  String get aboutOpenBrowserFailed;

  /// 정보 다이얼로그의 앱 한 줄 소개
  ///
  /// In ko, this message translates to:
  /// **'태그로 파일을 정리하고 찾는 앱입니다. 태그는 관리 폴더 안에 함께 저장되어 폴더를 옮기면 따라갑니다.'**
  String get aboutSummary;

  /// 정보 다이얼로그 — 소스 코드 저장소를 브라우저로 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'소스 코드 저장소'**
  String get aboutSourceRepository;

  /// 정보 다이얼로그 — 라이선스 목록 화면을 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get aboutOpenSourceLicenses;

  /// 업데이트 확인 결과 — 새 배포본의 릴리즈 페이지를 브라우저로 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'릴리즈 페이지 열기'**
  String get updateOpenReleasePage;

  /// 업데이트 확인 결과 — 스토어의 제품 페이지를 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'스토어에서 열기'**
  String get updateOpenStore;

  /// 스토어 주소를 받아 줄 앱이 없어 넘기지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'스토어 앱을 열지 못했습니다.'**
  String get updateOpenStoreFailed;

  /// 업데이트 조회가 끝나기 전까지 보이는 진행 문구
  ///
  /// In ko, this message translates to:
  /// **'확인하는 중…'**
  String get updateChecking;

  /// 업데이트 확인 결과 제목 — 새 배포본이 있음
  ///
  /// In ko, this message translates to:
  /// **'새 업데이트가 있습니다.'**
  String get updateAvailableHeadline;

  /// 업데이트 확인 결과 상세 — 쓰고 있는 버전과 배포된 최신 버전
  ///
  /// In ko, this message translates to:
  /// **'현재 {current} · 최신 {latest}'**
  String updateAvailableDetail(String current, String latest);

  /// 업데이트 확인 결과 제목 — 이미 최신
  ///
  /// In ko, this message translates to:
  /// **'최신 버전입니다.'**
  String get updateUpToDateHeadline;

  /// 업데이트 확인 결과 상세 — 쓰고 있는 버전
  ///
  /// In ko, this message translates to:
  /// **'현재 {current}'**
  String updateUpToDateDetail(String current);

  /// 업데이트 확인 결과 제목 — 이 실행의 버전을 읽지 못함
  ///
  /// In ko, this message translates to:
  /// **'버전을 알 수 없습니다.'**
  String get updateUnknownVersionHeadline;

  /// 업데이트 확인 결과 상세 — 버전을 몰라 비교가 서지 않음
  ///
  /// In ko, this message translates to:
  /// **'이 실행의 버전을 확인할 수 없어 배포본과 견줄 수 없습니다.'**
  String get updateUnknownVersionDetail;

  /// 업데이트 확인 결과 제목 — 스토어 배포본
  ///
  /// In ko, this message translates to:
  /// **'스토어가 업데이트를 관리합니다.'**
  String get updateManagedByStoreHeadline;

  /// 업데이트 확인 결과 상세 — 갱신 경로가 스토어임
  ///
  /// In ko, this message translates to:
  /// **'이 배포본은 스토어를 통해 갱신되므로 앱이 직접 받아 설치하지 않습니다.'**
  String get updateManagedByStoreDetail;

  /// 업데이트 확인 결과 제목 — 조회 실패
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하지 못했습니다.'**
  String get updateFailedHeadline;

  /// 업데이트 확인 결과 상세 — 조회 실패 시 안내
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결을 확인한 뒤 다시 시도해 주세요.'**
  String get updateFailedDetail;

  /// 도움말 다이얼로그의 탭 이름(메뉴의 항목별 보기에도 같은 이름이 쓰인다)
  ///
  /// In ko, this message translates to:
  /// **'사용법'**
  String get helpTabHowTo;

  /// 도움말 다이얼로그의 탭 이름(메뉴의 항목별 보기에도 같은 이름이 쓰인다)
  ///
  /// In ko, this message translates to:
  /// **'사용 팁'**
  String get helpTabTips;

  /// 도움말 다이얼로그의 탭 이름(메뉴의 항목별 보기에도 같은 이름이 쓰인다)
  ///
  /// In ko, this message translates to:
  /// **'기능과 단축키'**
  String get helpTabShortcuts;

  /// 도움말 다이얼로그의 탭 이름(메뉴의 항목별 보기에도 같은 이름이 쓰인다)
  ///
  /// In ko, this message translates to:
  /// **'시스템 태그'**
  String get helpTabSystemTags;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'태그와 태그값'**
  String get helpTopicTagsTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'태그는 종류를 만들어 두고 파일·폴더에 부여합니다. 값 유형이 \"라벨\"이면 값 없이 붙었는지만 따지고, 텍스트·숫자·날짜는 값을 함께 적습니다. \"링크\"는 워크스페이스 안의 다른 항목을, \"이미지\"는 바깥에서 가져온 이미지 파일을 값으로 갖습니다. 값 유형에 따라 정렬 기준(사전순·숫자순·시간순)이 달라집니다.'**
  String get helpTopicTagsBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'태그가 저장되는 곳'**
  String get helpTopicStorageTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'태그는 관리 폴더 안의 숨김 폴더에 함께 저장됩니다. 폴더를 통째로 옮기거나 복사하면 태그도 따라갑니다. 앱 전역 설정(최근 연 폴더 등)만 OS의 앱 데이터 폴더에 남습니다.'**
  String get helpTopicStorageBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'폴더마다 정하는 관리 방식'**
  String get helpTopicManageModeTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'폴더는 \"폴더만 관리\"(하나의 항목으로만 다루고 내부를 감춤), \"내부 관리\"(직속 내용만), \"재귀적으로 관리\"(하위까지 이어서) 중 하나로 다룹니다. 따로 정하지 않은 폴더는 상위의 방식을 물려받습니다. 큰 폴더의 내부를 인덱싱하지 않으려면 관리 방식을 바꾸세요.'**
  String get helpTopicManageModeBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'필터 · 정렬 · 그룹 세 줄'**
  String get helpTopicQueryRowsTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'도구모음의 세 줄은 문법이 같고 뜻만 다릅니다. 필터는 조건, 정렬은 단계, 그룹은 묶는 기준입니다. 어느 줄이든 조건 칩을 끌어 순서를 바꾸거나, 빈 곳을 눌러 텍스트로 직접 칠 수 있습니다. 태그 이름이 아니라 태그 자체를 기억하므로 나중에 태그 이름을 바꿔도 조건이 끊기지 않습니다. 정렬 캡슐을 누르면 오름차순·내림차순·무작위를 차례로 오갑니다 — 무작위는 그 태그값의 순서만 흩고 값이 같은 항목끼리는 건드리지 않아, 뒤 단계의 정렬이 그대로 살아 있습니다. 무작위를 다시 고를 때마다 새로 섞입니다.'**
  String get helpTopicQueryRowsBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'조건 프리셋'**
  String get helpTopicPresetsTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 필터·정렬·그룹에 이름 태그·썸네일 태그까지 한 벌로 묶어 이름을 붙여 둡니다. 프리셋을 누르면 지금 걸린 것을 모두 지우고 그 한 벌로 갈아끼웁니다 — 일부만 더해지는 것이 아닙니다. 하는 일에 따라 찾는 조건뿐 아니라 이름 칸과 썸네일에 보고 싶은 것도 함께 갈리기 때문에 다섯을 한 벌로 다룹니다. 무엇이 담겼는지는 캡슐에 마우스를 올리면 보입니다. 지금 걸린 것과 똑같은 프리셋은 강조되어, 무엇을 보고 있는지 알 수 있습니다. 이름 변경·덮어쓰기는 프리셋을 우클릭(모바일은 길게 누르기)하고, 순서는 끌어서 바꿉니다. 프리셋도 태그처럼 관리 폴더 안에 저장되어 폴더를 옮기면 따라갑니다. 자세히 보기의 열 머리글 정렬과 보기 모드·크기 배율은 검색 조건이 아니라 프리셋에 담기지 않습니다.'**
  String get helpTopicPresetsBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'이름 · 부제 · 썸네일 태그가 프리셋에 담긴다'**
  String get helpTopicPresetSourcesTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'이름·부제·썸네일 태그는 한 번 정해 두는 설정처럼 보이지만 프리셋에 함께 담깁니다. 그래서 프리셋을 부르면 필터·정렬·그룹만이 아니라 이름 칸과 그 아래 줄, 썸네일이 보이는 방식도 그 프리셋의 것으로 바뀝니다. 이 셋을 지정하지 않은 채로 저장한 프리셋을 부르면 파일 이름과 경로, 기본 썸네일로 되돌아갑니다 — 이 기능이 생기기 전에 만들어 둔 프리셋도 그렇습니다. 원하는 상태로 맞춘 뒤 그 프리셋에 덮어쓰면 다음부터는 함께 되살아납니다.'**
  String get helpTopicPresetSourcesBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'폴더 안에 다른 관리 폴더가 있을 때'**
  String get helpTopicNestedTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'이미 태그를 쓰던 폴더를 다른 관리 폴더 안에서 발견하면 어떻게 할지 묻습니다. 흡수하면 하위의 태그가 상위로 합쳐지고, 독립으로 두면 건드리지 않으며, 무시하면 이번에만 넘어갑니다. 흡수는 하위가 더 새로운 형식으로 저장돼 있으면 막힙니다.'**
  String get helpTopicNestedBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'키워드 — 파일로 남지 않는 항목'**
  String get helpTopicKeywordTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'키워드는 디스크에 파일이나 폴더로 남지 않고 태그 저장소 안에만 있는 항목입니다. 이름 하나가 전부이고, 작가의 국적이나 계정 같은 부연 정보는 그 키워드에 태그로 붙입니다 — 그래야 다른 항목과 똑같이 필터·정렬·그룹에 걸립니다. 파일에서는 링크 태그로 키워드를 가리켜 둘을 잇습니다. 스캔의 대상이 아니라 폴더 관리 방식이나 파일 이동에 영향받지 않고, 목록에서는 맨 위 층에 놓입니다.'**
  String get helpTopicKeywordBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'글자를 쳐서 항목 찾기'**
  String get helpTopicTypeAheadTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'목록에 포커스가 있을 때 글자를 치면 그 글자로 시작하는 항목으로 커서가 건너뜁니다(이름 칸에 보이는 이름 기준이라, 이름 태그로 갈아 낀 이름이 있으면 그 이름으로 찾습니다). 이어서 치면 검색어가 좁혀지고, 같은 글자를 거듭 치면 그 글자로 시작하는 항목들을 차례로 돕니다. 잠시 멈추면 검색어가 지워져 다음 글자가 새 검색이 됩니다. 목록을 줄이는 것이 아니라 커서만 옮기는 것이라, 필터를 걸어 둔 채로도 그대로 쓸 수 있습니다. 접어 둔 그룹이나 폴더 안에 있어 지금 보이지 않는 항목도 찾아냅니다 — 필터에 걸러지지 않았다면 대상이며, 찾으면 그 항목에 이르는 그룹·폴더만 펼쳐 드러냅니다. 세 보기 모드에서 모두 되고, 아이콘 보기는 지금 파고든 계층 안에서만 찾습니다.'**
  String get helpTopicTypeAheadBody;

  /// 도움말 사용법 탭의 개념 설명 — 제목
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊긴 항목'**
  String get helpTopicDisconnectedTitle;

  /// 도움말 사용법 탭의 개념 설명 — 본문
  ///
  /// In ko, this message translates to:
  /// **'앱 밖에서 파일을 옮기거나 지우면 그 항목은 연결 끊김으로 남고 태그는 보존됩니다. 같은 내용의 파일을 다시 찾으면 자동으로 이어 붙고, 못 찾으면 원본 파일 찾기로 직접 지목해 태그를 되살릴 수 있습니다.'**
  String get helpTopicDisconnectedBody;

  /// 도움말 기능·단축키 표의 묶음 제목
  ///
  /// In ko, this message translates to:
  /// **'폴더'**
  String get helpGroupFolder;

  /// 도움말 기능·단축키 표의 묶음 제목
  ///
  /// In ko, this message translates to:
  /// **'선택 · 태그'**
  String get helpGroupSelectionTags;

  /// 도움말 기능·단축키 표의 묶음 제목
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get helpGroupKeyword;

  /// 도움말 기능·단축키 표의 묶음에 붙는 한 줄 단서
  ///
  /// In ko, this message translates to:
  /// **'편집·삭제는 키워드를 하나만 고른 상태에서 듣습니다.'**
  String get helpGroupKeywordNote;

  /// 도움말 기능·단축키 표의 묶음 제목
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get helpGroupView;

  /// 도움말 기능·단축키 표의 묶음 제목
  ///
  /// In ko, this message translates to:
  /// **'키보드 탐색'**
  String get helpGroupKeyboardNav;

  /// 도움말 기능·단축키 표의 묶음에 붙는 한 줄 단서
  ///
  /// In ko, this message translates to:
  /// **'목록 보기에서, 목록에 포커스가 있을 때 듣습니다. 아이콘·자세히 보기는 각자의 방향키 이동을 따로 씁니다.'**
  String get helpGroupKeyboardNavNote;

  /// 도움말 기능·단축키 표의 묶음 제목
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get helpGroupHelp;

  /// 도움말 기능·단축키 탭 머리의 안내 문단
  ///
  /// In ko, this message translates to:
  /// **'메뉴·버튼으로 부를 수 있는 조작과, 있다면 그 단축키입니다. 지금 할 수 없는 조작(고른 항목이 없을 때의 태그 부여 등)도 함께 싣습니다.'**
  String get helpShortcutsIntro;

  /// 도움말 사용 팁 — 그 팁이 가리키는 명령의 이름을 다는 꼬리말
  ///
  /// In ko, this message translates to:
  /// **'관련 조작: {command}'**
  String helpTipRelatedCommand(String command);

  /// 도움말 시스템 태그 탭 머리의 안내 문단
  ///
  /// In ko, this message translates to:
  /// **'아래 태그들은 파일 자체에서 값을 끌어내 자동으로 붙습니다. 직접 만들거나 지울 수 없고 저장되지도 않지만, 직접 만든 태그와 똑같이 필터·정렬·그룹에 쓸 수 있습니다. 태그 관리에서 각각을 목록에 보일지만 정합니다. 어떤 항목에 값이 없으면(폴더의 크기 등) 그 항목에는 태그가 붙지 않은 것으로 다룹니다.'**
  String get helpSystemTagOverview;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'파일의 바이트 크기입니다. 폴더에는 붙지 않아, 이 태그를 \"있음\"으로 거르면 파일만 남습니다.'**
  String get helpSystemTagFileSize;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'파일시스템이 기록한 마지막 수정 시각입니다. 시간순으로 정렬·비교됩니다.'**
  String get helpSystemTagModifiedTime;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'점을 뺀 확장자를 소문자로 담습니다. 폴더와 확장자 없는 파일에는 붙지 않고, 이름이 점으로 시작하기만 하는 파일도 확장자로 보지 않습니다. 값으로 묶으면 종류별 파일 수를 볼 수 있습니다.'**
  String get helpSystemTagExtension;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'이미지의 가로 픽셀 수입니다. 크기를 읽을 수 있는 이미지에만 붙으므로, 이 태그를 \"있음\"으로 걸러 이미지만 모을 수 있습니다. 숫자라서 큰 것부터 정렬하거나 \"얼마 이상\"으로 거를 수 있습니다.'**
  String get helpSystemTagImageWidth;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'이미지의 세로 픽셀 수입니다. 가로와 따로 붙어(둘은 늘 함께 붙거나 함께 없습니다), 가로·세로를 각각 정렬 기준이나 조건으로 쓸 수 있습니다.'**
  String get helpSystemTagImageHeight;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'항목의 이름입니다. 시스템 태그 중 유일하게 값을 고칠 수 있고, 고치면 디스크의 실제 이름이 바뀝니다(키워드는 디스크에 실체가 없어 키워드의 이름만 바뀝니다).'**
  String get helpSystemTagFileName;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'폴더가 바로 아래에 담고 있는 파일의 수입니다. 하위 폴더와 그 안의 파일은 세지 않습니다. 폴더에만 붙으므로 폴더 표식을 겸해, 필터에서 \"있음\"으로 폴더만, 제외로 파일만 남길 수 있습니다(빈 폴더도 0이 붙습니다). 내부를 감춘 폴더에도 붙어, 열어 보지 않고 안에 무엇이 얼마나 있는지 가늠하거나 수량으로 정렬할 수 있습니다.'**
  String get helpSystemTagChildFileCount;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'키워드에만 붙는 표식으로 값은 없습니다. 키워드를 목록에서 보고 싶지 않으면 필터에서 이 태그를 제외하면 됩니다.'**
  String get helpSystemTagKeyword;

  /// 도움말 시스템 태그 탭 — 태그 하나의 설명
  ///
  /// In ko, this message translates to:
  /// **'가리키는 대상을 찾지 못한 링크 태그를 하나라도 가진 항목에 붙는 표식으로 값은 없습니다. 대상이 지워졌거나, 다른 태거에서 가져온 링크의 대상이 아직 이 폴더에 없을 때 생깁니다. 필터에서 \"있음\"으로 걸러 모아 두고, 각 링크 칩을 더블클릭해 다시 연결하거나 x로 지우면 됩니다.'**
  String get helpSystemTagUnresolvedLink;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'목록에서 파일 감추기'**
  String get tipHideFilesTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'감추기 전용 기능은 없습니다. 대신 \"숨김\" 같은 이름의 태그를 직접 만들어 감추고 싶은 항목에 부여하고, 필터 줄에서 그 태그를 상시 제외하세요. 태그는 그대로 남아 있어 제외를 풀면 다시 보입니다.'**
  String get tipHideFilesBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'폴더째 목록에서 빼기'**
  String get tipHideFolderTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'별도의 \"무시\" 관리 방식을 두지 않은 것도 같은 이유입니다. 폴더에 \"숨김\" 태그를 붙이고 필터에서 제외하면 그 폴더와 아래 내용이 목록에서 통째로 빠집니다.'**
  String get tipHideFolderBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'폴더에 붙인 태그를 하위에 전파하지 않기'**
  String get tipFolderGroupTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'폴더 태그를 하위 파일마다 복제할 필요가 없습니다. 그룹 줄에 \"폴더 계층\"을 넣으면(기본값) 하위 파일이 그 폴더 헤더 아래 모여, 태그를 전파한 것과 같은 효과를 냅니다. 폴더 단위로 태그를 관리하고 싶을 때 쓰세요.'**
  String get tipFolderGroupBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'태그값으로 묶어 보기'**
  String get tipGroupByValueTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'그룹 줄에 태그 이름을 넣으면 그 태그의 값별로 묶이고(SQL의 GROUP BY처럼) 헤더에 값별 파일 수가 뜹니다. 여러 단계를 넣으면 바깥에서 안쪽으로 중첩되고, \"폴더 계층\"과 섞으면 폴더 안을 다시 값으로 나눌 수 있습니다.'**
  String get tipGroupByValueBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'필터를 텍스트로 치기'**
  String get tipFilterTextTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'필터 줄의 빈 곳을 누르면 조건을 글자로 칩니다. 태그 이름과 연산자는 자동완성에서 고르고, 스페이스를 누르면 조건이 캡슐로 접힙니다. 접힌 캡슐은 글자 하나처럼 다뤄져 지우고 옮기는 것이 보통 텍스트와 같습니다.'**
  String get tipFilterTextBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'정렬 우선순위를 잘라 붙여 바꾸기'**
  String get tipSortTextTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'정렬 줄도 빈 곳을 누르면 같은 방식으로 칩니다. 왼쪽에서 오른쪽 순서가 그대로 정렬 우선순위라, 캡슐을 잘라 붙이면 드래그보다 빠르게 순서를 바꿉니다. 이름 앞에 접두사를 붙이면 내림차순·무작위가 됩니다.'**
  String get tipSortTextBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'하는 일에 따라 조건과 표시를 통째로 갈아타기'**
  String get tipPresetSwitchTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'읽을 것을 고를 때와 정리할 때는 보고 싶은 것이 다릅니다. 필터·정렬·그룹에 이름 태그·썸네일 태그까지 짜 두고 프리셋으로 저장하면, 다음부터는 캡슐 하나로 그 조합 전체를 되돌립니다. 예를 들어 읽을 때는 \"안 읽음\"만 남기고 제목 태그를 이름 자리에 세워 표지를 썸네일로 보는 프리셋을, 정리할 때는 태그가 없는 항목을 찾아 실제 파일 이름을 그대로 보는 프리셋을 나란히 두는 식입니다.'**
  String get tipPresetSwitchBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'원하는 이미지를 썸네일로 쓰기'**
  String get tipThumbnailSourceTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'값 유형이 \"링크\"인 태그를 만들어 파일에 부여하면(부여할 때 워크스페이스 안의 대상을 고릅니다) 그 대상의 이미지가 썸네일이 됩니다. 워크스페이스 밖의 이미지를 쓰려면 \"이미지\" 유형 태그를 만들어 파일을 고르세요. 어느 태그를 썸네일 출처로 쓸지와 그 우선순위는 썸네일 태그에서 정합니다.'**
  String get tipThumbnailSourceBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'태그값에 담기 어려운 정보를 키워드로 세우기'**
  String get tipKeywordEntityTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'작가처럼 그 자체가 여러 정보(국적·계정 등)를 갖는 대상은 태그값 문자열로 적으면 더 붙일 자리가 없습니다. 키워드를 하나 만들어 그 정보들을 키워드의 태그로 붙이고, 그림 파일에는 링크 태그로 그 키워드를 가리키세요. 키워드 캡슐을 더블클릭하면 곧장 그 대상으로 이동하고, 키워드에 붙인 태그로 되레 그림을 찾아낼 수도 있습니다.'**
  String get tipKeywordEntityBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'링크 태그로 다음 항목 넘기기'**
  String get tipLinkNextTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'링크 태그는 썸네일 외에도 쓸 수 있습니다. 링크 캡슐을 더블클릭(모바일은 더블탭)하면 가리키는 항목으로 곧장 이동하므로, 만화의 다음 권처럼 이어 보는 순서를 태그로 이어 둘 수 있습니다.'**
  String get tipLinkNextBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'파일 이름 대신 태그값을 이름으로 보기'**
  String get tipNameTagTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'내려받은 파일 이름이 알아볼 수 없는 문자열이어도 파일을 바꿀 필요는 없습니다. 제목 같은 텍스트 태그를 이름 태그로 지정하면 목록의 이름 자리에 그 값이 대신 보입니다. 여러 개를 순서대로 두면 앞에 있는 것부터 찾아 쓰고, 그 태그가 없는 항목은 원래 파일 이름을 그대로 보입니다.'**
  String get tipNameTagBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'이름 아래 줄에 경로 대신 다른 값 보기'**
  String get tipSubtitleTagTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'이름 아래 줄에는 기본으로 경로가 보입니다. 태그로 묶어 보는 동안에는 경로보다 작가·연도처럼 다른 축이 더 궁금할 수 있는데, 그때 부제 태그를 지정하면 그 값이 대신 보입니다. 이름 태그와 같은 방식이라 여러 개를 순서대로 둘 수 있고, 그 태그가 없는 항목은 경로를 그대로 보입니다.'**
  String get tipSubtitleTagBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'태그를 다른 폴더로 옮기기'**
  String get tipExportTagsTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'가져오기 기능은 따로 없습니다. 항목을 골라 내보내면 요청함 형식의 파일이 나오고, 그 파일을 받는 폴더의 .filetagger/queue/에 넣기만 하면 그대로 적용됩니다. 태그가 없으면 값 유형·색까지 그대로 만들어집니다.'**
  String get tipExportTagsBody;

  /// 도움말 사용 팁 — 제목
  ///
  /// In ko, this message translates to:
  /// **'끊어진 링크 모아서 손보기'**
  String get tipUnresolvedLinksTitle;

  /// 도움말 사용 팁 — 본문
  ///
  /// In ko, this message translates to:
  /// **'가리키던 항목이 지워졌거나, 다른 폴더에서 가져온 링크의 대상이 아직 없으면 링크 캡슐에 표식이 붙습니다. 필터에서 \"미해결 링크\" 태그를 \"있음\"으로 걸면 그런 항목만 모이고, 캡슐을 더블클릭해 다시 연결하거나 x로 지우면 됩니다.'**
  String get tipUnresolvedLinksBody;

  /// 스캔이 예외로 끝났을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'스캔에 실패했습니다: {error}'**
  String homeScanFailed(String error);

  /// OS가 그 파일을 열 프로그램을 찾지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'이 파일을 열 앱이 없습니다: {name}'**
  String homeNoAppForFile(String name);

  /// 파일 관리자를 띄우지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'탐색기에서 열지 못했습니다: {error}'**
  String homeRevealFailed(String error);

  /// 빈 상태 화면의 최근 연 폴더 목록 제목
  ///
  /// In ko, this message translates to:
  /// **'최근 폴더'**
  String get homeRecentFolders;

  /// 전역 설정을 읽지 못해 최근 폴더 목록을 못 보일 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'설정을 불러오지 못했습니다: {error}'**
  String homeSettingsLoadFailed(String error);

  /// 최근 연 폴더가 하나도 없을 때의 빈 목록 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 연 폴더가 없습니다.'**
  String get homeNoRecentFolders;

  /// 컨텍스트 메뉴의 키워드 하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get menuKeyword;

  /// 컨텍스트 메뉴의 폴더 관리 방식 하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'폴더 관리 옵션'**
  String get menuFolderManageOptions;

  /// 목록 행에서 폴더 관리 방식 시트를 여는 버튼의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'폴더 관리 방식'**
  String get tooltipFolderManageMode;

  /// 키워드를 새로 만드는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'키워드 만들기'**
  String get keywordCreateTitle;

  /// 키워드 만들기 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get keywordCreateConfirm;

  /// 키워드 이름을 고치는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'키워드 편집'**
  String get keywordEditTitle;

  /// 고른 항목에 내보낼 부여 기록이 하나도 없을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'내보낼 태그 부여가 없습니다.'**
  String get exportNothingToExport;

  /// 저장 다이얼로그의 파일 종류 이름 — 외부 앱 연동의 요청함 형식
  ///
  /// In ko, this message translates to:
  /// **'요청함 파일'**
  String get exportFileTypeLabel;

  /// 내보내기 성공 알림 — 동봉한 이미지가 없을 때
  ///
  /// In ko, this message translates to:
  /// **'태그 {count}건을 내보냈습니다.'**
  String exportDone(int count);

  /// 내보내기 성공 알림 — 이미지를 함께 담았을 때
  ///
  /// In ko, this message translates to:
  /// **'태그 {count}건을 내보냈습니다 (이미지 {images}개 동봉).'**
  String exportDoneWithImages(int count, int images);

  /// 내보내기가 예외로 끝났을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'내보내지 못했습니다: {error}'**
  String exportFailed(String error);

  /// 태그 부여 다이얼로그의 제목 — 이름을 알 수 없는 항목 하나
  ///
  /// In ko, this message translates to:
  /// **'파일 1개'**
  String get assignTitleSingleFile;

  /// 태그 부여 다이얼로그의 제목 — 여러 항목을 한꺼번에
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일'**
  String assignTitleFiles(int count);

  /// 이름 변경 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get renameTitle;

  /// 이름 변경 다이얼로그의 입력 칸 제목
  ///
  /// In ko, this message translates to:
  /// **'새 이름'**
  String get renameNewName;

  /// 이름 변경 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get renameConfirm;

  /// 이름에 경로 구분자가 섞였을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'이름에 경로 구분자(/ \\)는 쓸 수 없습니다.'**
  String get renamePathSeparator;

  /// 파일시스템이 이름 변경을 거부했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'이름을 바꾸지 못했습니다: {error}'**
  String renameFailed(String error);

  /// 관리 범위 축소 경고에서 루트를 가리키는 이름
  ///
  /// In ko, this message translates to:
  /// **'루트 폴더'**
  String get scopeRootFolder;

  /// 관리 범위를 줄일 때의 확인 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'관리 범위 축소'**
  String get scopeReductionTitle;

  /// 관리 범위 축소 확인 — 무엇의 범위가 줄어드는지
  ///
  /// In ko, this message translates to:
  /// **'‘{target}’의 관리 범위를 줄입니다.'**
  String scopeReductionTarget(String target);

  /// 관리 범위 축소 확인 — 함께 사라지는 태그 경고
  ///
  /// In ko, this message translates to:
  /// **'범위 밖이 되는 {count}개 하위 항목의 태그가 함께 제거되며, 되돌릴 수 없습니다.'**
  String scopeReductionWarning(int count);

  /// 관리 범위 축소 확인 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'범위 축소'**
  String get scopeReductionConfirm;

  /// 관리 폴더 안에서 다른 관리 폴더를 찾았을 때의 다이얼로그 제목
  ///
  /// In ko, this message translates to:
  /// **'중첩된 태그 폴더 발견'**
  String get nestedTitle;

  /// 중첩 워크스페이스 다이얼로그의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'하위 폴더가 자체 태그 데이터를 가지고 있습니다. 어떻게 처리할지 선택하세요.'**
  String get nestedPrompt;

  /// 중첩 워크스페이스 처리 — 하위 태그를 상위로 합치는 갈래
  ///
  /// In ko, this message translates to:
  /// **'흡수'**
  String get nestedAbsorb;

  /// 중첩 워크스페이스 처리 — 흡수의 설명
  ///
  /// In ko, this message translates to:
  /// **'태그와 목록을 현재 워크스페이스로 가져와 관리합니다.'**
  String get nestedAbsorbDetail;

  /// 중첩 워크스페이스 처리 — 흡수가 막힌 이유
  ///
  /// In ko, this message translates to:
  /// **'하위 태거가 더 높은 버전이라 흡수할 수 없습니다.'**
  String get nestedAbsorbBlocked;

  /// 중첩 워크스페이스 처리 — 하위를 건드리지 않는 갈래
  ///
  /// In ko, this message translates to:
  /// **'독립'**
  String get nestedIndependent;

  /// 중첩 워크스페이스 처리 — 독립의 설명
  ///
  /// In ko, this message translates to:
  /// **'내부를 열지 않는 단일 노드로 두고, 하위 태거는 건드리지 않습니다.'**
  String get nestedIndependentDetail;

  /// 중첩 워크스페이스 처리 — 하위 태거를 무시하고 그냥 인덱싱하는 갈래
  ///
  /// In ko, this message translates to:
  /// **'무시'**
  String get nestedIgnore;

  /// 중첩 워크스페이스 처리 — 무시의 설명
  ///
  /// In ko, this message translates to:
  /// **'하위 태거를 무시하고 내부 파일을 현재 규칙으로 인덱싱합니다.'**
  String get nestedIgnoreDetail;

  /// 흡수한 뒤 하위의 태그 폴더를 지울지 고르는 체크박스
  ///
  /// In ko, this message translates to:
  /// **'흡수 후 하위 태그 폴더 제거'**
  String get nestedRemoveSource;

  /// 하위 태그 폴더 제거를 켰을 때의 설명
  ///
  /// In ko, this message translates to:
  /// **'하위 .filetagger 폴더를 삭제합니다(되돌릴 수 없음).'**
  String get nestedRemoveSourceOn;

  /// 하위 태그 폴더 제거를 껐을 때의 설명
  ///
  /// In ko, this message translates to:
  /// **'하위 태거를 남기고 이후 ‘무시’로 처리합니다.'**
  String get nestedRemoveSourceOff;

  /// 중첩 워크스페이스 다이얼로그를 결정 없이 닫는 버튼
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get nestedLater;

  /// 중첩 워크스페이스 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get nestedApply;

  /// 다이얼로그 공통 — 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonOk;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get menuFile;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'최근 연 폴더'**
  String get menuRecentFolders;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get menuEdit;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'루트 폴더 관리 방식'**
  String get menuRootManageMode;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get menuView;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'보기 모드'**
  String get menuViewMode;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get menuTheme;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get menuTag;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get menuHelp;

  /// 메뉴바의 최상위 메뉴·하위 메뉴 이름
  ///
  /// In ko, this message translates to:
  /// **'항목별 보기'**
  String get menuHelpTopics;

  /// 테마 선택지 — OS 밝기 설정을 따른다
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정'**
  String get themeSystem;

  /// 테마 선택지 — 밝은 테마
  ///
  /// In ko, this message translates to:
  /// **'밝게'**
  String get themeLight;

  /// 테마 선택지 — 어두운 테마
  ///
  /// In ko, this message translates to:
  /// **'어둡게'**
  String get themeDark;

  /// 루트 폴더 관리 방식 선택지 — 직속 내용만 인덱싱
  ///
  /// In ko, this message translates to:
  /// **'직속 항목만 관리'**
  String get rootManageDirectOnly;

  /// 루트 폴더 관리 방식 선택지 — 하위까지 이어서 인덱싱
  ///
  /// In ko, this message translates to:
  /// **'전체 재귀 관리'**
  String get rootManageRecursive;

  /// 파일 목록 보기 모드 이름
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get viewModeList;

  /// 파일 목록 보기 모드 이름
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get viewModeIcon;

  /// 파일 목록 보기 모드 이름
  ///
  /// In ko, this message translates to:
  /// **'자세히'**
  String get viewModeDetail;

  /// 폴더 관리 방식 선택지 — 하나의 항목으로만 다루고 내부를 감춘다
  ///
  /// In ko, this message translates to:
  /// **'폴더만 관리 (내부 감춤)'**
  String get folderManageOpaque;

  /// 폴더 관리 방식 선택지 — 직속 내용만 인덱싱
  ///
  /// In ko, this message translates to:
  /// **'내부 관리'**
  String get folderManageManaged;

  /// 폴더 관리 방식 선택지 — 하위까지 이어서 인덱싱
  ///
  /// In ko, this message translates to:
  /// **'재귀적으로 관리'**
  String get folderManageRecursive;

  /// 이미지 태그 칩의 툴팁 — 값이 캐시 키라 이름만 보이는 까닭을 알린다
  ///
  /// In ko, this message translates to:
  /// **'커스텀 이미지'**
  String get chipCustomImage;

  /// 링크 태그 칩 — 가리킬 대상이 비어 있을 때 값 자리에 놓는 표기
  ///
  /// In ko, this message translates to:
  /// **'(없음)'**
  String get chipLinkNoTarget;

  /// 미해결 링크 칩의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'가리키는 대상을 찾지 못했습니다. 더블클릭해 다시 연결하거나 x로 지웁니다.'**
  String get chipUnresolvedHint;

  /// 정의가 사라진 태그를 가리키는 조건 칩의 이름 자리
  ///
  /// In ko, this message translates to:
  /// **'(삭제된 태그)'**
  String get chipDeletedTag;

  /// 태그 색을 직접 고르는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'색 고르기'**
  String get colorPickerTitle;

  /// 태그 선택 드롭다운의 이름표
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tagPickerLabel;

  /// 태그 선택 드롭다운의 입력 힌트
  ///
  /// In ko, this message translates to:
  /// **'태그 이름 검색'**
  String get tagPickerSearchHint;

  /// 파일 선택기의 파일 종류 이름 — 이미지 파일
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get pickerImageTypeLabel;

  /// 고른 파일을 이미지로 읽지 못해 캐시에 등록하지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'이미지를 등록하지 못했습니다.'**
  String get thumbnailRegisterFailed;

  /// 그룹 자동완성에서 폴더 계층 항목에 붙는 설명(값 유형 자리를 대신한다)
  ///
  /// In ko, this message translates to:
  /// **'경로 계층'**
  String get groupFolderHierarchyDesc;

  /// 도구모음 조건 줄(프리셋·필터·정렬·그룹)이 비었을 때 그 자리에 두는 한 낱말
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get queryEmpty;

  /// 태그 값 유형의 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'라벨'**
  String get valueTypeLabel;

  /// 태그 값 유형의 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'텍스트'**
  String get valueTypeText;

  /// 태그 값 유형의 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'숫자'**
  String get valueTypeNumber;

  /// 태그 값 유형의 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get valueTypeDate;

  /// 태그 값 유형의 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get valueTypeLink;

  /// 태그 값 유형의 표시 이름
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get valueTypeImage;

  /// 필터 연산자의 짧은 표시 — 칩과 조건 줄에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'있음'**
  String get filterOpExists;

  /// 필터 연산자의 짧은 표시 — 칩과 조건 줄에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'포함'**
  String get filterOpContains;

  /// 필터 연산자의 짧은 표시 — 칩과 조건 줄에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'미포함'**
  String get filterOpNotContains;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'있음 (존재)'**
  String get filterOpMenuExists;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'= 같음'**
  String get filterOpMenuEquals;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'≠ 다름'**
  String get filterOpMenuNotEquals;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'< 미만'**
  String get filterOpMenuLessThan;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'≤ 이하'**
  String get filterOpMenuLessOrEqual;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'> 초과'**
  String get filterOpMenuGreaterThan;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'≥ 이상'**
  String get filterOpMenuGreaterOrEqual;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'포함'**
  String get filterOpMenuContains;

  /// 필터 연산자의 설명이 붙은 표시 — 고르는 목록에 놓인다
  ///
  /// In ko, this message translates to:
  /// **'미포함'**
  String get filterOpMenuNotContains;

  /// 공통 — 편집 버튼·툴팁
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get commonEdit;

  /// 태그 칩 표시 토글의 툴팁 — 지금 보이는 태그를 감춘다
  ///
  /// In ko, this message translates to:
  /// **'목록에서 감추기'**
  String get tagVisibilityHide;

  /// 태그 칩 표시 토글의 툴팁 — 지금 감춘 태그를 다시 보인다
  ///
  /// In ko, this message translates to:
  /// **'목록에 표시하기'**
  String get tagVisibilityShow;

  /// 태그 합치기 버튼의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'다른 태그를 여기에 합치기'**
  String get tagMergeIntoThis;

  /// 값 유형·다중 허용이 같은 태그가 없어 합치기가 비활성일 때의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'합칠 수 있는 태그가 없습니다'**
  String get tagMergeNoCandidates;

  /// 태그 삭제 확인 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그 삭제'**
  String get tagDeleteTitle;

  /// 태그 삭제 확인 — 어느 태그가 지워지는지
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’ 태그를 삭제합니다.'**
  String tagDeleteTarget(String name);

  /// 태그 삭제 확인 — 함께 사라지는 부여 기록 경고
  ///
  /// In ko, this message translates to:
  /// **'{count}개 파일에 부여된 이 태그의 값이 모두 함께 제거되며, 되돌릴 수 없습니다.'**
  String tagDeleteWarning(int count);

  /// 태그 합치기 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’에 합치기'**
  String tagMergeTitle(String name);

  /// 태그 합치기 다이얼로그의 설명
  ///
  /// In ko, this message translates to:
  /// **'아래에서 고른 태그의 부여 기록을 ‘{name}’ 태그로 옮기고, 고른 태그들은 제거합니다. ‘{name}’의 이름과 색이 유지됩니다.'**
  String tagMergeDescription(String name);

  /// 태그 합치기 — 다중 부여가 아닌 태그에서 값이 하나만 남는다는 단서
  ///
  /// In ko, this message translates to:
  /// **'같은 파일에 두 태그가 모두 있으면 ‘{name}’의 값을 유지하고 합쳐지는 태그 쪽 값은 버립니다.'**
  String tagMergeSingleValueNote(String name);

  /// 태그 합치기 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'합치기'**
  String get tagMergeConfirm;

  /// 태그 합치기가 예외로 끝났을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'합치지 못했습니다: {error}'**
  String tagMergeFailed(String error);

  /// 태그 편집기 — 이름이 비었을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해주세요.'**
  String get tagNameRequired;

  /// 태그 편집기 — 저장이 거부됐을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했습니다(이름이 중복일 수 있습니다).'**
  String get tagSaveFailed;

  /// 태그 편집 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그 편집'**
  String get tagEditTitle;

  /// 태그 편집기의 값 유형 선택 칸 이름
  ///
  /// In ko, this message translates to:
  /// **'값 유형'**
  String get tagValueTypeField;

  /// 태그 편집기의 색 고르기 칸 이름
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get tagColorField;

  /// 태그 편집기 — 한 파일에 여러 번 붙일 수 있게 하는 스위치
  ///
  /// In ko, this message translates to:
  /// **'다중 부여 허용'**
  String get tagAllowMultiple;

  /// 태그 편집기 — 다중 부여 스위치의 설명
  ///
  /// In ko, this message translates to:
  /// **'한 파일에 이 태그를 여러 번 붙일 수 있게 합니다.'**
  String get tagAllowMultipleDetail;

  /// 팔레트 밖의 색으로 가는 스와치의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'직접 고르기'**
  String get tagColorCustom;

  /// 태그 관리 화면·다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그 관리'**
  String get tagManageTitle;

  /// 태그 관리 다이얼로그 머리의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'위에 있는 태그일수록 목록 행의 앞에 표시됩니다. 시스템 태그는 파일에서 자동으로 파생되어 표시 여부만 켜고 끌 수 있고, 기본적으로 사용자 태그 뒤에 놓이지만 원하는 자리로 끌어 옮길 수 있습니다.'**
  String get tagManageOrderNote;

  /// 태그 행의 부제에 붙는 표식 — 한 파일에 여러 번 붙일 수 있음
  ///
  /// In ko, this message translates to:
  /// **'다중 부여'**
  String get tagBadgeMultiple;

  /// 태그 행의 부제에 붙는 표식 — 값을 고칠 수 있는 시스템 태그
  ///
  /// In ko, this message translates to:
  /// **'수정 가능'**
  String get tagBadgeEditable;

  /// 시스템 태그 행의 부제 — 수정 가능 표식과 값 유형을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'수정 가능 · {type}'**
  String tagBadgeEditableWithType(String type);

  /// 태그 표시 순서 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그 표시 순서'**
  String get tagOrderTitle;

  /// 태그 표시 순서 다이얼로그 머리의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'위에 있는 태그일수록 목록 행의 앞에 표시됩니다. 시스템 태그는 기본적으로 사용자 태그 뒤에 놓이지만, 원하는 자리로 끌어 옮길 수 있습니다.'**
  String get tagOrderNote;

  /// 썸네일 출처로 쓸 태그를 정하는 자리의 제목
  ///
  /// In ko, this message translates to:
  /// **'썸네일 태그'**
  String get thumbnailTagTitle;

  /// 워크스페이스가 없어 태그를 다룰 수 없을 때의 안내
  ///
  /// In ko, this message translates to:
  /// **'폴더를 먼저 열어주세요.'**
  String get tagManageOpenFolderFirst;

  /// 태그 목록을 읽지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'태그를 불러오지 못했습니다: {error}'**
  String tagManageLoadFailed(String error);

  /// 사용자 태그가 하나도 없을 때의 빈 목록 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 만든 태그가 없습니다.'**
  String get tagManageEmpty;

  /// 태그 관리 화면의 시스템 태그 구역 제목
  ///
  /// In ko, this message translates to:
  /// **'시스템 태그'**
  String get systemTagSection;

  /// 태그 관리 화면의 시스템 태그 구역 설명
  ///
  /// In ko, this message translates to:
  /// **'파일에서 자동으로 파생되는 태그입니다. 표시 여부만 켜고 끌 수 있습니다.'**
  String get systemTagSectionNote;

  /// 도구모음 조건 줄의 이름
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get rowPresets;

  /// 도구모음 조건 줄의 이름
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get rowFilter;

  /// 도구모음 조건 줄의 이름
  ///
  /// In ko, this message translates to:
  /// **'정렬'**
  String get rowSort;

  /// 도구모음 조건 줄의 이름
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get rowGroup;

  /// 프리셋 줄의 더하기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'현재 조건을 프리셋으로 저장'**
  String get presetSaveTooltip;

  /// 필터 줄의 더하기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'필터 조건 추가'**
  String get filterAddTooltip;

  /// 필터 줄의 비우기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'필터 조건 모두 지우기'**
  String get filterClearTooltip;

  /// 정렬 줄의 더하기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'정렬 기준 추가'**
  String get sortAddTooltip;

  /// 정렬 줄의 비우기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'정렬 기준 모두 지우기'**
  String get sortClearTooltip;

  /// 그룹 줄의 더하기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'그룹 기준 추가'**
  String get groupAddTooltip;

  /// 그룹 줄의 비우기 버튼 툴팁
  ///
  /// In ko, this message translates to:
  /// **'그룹 기준 모두 지우기'**
  String get groupClearTooltip;

  /// 필터 조건 편집 — 날짜 값을 고르지 않았을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하세요.'**
  String get filterDateRequired;

  /// 필터 조건 편집 — 숫자 값이 숫자가 아닐 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'숫자를 입력하세요.'**
  String get filterNumberRequired;

  /// 필터 조건 다이얼로그의 제목 — 새로 더할 때
  ///
  /// In ko, this message translates to:
  /// **'필터 조건 추가'**
  String get filterConditionAddTitle;

  /// 필터 조건 다이얼로그의 제목 — 있던 조건을 고칠 때
  ///
  /// In ko, this message translates to:
  /// **'필터 조건 편집'**
  String get filterConditionEditTitle;

  /// 필터 조건 — 조건에 맞는 항목을 남기는 갈래
  ///
  /// In ko, this message translates to:
  /// **'표시'**
  String get filterIncludeSegment;

  /// 필터 조건 — 조건에 맞는 항목을 빼는 갈래
  ///
  /// In ko, this message translates to:
  /// **'제외'**
  String get filterExcludeSegment;

  /// 필터 조건 다이얼로그의 연산 선택 칸 이름
  ///
  /// In ko, this message translates to:
  /// **'연산'**
  String get filterOperatorField;

  /// 필터 조건 다이얼로그 — 날짜를 아직 고르지 않은 자리의 문구
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get filterPickDate;

  /// 필터 조건 다이얼로그 — 달력을 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get filterPickDateButton;

  /// 필터 조건 다이얼로그의 값 입력 칸 이름
  ///
  /// In ko, this message translates to:
  /// **'값'**
  String get filterValueField;

  /// 정렬 기준 추가 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'정렬 기준 추가'**
  String get sortKeyAddTitle;

  /// 정렬 기준 추가 — 라벨 태그에는 방향이 없다는 단서
  ///
  /// In ko, this message translates to:
  /// **'라벨 태그는 정렬 방법과 무관하게 부여된 항목을 위로 정렬합니다.'**
  String get sortLabelNote;

  /// 정렬 방법
  ///
  /// In ko, this message translates to:
  /// **'오름차순'**
  String get sortAscending;

  /// 정렬 방법
  ///
  /// In ko, this message translates to:
  /// **'내림차순'**
  String get sortDescending;

  /// 정렬 방법
  ///
  /// In ko, this message translates to:
  /// **'무작위'**
  String get sortRandom;

  /// 정렬 기준 추가 — 무작위를 골랐을 때의 설명
  ///
  /// In ko, this message translates to:
  /// **'값의 순서 대신 무작위로 섞습니다. 값이 같은 항목끼리는 흐트러지지 않아 뒤 단계의 정렬이 그대로 적용됩니다.'**
  String get sortRandomNote;

  /// 그룹 기준 추가 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'그룹 기준 추가'**
  String get groupKeyAddTitle;

  /// 공통 — 더하기 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get commonAdd;

  /// 프리셋을 걸 때 태그가 사라져 걸지 못한 조각이 있었음을 알린다
  ///
  /// In ko, this message translates to:
  /// **'없는 태그를 가리키는 항목 {count}개는 빼고 불러왔습니다.'**
  String presetAppliedWithDropped(int count);

  /// 프리셋 이름 변경 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름 변경'**
  String get presetRenameTitle;

  /// 프리셋 삭제 확인 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'프리셋 삭제'**
  String get presetDeleteTitle;

  /// 프리셋 삭제 확인의 본문
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’ 프리셋을 지웁니다. 지금 걸린 조건은 그대로 남습니다.'**
  String presetDeleteBody(String name);

  /// 프리셋 캡슐 컨텍스트 메뉴 항목
  ///
  /// In ko, this message translates to:
  /// **'이름 변경…'**
  String get presetMenuRename;

  /// 프리셋 캡슐 컨텍스트 메뉴 항목 — 지금 걸린 한 벌로 갈아 끼운다
  ///
  /// In ko, this message translates to:
  /// **'현재 조건·표시로 덮어쓰기'**
  String get presetMenuOverwrite;

  /// 프리셋 툴팁 요약의 한 줄 — 앞의 이름과 담긴 내용을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'필터: {value}'**
  String presetSummaryFilter(String value);

  /// 프리셋 툴팁 요약의 한 줄 — 앞의 이름과 담긴 내용을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'정렬: {value}'**
  String presetSummarySort(String value);

  /// 프리셋 툴팁 요약의 한 줄 — 앞의 이름과 담긴 내용을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'그룹: {value}'**
  String presetSummaryGroup(String value);

  /// 프리셋 툴팁 요약의 한 줄 — 앞의 이름과 담긴 내용을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'이름: {value}'**
  String presetSummaryName(String value);

  /// 프리셋 툴팁 요약의 한 줄 — 앞의 이름과 담긴 내용을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'부제: {value}'**
  String presetSummarySubtitle(String value);

  /// 프리셋 툴팁 요약의 한 줄 — 앞의 이름과 담긴 내용을 잇는다
  ///
  /// In ko, this message translates to:
  /// **'썸네일: {value}'**
  String presetSummaryThumbnail(String value);

  /// 정렬 단계가 하나도 없을 때의 기본 차례를 가리키는 표기
  ///
  /// In ko, this message translates to:
  /// **'기본(이름순)'**
  String get sortDefaultByName;

  /// 그룹 기준이 하나도 없을 때의 표기
  ///
  /// In ko, this message translates to:
  /// **'묶지 않음'**
  String get groupNotGrouped;

  /// 이름 태그를 정하지 않았을 때 이름 칸이 보이는 기본값
  ///
  /// In ko, this message translates to:
  /// **'파일 이름'**
  String get sourceDefaultName;

  /// 부제 태그를 정하지 않았을 때 이름 아래 줄이 보이는 기본값
  ///
  /// In ko, this message translates to:
  /// **'경로'**
  String get sourceDefaultSubtitle;

  /// 썸네일 태그를 정하지 않았을 때 쓰는 기본 썸네일
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get sourceDefaultThumbnail;

  /// 프리셋 저장 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'현재 조건·표시를 프리셋으로 저장'**
  String get presetSaveTitle;

  /// 프리셋 저장 — 이름이 이미 있을 때 이름 칸에 붙는 안내
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 프리셋을 덮어씁니다.'**
  String get presetOverwriteHelper;

  /// 프리셋 저장 다이얼로그의 확인 버튼 — 같은 이름을 갈아 끼울 때
  ///
  /// In ko, this message translates to:
  /// **'덮어쓰기'**
  String get presetSaveOverwrite;

  /// 이름 아래 줄에 무엇을 보일지 정하는 자리의 이름
  ///
  /// In ko, this message translates to:
  /// **'부제'**
  String get rowSubtitle;

  /// 썸네일을 무엇으로 보일지 정하는 자리의 이름
  ///
  /// In ko, this message translates to:
  /// **'썸네일'**
  String get rowThumbnail;

  /// 출처 우선순위 목록에서 정의가 사라진 태그를 가리키는 항목
  ///
  /// In ko, this message translates to:
  /// **'(없는 태그 {tagId})'**
  String sourceMissingTag(int tagId);

  /// 이름 칸에 보일 값의 출처를 정하는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'이름 태그'**
  String get nameTagTitle;

  /// 이름 태그 다이얼로그 머리의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'목록의 이름 자리에 보일 값의 우선순위입니다. 위에서 아래로 훑어 처음으로 글자를 내는 태그의 값을 씁니다. 어느 태그도 못 내면 파일 이름을 씁니다. 이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.'**
  String get nameTagNote;

  /// 이름 태그 다이얼로그 — 고른 태그가 없을 때의 빈 목록 문구
  ///
  /// In ko, this message translates to:
  /// **'지정한 태그가 없습니다. 아래에서 태그를 추가하세요.\n(비우면 파일 이름을 그대로 씁니다.)'**
  String get nameTagEmpty;

  /// 이름 아래 줄에 보일 값의 출처를 정하는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'부제 태그'**
  String get subtitleTagTitle;

  /// 부제 태그 다이얼로그 머리의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'목록의 이름 아래 줄에 보일 값의 우선순위입니다. 위에서 아래로 훑어 처음으로 글자를 내는 태그의 값을 씁니다. 어느 태그도 못 내면 경로를 씁니다. 이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.'**
  String get subtitleTagNote;

  /// 부제 태그 다이얼로그 — 고른 태그가 없을 때의 빈 목록 문구
  ///
  /// In ko, this message translates to:
  /// **'지정한 태그가 없습니다. 아래에서 태그를 추가하세요.\n(비우면 경로를 그대로 씁니다.)'**
  String get subtitleTagEmpty;

  /// 썸네일 태그 다이얼로그 머리의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'썸네일 출처의 우선순위입니다. 위에서 아래로 훑어 처음으로 이미지를 내는 출처를 씁니다. 어느 태그도 못 내면 기본 썸네일(자기 이미지·폴더 대표)을 씁니다. 링크·이미지 유형 태그는 태그 관리에서 만듭니다. 이 설정은 조건 프리셋에 함께 담겨, 프리셋을 부르면 같이 바뀝니다.'**
  String get thumbnailTagNote;

  /// 썸네일 태그 다이얼로그 — 고른 출처가 없을 때의 빈 목록 문구
  ///
  /// In ko, this message translates to:
  /// **'지정한 출처가 없습니다. 아래에서 태그를 추가하세요.\n(비우면 기본 썸네일만 씁니다.)'**
  String get thumbnailTagEmpty;

  /// 키워드 삭제 확인 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'키워드 삭제'**
  String get keywordDeleteTitle;

  /// 키워드 삭제 확인의 본문
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’ 키워드와 그 태그를 지웁니다. 되돌릴 수 없습니다.'**
  String keywordDeleteBody(String name);

  /// 링크 태그의 대상을 고르는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'링크 대상 선택'**
  String get linkTargetPickerTitle;

  /// 링크 대상 선택 — 검색 입력의 힌트
  ///
  /// In ko, this message translates to:
  /// **'파일 이름으로 검색'**
  String get linkTargetSearchHint;

  /// 링크 대상 선택 — 검색 결과가 비었을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'일치하는 파일이 없습니다.'**
  String get linkTargetNoMatch;

  /// 태그값 입력 — 숫자 태그에 숫자가 아닌 값을 넣었을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'숫자를 입력해주세요.'**
  String get tagValueNumberRequired;

  /// 태그값 입력 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’ 값'**
  String tagValuePromptTitle(String name);

  /// 태그값 입력 칸의 이름
  ///
  /// In ko, this message translates to:
  /// **'값'**
  String get tagValueField;

  /// 태그값 입력 — 숫자 태그에서 빈 입력이 어떻게 되는지
  ///
  /// In ko, this message translates to:
  /// **'비워두면 기본값이 채워집니다.'**
  String get tagValueNumberHelper;

  /// 태그값 입력 — 텍스트 태그에서 빈 입력이 어떻게 되는지
  ///
  /// In ko, this message translates to:
  /// **'빈 값도 저장할 수 있습니다.'**
  String get tagValueTextHelper;

  /// 태그 부여 다이얼로그 — 이미 붙어 있는 태그 묶음의 제목
  ///
  /// In ko, this message translates to:
  /// **'부여된 태그'**
  String get assignedTags;

  /// 태그 부여 다이얼로그 — 붙은 태그가 하나도 없을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'아직 부여된 태그가 없습니다.'**
  String get assignedTagsEmpty;

  /// 태그 부여 다이얼로그 — 만들어 둔 태그가 하나도 없을 때의 안내
  ///
  /// In ko, this message translates to:
  /// **'먼저 태그 관리에서 태그를 만들어주세요.'**
  String get assignNoDefinitions;

  /// 여러 항목에 태그를 부여할 때 — 이 태그를 가진 항목 수
  ///
  /// In ko, this message translates to:
  /// **'{count}/{total} 파일'**
  String assignFileCount(int count, int total);

  /// 여러 항목이 같은 태그에 서로 다른 값을 갖고 있음을 알리는 표식
  ///
  /// In ko, this message translates to:
  /// **'값 혼합'**
  String get assignMixedValue;

  /// 고른 항목 전체의 태그값을 하나로 맞추는 버튼의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'값을 모두 이 값으로 설정'**
  String get assignSetValueForAll;

  /// 고른 항목 전체에서 이 태그를 떼는 버튼의 툴팁
  ///
  /// In ko, this message translates to:
  /// **'모두 해제'**
  String get assignUnassignAll;

  /// 태그 부여 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'부여'**
  String get assignConfirm;

  /// 링크 태그값 — 아직 대상을 고르지 않은 자리의 문구
  ///
  /// In ko, this message translates to:
  /// **'대상 미선택'**
  String get assignLinkNoTarget;

  /// 링크 태그값 — 대상 선택기를 여는 버튼
  ///
  /// In ko, this message translates to:
  /// **'대상 선택'**
  String get assignLinkPick;

  /// 이미지 태그값 — 미리보기에 보일 이미지가 없을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'이미지 없음'**
  String get assignNoImage;

  /// 이미지 태그값 — 파일 선택기를 여는 버튼(아직 고르지 않았을 때)
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택'**
  String get assignImagePick;

  /// 이미지 태그값 — 파일 선택기를 여는 버튼(이미 고른 뒤)
  ///
  /// In ko, this message translates to:
  /// **'이미지 변경'**
  String get assignImageChange;

  /// 날짜 태그값 — 고르지 않으면 오늘로 부여됨을 알리는 문구
  ///
  /// In ko, this message translates to:
  /// **'오늘 (미선택)'**
  String get assignDateToday;

  /// 링크 태그를 부여하려는데 대상이 비었을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'링크 대상을 선택하세요.'**
  String get assignLinkRequired;

  /// 이미지 태그를 부여하려는데 이미지가 비었을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'이미지를 선택하세요.'**
  String get assignImageRequired;

  /// 스캔 진행 문구 — 아직 첫 보고가 오지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'스캔 중…'**
  String get scanning;

  /// 스캔 진행 문구 — 훑은 항목 수만 알려졌을 때
  ///
  /// In ko, this message translates to:
  /// **'스캔 중… 항목 {seen}개 확인'**
  String scanningSeen(int seen);

  /// 스캔 진행 문구 — 파일을 읽기 시작한 뒤
  ///
  /// In ko, this message translates to:
  /// **'스캔 중… 항목 {seen}개 확인 · 파일 {indexed}개 읽음'**
  String scanningSeenIndexed(int seen, int indexed);

  /// 상태표시줄 — 워크스페이스를 아직 열지 않았을 때
  ///
  /// In ko, this message translates to:
  /// **'열린 폴더 없음'**
  String get statusNoFolder;

  /// 상태표시줄 — 목록 수를 아직 세지 못했을 때
  ///
  /// In ko, this message translates to:
  /// **'목록 불러오는 중…'**
  String get statusLoading;

  /// 상태표시줄 — 목록에 보이는 항목 수
  ///
  /// In ko, this message translates to:
  /// **'항목 {count}개'**
  String statusItemCount(int count);

  /// 상태표시줄 — 고른 항목 수
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String statusSelectedCount(int count);

  /// 상태표시줄 — 선택을 푸는 버튼
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get statusClearSelection;

  /// 상태표시줄 — 걸린 필터 조건 수
  ///
  /// In ko, this message translates to:
  /// **'필터 {count}'**
  String statusFilterCount(int count);

  /// 상태표시줄 — 걸린 정렬 단계 수
  ///
  /// In ko, this message translates to:
  /// **'정렬 {count}'**
  String statusSortCount(int count);

  /// 상태표시줄 — 태그 DB가 열려 있음
  ///
  /// In ko, this message translates to:
  /// **'DB 연결됨'**
  String get statusDbConnected;

  /// 상태표시줄 — 태그 DB가 열려 있지 않음
  ///
  /// In ko, this message translates to:
  /// **'DB 미연결'**
  String get statusDbDisconnected;

  /// 상태표시줄의 프리뷰 토글 툴팁 — 지금 보이는 상태
  ///
  /// In ko, this message translates to:
  /// **'프리뷰 숨기기'**
  String get statusHidePreview;

  /// 상태표시줄의 프리뷰 토글 툴팁 — 지금 숨긴 상태
  ///
  /// In ko, this message translates to:
  /// **'프리뷰 보기'**
  String get statusShowPreview;

  /// 상태표시줄의 새 버전 알림 툴팁
  ///
  /// In ko, this message translates to:
  /// **'눌러 릴리즈 페이지를 엽니다.'**
  String get statusUpdateHint;

  /// 상태표시줄 — 배포처에 올라온 새 버전
  ///
  /// In ko, this message translates to:
  /// **'새 버전 {version}'**
  String statusNewVersion(String version);

  /// 전역 설정이 디스크에 남지 않는 중임을 알리는 툴팁
  ///
  /// In ko, this message translates to:
  /// **'설정 파일을 쓸 수 없어 테마와 최근 폴더 목록이 이번 실행 동안만 유지됩니다.'**
  String get statusSettingsUnsavedHint;

  /// 상태표시줄 — 전역 설정 저장 실패 표시
  ///
  /// In ko, this message translates to:
  /// **'설정이 저장되지 않는 중'**
  String get statusSettingsUnsaved;

  /// 외부 앱 연동 결과 툴팁 — 실패가 있었을 때
  ///
  /// In ko, this message translates to:
  /// **'외부 앱이 요청한 태그 변경입니다. 실패한 항목은 큐 파일에 사유가 남아 있습니다.'**
  String get statusExternalHintWithFailures;

  /// 외부 앱 연동 결과 툴팁 — 모두 성공했을 때
  ///
  /// In ko, this message translates to:
  /// **'외부 앱이 요청한 태그 변경입니다.'**
  String get statusExternalHint;

  /// 상태표시줄 — 외부 요청으로 적용된 건수
  ///
  /// In ko, this message translates to:
  /// **'외부 적용 {count}'**
  String statusExternalApplied(int count);

  /// 상태표시줄 — 외부 요청 중 실패한 건수
  ///
  /// In ko, this message translates to:
  /// **'실패 {count}'**
  String statusExternalFailed(int count);

  /// 목록을 읽지 못했을 때의 알림
  ///
  /// In ko, this message translates to:
  /// **'목록을 불러오지 못했습니다: {error}'**
  String listLoadFailed(String error);

  /// 필터가 걸린 채 목록이 비었을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'필터 조건에 맞는 파일이 없습니다.'**
  String get listEmptyFiltered;

  /// 필터 없이 목록이 비었을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'이 폴더에는 표시할 파일이 없습니다.'**
  String get listEmptyFolder;

  /// 아이콘 보기에서 그룹 안이 비었을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'이 그룹에는 표시할 항목이 없습니다.'**
  String get listEmptyGroup;

  /// 트리 캐럿의 툴팁 — 지금 펼쳐진 상태
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get treeCollapse;

  /// 트리 캐럿의 툴팁 — 지금 접힌 상태
  ///
  /// In ko, this message translates to:
  /// **'펼치기'**
  String get treeExpand;

  /// 연결이 끊긴 항목의 상태 표식 툴팁
  ///
  /// In ko, this message translates to:
  /// **'연결 끊김 — 원본 파일을 찾아 태그를 재연결하세요'**
  String get markMissing;

  /// 내부를 감춘 폴더의 상태 표식 툴팁
  ///
  /// In ko, this message translates to:
  /// **'내부 감춤 — 메뉴에서 ‘내부 관리’로 펼치기'**
  String get markOpaqueFolder;

  /// 키워드 노드의 부제 자리 — 경로가 없어 종류를 대신 적는다
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get subtitleKeyword;

  /// 그룹 헤더 — 그 태그의 값이 없는 항목을 모은 버킷
  ///
  /// In ko, this message translates to:
  /// **'{name} · (미분류)'**
  String groupUnclassified(String name);

  /// 자세히 보기 열 머리글 메뉴 — 열을 더한다
  ///
  /// In ko, this message translates to:
  /// **'추가…'**
  String get detailColumnAdd;

  /// 자세히 보기 열 머리글 메뉴 — 열을 뺀다
  ///
  /// In ko, this message translates to:
  /// **'제거'**
  String get detailColumnRemove;

  /// 아이콘 보기의 경로 표시 — 파고들기 전 맨 위 자리
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get iconViewAll;

  /// 아이콘 보기에서 한 단계 위로 나가는 버튼
  ///
  /// In ko, this message translates to:
  /// **'상위로'**
  String get iconViewUp;

  /// 프리뷰 창 — 여러 항목을 골랐을 때 보이는 수
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String previewSelectedCount(int count);

  /// 프리뷰 창 — 고른 항목이 없을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'항목을 선택하면 미리보기가 표시됩니다'**
  String get previewEmpty;

  /// 모바일 폴더 관리 방식 시트의 제목
  ///
  /// In ko, this message translates to:
  /// **'폴더 관리 방식'**
  String get sheetFolderManageTitle;

  /// 모바일 폴더 관리 방식 — 내부를 감추는 갈래
  ///
  /// In ko, this message translates to:
  /// **'폴더만 관리'**
  String get sheetFolderOpaque;

  /// 모바일 폴더 관리 방식 — 폴더만 관리의 설명
  ///
  /// In ko, this message translates to:
  /// **'폴더 하나로만 다루고 내부는 감춥니다.'**
  String get sheetFolderOpaqueDetail;

  /// 모바일 폴더 관리 방식 — 내부 관리의 설명
  ///
  /// In ko, this message translates to:
  /// **'직속 내용만 인덱싱합니다.'**
  String get sheetFolderManagedDetail;

  /// 모바일 폴더 관리 방식 — 재귀 관리의 설명
  ///
  /// In ko, this message translates to:
  /// **'하위 폴더까지 이어서 인덱싱합니다.'**
  String get sheetFolderRecursiveDetail;

  /// 연결이 끊긴 항목의 원본을 지목하는 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'원본 파일 찾기'**
  String get reconnectTitle;

  /// 원본 파일 찾기 다이얼로그의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’의 태그를 옮길 원본 파일을 고르세요. 이름이 비슷한 후보가 위에 옵니다. 원본이 없으면 \"보존 취소\"로 태그를 제거할 수 있습니다.'**
  String reconnectPrompt(String name);

  /// 원본 파일 찾기 — 검색 입력의 힌트
  ///
  /// In ko, this message translates to:
  /// **'경로로 검색'**
  String get reconnectSearchHint;

  /// 원본 파일 찾기 — 후보가 하나도 없을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'연결할 수 있는(태그 없는) 후보 노드가 없습니다.'**
  String get reconnectNoCandidates;

  /// 원본 파일 찾기 — 검색 결과가 비었을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get reconnectNoMatch;

  /// 원본 파일 찾기 — 태그를 되살리지 않고 지우는 버튼
  ///
  /// In ko, this message translates to:
  /// **'보존 취소(제거)'**
  String get reconnectRemove;

  /// 태그 내보내기 다이얼로그의 제목
  ///
  /// In ko, this message translates to:
  /// **'태그 내보내기'**
  String get exportTitle;

  /// 태그 내보내기 다이얼로그의 안내 문구
  ///
  /// In ko, this message translates to:
  /// **'{count}개 항목의 태그를 요청함 파일 하나로 내보냅니다. 받는 쪽은 그 파일을 자기 폴더의 요청함에 넣기만 하면 됩니다.'**
  String exportPrompt(int count);

  /// 태그 내보내기 — 고를 태그 목록의 제목
  ///
  /// In ko, this message translates to:
  /// **'내보낼 태그'**
  String get exportTagsToSend;

  /// 태그 내보내기 — 후보를 모두 고르는 버튼
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get exportSelectAll;

  /// 태그 내보내기 — 고른 것을 모두 푸는 버튼
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get exportSelectNone;

  /// 태그 내보내기 — 내보낼 후보가 하나도 없을 때의 문구
  ///
  /// In ko, this message translates to:
  /// **'고른 항목에 붙은 태그가 없습니다.'**
  String get exportNoCandidates;

  /// 태그 내보내기 — 값을 함께 담을지 고르는 스위치
  ///
  /// In ko, this message translates to:
  /// **'태그값 포함'**
  String get exportIncludeValues;

  /// 태그 내보내기 — 태그값 포함 스위치의 설명
  ///
  /// In ko, this message translates to:
  /// **'끄면 태그만 붙고 값은 비어 갑니다.'**
  String get exportIncludeValuesDetail;

  /// 태그 내보내기 — 커스텀 이미지를 함께 담을지 고르는 스위치
  ///
  /// In ko, this message translates to:
  /// **'이미지 파일 포함'**
  String get exportIncludeImages;

  /// 태그 내보내기 — 이미지 포함 스위치의 설명
  ///
  /// In ko, this message translates to:
  /// **'커스텀 썸네일 이미지를 요청 파일 옆에 함께 씁니다.'**
  String get exportIncludeImagesDetail;

  /// 태그 내보내기 다이얼로그의 확인 버튼
  ///
  /// In ko, this message translates to:
  /// **'내보내기…'**
  String get exportConfirm;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'크기'**
  String get systemTagFileSize;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'수정 시각'**
  String get systemTagModifiedTime;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'확장자'**
  String get systemTagExtension;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'이미지 너비'**
  String get systemTagImageWidth;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'이미지 높이'**
  String get systemTagImageHeight;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'파일 이름'**
  String get systemTagFileName;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'내부 파일 수량'**
  String get systemTagChildFileCount;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'키워드'**
  String get systemTagKeyword;

  /// 시스템 태그의 이름 — 칩·피커·조건 텍스트가 함께 쓴다
  ///
  /// In ko, this message translates to:
  /// **'미해결 링크'**
  String get systemTagUnresolvedLink;

  /// 폴더 계층 그룹 키의 이름 — 그룹 줄과 조건 텍스트에서 태그 이름처럼 쓰인다
  ///
  /// In ko, this message translates to:
  /// **'폴더 계층'**
  String get groupFolderHierarchy;

  /// 키워드 이름 규칙 위반 — 이름이 비었다
  ///
  /// In ko, this message translates to:
  /// **'키워드 이름을 입력하세요.'**
  String get keywordNameEmpty;

  /// 키워드 이름 규칙 위반 — 경로 구분자가 섞였다
  ///
  /// In ko, this message translates to:
  /// **'이름에 경로 구분자(/ \\)는 쓸 수 없습니다.'**
  String get keywordNameSeparator;

  /// 키워드 이름 규칙 위반 — 같은 이름이 이미 있다
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 키워드가 이미 있습니다.'**
  String get keywordNameDuplicate;

  /// 이름 변경이 막힌 사유 — 그 자리에 같은 이름이 이미 있다
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 항목이 이미 있습니다.'**
  String get renameTargetExists;

  /// 파일 관리자를 띄울 방법이 없는 플랫폼에서의 알림
  ///
  /// In ko, this message translates to:
  /// **'이 플랫폼에서는 파일 관리자를 열 수 없습니다.'**
  String get revealUnsupported;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
