enum AppRole {
  student('Student'),
  householder('Householder'),
  admin('Admin');

  const AppRole(this.wire);

  final String wire;

  String toWire() => wire;

  static AppRole? fromWire(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final role in AppRole.values) {
      if (role.wire.toLowerCase() == normalized) return role;
    }
    return null;
  }

  static List<AppRole> fromWireList(Iterable<String> values) =>
      values.map(fromWire).whereType<AppRole>().toList();
}
