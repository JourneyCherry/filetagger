import 'dart:ui';

enum ValueType {
  label,
  numeric,
  string,
}

class Types {
  static int bool2int(bool value) => value ? 1 : 0;

  static bool int2bool(dynamic value) =>
      (value == null) ? false : (value as int == 1);

  static int color2int(Color value) =>
      (value.a * 255).round() << 24 |
      (value.r * 255).round() << 16 |
      (value.g * 255).round() << 8 |
      (value.b * 255).round();

  static bool verify(ValueType type, dynamic value) {
    switch (type) {
      case ValueType.label:
        return (value == null);
      case ValueType.numeric:
        return (value is int);
      case ValueType.string:
        return (value is String);
    }
  }
}
