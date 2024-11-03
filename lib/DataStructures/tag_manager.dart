enum TagType {
  tagonly,
  numeric,
  string,
  date,
}

class TagTypeData {
  TagType type;
  bool isDuplicable;
  final bool _systemTag;

  TagTypeData({
    required this.type,
    this.isDuplicable = false,
    bool isSystemTag = false,
  }) : _systemTag = isSystemTag;

  bool get isSystemTag => _systemTag;
}

class TagManager {
  TagManager._(); //private 생성자

  static final TagManager _instance = TagManager._(); //싱글톤 인스턴스

  factory TagManager() => _instance;

  Map<String, TagTypeData> tagTypes = {}; //<tag이름, 해당 태그 정보>

  bool makeTag({
    required String name,
    required TagType type,
    bool duplicable = false,
    bool systemTag = false,
  }) {
    if (tagTypes.containsKey(name)) {
      //이미 존재하는 키인 경우
      return false;
    }
    tagTypes[name] = TagTypeData(
      type: type,
      isDuplicable: duplicable,
      isSystemTag: systemTag,
    );
    return true;
  }

  bool removeTag(String name) {
    if (!tagTypes.containsKey(name)) {
      //키가 없거나
      return false;
    }
    if (tagTypes[name]!.isSystemTag) {
      //시스템 태그인 경우
      return false;
    }
    tagTypes.remove(name);
    return true;
  }

  TagTypeData? getTagInfo(String name) => tagTypes[name];
}
