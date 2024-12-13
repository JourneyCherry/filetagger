enum ValueType {
  label,
  numeric,
  string,
}

class Types {
  static int bool2int(bool value) => value ? 1 : 0;

  static bool int2bool(int value) => (value == 1);

  static bool verify(ValueType type, dynamic value) {
    switch (type) {
      case ValueType.label:
        return (value == null);
      case ValueType.numeric:
        return (value is int);
      case ValueType.string:
        return (value is String);
      default:
        return false;
    }
  }
}
