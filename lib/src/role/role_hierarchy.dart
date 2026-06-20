import 'app_role.dart';

class RoleHierarchy {
  const RoleHierarchy._();

  static const Set<AppRole> selfAssignable = {
    AppRole.student,
    AppRole.householder,
  };

  static List<AppRole> assignableFor(Iterable<AppRole> held) {
    final heldSet = held.toSet();
    return selfAssignable.where((r) => !heldSet.contains(r)).toList();
  }

  static const List<AppRole> _activePriority = [
    AppRole.householder,
    AppRole.student,
    AppRole.admin,
  ];

  static AppRole? defaultActive(Iterable<AppRole> held) {
    final heldSet = held.toSet();
    for (final role in _activePriority) {
      if (heldSet.contains(role)) return role;
    }
    return heldSet.isEmpty ? null : heldSet.first;
  }
}
