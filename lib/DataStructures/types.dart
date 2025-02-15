import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum ValueType {
  label,
  numeric,
  string,
  datetime,
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
      case ValueType.datetime:
        return (value is DateTime);
    }
  }

  static bool isParsable(ValueType type, String? value) {
    switch (type) {
      case ValueType.label:
        return value == null || value.isEmpty;
      case ValueType.numeric:
        if (value == null) return false;
        return int.tryParse(value) != null;
      case ValueType.string:
        return true;
      case ValueType.datetime:
        if (value == null) return false;
        return DateTime.tryParse(value) != null;
    }
  }

  static dynamic parseString(ValueType type, String? value) {
    switch (type) {
      case ValueType.label:
        return null;
      case ValueType.numeric:
        if (value == null) return 0;
        return int.tryParse(value) ?? 0;
      case ValueType.string:
        return value ?? '';
      case ValueType.datetime:
        if (value == null) return DateTime.now();
        return DateTime.tryParse(value) ?? DateTime.now();
    }
  }
}

class TypeLocalizations {
  static String getTypeName(BuildContext context, ValueType type) {
    switch (type) {
      case ValueType.label:
        return AppLocalizations.of(context)!.type_label;
      case ValueType.numeric:
        return AppLocalizations.of(context)!.type_numeric;
      case ValueType.string:
        return AppLocalizations.of(context)!.type_string;
      case ValueType.datetime:
        return AppLocalizations.of(context)!.type_datetime;
    }
  }

  static String getTypeDesc(BuildContext context, ValueType type) {
    switch (type) {
      case ValueType.label:
        return AppLocalizations.of(context)!.type_label_description;
      case ValueType.numeric:
        return AppLocalizations.of(context)!.type_numeric_description;
      case ValueType.string:
        return AppLocalizations.of(context)!.type_string_description;
      case ValueType.datetime:
        return AppLocalizations.of(context)!.type_datetime_description;
    }
  }
}
