enum DataType {
  label,
  numeric,
  string,
}

class Types {
  static bool verify(int type, dynamic value) {
    switch (type) {
      case 0:
        return (value == null);
      case 1:
        return (value is int);
      case 2:
        return (value is String);
      default:
        return false;
    }
  }
}
